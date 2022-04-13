//
//  UDPAudio.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 3/3/22.
//

import Foundation
import Network
import Combine
import AVFoundation

class UDPAudio: UDPBase {
    
    enum Published {
        case sendQueueSize(Int)
    }
    
    var published = PassthroughSubject<Published, Never>()
    
    private let engine: AVAudioEngine

//    private var rxAudioBuffer = [Int8]()
    
    private var notificationCounter = 0
    
    private var saveFile: AVAudioFile? = nil
    private var radioFormat: AVAudioFormat
    
    private let buffer: AVAudioPCMBuffer
    private let monoChannel: UnsafeMutableRawPointer
    
    private let nco = NCOCosine(frequency: Double(700), sampleRate: Double(Constants.rxSampleRate))
    
    var audioTimer: Timer?
    
    private var ringBuffer = CreateRingBuffer()
    
    private var inFrameCount = Int64(0)
    
    private var inToOutSampleTimeOffset = Float64(0)
    
    private var ablIn: AudioBufferList!

    private let mDataIn = malloc(320)

    override init(host: String, port: UInt16,
         user: String, password: String, computer: String) {
                
        engine = AVAudioEngine()
        let output = engine.outputNode
        
        // force desired output soundcard
        // get the low level input audio unit from the engine:
//        if let outputUnit = output.audioUnit {
//            // use core audio low level call to set the input device:
//            var outputDeviceID: AudioDeviceID = 51  // replace with actual, dynamic value: 73 = right monitor, 51 = headphones
//            AudioUnitSetProperty(outputUnit,
//                                 kAudioOutputUnitProperty_CurrentDevice,
//                                 kAudioUnitScope_Global,
//                                 0,
//                                 &outputDeviceID,
//                                 UInt32(MemoryLayout<AudioDeviceID>.size))
//        }
        
        
//        var absd = Codecs.absd(sampleRate: Double(Constants.rxSampleRate),
//                               bytesPerFrame: 1,
//                               channelsPerFrame: 1,
//                               coding: Codecs.Coding.linear)
//        radioFormat = AVAudioFormat(streamDescription: &absd)!
//        print (radioFormat)

        
        radioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                    sampleRate: 8000,
                                    interleaved: true,
                                    channelLayout: AVAudioChannelLayout(layoutTag: Constants.rxLayout)!)
        
        buffer = AVAudioPCMBuffer(pcmFormat: radioFormat, frameCapacity: 2048)!
        monoChannel = buffer.audioBufferList.pointee.mBuffers.mData!
        print ("mDataByteSize = \(buffer.audioBufferList.pointee.mBuffers.mDataByteSize)")
        
//        let settings = [
//            AVFormatIDKey: kAudioFormatULaw,
//            AVSampleRateKey: 8000,
//            AVNumberOfChannelsKey: 1,
//            AVLinearPCMBitDepthKey: 8
//        ]
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("ic7610.wav")
        try? FileManager.default.removeItem(at: fileUrl)
        
//        saveFile = try? AVAudioFile(forWriting: fileUrl,
//                                   settings: settings)

        super.init(host: host, port: port, user: user, password: password, computer: computer)
        // audioTimer = Timer(timeInterval: 0.2, repeats: true, block: onAudioTimer(timer:))
        
        let radioABSD = radioFormat.streamDescription.pointee
        print ("radioABSD = \(radioABSD)")
        
        AllocateBuffer(ringBuffer,
                       Int32(radioABSD.mChannelsPerFrame),
                       radioABSD.mBytesPerFrame,
                       160 * 3)
        let audioBufferIn = AudioBuffer(mNumberChannels: 1, mDataByteSize: 320, mData: mDataIn)
        ablIn = AudioBufferList(mNumberBuffers: 1, mBuffers: (audioBufferIn))
        
        let srcNode = AVAudioSourceNode(format: radioFormat) { [weak self] _, timeStamp, frameCount, audioBufferList -> OSStatus in
            if let self = self {
                // print ("frameCount: \(frameCount)")
                Locks.audioLock.lock()
                defer {
                    Locks.audioLock.unlock()
                }
                if self.inToOutSampleTimeOffset == -1 {
                    self.inToOutSampleTimeOffset = Double(timeStamp.pointee.mSampleTime)
                    print ("inOutSampleTimeOffset = \(self.inToOutSampleTimeOffset)")
                }
                let outputProcErr = FetchBuffer(self.ringBuffer,
                                                audioBufferList,
                                                frameCount,
                                                Int64(timeStamp.pointee.mSampleTime - self.inToOutSampleTimeOffset))
                
                self.inToOutSampleTimeOffset += Double((frameCount - audioBufferList.pointee.mBuffers.mDataByteSize / 2))
                
                // print ("mDataByteSize = \(audioBufferList.pointee.mBuffers.mDataByteSize)")
                 
                if outputProcErr > 0 {
                    print ("FetchBuffer error \(outputProcErr)")
                }
            }
            return noErr
        }
        engine.attach(srcNode)
        engine.connect(srcNode, to: output, format: radioFormat)
        

        do {
            try engine.start()
        } catch {
            basePublished.send(.state("Could not start engine: \(error)"))
        }
        // RunLoop.main.add(audioTimer!, forMode: .common)
    }
    
    override func startConnection() {
        disconnecting = false
        retryPacket = packetCreate.areYouTherePacket()
        send(data: retryPacket)
    }

    
    func disconnect() {
        saveFile = nil
        engine.stop()
        basePublished.send(.state("Disconnecting..."))
        invalidateTimers()
        disconnecting = true
        send(data: self.packetCreate.disconnectPacket())
        armIdleTimer()
    }
    
    override func receive(data: Data) {
        typealias c = AudioDefinition
        current = data
        // print ("data.count = \(data.count)")
        if checkRetransmitRequest() {
            return
        }
        Locks.audioLock.lock()
        defer {
            Locks.audioLock.unlock()
        }
        if current.count > c.headerLength {
            if inToOutSampleTimeOffset == 0 {
                inToOutSampleTimeOffset = -1
                inFrameCount = 0
            }
            let audioData = current.dropFirst(c.headerLength)
            
            audioData.withUnsafeBytes{ dPtr in
                let data = Array(dPtr.bindMemory(to: Int8.self))
                // print ("data.count \(data.count)")
                mDataIn?.copyMemory(from: data, byteCount: data.count)
                
                // print ("inFrameCount = \(inFrameCount)")
                let storeError = StoreBuffer(ringBuffer, &ablIn, UInt32(data.count / 2), inFrameCount)
                inFrameCount += Int64(data.count / 2)
                if storeError != 0 {
                    print("StoreBuffer error = \(storeError)")
                }

                if let saveFile = saveFile {
                    // audioBuffer.mData?.copyMemory(from: data, byteCount: data.count)
                    // monoChannel.assign(from: data, count: data.count)
                    monoChannel.copyMemory(from: data, byteCount: data.count)
                    buffer.frameLength = UInt32(data.count)
                    do {
                        try saveFile.write(from: buffer)
                    } catch {
                        print (error)
                    }
                }
            }
            
            return
        }
        switch current.count {
        case ControlDefinition.dataLength:
            typealias p = ControlDefinition
            switch current[p.type].uint16 {
            case ControlPacketType.iAmHere:
                let remoteId = current[p.sendId].uint32
                packetCreate.remoteId = remoteId
                basePublished.send(.connected(true))
                basePublished.send(.state("Connected"))
                
                let packet = packetCreate.areYouReadyPacket()
                send(data: packet)

                
                self.invalidateTimers()
                // armIdleTimer()
                armPingTimer()
            default:
                break
            }
        case PingDefinition.dataLength:
            receivePing()
        default:
            break
        }
    }
    

    func onAudioTimer(timer: Timer) {
        var data = [Int16]()
        data.reserveCapacity(160)
        for _ in 0..<10 {
            data.removeAll(keepingCapacity: true)
            for _ in 0..<160 {
                data.append(nco.value)
            }
            let packet = packetCreate.audioPacket(data: data)
            send(data: packet)
        }
    }
}

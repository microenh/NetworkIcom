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

    private var rxAudioBuffer = [Int8]()
    
    private var notificationCounter = 0
    
    private var saveFile: AVAudioFile? = nil
    private var radioFormat: AVAudioFormat
    
    private let buffer: AVAudioPCMBuffer
    private let monoChannel: UnsafeMutableRawPointer
    
    private let nco = NCOCosine(frequency: Double(700), sampleRate: Double(Constants.rxSampleRate))
    
    var audioTimer: Timer?
    
    
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
        
        
        var absd = Codecs.absd(sampleRate: Double(Constants.rxSampleRate),
                               bytesPerFrame: 1,
                               channelsPerFrame: 1,
                               coding: Codecs.Coding.ulaw)
        radioFormat = AVAudioFormat(streamDescription: &absd)!
        // print (radioFormat)

        
//        radioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
//                                    sampleRate: Double(Constants.rxSampleRate),
//                                    interleaved: true,
//                                    channelLayout: AVAudioChannelLayout(layoutTag: Constants.rxLayout)!)
        
        buffer = AVAudioPCMBuffer(pcmFormat: radioFormat, frameCapacity: 2048)!
        monoChannel = buffer.audioBufferList.pointee.mBuffers.mData!
        print (buffer.audioBufferList.pointee.mBuffers.mDataByteSize)
        
        let settings = [
            AVFormatIDKey: kAudioFormatULaw,
            AVSampleRateKey: 8000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 8
        ]
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("ic7610.wav")
        try? FileManager.default.removeItem(at: fileUrl)
        
//        saveFile = try? AVAudioFile(forWriting: fileUrl,
//                                   settings: settings)

        super.init(host: host, port: port, user: user, password: password, computer: computer)
        // audioTimer = Timer(timeInterval: 0.2, repeats: true, block: onAudioTimer(timer:))
        
        let srcNode = AVAudioSourceNode(format: radioFormat) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            if let self = self {
                Locks.audioLock.lock()
                let adjFrameCount = (Codecs.isStereo(Constants.rxCodec) ? 2 : 1) * Int(frameCount)
                // print (adjFrameCount)
                if self.notificationCounter == 0 {
                    self.notificationCounter = 200
                    let ct = self.rxAudioBuffer.count
                    if ct >= 4 * adjFrameCount {
                        self.rxAudioBuffer.removeFirst(ct - adjFrameCount)
                    }
                    self.published.send(.sendQueueSize(self.rxAudioBuffer.count))
                } else {
                    self.notificationCounter -= 1
                }
                let buf1 = UnsafeMutableRawPointer(audioBufferList.pointee.mBuffers.mData)
                if let buf1 = buf1 {
                    if self.rxAudioBuffer.count >= adjFrameCount {
                        buf1.copyMemory(from: self.rxAudioBuffer, byteCount: adjFrameCount)
                        self.rxAudioBuffer.removeFirst(adjFrameCount)
                    } else {
                        buf1.initializeMemory(as: UInt8.self, repeating: 0, count: adjFrameCount)
                    }
                }
                Locks.audioLock.unlock()
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
        if checkRetransmitRequest() {
            return
        }
        if current.count > c.headerLength {
            Locks.audioLock.lock()
            let audioData = current.dropFirst(c.headerLength)
            audioData.withUnsafeBytes{ (dPtr: UnsafeRawBufferPointer) in
                let data = Array(dPtr.bindMemory(to: Int8.self))
                // print (data.count)
                rxAudioBuffer.append(contentsOf: data)

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
            
            Locks.audioLock.unlock()
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

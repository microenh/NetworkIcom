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
        case underrunCount(Int)
        case overrunCount(Int)
    }
    
    var published = PassthroughSubject<Published, Never>()
    
    private let engine: AVAudioEngine

    private var notificationCounter = 0
    
    private var saveFile: AVAudioFile? = nil
    private var radioFormat: AVAudioFormat
    
//    private let buffer: AVAudioPCMBuffer
//    private let monoChannel: UnsafeMutableRawPointer
    
    private var underrunCount = 0
    private var overrunCount = 0
    
    private var ringBuffer = FIFORingBuffer()
    
    private let buffer: AVAudioPCMBuffer
    private let monoChannel: UnsafeMutablePointer<Int16>
    
    init(mConnectionInfo: ConnectionInfo,
         mPort: UInt16,
         rxAudio: RxAudio,
         txAudio: TxAudio) {
                        
        ringBuffer.bytesPerFrame = rxAudio.bytesPerFrame
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
        
        
        let audioFormat = rxAudio.audioFormat
        guard let audioFormat = audioFormat else {
            print ("bad format")
            exit(1)
        }
        self.radioFormat = audioFormat
        
//        let settings = [
//            AVFormatIDKey: audioFormat.  // kAudioFormatULaw,
//            AVSampleRateKey: 8000,
//            AVNumberOfChannelsKey: 1,
//            AVLinearPCMBitDepthKey: 8
//        ]
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("ic7610.wav")
        try? FileManager.default.removeItem(at: fileUrl)
        
        saveFile = try? AVAudioFile(forWriting: fileUrl,
                                    settings: audioFormat.settings)
        
        buffer = AVAudioPCMBuffer(pcmFormat: radioFormat, frameCapacity: 2048)!
        monoChannel = buffer.int16ChannelData![0]

        super.init(mConnectionInfo: mConnectionInfo, mPort: mPort,
                   mRxAudio: rxAudio, mTxAudio: txAudio)
         
        // print ("radioFormat: \(radioFormat)")
        let srcNode = AVAudioSourceNode(format: radioFormat) { [weak self] _, timeStamp, frameCount, audioBufferList -> OSStatus in
            if let self = self {
                // print ("frameCount: \(frameCount)")
                Locks.audioLock.lock()
                defer {
                    Locks.audioLock.unlock()
                }
                if self.ringBuffer.fetch(abl: audioBufferList, frameCount: Int(frameCount)) {
                    self.underrunCount += 1
                    self.published.send(.underrunCount(self.underrunCount))
                }
            }
            return noErr
        }
        
        engine.attach(srcNode)
        engine.connect(srcNode, to: output, format: radioFormat)
        // engine.prepare()
    
        do {
            try engine.start()
        } catch {
            basePublished.send(.state("Could not start engine: \(error)"))
        }
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
            let audioData = current.dropFirst(c.headerLength)
            // print (audioData.count)
            if ringBuffer.store(audioData) {
                self.overrunCount += 1
                self.published.send(.overrunCount(self.overrunCount))
            }
            audioData.withUnsafeBytes{ (dPtr: UnsafeRawBufferPointer) in
                let data = Array(dPtr.bindMemory(to: Int16.self))
                
                if let saveFile = saveFile {
                    monoChannel.assign(from: data, count: data.count)
                    buffer.frameLength = UInt32(data.count)
                    do {
                        try saveFile.write(from: buffer)
                    } catch {
                        print (error)
                    }
                }
            }
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
}

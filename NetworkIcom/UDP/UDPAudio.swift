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

    private var rxAudioBuffer = [Int16]()
    
    private var notificationCounter = 0
    
    override init(host: String, port: UInt16,
         user: String, password: String, computer: String) {
                
        engine = AVAudioEngine()
        let output = engine.outputNode
        
        // force desired output soundcard
        // get the low level input audio unit from the engine:
        if let outputUnit = output.audioUnit {
            // use core audio low level call to set the input device:
            var outputDeviceID: AudioDeviceID = 51  // replace with actual, dynamic value: 73 = right monitor, 51 = headphones
            AudioUnitSetProperty(outputUnit,
                                 kAudioOutputUnitProperty_CurrentDevice,
                                 kAudioUnitScope_Global,
                                 0,
                                 &outputDeviceID,
                                 UInt32(MemoryLayout<AudioDeviceID>.size))
        }
            
        super.init(host: host, port: port, user: user, password: password, computer: computer)
        
        let radioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                        sampleRate: Double(Constants.rxSampleRate),
                                        interleaved: true,
                                        channelLayout: AVAudioChannelLayout(layoutTag: Constants.rxLayout)!)
        
        let srcNode = AVAudioSourceNode(format: radioFormat) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            if let self = self {
                if self.notificationCounter == 0 {
                    self.notificationCounter = 200
                    self.published.send(.sendQueueSize(self.rxAudioBuffer.count))
                } else {
                    self.notificationCounter -= 1
                }
                let buf = UnsafeMutableBufferPointer<Int16>(UnsafeMutableAudioBufferListPointer(audioBufferList)[0])
                let adjFrameCount = (Constants.rxStereo ? 2 : 1) * Int(frameCount)
                if self.rxAudioBuffer.count >= adjFrameCount {
                    Locks.audioLock.lock()
                    for frame in 0..<adjFrameCount {
                        buf[frame] = self.rxAudioBuffer[frame]
                    }
                    self.rxAudioBuffer.removeFirst(adjFrameCount)
                    Locks.audioLock.unlock()
                } else {
                    for frame in 0..<adjFrameCount {
                        buf[frame] = 0
                    }
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
    }
    
    override func startConnection() {
        disconnecting = false
        retryPacket = packetCreate.areYouTherePacket()
        send(data: retryPacket)
    }

    
    func disconnect() {
        engine.stop()
        basePublished.send(.state("Disconnecting..."))
        invalidateTimers()
        disconnecting = true
        // send(data: self.packetCreate.disconnectPacket())
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
            current.dropFirst(c.headerLength).withUnsafeBytes{ (dPtr: UnsafeRawBufferPointer) in
                rxAudioBuffer.append(contentsOf: Array(dPtr.bindMemory(to: Int16.self)))
            }
            Locks.audioLock.unlock()
            return
        }
        switch current.count {
        case ControlDefinition.dataLength:
            typealias p = ControlDefinition
            switch current[p.type].uint16 {
            case ControlPacketType.iAmHere:
                packetCreate.remoteId = current[p.sendId].uint32
                basePublished.send(.connected(true))
                basePublished.send(.state("Connected"))

                
                self.invalidateTimers()
                // armIdleTimer()
                // armPingTimer()
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

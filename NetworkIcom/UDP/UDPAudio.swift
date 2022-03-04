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
import DequeModule

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
        // let outputFormat = output.inputFormat(forBus: 0)
        
        // print (outputFormat.sampleRate)
        
        let inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                        sampleRate: Double(Constants.rxSampleRate), //outputFormat.sampleRate,
                                    interleaved: true,
                                    channelLayout: AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono)!)

        super.init(host: host, port: port, user: user, password: password, computer: computer)
        let srcNode = AVAudioSourceNode { [weak self] isSilence, _, frameCount, audioBufferList -> OSStatus in
            // isSilence.pointee = true
            if let self = self {
                if self.notificationCounter == 0 {
                    self.notificationCounter = 50
                    self.published.send(.sendQueueSize(self.rxAudioBuffer.count))
                } else {
                    self.notificationCounter -= 1
                }
                let buf: UnsafeMutableBufferPointer<Int16> = UnsafeMutableBufferPointer(UnsafeMutableAudioBufferListPointer(audioBufferList)[0])
                if self.rxAudioBuffer.count >= frameCount {
                    Locks.audioLock.lock()
                    for frame in 0..<Int(frameCount) {
                        buf[frame] = self.rxAudioBuffer[frame]
                    }
                    self.rxAudioBuffer.removeFirst(Int(frameCount))
                    Locks.audioLock.unlock()
                    // isSilence.pointee = false
                } else {
                    for frame in 0..<Int(frameCount) {
                        buf[frame] = 0
                    }
                }
            }
            return noErr
        }
        engine.attach(srcNode)
        engine.connect(srcNode, to: output, format: inputFormat)
        do {
            try engine.start()
        } catch {
            print("Could not start engine: \(error)")
        }

    }
    
    func disconnect() {
        basePublished.send(.state("Disconnecting..."))
        self.invalidateTimers()
        self.disconnecting = true
        self.send(data: self.packetCreate.disconnectPacket())
        self.armIdleTimer()
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
//            DispatchQueue.main.async { [weak self] in
//                self?.civDecode(civData)
//            }
            return
        }
        switch current.count {
        case ControlDefinition.dataLength:
            typealias p = ControlDefinition
            switch current[p.type].uint16 {
            case ControlPacketType.iAmHere:
                packetCreate.remoteId = current[p.sendId].uint32
                basePublished.send(.state("Connected"))
                basePublished.send(.connected(true))
                
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

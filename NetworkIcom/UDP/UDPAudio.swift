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

    private var deque = Deque<Int16>()

    override init(host: String, port: UInt16,
         user: String, password: String, computer: String) {
        
        engine = AVAudioEngine()
        let output = engine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        
        let inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                    sampleRate: outputFormat.sampleRate,
                                    interleaved: true,
                                    channelLayout: AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Stereo)!)

        super.init(host: host, port: port, user: user, password: password, computer: computer)
        let srcNode = AVAudioSourceNode { [weak self] isSilence, _, frameCount, audioBufferList -> OSStatus in
            isSilence.pointee = true
            if let self = self {
                if self.deque.count >= 2 * frameCount {
                    Locks.audioLock.lock()
                    let buf: UnsafeMutableBufferPointer<Int16> = UnsafeMutableBufferPointer(UnsafeMutableAudioBufferListPointer(audioBufferList)[0])
                    for frame in 0..<Int(frameCount) {
                        buf[frame * 2] = self.deque.removeFirst()
                        buf[frame * 2 + 1] = self.deque.removeFirst()
                    }
                    Locks.audioLock.unlock()
                    isSilence.pointee = false
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
            let audioData = current.dropFirst(c.headerLength)
            Locks.audioLock.lock()
            audioData.withUnsafeBytes { (dataPtr: UnsafeRawBufferPointer) in
                for i in 0..<audioData.count / 2 {
                    let i16 = dataPtr.load(fromByteOffset: i * 2, as: Int16.self)
                    deque.append(i16)
                }
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
                armIdleTimer()
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

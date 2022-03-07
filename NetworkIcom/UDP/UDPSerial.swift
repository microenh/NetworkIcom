//
//  UDPSerial.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/10/22.
//

import Foundation
import Network
import Combine

class UDPSerial: UDPBase {
    
    private(set) var civ: CIV
    
    enum Published {
        case sendQueueSize(Int)
    }
    
    let civDecode: (Data) -> ()
    
    var published = PassthroughSubject<Published, Never>()

    init(host: String, port: UInt16,
         user: String, password: String, computer: String,
         radioCivAddr: UInt8, hostCivAddr: UInt8,
         civDecode: @escaping (Data) -> ()) {
        
        civ = CIV(radioCivAddr: radioCivAddr, hostCivAddr: hostCivAddr)
        self.civDecode = civDecode
        super.init(host: host, port: port, user: user, password: password, computer: computer)
    }
    
    func disconnect() {
        basePublished.send(.state("Disconnecting..."))
        self.invalidateTimers()
        self.disconnecting = true
        self.send(data: self.packetCreate.disconnectPacket())
        self.send(data: self.packetCreate.openClosePacket(open: false))
        self.armIdleTimer()
    }
       
    private var sendQueue = Queue<Data>()
    private var waitReply = false
    func send(command: UInt8,
              subCommand: UInt8? = nil,
              selector: Data? = nil,
              data: Data? = nil) {
        let civPacket = civ.buildRequest(command: command,
                                         subCommand: subCommand,
                                         selector: selector,
                                         data: data)
        sendQueue.enqueue(civPacket)
        published.send(.sendQueueSize(sendQueue.size))
        sendIfNeeded()
    }
    
    private func sendIfNeeded() {
        if !waitReply, let data = sendQueue.dequeue() {
            published.send(.sendQueueSize(sendQueue.size))
            waitReply = true
            let civPacket = packetCreate.civPacket(civData: data)
            // print(civPacket.dump())
            track(data: civPacket)
            send(data: civPacket)
        }
    }
    
    override func onIdleTimer(timer: Timer) {
        waitReply = false
        super .onIdleTimer(timer: timer)
    }
    
    override func receive(data: Data) {
        typealias c = CIVDefinition
        current = data
        if checkRetransmitRequest() {
            return
        }
        if current.count > c.headerLength && current[c.cmd].uint8 == CIVCode.code {
            // print (current.dump)
            let civData = Data(current.dropFirst(c.headerLength))
            // print (civData.dump)
            if !civ.isUnsolicited(civData: civData) {
                waitReply = false
                sendIfNeeded()
            }
//            DispatchQueue.main.async { [weak self] in
//                self?.civDecode(civData)
//            }
            self.civDecode(civData)
            return
        }
        switch current.count {
        case ControlDefinition.dataLength:
            typealias p = ControlDefinition
            switch current[p.type].uint16 {
            case ControlPacketType.iAmHere:
                packetCreate.remoteId = current[p.sendId].uint32
                armResendTimer()
                retryPacket = packetCreate.areYouReadyPacket()
                send(data: retryPacket)
            case ControlPacketType.iAmReady:
                resendTimer?.invalidate()
                let packet = packetCreate.openClosePacket(open: true)
                send(data: packet)
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

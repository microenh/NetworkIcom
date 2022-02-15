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

    init(host: String, port: UInt16,
         user: String, password: String, computer: String,
         radioCivAddr: UInt8, hostCivAddr: UInt8) {
        
        civ = CIV(radioCivAddr: radioCivAddr, hostCivAddr: hostCivAddr)
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
              selector: UInt8? = nil,
              data: [UInt8]? = nil) {
        let civPacket = civ.buildRequest(command: command,
                                         subCommand: subCommand,
                                         selector: selector,
                                         data: data)
        sendQueue.enqueue(civPacket)
        sendIfNeeded()
    }
    
    private func sendIfNeeded() {
        if !waitReply || true, let data = sendQueue.dequeue() {
            waitReply = true
            let civPacket = packetCreate.civPacket(civData: data)
            // print(civPacket.dump())
            track(data: civPacket)
            send(data: civPacket)
        }
    }
    
    override func receive(data: Data) {
        typealias c = CIVDefinition
        current = data
        if checkRetransmitRequest() {
            return
        }
        if current.count > c.headerLength && current[c.cmd].uint8 == CIVCode.code {
            civ.decode(current)
            if civ.isReply {
                waitReply = false
                sendIfNeeded()
            }
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

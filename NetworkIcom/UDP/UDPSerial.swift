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
    
    private(set) var civDecode: CIV

    init(host: String, port: UInt16,
         user: String, password: String, computer: String,
         radioCivAddr: UInt8, hostCivAddr: UInt8) {
        
        civDecode = CIV(radioCivAddr: radioCivAddr, hostCivAddr: hostCivAddr)
        super.init(host: host, port: port, user: user, password: password, computer: computer)
    }
    
    func disconnect() {
        udpBasePublishedData.send(.state("Disconnecting..."))
        self.invalidateTimers()
        self.disconnecting = true
        self.send(data: self.packetCreate.openClosePacket(open: false))
        self.armIdleTimer()
    }
        
    override func receive(data: Data) {
        typealias c = CIVDefinition
        current = data
        if checkRetransmitRequest() {
            return
        }
        if current.count > c.headerLength && current[c.cmd].uint8 == CIVCode.code {
            // let civ = current.dropFirst(c.headerLength)
            civDecode.decode(current)
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
                armResendTimer()
                let packet = packetCreate.openClosePacket(open: true)
                send(data: packet)
                udpBasePublishedData.send(.state("Connected"))
                udpBasePublishedData.send(.connected(true))
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

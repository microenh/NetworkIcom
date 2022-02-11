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
    
    private(set) var civData = CurrentValueSubject<Data, Never>(Data())
    
    private var packetCreate: PacketCreateSerial
    private(set) var civDecode: CIVDecode

    init(host: String,
         port: UInt16,
         radioCivAddr: UInt8,
         hostCivAddr: UInt8) {
        
        civDecode = CIVDecode(radioCivAddr: radioCivAddr, hostCivAddr: hostCivAddr)
        
        packetCreate = PacketCreateSerial()
        super.init(host: host, port: port)
    }
    
    func disconnect() {
        state.value = "Disconnecting..."
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
            let civ = current.dropFirst(c.headerLength)
            civData.value = civ
            civDecode.decode(civData: civ)
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
                state.value = "Connected"
                connected.send(true)
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
    
    // -----
    
    override func createAreYouTherePacket() -> Data {
        packetCreate.areYouTherePacket()
    }
    
    override func createPingPacket() -> Data {
        packetCreate.pingPacket()
    }
    
    override func createPingPacket(replyTo: Data) -> Data {
        packetCreate.pingPacket(replyTo: replyTo)
    }
    
    override func createIdlePacket() -> Data {
        packetCreate.idlePacket()
    }

    override func createIdlePacket(withSequence: UInt16) -> Data {
        packetCreate.idlePacket(withSequence: withSequence)
    }
}

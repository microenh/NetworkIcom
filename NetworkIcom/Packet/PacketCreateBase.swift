//
//  PacketCreateBase.swift
//  NetworkWWDC2018
//
//  Created by Mark Erbaugh on 2/6/22.
//

import Foundation

class PacketCreateBase {
    let myId = UInt32.random(in: .min ... .max)
    var remoteId: UInt32? = nil
    private var pingDataA = UInt16(0)
    private let pingDataB = UInt16.random(in: .min ... .max)
    
    private var _idlePacket: Data? = nil
    private var _pingPacket: Data? = nil
    
    private var _sequence = UInt16(0)
    private var _pingSequence = UInt16(0)
    
//    private var retransmitSequences = Queue<UInt16>()
//    private var retransmitData = [UInt16: Data]()
        
    // ------------------------------------------------------------------
    
    var sequence: UInt16 {
        _sequence &+= 1
        return _sequence
    }
       
    private var pingSequence: UInt16 {
        _pingSequence &+= 1
        return _pingSequence
    }

    func idlePacket(withSequence: UInt16? = nil) -> Data {
        typealias p = ControlDefinition
        let seq = withSequence ?? sequence
        if _idlePacket == nil {
            var packet = Data(count: p.dataLength)
            packet[p.length] = Data(UInt32(p.dataLength))
            packet[p.type] = Data(ControlPacketType.idle)
            packet[p.sendId] = Data(myId)
            packet[p.sequence] = Data(seq)
            if let remoteId = remoteId {
                packet[p.recvId] = Data(remoteId)
                _idlePacket = packet
            }
            return packet
        } else {
            _idlePacket![p.sequence] = Data(seq)
            return _idlePacket!
        }
    }
    
    func pingPacket() -> Data {
        typealias c = ControlDefinition
        typealias p = PingDefinition
        let sequence = pingSequence
        if _pingPacket == nil {
            var packet = Data(count: p.dataLength)
            packet[c.length] = Data(UInt32(p.dataLength))
            packet[c.type] = Data(PingPacketType.ping)
            packet[c.sendId] = Data(myId)
            packet[p.dataA] = Data(pingDataA)
            pingDataA = UInt16.random(in: UInt16.min...UInt16.max)
            packet[p.dataB] = Data(pingDataB)
            packet[c.sequence] = Data(sequence)
            if let remoteId = remoteId {
                packet[c.recvId] = Data(remoteId)
                _pingPacket = packet
            }
            return packet
        } else {
            _pingPacket![c.sequence] = Data(sequence)
            return _pingPacket!
        }
    }
    
    func pingPacket(replyTo: Data) -> Data {
        typealias c = ControlDefinition
        typealias p = PingDefinition
        var result = replyTo
        result[c.length] = Data(UInt32(p.dataLength))
        result[c.sendId] = replyTo[c.recvId]
        result[c.recvId] = replyTo[c.sendId]
        result[p.request] = Data(UInt8(1))
        return result
    }
    
    func areYouTherePacket() -> Data {
        typealias c = ControlDefinition
        var packet = Data(count: c.dataLength)
        packet[c.length] = Data(UInt32(c.dataLength))
        packet[c.type] = Data(ControlPacketType.areYouThere)
        packet[c.sendId] = Data(myId)
        return packet
    }
    
    func areYouReadyPacket() -> Data {
        typealias c = ControlDefinition
        var packet = Data(count: c.dataLength)
        packet[c.length] = Data(UInt32(c.dataLength))
        packet[c.type] = Data(ControlPacketType.areYouReady)
        packet[c.sendId] = Data(myId)
        packet[c.sequence] = Data(UInt16(1))
        if let remoteId = remoteId {
            packet[c.recvId] = Data(remoteId)
        }
        return packet
    }
    
    func disconnectPacket() -> Data {
        typealias c = ControlDefinition
        var packet = Data(count: c.dataLength)
        packet[c.length] = Data(UInt32(c.dataLength))
        packet[c.type] = Data(ControlPacketType.disconnect)
        packet[c.sendId] = Data(myId)
        packet[c.sequence] = Data(UInt16(1))
        if let remoteId = remoteId {
            packet[c.recvId] = Data(remoteId)
        }
        return packet
    }
    
//    func parseRequest(data: Data) -> [UInt16] {
//        var result = [UInt16]()
//        typealias p = ControlDefinition
//        if data.count == p.dataLength {
//            result.append(data[p.sequence].uint16)
//        } else {
//            for i in stride(from: 16, to: data.count, by: 4) {
//                result.append(data[i..<i+2].uint16)
//            }
//        }
//        // print (result)
//        return result
//    }
//    
//    private static let queueSize = 20
//    
//    func track(data: Data) {
//        typealias c = ControlDefinition
//        let sequence = data[c.sequence].uint16
//        if retransmitSequences.size == PacketCreateBase.queueSize {
//            if let oldSequence = retransmitSequences.dequeue() {
//                _ = retransmitData.removeValue(forKey: oldSequence)
//            }
//        }
//        retransmitSequences.enqueue(sequence)
//        retransmitData[sequence] = data
//    }
//    
//    func getTracked(sequence: UInt16) -> Data {
//        retransmitData[sequence] ?? idlePacket(withSequence: sequence)
//    }

}

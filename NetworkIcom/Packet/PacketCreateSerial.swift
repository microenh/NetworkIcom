//
//  PacketCreateSerial.swift
//  NetworkWWDC2018
//
//  Created by Mark Erbaugh on 2/6/22.
//

import Foundation

class PacketCreateSerial: PacketCreateBase {
        
    private var _civHeader: Data? = nil
    
    private var _civSequence = UInt16(0)
    
    // ------------------------------------------------------------------
    
    var civSequence: UInt16 {
        _civSequence &+= 1
        return _civSequence
    }
    
    func openClosePacket(open: Bool) -> Data {
        typealias c = ControlDefinition
        typealias o = OpenCloseDefinition
        var packet = Data(count: o.dataLength)
        packet[c.length] = Data(UInt32(o.dataLength))
        packet[c.sendId] = Data(myId)
        packet[c.sequence] = Data(sequence)
        if let remoteId = remoteId {
            packet[c.recvId] = Data(remoteId)
        }
        packet[o.data] = Data(PacketCode.openClose)
        packet[o.sequence] = Data(open ? UInt16(1) : 0)
        packet[o.request] = Data(open ? OpenClosePacketType.open : OpenClosePacketType.close)
        return packet
    }
    
    func civPacket(civData: Data) -> Data {
        typealias c = ControlDefinition
        typealias civ = CIVDefinition
        if _civHeader == nil {
            _civHeader = Data(count: civ.headerLength)
            _civHeader![c.sendId] = Data(myId)
            _civHeader![c.recvId] = Data(remoteId)
            _civHeader![civ.cmd] = Data(CIVCode.code)
        }
        _civHeader![c.length] = Data(UInt32(civ.headerLength + civData.count))
        _civHeader![c.sequence] = Data(sequence)
        _civHeader![civ.length] = Data(UInt16(civData.count))
        _civHeader![civ.sequence] = Data(civSequence.bigEndian)

        return _civHeader! + civData
    }
}

//
//  PacketCreate.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/11/22.
//

import Foundation

class PacketCreate {
    let myId = UInt32.random(in: .min ... .max)
    var remoteId: UInt32? = nil
    private var pingDataA = UInt16(0)
    private let pingDataB = UInt16.random(in: .min ... .max)
    
    private var _idlePacket: Data? = nil
    private var _pingPacket: Data? = nil
    
    private var _sequence = UInt16(0)
    private var _pingSequence = UInt16(0)
    
    private var _civHeader: Data? = nil
    private var _civSequence = UInt16(0)
    
    private var user: String
    private var password: String
    private var computer: String
    
    private var tokRequest = UInt16.random(in: .min ... .max)
    var token: UInt32? = nil
    
    private var _tokenPacket: Data? = nil
    
    private var _innerSequence = UInt8(0)
        
    init(user: String, password: String, computer: String) {
        self.user = user
        self.password = password
        self.computer = computer
    }

    // ------------------------------------------------------------------
    
    private var sequence: UInt16 {
        _sequence &+= 1
        return _sequence
    }
       
    private var civSequence: UInt16 {
        _civSequence &+= 1
        return _civSequence
    }
 
    private var pingSequence: UInt16 {
        _pingSequence &+= 1
        return _pingSequence
    }
    
    var innerSequence: UInt8 {
        _innerSequence &+= 1
        return _innerSequence
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

    func disconnectPacket(replyTo: Data) -> Data {
        typealias c = ControlDefinition
        var packet = Data(count: c.dataLength)
        packet[c.length] = Data(UInt32(c.dataLength))
        packet[c.type] = Data(ControlPacketType.disconnect)
        packet[c.sendId] = replyTo[c.recvId]
        packet[c.recvId] = replyTo[c.sendId]
        packet[c.sequence] = Data(UInt16(1))
        return packet
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
        packet[o.cmd] = Data(PacketCode.openClose)
        packet[o.length] = Data(UInt16(1))
        packet[o.sequence] = Data(civSequence.bigEndian)
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
        _civHeader![civ.sequence] = Data(civSequence)

        return _civHeader! + civData
    }

    func tokenPacket(tokenType: UInt16 = TokenType.renew) -> Data {
        typealias c = ControlDefinition
        typealias t = TokenDefinition
        let seq = sequence
        if _tokenPacket == nil {
            var packet = Data(count: t.dataLength)
            packet[c.length] = Data(UInt32(t.dataLength))
            packet[c.sendId] = Data(myId)
            packet[t.tokReq] = Data(tokRequest)
            packet[t.code] = Data(PacketCode.token)
            packet[t.res] = Data(tokenType)
            packet[c.sequence] = Data(seq)
            packet[t.sequence] = Data(innerSequence)
            if let remoteId = remoteId, let token = token {
                packet[c.recvId] = Data(remoteId)
                packet[t.token] = Data(token)
                _tokenPacket = packet
            }
            return packet
        } else {
            _tokenPacket![t.res] = Data(tokenType)
            _tokenPacket![c.sequence] = Data(seq)
            _tokenPacket![t.sequence] = Data(innerSequence)
            return _tokenPacket!
        }
    }
    
    func statusPacket(replyTo: Data) -> Data {
        typealias c = ControlDefinition
        typealias t = TokenDefinition
        typealias s = StatusDefinition
        var result = replyTo
        result[c.sendId] = replyTo[c.recvId]
        result[c.recvId] = replyTo[c.sendId]
        result[t.reqRep] = Data(true)

        return result
    }
    
    func loginPacket() -> Data {
        typealias c = ControlDefinition
        typealias t = TokenDefinition
        typealias l = LoginDefinition
        var packet = Data(count: l.dataLength)
        packet[c.length] = Data(UInt32(l.dataLength))
        packet[c.sequence] = Data(sequence)
        packet[t.sequence] = Data(innerSequence)
        packet[c.sendId] = Data(myId)
        packet[t.tokReq] = Data(tokRequest)
        packet[t.code] = Data(PacketCode.login)
        packet[l.userName] = encode(user)
        packet[l.password] = encode(password)
        packet[l.computer] = Data(computer)
        if let remoteId = remoteId {
            packet[c.recvId] = Data(remoteId)
        }
        return packet
    }
    
    func connInfoPacket(replyTo: Data) -> Data {
        typealias c = ControlDefinition
        typealias t = TokenDefinition
        typealias ci = ConnInfoDefinition
        var result = replyTo
        result[c.sendId] = replyTo[c.recvId]
        result[c.recvId] = replyTo[c.sendId]
        result[t.code] = Data(UInt16(0x180))
        result[t.res] = Data(UInt16(0x03))
        // result[t.reqRep] = Data(UInt16(0x01))
        // result[ci.userName] = encode(user)
        // result[ci.enableRx] = Data(UInt8(0x01))
        // result[ci.enableTx] = Data(UInt8(0x01))
        // result[ci.rxCodec] = UInt8(0x04).data
        // result[ci.txCodec] = UInt8(0x04).data
        // result[ci.rxSamp] = UInt32(16000).bigEndian.data
        // result[ci.txSamp] = UInt32( 8000).bigEndian.data
        // result[ci.civPort] = Data(UInt32(50002).bigEndian)
        // result[ci.audioPort] = UInt32(50003).bigEndian.data
        // result[ci.txBuffer] = UInt32(100).bigEndian.data
        // result[ci.convert] = Data(UInt8(0x01))
        return result
    }
    
    func connInfoPacket(radioName: String,
                        userName: String,
                        civPort: UInt16,
                        audioPort: UInt16) -> Data {
        typealias c = ControlDefinition
        typealias t = TokenDefinition
        typealias ci = ConnInfoDefinition
        var packet = Data(count: ci.dataLength)
        packet[c.length] = Data(UInt32(ci.dataLength))
        packet[c.sequence] = Data(sequence)
        packet[c.sendId] = Data(myId)
        packet[t.code] = Data(PacketCode.connInfo)
        packet[t.res] = Data(CommInfoType.commInfo)
        packet[t.sequence] = Data(innerSequence)
        packet[t.tokReq] = Data(tokRequest)
        packet[t.commCap] = Data(CommonCapType.commonCap)
        // packet[ci.macAddr] = macAddr
        packet[ci.radio] = Data(radioName)
        packet[ci.userName] = encode(userName)
        packet[ci.enableRx] = Data(UInt8(1))
        packet[ci.enableTx] = Data(UInt8(1))
        packet[ci.rxCodec] = Data(UInt8(4))
        packet[ci.txCodec] = Data(UInt8(4))
        packet[ci.rxSamp] = Data(UInt32(48000).bigEndian)
        packet[ci.txSamp] = Data(UInt32(48000).bigEndian)
        packet[ci.civPort] = Data(UInt32(civPort).bigEndian)
        packet[ci.audioPort] = Data(UInt32(audioPort).bigEndian)
        packet[ci.txBuffer] = Data(UInt32(1024 * 1024 * 3200).bigEndian)
        packet[ci.convert] = Data(UInt8(1))
        if let remoteId = remoteId {
            packet[c.recvId] = Data(remoteId)
        }
        if let token = token {
            packet[t.token] = Data(token)
        }
        return packet
    }

}

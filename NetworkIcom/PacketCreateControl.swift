//
//  PacketCreateControl.swift
//  NetworkWWDC2018
//
//  Created by Mark Erbaugh on 2/6/22.
//

import Foundation

class PacketCreateControl: PacketCreateBase {
    
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
    
    var innerSequence: UInt8 {
        _innerSequence &+= 1
        return _innerSequence
    }
    
    func tokenPacket(tokenType: UInt16 = TokenType.renew) -> Data {
        typealias c = ControlDefinition
        typealias t = TokenDefinition
        if _tokenPacket == nil {
            var packet = Data(count: t.dataLength)
            packet[c.length] = Data(UInt32(t.dataLength))
            packet[c.sendId] = Data(myId)
            packet[t.tokReq] = Data(tokRequest)
            packet[t.code] = Data(PacketCode.token)
            packet[t.res] = Data(tokenType)
            packet[c.sequence] = Data(sequence)
            packet[t.sequence] = Data(innerSequence)
            if let remoteId = remoteId, let token = token {
                packet[c.recvId] = Data(remoteId)
                packet[t.token] = Data(token)
                _tokenPacket = packet
            }
            packet[t.res] = Data(tokenType)
            return packet
        } else {
            _tokenPacket![t.res] = Data(tokenType)
            _tokenPacket![c.sequence] = Data(sequence)
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
    
//    func connInfoPacket(replyTo: Data, user: String) -> Data {
//        typealias c = ControlDefinition
//        typealias t = TokenDefinition
//        typealias ci = ConnInfoDefinition
//        var result = replyTo
//        result[c.sendId] = replyTo[c.recvId]
//        result[c.recvId] = replyTo[c.sendId]
//        result[c.sequence] = replyTo[c.sequence]
//        result[t.code] = Data(UInt16(0x180))
//        result[t.res] = Data(UInt16(0x03))
//        result[t.sequence] = replyTo[t.sequence]
//        result[ci.userName] = encode(user)
//        // result[ci.enableRx] = Data(UInt8(0x01))
//        // result[ci.enableTx] = Data(UInt8(0x01))
//        // result[ci.rxCodec] = UInt8(0x04).data
//        // result[ci.txCodec] = UInt8(0x04).data
//        // result[ci.rxSamp] = UInt32(16000).bigEndian.data
//        // result[ci.txSamp] = UInt32( 8000).bigEndian.data
//         result[ci.civPort] = Data(UInt32(50002).bigEndian)
//        // result[ci.audioPort] = UInt32(50003).bigEndian.data
//        // result[ci.txBuffer] = UInt32(100).bigEndian.data
//        result[ci.convert] = Data(UInt8(0x01))
//        return result
//    }
    
//    func connInfoPacket(radioName: String,
//                        userName: String,
//                        civPort: UInt32,
//                        audioPort: UInt32) -> Data {
//        typealias c = ControlDefinition
//        typealias t = TokenDefinition
//        typealias ci = ConnInfoDefinition
//        var packet = Data(count: ci.dataLength)
//        packet[c.length] = Data(UInt32(ci.dataLength))
//        packet[c.sequence] = Data(sequence)
//        packet[c.sendId] = Data(myId)
//        packet[t.code] = Data(PacketCode.connInfo)
//        packet[t.res] = Data(CommInfoType.commInfo)
//        packet[t.sequence] = Data(innerSequence)
//        packet[t.tokReq] = Data(tokRequest)
//        packet[t.commCap] = Data(CommonCapType.commonCap)
//        // packet[ci.macAddr] = macAddr
//        packet[ci.radio] = Data(radioName)
//        packet[ci.userName] = encode(userName)
//        packet[ci.enableRx] = Data(UInt8(1))
//        packet[ci.enableTx] = Data(UInt8(1))
//        packet[ci.rxCodec] = Data(UInt8(4))
//        packet[ci.txCodec] = Data(UInt8(4))
//        packet[ci.rxSamp] = Data(UInt32(48000).bigEndian)
//        packet[ci.txSamp] = Data(UInt32(48000).bigEndian)
//        packet[ci.civPort] = Data(UInt32(civPort).bigEndian)
//        packet[ci.audioPort] = Data(UInt32(audioPort).bigEndian)
//        packet[ci.txBuffer] = Data(UInt32(1024 * 1024 * 3200).bigEndian)
//        packet[ci.convert] = Data(UInt8(1))
//        if let remoteId = remoteId {
//            packet[c.recvId] = Data(remoteId)
//        }
//        if let token = token {
//            packet[t.token] = Data(token)
//        }
//        return packet
//    }
}

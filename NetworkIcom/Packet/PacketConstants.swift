//
//  PacketConstants.swift
//  NetworkWWDC2018
//
//  Created by Mark Erbaugh on 1/25/22.
//

import Foundation


struct ControlDefinition {
    static let dataLength = 0x10
    static let length   = (0x00, 4)
    static let type     = (0x04, 2)
    static let sequence = (0x06, 2)
    static let sendId   = (0x08, 4)
    static let recvId   = (0x0c, 4)
}

struct WatchdogDefinition {
    static let dataLength = 0x14
    // Control
    static let secondsA = (0x10, 2)
    static let secondsB = (0x12, 2)
}

struct PingDefinition {
    static let dataLength = 0x15
    // Control
    static let request  = (0x10, 1)  // 0 - request, 1 - response
    static let dataA    = (0x11, 2)
    static let dataB    = (0x13, 2)
}

struct OpenCloseDefinition {
    static let dataLength = 0x16
    // Control
    static let cmd      = (0x10, 1)  // 0xc0
    static let length   = (0x11, 2)  // length of data (0x001)
    static let sequence = (0x13, 2)
    static let request  = (0x15, 1)
    
    // 16000000 0000 0100 2848f1fb f156e26b c0 0100 0000 04
    // 16000000 0000 0100 0c7fc352 c5ad823e c0 0100 0000 05
}

// UDP packet containing CI-V string
struct CIVDefinition {
    static let headerLength = 0x15
    // Control
    static let cmd      = (0x10, 1) // 0xc1
    static let length   = (0x11, 2) // length of CI-V packet (incl fefe and fd) little-endian
    static let sequence = (0x13, 2) // radio big-endian, computer little-endian
    // sample packet: 1e0000000000900fc5ad823e0c7fc352 c1 0900 000d fefee09815020000fd
}

// offsets in CI-V data
struct CIVPacketDefinition {
    static let dest        = (0x02, 1)
    static let src         = (0x03, 1)
    static let cmd         = (0x04, 1)
    static let subCmd      = (0x05, 1)
    static let selector    = (0x06, 2)
    static let frequency   = (0x05, 5)
    static let modeFilter  = (0x05, 2)
    static let attenuation = (0x05, 1)
    static let panMainSub  = (0x06, 1)
    static let panOrder    = (0x07, 1)
    static let panDivision = (0x08, 1)
    static let panScopeMode = (0x09, 1)
    static let panLower     = (0x0a, 5)
    static let panUpper     = (0x0f, 5)
    static let panOutOfRange = (0x14, 1)
    static let panData       = (0x15, 689)
}

struct RetransmitDefinition {
    static let dataLength = 0x18
    // Control
    static let first    = (0x10, 2)
    static let second   = (0x12, 2)
    static let third    = (0x14, 2)
    static let fourth   = (0x16, 2)
}

struct TokenDefinition {
    static let dataLength = 0x40
    // Control
    static let code     = (0x13, 2)
    static let res      = (0x15, 2)
    static let sequence = (0x17, 1)
    static let tokReq   = (0x1a, 2)
    static let token    = (0x1c, 4)
    static let commCap  = (0x27, 2)
    static let reqRep   = (0x29, 1)
    static let macAddr  = (0x2a, 6)
}

struct StatusDefinition {
    static let dataLength = 0x50
    // Control
    // Token
    static let civPort   = (0x40, 4)
    static let audioPort = (0x44, 4)
}

struct LoginResponseDefinition {
    static let dataLength = 0x60
    // Control
    // Token
    static let netType  = (0x40, 16)
}

struct LoginDefinition {
    static let dataLength = 0x80
    // Control
    // Token
    static let userName = (0x40, 16)
    static let password = (0x50, 16)
    static let computer = (0x60, 16)
}

struct ConnInfoDefinition {
    static let dataLength = 0x90
    // Control
    // Token
    static let radio     = (0x40, 16)
    static let userName  = (0x60, 16)
    static let enableRx  = (0x70, 1)
    static let enableTx  = (0x71, 1)
    static let rxCodec   = (0x72, 1)
    static let txCodec   = (0x73, 1)
    static let rxSamp    = (0x74, 4)
    static let txSamp    = (0x78, 4)
    static let civPort   = (0x7c, 4)
    static let audioPort = (0x80, 4)
    static let txBuffer  = (0x84, 4)
    static let convert   = (0x88, 1)
}

struct CapabilitesDefinition {
    static let dataLength = 0xa8
    // Control
    // Token
    static let commCap   = (0x49, 1)
    static let macAddr   = (0x4c, 6)
    static let radio     = (0x52, 16)
    static let audio     = (0x72, 16)
    static let connnType = (0x92, 2)
    static let civAddr   = (0x94, 1)
    static let rxSample  = (0x95, 2)
    static let txSample  = (0x97, 2)
    static let enableA   = (0x99, 1)
    static let enableB   = (0x9a, 1)
    static let enableC   = (0x9b, 1)
    static let baud      = (0x9c, 4)
    static let capF      = (0xa0, 2)
    static let capG      = (0xa3, 2)
}

// -----------------------------

struct ControlPacketType {
    static let idle = UInt16(0)
    static let retransmit = UInt16(1)
    static let areYouThere = UInt16(3)
    static let iAmHere = UInt16(4)
    static let disconnect = UInt16(5)
    static let areYouReady = UInt16(6)
    static let iAmReady = UInt16(6)
}

struct PingPacketType {
    static let ping = UInt16(7)
}

struct OpenClosePacketType {
    static let open = UInt8(4)
    static let close = UInt8(0)
}

struct TokenType {
    static let remove = UInt16(1)
    static let acknowledge = UInt16(2)
    static let renew = UInt16(5)
}

struct CommInfoType {
    static let commInfo = UInt16(3)
}

struct CommonCapType {
    static let commonCap = UInt32(0x8001)
}

struct CIVCode {
    static let code = UInt8(0xc1)
}

struct PacketCode {
    static let login = UInt16(0x170)
    static let loginReply = UInt16(0x250)
    
    static let token = UInt16(0x130)
    static let tokenReply = UInt16(0x230)
    
    static let connInfo = UInt16(0x180)
    static let connInforReply = UInt16(0x380)
    
    static let status = UInt16(0x240)
    
    static let openClose = UInt8(0xc0)
    
    
    static let civToRadio = UInt16(0x9c1)
    static let civFromRadio = UInt16(0xbc1)
}

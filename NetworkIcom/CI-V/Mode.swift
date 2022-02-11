//
//  Mode.swift
//  Icom7610
//
//  Created by Mark Erbaugh on 11/22/21.
//

import Foundation

enum Mode: UInt8, Identifiable, CaseIterable, CustomStringConvertible {
    case lsb   = 0x00
    case usb   = 0x01
    case am    = 0x02
    case cw    = 0x03
    case rtty  = 0x04
    case fm    = 0x05
    case cwr   = 0x07
    case rttyr = 0x08
    case psk   = 0x12
    case pskr  = 0x13
    
    init(buffer: Data) {
        self = Mode(rawValue: buffer.first ?? Mode.lsb.rawValue) ?? .lsb
    }
    
    var description: String {
        switch self {
        case .lsb:   return "LSB"
        case .usb:   return "USB"
        case .am:    return "AM"
        case .cw:    return "CW"
        case .rtty:  return "RTTY"
        case .fm:    return "FM"
        case .cwr:   return "CW-R"
        case .rttyr: return "RTTY-R"
        case .psk:   return "PSK"
        case .pskr:  return "PSK-R"
        }
    }
    
    var id: UInt8 {self.rawValue}
    
    var buffer: Data {
        Data([self.rawValue])
    }
        
    var dataMode: Bool {
        Set([Mode.cw, .rtty, .psk, .rttyr, .pskr]).contains(self)
    }
}

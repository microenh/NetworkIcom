//
//  Band.swift
//  Icom7610
//
//  Created by Mark Erbaugh on 11/22/21.
//

import Foundation

enum Band: UInt8, Identifiable, CaseIterable, CustomStringConvertible {
    case band160 = 0x01
    case band80 = 0x02
    case band40 = 0x03
    case band30 = 0x04
    case band20 = 0x05
    case band17 = 0x06
    case band15 = 0x07
    case band12 = 0x08
    case band10 = 0x09
    case band6 = 0x10
    case bandGeneral = 0x11
    
    init(buffer: ArraySlice<UInt8>) {
        self = Band(rawValue: buffer.first ?? Band.band160.rawValue) ?? .band160
    }
    
    var id: UInt8 { self.rawValue }
    
    var description: String {
        switch self {
        case .band160: return "1.8 MHz"
        case .band80: return "3.5 MHz"
        case .band40: return "7 MHz"
        case .band30: return "10 MHz"
        case .band20: return "14 MHz"
        case .band17: return "18 MHz"
        case .band15: return "21 MHz"
        case .band12: return "24 MHz"
        case .band10: return "28 MHz"
        case .band6: return "50 MHz"
        case .bandGeneral: return "General"
        }
    }
    
    var buffer: Data {
        Data([self.rawValue])
    }
}

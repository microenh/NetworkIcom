//
//  Attenuation.swift
//  Icom7610a
//
//  Created by Mark Erbaugh on 11/29/21.
//

import Foundation

enum Attenuation: UInt8, Identifiable, CaseIterable, CustomStringConvertible {
    case attOff = 0x00
    case att03 = 0x03
    case att06 = 0x06
    case att09 = 0x09
    case att12 = 0x12
    case att15 = 0x15
    case att18 = 0x18
    case att21 = 0x21
    case att24 = 0x24
    case att27 = 0x27
    case att30 = 0x30
    case att33 = 0x33
    case att36 = 0x36
    case att39 = 0x39
    case att42 = 0x42
    case att45 = 0x45
    
    init(value: UInt8) {
        self = Attenuation(rawValue: value) ?? .attOff
    }

    var id: UInt8 {self.rawValue}

    var description: String {
        self == .attOff ? "OFF" : "\(self.rawValue.fromBCD) dB"
    }
    
    var buffer: Data {
        Data([self.rawValue])
    }
}

enum AttenuationBand {
    case mw      //      0.030 -  1.599.999
    case b160    //  1.600.000 -  1.999.999
    case b80     //  2.000.000 -  5.999.999
    case b40     //  6.000.000 -  7.999.999
    case b30     //  8.000.000 - 10.999.999
    case b20     // 11.000.000 - 14.999.999
    case b17     // 15.000.000 - 19.999.999
    case b15     // 20.000.000 - 21.999.999
    case b12     // 22.999.999 - 25.999.999
    case b10     // 26.000.000 - 29.999.999
    case vhf     // 30.000.000 - 44.999.999
    case b6      // 45.000.000 - 60.000.000
    
    init(frequency: Int) {
        switch frequency {
        case 0..<1_600_000: self = .mw
        case 1_600_000..<2_000_000: self = .b160
        case 2_000_000..<6_000_000: self = .b80
        case 6_000_000..<8_000_000: self = .b40
        case 8_000_000..<11_0000_000: self = .b30
        case 11_000_000..<15_000_000: self = .b20
        case 15_000_000..<20_000_000: self = .b17
        case 20_000_000..<22_000_000: self = .b15
        case 22_000_000..<26_000_000: self = .b12
        case 26_000_000..<30_000_000: self = .b10
        case 30_000_000..<45_000_000: self = .vhf
        default: self = .b6
        }
    }
}

//extension Icom7610Interface {
//
//    func processAttenuation() {
//        updateData(.attenuation(Attenuation(buffer: inDataBuffer.dropFirst(1))))
//    }
//    func requestAttenuation() {
//        request(command: 0x11)
//    }
//
//    func sendAttenuation(attenuation: Attenuation) {
//        request(command: 0x11, data: attenuation.buffer)
//    }
//}
//

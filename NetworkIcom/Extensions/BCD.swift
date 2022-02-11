//
//  BCD.swift
//  Icom7610
//
//  Created by Mark Erbaugh on 11/22/21.
//

import Foundation

extension UInt8 {
    init(bcd: Data) {
        self = UInt8(bcd.first!).fromBCD
    }
    // retrieve a Hex value: 0x88 -> 88
    // if > 0x99 -> 99
    var fromBCD: UInt8 {
        self > 0x99 ? 99 : (((self & 0xf0) >> 4) * 10) + (self & 0x0f)
    }
    
    // retrieve a BCD representation: 85 -> 0x85
    // if > 99 -> 0x99
    var toBCD: UInt8 {
        self > 99 ? 0x99 : ((self / 10) << 4 | (self % 10))
    }
    
    var buffer: Data {
        Data([(self.toBCD)])
    }
    
}

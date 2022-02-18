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
    
    var buffer2: Data {
        Data([(self / 100).toBCD, (self % 100).toBCD])
    }
}

extension UInt16 {
    
    // 9876 -> Data([0x98, 0x76])
    var bcdSelector: Data {
        Data([UInt8(self / 100).toBCD, UInt8((self % 100)).toBCD])
    }
}

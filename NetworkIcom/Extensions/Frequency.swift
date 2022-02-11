//
//  Frequency.swift
//  Icom7610
//
//  Created by Mark Erbaugh on 11/25/21.
//

import Foundation

extension Int {
    
    init(frequencyBuffer: Data) {
        // | 10 Hz : 1Hz | 1 kHz : 100 Hz | 100 kHz : 10 kHz | 10 MHz : 1 MHz | 1 GHz (fixed 0) : 100 MHz (fixed 0) |
        self = frequencyBuffer.prefix(5).reversed().reduce(0){total, c in
            100 * total + Int(c.fromBCD)}
    }
    
    var frequencyBuffer: Data {
        Data([UInt8(self % 100).toBCD, UInt8((self / 100) % 100).toBCD,
         UInt8((self / 10_000) % 100).toBCD, UInt8((self / 1_000_000) % 100).toBCD,
         UInt8((self / 100_000_000) % 100).toBCD])
    }
    
    init(offsetFrequencyBuffer: Data) {
        let f = offsetFrequencyBuffer.prefix(3).reversed().reduce(0){ total, c in
            100 * total + Int(c.fromBCD)}
        self = f * ((offsetFrequencyBuffer.dropFirst(3).first == 1) ? -1 : 0) * 100
    }
    
    var offsetFrequencyBuffer: Data {
        Data([UInt8((self / 100) % 100).toBCD,
         UInt8((self / 10_000) % 100).toBCD,
         UInt8((self / 1_000_000) % 100).toBCD,
         self < 0 ? 1 : 0])
    }
    
    var tone: Double {
        Double(self) * 0.1
    }
}

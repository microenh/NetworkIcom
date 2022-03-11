//
//  NCO.swift
//  SignalGeneratorApp
//
//  Created by Mark Erbaugh on 2/28/22.
//

import Foundation

class NCOCosine {
    static let twoPi = Double.pi * 2
    
    private var phase = 0.0
    private let phaseInc: Double
    
    init(frequency: Double, sampleRate: Double) {
        phaseInc = NCOCosine.twoPi * frequency / sampleRate
    }
    
    var value: Int16 {
        let r = Int16(cos(phase) * 32767)
        phase += phaseInc
        if phase >= NCOCosine.twoPi {
            phase -= NCOCosine.twoPi
        }
        return r
    }
}

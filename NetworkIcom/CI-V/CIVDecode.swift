//
//  CIVDecode.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/10/22.
//

import Foundation
import Combine

class CIVDecode {
    
    private(set) var frequency = CurrentValueSubject<Int, Never>(0)
    
    private let radioCivAddr: UInt8
    private let hostCivAddr: UInt8
    
    init(radioCivAddr: UInt8, hostCivAddr: UInt8) {
        self.radioCivAddr = radioCivAddr
        self.hostCivAddr = hostCivAddr
    }
    
    func decode(civData: Data) {
        switch civData[civData.startIndex + 4] {
        case 0x00, 0x03:
            frequency.value = Int(frequencyBuffer: civData.dropFirst(5))
        case 0x01, 0x04:
            // updateVM(.modeFilter(ModeFilter(buffer: civ.dropFirst(5))))
            break
        case 0x11:
            // updateVM(.attenuation(Attenuation(buffer: civ.dropFirst(5))))
            break
        case 0xfa:  // NAK
            print ("NAK")
            break
        case 0xfb:  // ACK
            print ("ACK")
            break
            
        default:
            civData.dump()
        }

        
    }
}

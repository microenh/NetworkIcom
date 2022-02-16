//
//  CIVDecode.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/16/22.
//

import Foundation

class CIVDecode: ObservableObject {
    
    @Published var frequency = 0
    @Published var modeFilter = ModeFilter(mode: .lsb, filter: .fil1)
    @Published var attenuation = Attenuation.attOff
    @Published var printDump = ""
    
    let hostCivAddr: UInt8
    
    init (hostCivAddr: UInt8) {
        self.hostCivAddr = hostCivAddr
    }
    
    func decode(_ current: Data) {
        typealias c = CIVPacketDefinition
        if current[c.src].uint8 == hostCivAddr {
            return  // ignore echo
        }
        switch current[c.cmd].uint8 {
        case 0x00, 0x03:
            frequency = Int(frequencyBuffer: current[c.frequency])
        case 0x01, 0x04:
            modeFilter = ModeFilter(buffer: current[c.modeFilter])
        case 0x11:
            attenuation = Attenuation(value: current[c.attenuation].uint8)
        case 0xfa:  // NAK
            printDump = "NAK"
        case 0xfb:  // ACK
            printDump = "ACK"
        default:
            // print (current.count)
            printDump = current.dump
        }
    }
}

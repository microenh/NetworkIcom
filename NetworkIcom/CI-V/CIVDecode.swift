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
            let frequency = Int(frequencyBuffer: current[c.frequency])
            DispatchQueue.main.async { [weak self] in
                self?.frequency = frequency
            }
        case 0x01, 0x04:
            let modeFilter = ModeFilter(buffer: current[c.modeFilter])
            DispatchQueue.main.async { [weak self] in
                self?.modeFilter = modeFilter
            }
        case 0x11:
            let attenuation = Attenuation(value: current[c.attenuation].uint8)
            DispatchQueue.main.async { [weak self] in
                self?.attenuation = attenuation
            }
        case 0xfa:  // NAK
            DispatchQueue.main.async { [weak self] in
                self?.printDump = "NAK"
            }
        case 0xfb:  // ACK
            DispatchQueue.main.async { [weak self] in
                self?.printDump = "ACK"
            }
        default:
            // print (current.dropFirst(6).dump)
            DispatchQueue.main.async { [weak self] in
                self?.printDump = current.dump
            }
        }
    }
}

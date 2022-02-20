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
    @Published var panadapter = (Data(), Data(), 0.0)
    
    let hostCivAddr: UInt8
    
    static let historyCount = 10
    
    var panHistory = Array(repeating: Array(repeating: UInt8(0), count: CIVDecode.historyCount), count: 689)
    var panIndex = -1
   
    var lastPan = Date.now
    
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
        case 0x27:
            if current[c.subCmd].uint8 == 0 {
                let data = Data(current.dropFirst(c.panData.0).dropLast())
                panIndex += 1
                if panIndex >= CIVDecode.historyCount {
                    panIndex = 0
                }
                for i in 0..<689 {
                    panHistory[i][panIndex] = data[i]
                }
                let data2 = Data(panHistory.map{$0.max() ?? 0})
                let current = Date.now
                let delta = current.timeIntervalSince(lastPan) * 1000
                lastPan = current
                DispatchQueue.main.async { [weak self] in
                    self?.panadapter = (data, data2, delta)
                }
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

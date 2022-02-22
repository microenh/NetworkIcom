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
    @Published var panadapterMain = (Data(), Data(), 0.0)
    @Published var panadapterSub = (Data(), Data(), 0.0)

    let hostCivAddr: UInt8
    
    static let historyCount = 40
    static let points = 689
    
    var panHistory = [Array(repeating: Array(repeating: UInt8(0), count: CIVDecode.historyCount), count: CIVDecode.points),
                      Array(repeating: Array(repeating: UInt8(0), count: CIVDecode.historyCount), count: CIVDecode.points)]
    var panHistoryIndex = [0, 0]
    var lastPanTime = [Date.now, Date.now]
    
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
            switch current[c.subCmd].uint8 {
            case UInt8(0):
                let panIndex = Int(current[c.panMainSub].uint8)
                let data = Data(current.dropFirst(c.panData.0).dropLast())
                for (i,j) in data.enumerated() {
                    panHistory[panIndex][i][panHistoryIndex[panIndex]] = j
                }
                panHistoryIndex[panIndex] = (panHistoryIndex[panIndex] + 1) % CIVDecode.historyCount
                let data2 = Data(panHistory[panIndex].map{$0.max() ?? 0})
                let current = Date.now
                let delta = current.timeIntervalSince(lastPanTime[panIndex]) * 1000
                lastPanTime[panIndex] = current
                DispatchQueue.main.async { [weak self] in
                    if let self = self {
                        if panIndex == 0 {
                            self.panadapterMain = (data, data2, delta)
                        } else {
                            self.panadapterSub = (data, data2, delta)
                        }
                    }
                }
            default: break
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

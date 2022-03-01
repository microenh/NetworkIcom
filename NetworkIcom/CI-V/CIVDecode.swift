//
//  CIVDecode.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/16/22.
//

import Foundation
import SwiftUI

struct WaterfallSettings {
    static let columns = 689
    static let rows = 100
    static let waterfallGain = 4
    static let historyCount = 40
}

class CIVDecode: ObservableObject {
    
    @Published var frequency = 0
    @Published var modeFilter = ModeFilter(mode: .lsb, filter: .fil1)
    @Published var attenuation = Attenuation.attOff
    @Published var printDump = ""
    @Published var panadapterMain = (
        panadapter: Data(),
        history: Data(),
        timing: 0.0,
        scopeMode: UInt8(0),
        panLower: 0,
        panUpper: 0)
    @Published var panadapterSub = (
        panadapter: Data(),
        history: Data(),
        timing: 0.0,
        scopeMode: UInt8(0),
        panLower: 0,
        panUpper: 0)
    private(set) var waterfallContexts: [CGContext]
    private let colorMap: Array<PixelColor>
    private static let bytesPerPixel = MemoryLayout<PixelColor>.size
    private static let bytesPerRow = CIVDecode.bytesPerPixel * WaterfallSettings.columns
    private static let bytesToMove = bytesPerRow * (WaterfallSettings.rows - 1)
    
    let hostCivAddr: UInt8
    
    
    var panHistory = [Array(repeating: Array(repeating: UInt8(0), count: WaterfallSettings.historyCount), count: WaterfallSettings.columns),
                      Array(repeating: Array(repeating: UInt8(0), count: WaterfallSettings.historyCount), count: WaterfallSettings.columns)]
    var panHistoryIndex = [0, 0]
    var lastPanTime = [Date.now, Date.now]
    
    init (hostCivAddr: UInt8) {
        self.hostCivAddr = hostCivAddr
        colorMap = setColors(palette: FLDigiPalette.fldigi)
        let contextMain = CGContext(
            data: nil,
            width: WaterfallSettings.columns,
            height: WaterfallSettings.rows,
            bitsPerComponent: 8,
            bytesPerRow: CIVDecode.bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let contextSub = CGContext(
            data: nil,
            width: WaterfallSettings.columns,
            height: WaterfallSettings.rows,
            bitsPerComponent: 8,
            bytesPerRow: CIVDecode.bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

        self.waterfallContexts = [contextMain, contextSub]
        waterfallClear(which: 0)
        waterfallClear(which: 1)
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
                
                let lower = Int(frequencyBuffer: current[c.panLower])
                let upper = Int(frequencyBuffer: current[c.panUpper])
                let scopeMode = current[c.panScopeMode].uint8
                
                var panLower: Int
                var panUpper: Int
                

                
                if scopeMode == 0 {
                    panLower = lower - upper
                    panUpper = lower + upper
                } else {
                    panLower = lower
                    panUpper = upper
                }
                
                // print ("l: \(lower), u: \(upper)")
                
                // calculate time since last update (msec)
                let currentTime = Date.now
                let delta = currentTime.timeIntervalSince(lastPanTime[panIndex]) * 1000
                lastPanTime[panIndex] = currentTime
                
                // panadapter data
                let data = Data(current.dropFirst(c.panData.0).dropLast())
                // save to history
                for (i,j) in data.enumerated() {
                    panHistory[panIndex][i][panHistoryIndex[panIndex]] = j
                }
                // max history data
                let data2 = Data(panHistory[panIndex].map{$0.max() ?? 0})
                panHistoryIndex[panIndex] = (panHistoryIndex[panIndex] + 1) % WaterfallSettings.historyCount
                
                // update waterfall
                if let waterfallData = waterfallContexts[panIndex].data {
                    // move existing data down one row and insert new data row at top
                    waterfallData.advanced(by: CIVDecode.bytesPerRow).copyMemory(from: waterfallData, byteCount: CIVDecode.bytesToMove)
                    let pixelData = data.map{colorMap[min(WaterfallSettings.waterfallGain * Int($0), 255)]}
                    waterfallData.copyMemory(from: pixelData, byteCount: CIVDecode.bytesPerRow)
                }
                
                // update publisher
                DispatchQueue.main.async { [weak self] in
                    if let self = self {
                        if panIndex == 0 {
                            self.panadapterMain = (data, data2, delta, scopeMode, panLower, panUpper)
                        } else {
                            self.panadapterSub = (data, data2, delta, scopeMode, panLower, panUpper)
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
    
    func waterfallClear(which: Int) {
        if let data = waterfallContexts[which].data {
            data.initializeMemory(as: PixelColor.self,
                                  repeating: .black,
                                  count: WaterfallSettings.columns * WaterfallSettings.rows)
        }
    }
    
}

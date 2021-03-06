//
//  CIVCommands0x18.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/17/22.
//

import Foundation

enum SquelchType : UInt8 {
    case off = 0
    case tone
    case tsql
}

enum DataMode : UInt8 {
    case off = 0
    case data1
    case data2
    case data3
}

enum Tones: UInt16 {
    case t67_0 = 670
    case t71_9 = 719
    case t74_4 = 744
    case t77_0 = 770
    case t79_7 = 797
    case t82_5 = 825
    case t85_4 = 854
    case t88_5 = 885
    case t91_5 = 915
    case t94_8 = 948
    case t97_4 = 975
    case t100_0 = 1000
    case t103_5 = 1035
    case t107_2 = 1072
    case t110_9 = 1109
    case t114_8 = 1148
    case t118_8 = 1188
    case t123_0 = 1230
    case t127_3 = 1273
    case t131_8 = 1318
    case t136_5 = 1365
    case t141_3 = 1413
    case t146_2 = 1462
    case t151_4 = 1514
    case t156_7 = 1567
    case t162_2 = 1622
    case t167_9 = 1679
    case t173_8 = 1738
    case t179_9 = 1799
    case t186_2 = 1862
    case t192_8 = 1928
    case t203_5 = 2035
    case t210_7 = 2107
    case t218_1 = 2181
    case t225_7 = 2257
    case t233_6 = 2336
    case t241_8 = 2418
    case t250_3 = 2503
    case t254_1 = 2541
}

enum BandStack : UInt8 {
    case latest = 1
    case mid
    case oldest
}

struct MemoryContents {
    let selected: UInt8
    let frequency: Int
    let mode: Mode
    let filter: Filter
    let dataMode: DataMode
    let squelchType: SquelchType
    let repeaterTone: Tones
    let toneSquelch: Tones
    let memoryName: String
    
    var data: Data {
        selected.data + frequency.frequencyBuffer + mode.rawValue.data +
        filter.rawValue.data + (dataMode.rawValue << 4 + squelchType.rawValue).data +
        repeaterTone.rawValue.toneBuffer + toneSquelch.rawValue.toneBuffer + memoryName.dataPaddedWithSpaces(length: 10)
    }
}

struct BandstackContents {
    let frequency: Int
    let mode: Mode
    let filter: Filter
    let dataMode: DataMode
    let squelchType: SquelchType
    let repeaterTone: Tones
    let toneSquelch: Tones
    
    var data: Data {
        frequency.frequencyBuffer + mode.rawValue.data +
        filter.rawValue.data + (dataMode.rawValue << 4 + squelchType.rawValue).data +
        repeaterTone.rawValue.toneBuffer + toneSquelch.rawValue.toneBuffer
    }
}

struct HpfLpf {
    let hpf: UInt8
    let lpf: UInt8
    
    var data: Data {
        hpf.buffer + lpf.buffer
    }
}


extension IcomVM {
    
    func readSetMemoryContents(memory: UInt8, contents: MemoryContents? = nil) {
        serial?.send(command: 0x1a, subCommand: 0x00, selector: UInt16(memory).bcdSelector, data: contents?.data)
    }
    
    func clearMemoryContents(memory: UInt8) {
        serial?.send(command: 0x1a, subCommand: 0x00, data: memory.buffer2 + UInt8(0xff).data)
    }
    
    func readSetBandStackRegister(band: Band, which: BandStack, contents: BandstackContents? = nil) {
        serial?.send(command: 0x1a, subCommand: 0x01,
                     data: band.rawValue.data + which.rawValue.data + (contents?.data ?? Data()))
    }
    
    // use empty String to clear memory
    func readSetMemoryKeyer(which: UInt8, message: String? = nil) {
        serial?.send(command: 0x1a, subCommand: 0x02, data: which.buffer + (message?.dataPaddedWithSpaces(length: 70) ?? Data()))
    }
    
    // SSB/CW/PSK: 0 ... 40, RTTY: 0 ... 31, AM: 0 ... 49
    func readSetIFFilterWidth(width: UInt8? = nil) {
        serial?.send(command: 0x1a, subCommand: 0x03, data: width?.buffer)
    }
    
    // 0 ... 13
    func readSetAGCTimeConstant(time: UInt8? = nil) {
        serial?.send(command: 0x1a, subCommand: 0x04, data: time?.buffer)
    }
    
    func readSetSsbRxHpfLpf(hpfLpf: HpfLpf? = nil) {
        serial?.send(command: 0x1a, subCommand: 0x05, selector: UInt16(1).bcdSelector, data: hpfLpf?.data)
    }

}

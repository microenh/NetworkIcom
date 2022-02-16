//
//  CIVCommands.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/15/22.
//

import Foundation

extension IcomVM {
    func readBandEdgeFrequencies() {
        serial?.send(command: 0x02)
    }
    
    func readOperatingFrequency() {
        serial?.send(command: 0x03)
    }
    func readOperatingMode() {
        serial?.send(command: 0x04)
    }
    
    func setOperatingFrequency(frequency: Int) {
        serial?.send(command: 0x05, data: frequency.frequencyBuffer)
    }
    
    func setOperatingMode(mode: Mode, filter: Filter) {
        serial?.send(command: 0x06, data: ModeFilter(mode: mode, filter: filter).buffer)
    }
    
    func exchangeMainSub() {
        serial?.send(command: 0x07, subCommand: 0xb0)
    }
    
    func equalizeMainSub() {
        serial?.send(command: 0x07, subCommand: 0xb1)
    }
    
    func dualWatch(on: Bool? = nil) {
        serial?.send(command: 0x07, subCommand: 0xc2, data: on?.data)
    }
    
    func subBand(on: Bool? = nil) {
        serial?.send(command: 0x07, subCommand: 0xd2, data: on?.data)
    }
    
    // 1 .. 99, 100 (P1), 101 (P2)
    func selectMemory(channel: UInt8) {
        serial?.send(command: 0x08, data: channel.buffer2)
    }
    
    func memoryWrite() {
        serial?.send(command: 0x09)
    }
    
    func memoryToVFO() {
        serial?.send(command: 0x0a)
    }
    
    func memoryClear() {
        serial?.send(command: 0x0b)
    }

    func readAttenuation()        { serial?.send(command: 0x11) }
    func readSsbRxHpfLpf()        { serial?.send(command: 0x1a, subCommand: 0x05, selector: 0x01) }
}

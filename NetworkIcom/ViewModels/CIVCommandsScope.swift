//
//  CIVCommandsScope.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/18/22.
//

import Foundation

extension IcomVM {
    
    func readSetScopeOn(on: Bool? = nil) {
        serial?.send(command: 0x27, subCommand: 0x10, data: on?.data)
    }
    
    func readSetScopeWaveOn(on: Bool? = nil) {
        serial?.send(command: 0x27, subCommand: 0x11, data: on?.data)
    }
}

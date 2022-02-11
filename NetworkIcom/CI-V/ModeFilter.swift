//
//  ModeFilter.swift
//  Icom7610
//
//  Created by Mark Erbaugh on 11/23/21.
//

import Foundation

struct ModeFilter: CustomStringConvertible {
    var mode: Mode
    var filter: Filter
    
    init(mode: Mode, filter: Filter) {
        self.mode = mode
        self.filter = filter
    }
    
    init(buffer: Data) {
        self.mode = Mode(buffer: buffer)
        self.filter = Filter(buffer: buffer.dropFirst(1))
    }
    
    var description: String {
        "Mode: \(mode), Filter: \(filter)"
    }
    
    var buffer: Data {
        mode.buffer + filter.buffer
    }
}

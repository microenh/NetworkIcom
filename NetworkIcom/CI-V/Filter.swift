//
//  Filter.swift
//  Icom7610
//
//  Created by Mark Erbaugh on 11/22/21.
//

import Foundation

enum Filter: UInt8, Identifiable, CaseIterable, CustomStringConvertible {
    
    case fil1 = 1
    case fil2 = 2
    case fil3 = 3
    
    init(buffer: Data) {
        self = Filter(rawValue: buffer.first ?? Filter.fil1.rawValue) ?? .fil1
    }
    
    var id: UInt8 {
        return self.rawValue
    }
    
    var description: String {
        "FIL\(self.rawValue)"
    }
    
    var buffer: Data {
        Data([self.rawValue])
    }
}

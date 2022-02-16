//
//  Bool.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/15/22.
//

import Foundation

extension Bool {
    var data: Data {
        Data([self ? UInt8(1) : 0])
    }
}

//
//  UInt16.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/17/22.
//

import Foundation

extension UInt16 {
    var toneBuffer : Data {
        Data([UInt8(0), UInt8(self / 100).toBCD, UInt8(self % 100).toBCD])
    }

}

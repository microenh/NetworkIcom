//
//  UInt8.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/16/22.
//

import Foundation

extension UInt8 {
    var data: Data {
        Data([self])
    }

}

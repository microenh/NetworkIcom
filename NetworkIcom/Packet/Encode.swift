//
//  Encode.swift
//  NetworkWWDC2018
//
//  Created by Mark Erbaugh on 2/6/22.
//

import Foundation

/*
 * Encode the user name and password int 16 byte (zero padded) data arrays
 * Decode isn't used by the radio communications, but reverses the process
 */

func encode(_ data: String) -> Data {
    let length = 16
    let encodeKey = [UInt8(0x47),
                     0x5d,0x4c,0x42,0x66,0x20,0x23,0x46,0x4e,0x57,0x45,0x3d,0x67,0x76,0x60,0x41,0x62,
                     0x39,0x59,0x2d,0x68,0x7e,0x7c,0x65,0x7d,0x49,0x29,0x72,0x73,0x78,0x21,0x6e,0x5a,
                     0x5e,0x4a,0x3e,0x71,0x2c,0x2a,0x54,0x3c,0x3a,0x63,0x4f,0x43,0x75,0x27,0x79,0x5b,
                     0x35,0x70,0x48,0x6b,0x56,0x6f,0x34,0x32,0x6c,0x30,0x61,0x6d,0x7b,0x2f,0x4b,0x64,
                     0x38,0x2b,0x2e,0x50,0x40,0x3f,0x55,0x33,0x37,0x25,0x77,0x24,0x26,0x74,0x6a,0x28,
                     0x53,0x4d,0x69,0x22,0x5c,0x44,0x31,0x36,0x58,0x3b,0x7a,0x51,0x5f,0x52]
        
    return Data((data.prefix(length).utf8).enumerated().map { (index, item) in
        let p = index + Int(item)
        return encodeKey[(p > 126 ? 32 + p % 127 : p) - 32]
    } + Data(count: length - data.count))
}


func decode(_ data: Data) -> String? {
    let decodeKey = [UInt8(0x25),
                     0x3e,0x74,0x26,0x6c,0x6a,0x6d,0x4e,0x70,0x3a,0x46,0x62,0x45,0x33,0x63,0x5e,0x5a,
                     0x77,0x58,0x68,0x57,0x51,0x78,0x69,0x61,0x31,0x49,0x7a,0x48,0x2b,0x43,0x66,0x65,
                     0x2f,0x23,0x4c,0x76,0x2a,0x27,0x20,0x53,0x39,0x42,0x5f,0x22,0x72,0x28,0x4b,0x64,
                     0x7c,0x7e,0x71,0x47,0x67,0x55,0x29,0x79,0x32,0x40,0x50,0x75,0x21,0x41,0x7d,0x2e,
                     0x5b,0x30,0x4a,0x60,0x37,0x24,0x2c,0x34,0x73,0x6f,0x54,0x59,0x5c,0x3f,0x56,0x52,
                     0x44,0x3b,0x3c,0x6e,0x4d,0x2d,0x6b,0x3d,0x4f,0x7b,0x5d,0x36,0x38,0x35]
    
    return String(data: Data(data.filter{$0 > 0}.enumerated().map{ (index, item) in
        let k = Int(decodeKey[Int(item) - 32]) - index
        return UInt8(k < 32 ? k + 127 - 32 : k)
    }), encoding: .utf8)
}

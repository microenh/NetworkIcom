//
//  Constants.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 3/4/22.
//

import Foundation

struct Constants {
    static let rxSampleRate = 8000
    static let txSampleRate = 8000
    static let rxStereo = true
    static let rxCodec = UInt8(Constants.rxStereo ? 0x10 : 0x04)  // 0x10 - stereo, 0x04 - mono
    static let txCodec = UInt8(0x04)  // 0x10 - stereo, 0x04 - mono
}

//
//  Constants.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 3/4/22.
//

import Foundation
import AVFoundation

struct Constants {
    static let rxSampleRate = 8000
    static let txSampleRate = 8000
    static let rxStereo = false
    static let rxCodec = UInt8(Constants.rxStereo ? 0x10 : 0x04)  // 0x10 - stereo, 0x04 - mono
    static let rxLayout = Constants.rxStereo ? kAudioChannelLayoutTag_Stereo : kAudioChannelLayoutTag_Mono
    static let txCodec = UInt8(0x04)  // 0x10 - stereo, 0x04 - mono
    static let txTimerFraction = 5
}

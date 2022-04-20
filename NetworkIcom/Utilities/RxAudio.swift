//
//  RxAudio.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 4/19/22.
//

import AVFoundation

class RxAudio {
    static let rxULaw_8bit_1ch  = UInt8(0x01)
    static let rxULaw_8bit_2ch  = UInt8(0x20)
    
    static let rxLpcm_8bit_1ch  = UInt8(0x02)
    static let rxLpcm_8bit_2ch  = UInt8(0x08)
    
    static let rxLpcm_16bit_1ch = UInt8(0x04)
    static let rxLpcm_16bit_2ch = UInt8(0x10)
    
    let rate: UInt16
    let channels: UInt8
    let size: UInt8
    let uLaw: Bool
    let enable: UInt8

    let audioFormat: AVAudioFormat!
    let bytesPerFrame: UInt8
    let radioFormat: UInt8
    
    /// - Parameters:
    ///   - rate 8000, 16000, 24000, 48000
    ///   - channels: 1, 2
    ///   - size: 1, 2
    ///   - uLaw: 8-bit encoding - true: uLaw, false: lpcm  (always lpcm for 16-bit)
    ///   - enable: Bool
    init(rate: UInt16, channels: UInt8, size: UInt8, uLaw: Bool, enable: Bool) {
        self.rate = rate
        self.channels = channels
        self.size = size
        self.uLaw = uLaw
        self.enable = enable ? 1 : 0
        bytesPerFrame = channels * size
        var absd = AudioStreamBasicDescription(mSampleRate: Float64(rate),
                                               mFormatID: size == 1 && uLaw ? kAudioFormatULaw : kAudioFormatLinearPCM,
                                               mFormatFlags: size == 1 && uLaw ? kAudioFormatFlagIsSignedInteger : 0,
                                               mBytesPerPacket: UInt32(bytesPerFrame),
                                               mFramesPerPacket: 1,
                                               mBytesPerFrame: UInt32(bytesPerFrame),
                                               mChannelsPerFrame: UInt32(channels),
                                               mBitsPerChannel: UInt32(size) * 8,
                                               mReserved: 0)
        audioFormat = AVAudioFormat(streamDescription: &absd)
        radioFormat = channels == 2
          ? size == 1
            ? uLaw ? RxAudio.rxULaw_8bit_2ch : RxAudio.rxLpcm_8bit_2ch
            : RxAudio.rxLpcm_16bit_2ch
          : size == 1
            ? uLaw ? RxAudio.rxULaw_8bit_1ch : RxAudio.rxLpcm_8bit_1ch
            : RxAudio.rxLpcm_16bit_1ch
    }

}

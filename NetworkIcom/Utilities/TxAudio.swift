//
//  TxAudio.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 4/19/22.
//

import AVFoundation


class TxAudio {
    static let txULaw_8bit_1ch  = UInt8(0x01)
    static let txLpcm_8bit_1ch  = UInt8(0x02)
    static let txLpcm_16bit_1ch = UInt8(0x04)

    let rate: UInt16
    let size: UInt8
    let uLaw: Bool
    let enable: UInt8

    let audioFormat: AVAudioFormat?
    let radioFormat: UInt8
    
    /// - Parameters:
    ///   - rate 8000, 16000, 24000, 48000
    ///   - size: 1, 2
    ///   - uLaw: 8-bit encoding - true: uLaw, false: lpcm  (always lpcm for 16-bit)
    ///   - enable: Bool
    init(rate: UInt16 = Defaults.txRate,
         size: UInt8 = Defaults.txSize,
         uLaw: Bool = Defaults.txULaw,
         enable: Bool = Defaults.txEnable) {
        self.rate = rate
        self.size = size
        self.uLaw = uLaw
        self.enable = enable ? 1 : 0
        var absd = AudioStreamBasicDescription(mSampleRate: Float64(rate),
                                               mFormatID: size == 1 && uLaw ? kAudioFormatULaw : kAudioFormatLinearPCM,
                                               mFormatFlags: kAudioFormatFlagIsSignedInteger,
                                               mBytesPerPacket: UInt32(size),
                                               mFramesPerPacket: 1,
                                               mBytesPerFrame: UInt32(size),
                                               mChannelsPerFrame: 1,
                                               mBitsPerChannel: UInt32(size) * 8,
                                               mReserved: 0)
        audioFormat = AVAudioFormat(streamDescription: &absd)
        radioFormat = size == 1
            ? uLaw ? TxAudio.txULaw_8bit_1ch : TxAudio.txLpcm_8bit_1ch
            : TxAudio.txLpcm_16bit_1ch
    }
}



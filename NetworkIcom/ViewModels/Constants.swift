//
//  Constants.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 3/4/22.
//

import Foundation
import AVFoundation

struct Codecs {
    static let rxNone           = UInt8(0x00)
    static let rxULaw_8bit_1ch  = UInt8(0x01)
    static let rxLpcm_8bit_1ch  = UInt8(0x02)
    static let rxLpcm_16bit_1ch = UInt8(0x04)
    static let rxALaw_8bit_2ch  = UInt8(0x08)
    static let rxLpcm_16bit_2ch = UInt8(0x10)
    static let rxULaw_8bit_2ch  = UInt8(0x20)
    
    static let txNone           = UInt8(0x00)
    static let txULaw_8bit_1ch  = UInt8(0x01)
    static let txLpcm_8bit_1ch  = UInt8(0x02)
    static let txLpcm_16bit_1ch = UInt8(0x04)
    
    private static let stereoCodecs: Set = [rxALaw_8bit_2ch,
                                            rxLpcm_16bit_2ch,
                                            rxULaw_8bit_2ch]
    
    private static let twoByteCodecs: Set = [rxLpcm_16bit_1ch,
                                             rxLpcm_16bit_2ch,
                                             txLpcm_16bit_1ch]
    
    static func isStereo(_ codec: UInt8) -> Bool {
        Codecs.stereoCodecs.contains(codec)
    }
    
    static func is2Byte(_ codec: UInt8) -> Bool {
        Codecs.twoByteCodecs.contains(codec)
    }
    
    enum Coding {
        case linear
        case alaw
        case ulaw
        
        var formatID: AudioFormatID {
            switch self {
            case .linear:
                return kAudioFormatLinearPCM
            case .alaw:
                return kAudioFormatALaw
            case .ulaw:
                return kAudioFormatULaw
            }
        }
    }
    
    static func absd(sampleRate: Float64, bytesPerFrame: UInt32, channelsPerFrame: UInt32, coding: Coding) -> AudioStreamBasicDescription {
        AudioStreamBasicDescription (
            mSampleRate: sampleRate,
            mFormatID: coding.formatID,
            mFormatFlags: 0, // kAudioFormatFlagIsSignedInteger
//                        | kAudioFormatFlagIsBigEndian
//                        | kAudioFormatFlagIsPacked, // | kAudioFormatFlagsCanonical,

            
            mBytesPerPacket: bytesPerFrame * channelsPerFrame,
            mFramesPerPacket: 1,
            mBytesPerFrame: bytesPerFrame,
            mChannelsPerFrame: channelsPerFrame,
            mBitsPerChannel: bytesPerFrame * 8,
            mReserved: 0)
    }
}

struct Constants {
    static let rxSampleRate = 8000
    static let txSampleRate = 8000
    static let rxStereo = false
    static let rxLayout = Constants.rxStereo ? kAudioChannelLayoutTag_Stereo : kAudioChannelLayoutTag_Mono


    static let rxCodec = Codecs.rxLpcm_16bit_1ch
    static let txCodec = Codecs.txNone
    static let txTimerFraction = 5
}



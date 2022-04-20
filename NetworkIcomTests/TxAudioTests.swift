//
//  TxAudioTests.swift
//  NetworkIcomTests
//
//  Created by Mark Erbaugh on 4/19/22.
//

import XCTest
import AVFoundation

class TxAudioTests: XCTestCase {

    func test8kMono8bituLaw() {
        let txAudio = TxAudio(rate: 8000, size: 1, uLaw: true, enable: true)
        let audioFormat = txAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatULaw,
                                                     mFormatFlags: kAudioFormatFlagIsSignedInteger,
                                                     mBytesPerPacket: 1,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 1,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 8,
                                                     mReserved: 0)
        
        XCTAssertEqual(txAudio.radioFormat, TxAudio.txULaw_8bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }
    
    func test8kMono8bitLpcm() {
        let txAudio = TxAudio(rate: 8000, size: 1, uLaw: false, enable: true)
        let audioFormat = txAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: kAudioFormatFlagIsSignedInteger,
                                                     mBytesPerPacket: 1,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 1,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 8,
                                                     mReserved: 0)
        
        XCTAssertEqual(txAudio.radioFormat, TxAudio.txLpcm_8bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }

    func test8kMono16bituLaw() {
        let txAudio = TxAudio(rate: 8000, size: 2, uLaw: true, enable: true)
        let audioFormat = txAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: kAudioFormatFlagIsSignedInteger,
                                                     mBytesPerPacket: 2,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 2,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 16,
                                                     mReserved: 0)
        
        XCTAssertEqual(txAudio.radioFormat, TxAudio.txLpcm_16bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }
    
    func test8kMono16bitLpcm() {
        let txAudio = TxAudio(rate: 8000, size: 2, uLaw: false, enable: true)
        let audioFormat = txAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: kAudioFormatFlagIsSignedInteger,
                                                     mBytesPerPacket: 2,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 2,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 16,
                                                     mReserved: 0)
        
        XCTAssertEqual(txAudio.radioFormat, TxAudio.txLpcm_16bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }

    func test16kMono8bituLaw() {
        let txAudio = TxAudio(rate: 16000, size: 1, uLaw: true, enable: true)
        let audioFormat = txAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 16000,
                                                     mFormatID: kAudioFormatULaw,
                                                     mFormatFlags: kAudioFormatFlagIsSignedInteger,
                                                     mBytesPerPacket: 1,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 1,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 8,
                                                     mReserved: 0)
        
        XCTAssertEqual(txAudio.radioFormat, TxAudio.txULaw_8bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }
}

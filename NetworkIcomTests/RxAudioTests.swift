//
//  RxAudioTests.swift
//  NetworkIcomTests
//
//  Created by Mark Erbaugh on 4/19/22.
//

import XCTest
import AVFoundation

class RxAudioTests: XCTestCase {

    func test8kMono8bituLaw() {
        let rxAudio = RxAudio(rate: 8000, channels: 1, size: 1, uLaw: true, enable: true)
        let audioFormat = rxAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatULaw,
                                                     mFormatFlags: kAudioFormatFlagIsSignedInteger,
                                                     mBytesPerPacket: 1,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 1,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 8,
                                                     mReserved: 0)
        
        XCTAssertEqual(rxAudio.radioFormat, RxAudio.rxULaw_8bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }

    func test8kMono8bitLpcm() {
        let rxAudio = RxAudio(rate: 8000, channels: 1, size: 1, uLaw: false, enable: true)
        let audioFormat = rxAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: 0,
                                                     mBytesPerPacket: 1,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 1,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 8,
                                                     mReserved: 0)
        
        XCTAssertEqual(rxAudio.radioFormat, RxAudio.rxLpcm_8bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }

    func test8kMono16bitUlaw() {
        let rxAudio = RxAudio(rate: 8000, channels: 1, size: 2, uLaw: true, enable: true)
        let audioFormat = rxAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: 0,
                                                     mBytesPerPacket: 2,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 2,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 16,
                                                     mReserved: 0)
        
        XCTAssertEqual(rxAudio.radioFormat, RxAudio.rxLpcm_16bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }
    
    func test8kMono16bitLpcm() {
        let rxAudio = RxAudio(rate: 8000, channels: 1, size: 2, uLaw: false, enable: true)
        let audioFormat = rxAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: 0,
                                                     mBytesPerPacket: 2,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 2,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 16,
                                                     mReserved: 0)
        
        XCTAssertEqual(rxAudio.radioFormat, RxAudio.rxLpcm_16bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }
    
    func test8kStereo8bituLaw() {
        let rxAudio = RxAudio(rate: 8000, channels: 2, size: 1, uLaw: true, enable: true)
        let audioFormat = rxAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatULaw,
                                                     mFormatFlags: kAudioFormatFlagIsSignedInteger,
                                                     mBytesPerPacket: 2,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 2,
                                                     mChannelsPerFrame: 2,
                                                     mBitsPerChannel: 8,
                                                     mReserved: 0)
        
        XCTAssertEqual(rxAudio.radioFormat, RxAudio.rxULaw_8bit_2ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }

    func test8kStereo8bitLpcm() {
        let rxAudio = RxAudio(rate: 8000, channels: 2, size: 1, uLaw: false, enable: true)
        let audioFormat = rxAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: 0,
                                                     mBytesPerPacket: 2,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 2,
                                                     mChannelsPerFrame: 2,
                                                     mBitsPerChannel: 8,
                                                     mReserved: 0)
        
        XCTAssertEqual(rxAudio.radioFormat, RxAudio.rxLpcm_8bit_2ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }

    func test8kStereo16bitUlaw() {
        let rxAudio = RxAudio(rate: 8000, channels: 2, size: 2, uLaw: true, enable: true)
        let audioFormat = rxAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: 0,
                                                     mBytesPerPacket: 4,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 4,
                                                     mChannelsPerFrame: 2,
                                                     mBitsPerChannel: 16,
                                                     mReserved: 0)
        
        XCTAssertEqual(rxAudio.radioFormat, RxAudio.rxLpcm_16bit_2ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }

    func test8kStereo16bitLpcm() {
        let rxAudio = RxAudio(rate: 8000, channels: 2, size: 2, uLaw: false, enable: true)
        let audioFormat = rxAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 8000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: 0,
                                                     mBytesPerPacket: 4,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 4,
                                                     mChannelsPerFrame: 2,
                                                     mBitsPerChannel: 16,
                                                     mReserved: 0)
        
        XCTAssertEqual(rxAudio.radioFormat, RxAudio.rxLpcm_16bit_2ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }

    func test16kMono8bituLaw() {
        let rxAudio = RxAudio(rate: 16000, channels: 1, size: 1, uLaw: true, enable: true)
        let audioFormat = rxAudio.audioFormat
        var targetAbsd = AudioStreamBasicDescription(mSampleRate: 16000,
                                                     mFormatID: kAudioFormatULaw,
                                                     mFormatFlags: kAudioFormatFlagIsSignedInteger,
                                                     mBytesPerPacket: 1,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 1,
                                                     mChannelsPerFrame: 1,
                                                     mBitsPerChannel: 8,
                                                     mReserved: 0)
        
        XCTAssertEqual(rxAudio.radioFormat, RxAudio.rxULaw_8bit_1ch)
        XCTAssertEqual(audioFormat, AVAudioFormat(streamDescription: &targetAbsd))
    }
}

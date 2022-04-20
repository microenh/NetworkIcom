//
//  TestRingBuffer.swift
//  NetworkIcomTests
//
//  Created by Mark Erbaugh on 4/20/22.
//

import XCTest
import Foundation
import AVFoundation

class TestRingBuffer: XCTestCase {
    
    func testFetchSingleBuffer() {
        let buffer: FIFORingBuffer! = FIFORingBuffer(maxBytesPerFrame: 1, maxFrames: 512)
        let src = Data(UInt8(1)...160)
        XCTAssertFalse(buffer.store(src))

        let bufferSizeBytes = MemoryLayout<UInt8>.size * 200

        let abl = AudioBufferList.allocate(maximumBuffers: 1)
        for i in 0..<abl.count {
            abl[i] = AudioBuffer(mNumberChannels: 1,
                                 mDataByteSize: UInt32(bufferSizeBytes),
                                 mData: malloc(bufferSizeBytes))
        }

        // Free your buffers and the pointer when you're done.
        defer {
            for buffer in abl {
                free(buffer.mData)
            }
        }

        _ = buffer.store(src)
        for ab in abl {
            memset(ab.mData, 255, Int(ab.mDataByteSize))
        }
        XCTAssertFalse(buffer.fetch(abl: abl.unsafeMutablePointer, frameCount: 160))
        XCTAssertEqual(abl[0].mDataByteSize, 160)

        XCTAssertEqual(abl[0].mData!.assumingMemoryBound(to: UInt8.self).pointee, 1)
        XCTAssertEqual(abl[0].mData!.advanced(by: 1).assumingMemoryBound(to: UInt8.self).pointee, 2)
        XCTAssertEqual(abl[0].mData!.advanced(by: 2).assumingMemoryBound(to: UInt8.self).pointee, 3)
        XCTAssertEqual(abl[0].mData!.advanced(by: 3).assumingMemoryBound(to: UInt8.self).pointee, 4)
        XCTAssertEqual(abl[0].mData!.advanced(by: 159).assumingMemoryBound(to: UInt8.self).pointee, 160)
        XCTAssertEqual(abl[0].mData!.advanced(by: 160).assumingMemoryBound(to: UInt8.self).pointee, 255)
    }

    func testFetchTwoBuffers() {
        let buffer: FIFORingBuffer! = FIFORingBuffer(maxBytesPerFrame: 1, maxFrames: 512)

        let bufferSizeBytes = MemoryLayout<UInt8>.size * 200

        let abl = AudioBufferList.allocate(maximumBuffers: 2)
        for i in 0..<abl.count {
            abl[i] = AudioBuffer(mNumberChannels: 1,
                                 mDataByteSize: UInt32(bufferSizeBytes),
                                 mData: malloc(bufferSizeBytes))
        }

        // Free your buffers and the pointer when you're done.
        defer {
            for buffer in abl {
                free(buffer.mData)
            }
        }

        XCTAssertFalse(buffer.store(Data(UInt8(1)...160)))
        XCTAssertFalse(buffer.store(Data([UInt8](UInt8(1)...160).reversed())))
        for ab in abl {
            memset(ab.mData, 255, Int(ab.mDataByteSize))
        }
        XCTAssertFalse(buffer.fetch(abl: abl.unsafeMutablePointer, frameCount: 160))
        XCTAssertEqual(abl[0].mDataByteSize, 160)

        XCTAssertEqual(abl[0].mData!.assumingMemoryBound(to: UInt8.self).pointee, 1)
        XCTAssertEqual(abl[0].mData!.advanced(by: 1).assumingMemoryBound(to: UInt8.self).pointee, 2)
        XCTAssertEqual(abl[0].mData!.advanced(by: 2).assumingMemoryBound(to: UInt8.self).pointee, 3)
        XCTAssertEqual(abl[0].mData!.advanced(by: 3).assumingMemoryBound(to: UInt8.self).pointee, 4)
        XCTAssertEqual(abl[0].mData!.advanced(by: 159).assumingMemoryBound(to: UInt8.self).pointee, 160)
        XCTAssertEqual(abl[0].mData!.advanced(by: 160).assumingMemoryBound(to: UInt8.self).pointee, 255)

        XCTAssertEqual(abl[1].mDataByteSize, 160)

        XCTAssertEqual(abl[1].mData!.assumingMemoryBound(to: UInt8.self).pointee, 160)
        XCTAssertEqual(abl[1].mData!.advanced(by: 1).assumingMemoryBound(to: UInt8.self).pointee, 159)
        XCTAssertEqual(abl[1].mData!.advanced(by: 2).assumingMemoryBound(to: UInt8.self).pointee, 158)
        XCTAssertEqual(abl[1].mData!.advanced(by: 3).assumingMemoryBound(to: UInt8.self).pointee, 157)
        XCTAssertEqual(abl[1].mData!.advanced(by: 159).assumingMemoryBound(to: UInt8.self).pointee, 1)
        XCTAssertEqual(abl[1].mData!.advanced(by: 160).assumingMemoryBound(to: UInt8.self).pointee, 255)
    }

    func testFetchTwoPartialBuffers() {
        let buffer: FIFORingBuffer! = FIFORingBuffer(maxBytesPerFrame: 1, maxFrames: 512)

        let bufferSizeBytes = MemoryLayout<UInt8>.size * 200

        let abl = AudioBufferList.allocate(maximumBuffers: 2)
        for i in 0..<abl.count {
            abl[i] = AudioBuffer(mNumberChannels: 1,
                                 mDataByteSize: UInt32(bufferSizeBytes),
                                 mData: malloc(bufferSizeBytes))
        }

        // Free your buffers and the pointer when you're done.
        defer {
            for buffer in abl {
                free(buffer.mData)
            }
        }

        XCTAssertFalse(buffer.store(Data(UInt8(1)...160)))
        for ab in abl {
            memset(ab.mData, 255, Int(ab.mDataByteSize))
        }
        XCTAssertTrue(buffer.fetch(abl: abl.unsafeMutablePointer, frameCount: 160))
        XCTAssertEqual(abl[0].mDataByteSize, 160)

        XCTAssertEqual(abl[0].mData!.assumingMemoryBound(to: UInt8.self).pointee, 1)
        XCTAssertEqual(abl[0].mData!.advanced(by: 1).assumingMemoryBound(to: UInt8.self).pointee, 2)
        XCTAssertEqual(abl[0].mData!.advanced(by: 2).assumingMemoryBound(to: UInt8.self).pointee, 3)
        XCTAssertEqual(abl[0].mData!.advanced(by: 3).assumingMemoryBound(to: UInt8.self).pointee, 4)
        XCTAssertEqual(abl[0].mData!.advanced(by: 159).assumingMemoryBound(to: UInt8.self).pointee, 160)
        XCTAssertEqual(abl[0].mData!.advanced(by: 160).assumingMemoryBound(to: UInt8.self).pointee, 255)

        XCTAssertEqual(abl[1].mDataByteSize, 0)

        XCTAssertEqual(abl[1].mData!.assumingMemoryBound(to: UInt8.self).pointee, 255)
        XCTAssertEqual(abl[1].mData!.advanced(by: 1).assumingMemoryBound(to: UInt8.self).pointee, 255)
        XCTAssertEqual(abl[1].mData!.advanced(by: 2).assumingMemoryBound(to: UInt8.self).pointee, 255)
        XCTAssertEqual(abl[1].mData!.advanced(by: 3).assumingMemoryBound(to: UInt8.self).pointee, 255)
        XCTAssertEqual(abl[1].mData!.advanced(by: 79).assumingMemoryBound(to: UInt8.self).pointee, 255)
        XCTAssertEqual(abl[1].mData!.advanced(by: 80).assumingMemoryBound(to: UInt8.self).pointee, 255)
        XCTAssertEqual(abl[1].mData!.advanced(by: 159).assumingMemoryBound(to: UInt8.self).pointee, 255)
        XCTAssertEqual(abl[1].mData!.advanced(by: 160).assumingMemoryBound(to: UInt8.self).pointee, 255)
    }

    func testFetchSingle16BitBuffer() {

        func f(_ start: UInt8) -> UInt16 {
            UInt16(start + 1) << 8 | UInt16(start)
        }

        XCTAssertEqual(f(1), 513)

        typealias Sample = UInt16
        let sampleSize = MemoryLayout<Sample>.size
        let buffer: FIFORingBuffer! = FIFORingBuffer(maxBytesPerFrame: 2, maxFrames: 512)
        let src = Data(UInt8(1)...160)

        let bufferSizeBytes = sampleSize * 200

        let abl = AudioBufferList.allocate(maximumBuffers: 1)
        for i in 0..<abl.count {
            abl[i] = AudioBuffer(mNumberChannels: 1,
                                 mDataByteSize: UInt32(bufferSizeBytes),
                                 mData: malloc(bufferSizeBytes))
        }

        // Free your buffers and the pointer when you're done.
        defer {
            for buffer in abl {
                free(buffer.mData)
            }
        }

        XCTAssertFalse(buffer.store(src))
        XCTAssertFalse(buffer.store(src))
        for ab in abl {
            memset(ab.mData, 255, Int(ab.mDataByteSize))
        }
        XCTAssertFalse(buffer.fetch(abl: abl.unsafeMutablePointer, frameCount: 160))
        XCTAssertEqual(abl[0].mDataByteSize, 320)

        XCTAssertEqual(abl[0].mData!.assumingMemoryBound(to: Sample.self).pointee, f(1))
        XCTAssertEqual(abl[0].mData!.advanced(by: sampleSize).assumingMemoryBound(to: Sample.self).pointee, f(3))
        XCTAssertEqual(abl[0].mData!.advanced(by: 2 * sampleSize).assumingMemoryBound(to: Sample.self).pointee, f(5))
        XCTAssertEqual(abl[0].mData!.advanced(by: 3 * sampleSize).assumingMemoryBound(to: Sample.self).pointee, f(7))
        XCTAssertEqual(abl[0].mData!.advanced(by: 159 * sampleSize).assumingMemoryBound(to: Sample.self).pointee, f(159))
        XCTAssertEqual(abl[0].mData!.advanced(by: 160 * sampleSize).assumingMemoryBound(to: Sample.self).pointee, 0xffff)
    }
}

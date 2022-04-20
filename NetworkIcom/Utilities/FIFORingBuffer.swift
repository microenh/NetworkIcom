//
//  RingBuffer.swift
//  TestRingBuffer2
//
//  Created by Mark Erbaugh on 4/13/22.
//

import Foundation
import AVFoundation

fileprivate struct Settings {
    static let maxBytesPerFrame = 4
    static let maxFrames = 3000
}

class FIFORingBuffer {
    
    private var mData: UnsafeMutableRawPointer!
    private var size: Int
    private var _bytesPerFrame: UInt8
    private var readIndex: Int
    private var writeIndex = 0
    
    init() {
        _bytesPerFrame = UInt8(Settings.maxBytesPerFrame)
        size = Int(_bytesPerFrame) * Settings.maxFrames
        readIndex = size
        mData = malloc(size)
    }
    
    deinit {
        free(mData)
    }
    
    var bytesPerFrame: UInt8 {
        get { _bytesPerFrame }
        set {
            clear()
            _bytesPerFrame = newValue
        }
    }
        
    /// Fill an AudioBufferList with data from the buffer
    ///
    /// The buffers are assumed to be large enough to handle frameCount frames.
    /// If there is not enough data to fill the buffer, zero is used
    ///
    /// - Parameters:
    ///   - abl: a pointer to the AudioBufferList
    ///   - frameCount: the number of frames requested
    ///   
    /// - Returns: true on buffer underrun
    func fetch(abl: UnsafeMutablePointer<AudioBufferList>, frameCount: Int) -> Bool {
        guard mData != nil else {
            return true
        }
        guard frameCount > 0 else {
            return false
        }
        var result = false
        let bufferCount = Int(abl.pointee.mNumberBuffers)
        let bytesRequested = frameCount * Int(_bytesPerFrame)
        withUnsafeMutablePointer(to: &abl.pointee.mBuffers) { start in
            let ab = UnsafeMutableBufferPointer(start: start, count: bufferCount)
            for i in 0..<bufferCount {
                let bytesGranted = fetch(count: bytesRequested, dest: ab[i].mData!)
                ab[i].mDataByteSize = UInt32(bytesGranted)
                result = result || (bytesGranted < bytesRequested)
            }
        }
        return result
    }

    /// - Returns: bytes retrieved
    private func fetch(count: Int, dest: UnsafeMutableRawPointer) -> Int {
        if readIndex == size {
            return 0
        }
        let canReturn = min(count, self.count)
        let canCopyFromEnd = min(canReturn, size - readIndex)
        if canCopyFromEnd > 0 {
            dest.copyMemory(from: mData.advanced(by: readIndex), byteCount: canCopyFromEnd)
        }
        let canCopyFromBeginning = min(readIndex, canReturn - canCopyFromEnd)
        if canCopyFromBeginning > 0 {
            dest.advanced(by: canCopyFromEnd).copyMemory(from: mData, byteCount: canCopyFromBeginning)
        }
        readIndex = (readIndex + canCopyFromEnd + canCopyFromBeginning) % size
        if readIndex == writeIndex {
            // buffer empty
            writeIndex = 0
            readIndex = size
        }
        return canReturn
    }
    
    /// - Returns: true on buffer overrrun
    func store(_ data: Data) -> Bool {
        data.withUnsafeBytes { data in
            guard mData != nil else {
                return true
            }
            if data.count == 0 {
                return true
            }
            let overrun = data.count + self.count > size
            if data.count >= size {
                // copy last <size> bytes from source
                let p = data.baseAddress?.advanced(by: data.count - size)
                mData.copyMemory(from: p!, byteCount: size)
                readIndex = 0
                writeIndex = 0
                return overrun
            }
            // copy from writeIndex to end
            let canCopyToEnd = min(data.count, size - writeIndex)
            if canCopyToEnd > 0 {
                mData.advanced(by: writeIndex).copyMemory(from: data.baseAddress!, byteCount: canCopyToEnd)
            }
            // copy from beginning
            let canCopyToBeginning = min(writeIndex, data.count - canCopyToEnd)
            if canCopyToBeginning > 0 {
                let p = data.baseAddress?.advanced(by: canCopyToEnd)
                mData.copyMemory(from: p!, byteCount: canCopyToBeginning)
            }
            // adjust readIndex, writeIndex
            let newWriteIndex = writeIndex + canCopyToEnd + canCopyToBeginning
            if readIndex == size {
                readIndex = 0
            } else {
                let adjRead = readIndex + (readIndex < writeIndex ? size : 0)
                if (writeIndex..<newWriteIndex).contains(adjRead) {
                    readIndex = newWriteIndex % size
                }
            }
            writeIndex = newWriteIndex % size
            return overrun
        }
    }
    
    func clear() {
        readIndex = size
        writeIndex = 0
    }
    
    var count: Int {
        var ct = writeIndex - readIndex
        if ct <= 0 {
            ct += size
        }
        return ct
    }
}

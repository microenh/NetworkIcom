//
//  RingBuffer.swift
//  TestRingBuffer2
//
//  Created by Mark Erbaugh on 4/13/22.
//

import Foundation
import AVFoundation

class FIFORingBuffer {
    
    private var mData: UnsafeMutableRawPointer!
    private var size: Int
    private var bytesPerFrame: Int
    private var readIndex: Int
    private var writeIndex = 0
    
    init?(bytesPerFrame: Int, maxFrames: Int) {
        self.bytesPerFrame = bytesPerFrame
        size = bytesPerFrame * maxFrames
        readIndex = size
        mData = malloc(size)
        if mData == nil {
            return nil
        }
    }
    
    deinit {
        free(mData)
    }
    
    func fetch(abl: UnsafeMutablePointer<AudioBufferList>, frameCount: Int)  -> Int {
        var totalBytes = 0
        var count = Int(abl.pointee.mNumberBuffers)
        let maxBytes = min(self.count / (bytesPerFrame * count), frameCount) * bytesPerFrame
        for i in 0..<count {
            let bytesRequested = Int(abl.pointee.mBuffers.mDataByteSize)
            let bytesToGrant = min(maxBytes, bytesRequested)
            if bytesToGrant < bytesRequested {
                
                memset(abl.pointee.mBuffers.mData?.advanced(by: bytesToGrant), 0, bytesRequested - bytesToGrant)
            }
            let bytes = fetch(count: bytesToGrant, dest: abl.pointee.mBuffers.mData!)
            abl.pointee.mBuffers.mDataByteSize = UInt32(bytes)
            totalBytes += bytes
        }
        return totalBytes
    }

    func fetch(count: Int, dest: UnsafeMutableRawPointer) -> Int {
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
    
    func store(_ data: Data) {
        data.withUnsafeBytes{ data in
            if data.count == 0 {
                return
            }
            if data.count >= size {
                // copy last <size> bytes from source
                let p = data.baseAddress?.advanced(by: data.count - size)
                mData.copyMemory(from: p!, byteCount: size)
                readIndex = 0
                writeIndex = 0
                return
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

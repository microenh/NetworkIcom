//
//  Palette.swift
//  TestBitmap
//
//  Created by Mark Erbaugh on 2/22/22.
//

import Foundation

struct FLDigiPalette {
    static let fldigi = [[UInt8(0),0,0], [0, 0,177], [ 3,110,227], [ 0,204,204], [223,223,223], [  0,234,  0], [244,244,  0], [250,126,  0], [244,  0,  0]]
    static let scope  = [[UInt8(0),0,0], [0, 0,167], [ 0, 79,255], [ 0,239,255], [  0,255, 75], [ 95,255,  0], [255,255,  0], [255,127,  0], [255,  0,  0]]
    static let cyan   = [[UInt8(0),0,0], [5,10, 10], [22, 42, 42], [52, 99, 99], [ 94,175,175], [131,209,209], [162,224,224], [202,239,239], [255,255,255]]
}

func setColors(palette: [[UInt8]]) -> [PixelColor] {
    var result = Array<PixelColor>(repeating: PixelColor.clear, count: 256)
    for i in 0..<256 {
        // result[i].a = UInt8(sqrt(Double(i) / 256.0) * 200)
        result[i].a = 255
    }
    for n in 0..<8 {
        for i in 0..<25 {
            let r = Double(palette[n][0]) + (Double(i) * (Double(palette[n+1][0]) - Double(palette[n][0])) / 25)
            let g = Double(palette[n][1]) + (Double(i) * (Double(palette[n+1][1]) - Double(palette[n][1])) / 25)
            let b = Double(palette[n][2]) + (Double(i) * (Double(palette[n+1][2]) - Double(palette[n][2])) / 25)
            result[i + 25 * n].r = UInt8(r)
            result[i + 25 * n].g = UInt8(g)
            result[i + 25 * n].b = UInt8(b)
        }
    }
    for i in 200..<256 {
        result[i].r = palette[8][0]
        result[i].g = palette[8][1]
        result[i].b = palette[8][2]
    }
    return result
}

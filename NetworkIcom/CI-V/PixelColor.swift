//
//  Color.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import CoreGraphics

public struct PixelColor {
    public var r, g, b, a: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
}

public extension PixelColor {
    static let clear = PixelColor(r: 0, g: 0, b: 0, a: 0)
    static let black = PixelColor(r: 0, g: 0, b: 0)
    static let white = PixelColor(r: 255, g: 255, b: 255)
    static let red = PixelColor(r: 217, g: 87, b: 99)
    static let green = PixelColor(r: 153, g: 229, b: 80)
    static let yellow = PixelColor(r: 251, g: 242, b: 54)
}

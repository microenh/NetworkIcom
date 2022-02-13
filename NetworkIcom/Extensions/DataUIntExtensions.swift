//
//  DataUIntExtensions.swift
//  NetworkWWDC2018
//
//  Created by Mark Erbaugh on 1/16/22.
//

import Foundation

extension Data {
    var bool: Bool { self[startIndex] > 0 }
    var uint8: UInt8 { to(UInt8.self) }
    var uint16: UInt16 { to(UInt16.self) }
    var uint32: UInt32 { to(UInt32.self) }
    
    var string: String {
        String(data: self.filter{$0 > 0}, encoding: .utf8)!
    }
    
    var hexByteString: String {
        map {String(format: "%02X", $0)}.joined(separator: " ")
    }

    subscript( _ d: (Int, Int) ) -> Data {
        get { self[d.0..<d.0+d.1] }
        set { self[d.0..<d.0+d.1] = (newValue + Data(count: d.1)).prefix(d.1)}
    }
    
    init<T>(_ value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }
    
    init(_ value: String) {
        self = Data(Array(value.utf8))
    }
    
    private func to<T>(_ type: T.Type) -> T where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0)} )
        return value
    }
    
    func dump(columns: Int = 16) -> String {
        var result = ""
        for i in stride(from: 0, to: self.count, by: columns) {
            let j = Swift.min(i + columns, self.count)
            let k = i + columns - j
            
            let hex = (self[i..<j].map() {b in String(format: "%02x", b)} + Array(repeating: "  ", count: k)).joined(separator: " ")
            let ascii = self[i..<j].map() {b in (32..<128).contains(b) ? String(format: "%c", b)  : "."}.joined(separator: "")
            result += "\r" + hex + " | " + ascii
        }
        return result
    }
}

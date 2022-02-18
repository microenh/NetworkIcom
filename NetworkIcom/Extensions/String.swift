//
//  String.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/18/22.
//

import Foundation

extension String {
    
    func dataPaddedWithSpaces(length: Int) -> Data {
        (Data(self.compactMap{$0.asciiValue}) + Data(repeating: 0x20, count: length)).prefix(length)
    }
}

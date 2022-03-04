//
//  Locks.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/10/22.
//

import Foundation

struct Locks {
    static let sendLock = NSLock()
    static let audioLock = NSLock()
}

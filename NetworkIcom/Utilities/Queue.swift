//
//  Queue.swift
//  Icom7610a
//
//  Created by Mark Erbaugh on 11/26/21.
//

import Foundation

struct Queue<T> {
    private var list = [T]()
    
    mutating func enqueue(_ element: T) {
        list.append(element)
    }
    
    mutating func dequeue() -> T? {
        if !list.isEmpty {
            return list.removeFirst()
        } else {
            return nil
        }
    }
    
    func peek() -> T? {
        if !list.isEmpty {
            return list[0]
        } else {
            return nil
        }
    }
    
    var isEmpty: Bool {
        list.isEmpty
    }
    
    var size: Int {
        list.count
    }
}

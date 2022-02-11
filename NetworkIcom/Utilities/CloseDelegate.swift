//
//  Close.swift
//  UDP4
//
//  Created by Mark Erbaugh on 1/14/22.
//

import Foundation
import SwiftUI

/*
 To close the application when clicking the Red "close window" button:
 add '@NSApplicationDelegateAdaptor(CloseDelegate.self) var closeDelegate'
 to the App struct
 */


class CloseDelegate: NSObject, NSApplicationDelegate {
    // close app when last window closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

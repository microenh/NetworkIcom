//
//  NetworkIcomApp.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/8/22.
//

import SwiftUI

@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor(CloseDelegate.self) var closeDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

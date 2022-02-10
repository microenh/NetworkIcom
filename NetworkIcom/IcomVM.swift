//
//  IcomVM.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/10/22.
//

import Foundation
import SwiftUI

class IcomVM: ObservableObject {
    
    @Published var controlLatency = 0.0
    @Published var controlState = "Disconnected"
    @Published var controlRetransmitCount = 0
    
    private let host: String
    private let controlPort: UInt16
    private let user: String
    private let password: String
    private let computer: String

    private func notifyControl(notification: UDPControl.Notifications) {
        switch notification {
        case .latency(let latency):
            DispatchQueue.main.async { [weak self] in
                self?.controlLatency = latency
            }
        case .state(let state):
            DispatchQueue.main.async { [weak self] in
                self?.controlState = state
            }
        case .retransmitCount(let count):
            DispatchQueue.main.async { [weak self] in
                self?.controlRetransmitCount = count
            }
        case .disconnected:
            control = nil
        case .connected:
            break
        }
    }
    
    private var control: UDPControl?
    
    init(host: String,
         controlPort: UInt16,
         user: String,
         password: String,
         computer: String) {
        
        self.host = host
        self.controlPort = controlPort
        self.user = user
        self.password = password
        self.computer = computer
    }
    
    func connect() {
        control = UDPControl(host: host,
                             port: controlPort,
                             user: user,
                             password: password,
                             computer: computer, notify: notifyControl)
    }
    
    func disconnect() {
        control?.disconnect()
    }
}

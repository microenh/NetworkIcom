//
//  IcomVM.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/10/22.
//

import Foundation
import SwiftUI
import Combine

class IcomVM: ObservableObject {
    
    @Published var controlLatency = 0.0
    @Published var controlState = ""
    @Published var controlRetransmitCount = 0
    
    private let host: String
    private let controlPort: UInt16
    private let user: String
    private let password: String
    private let computer: String

    var control: UDPControl?
    
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
    
    private var controlCancellables: Set<AnyCancellable?> = []
    
    func connect() {
        control = UDPControl(host: host,
                             port: controlPort,
                             user: user,
                             password: password,
                             computer: computer)
        setupControlSinks()
    }
    
    private func setupControlSinks() {
        controlCancellables.insert(control?.latency.receive(on: DispatchQueue.main).sink { [weak self] latency in
            self?.controlLatency = latency
        })
        controlCancellables.insert(control?.state.receive(on: DispatchQueue.main).sink { [weak self] state in
            self?.controlState = state
        })
        controlCancellables.insert(control?.retransmitCount.receive(on: DispatchQueue.main).sink { [weak self] count in
            self?.controlRetransmitCount = count
        })
        controlCancellables.insert(control?.disconnected.receive(on: DispatchQueue.main).sink { [weak self] disconnected in
            if disconnected {
                self?.control = nil
                self?.controlCancellables = []
            }
        })
    }
    
    func disconnect() {
        control?.disconnect()
    }
}

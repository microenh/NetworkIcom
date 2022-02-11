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
    @Published var radioCivAddr = UInt8(0)
    @Published var serialLatency = 0.0
    @Published var serialState = ""
    @Published var serialRetransmitCount = 0
    @Published var civData = Data()
    @Published var frequency = 0

    private let host: String
    private let controlPort: UInt16
    private let serialPort: UInt16
    private let user: String
    private let password: String
    private let computer: String
    private let hostCivAddr: UInt8

    var control: UDPControl?
    var serial: UDPSerial?
    
    init(host: String,
         controlPort: UInt16,
         serialPort: UInt16,
         user: String,
         password: String,
         computer: String,
         hostCivAddr: UInt8) {
        
        self.host = host
        self.controlPort = controlPort
        self.serialPort = serialPort
        self.user = user
        self.password = password
        self.computer = computer
        self.hostCivAddr = hostCivAddr
    }
    
    
    func connectControl() {
        control = UDPControl(host: host,
                             port: controlPort,
                             user: user,
                             password: password,
                             computer: computer)
        setupControlSinks()
    }
    
    func disconnectControl() {
        control?.disconnect()
    }
    
    private var controlCancellables: Set<AnyCancellable?> = []
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
        controlCancellables.insert(control?.radioCivAddr.receive(on: DispatchQueue.main).sink { [weak self] civID in
            self?.radioCivAddr = civID
        })
        controlCancellables.insert(control?.connected.receive(on: DispatchQueue.main).sink { [weak self] connected in
            if connected {
            } else {
                self?.control = nil
                self?.controlCancellables = []
            }
        })
    }
    
    func connectSerial() {
        serial = UDPSerial(host: host,
                           port: serialPort,
                           radioCivAddr: radioCivAddr,
                           hostCivAddr: hostCivAddr)
        setupSerialSinks()
        setupRadioSinks()
    }
    
    func disconnectSerial() {
        serial?.disconnect()
    }
    
    private var serialCancellables: Set<AnyCancellable?> = []
    private func setupSerialSinks() {
        serialCancellables.insert(serial?.latency.receive(on: DispatchQueue.main).sink { [weak self] latency in
            self?.serialLatency = latency
        })
        serialCancellables.insert(serial?.state.receive(on: DispatchQueue.main).sink { [weak self] state in
            self?.serialState = state
        })
        serialCancellables.insert(serial?.retransmitCount.receive(on: DispatchQueue.main).sink { [weak self] count in
            self?.serialRetransmitCount = count
        })
        serialCancellables.insert(serial?.civData.receive(on: DispatchQueue.main).sink { [weak self] civData in
            self?.civData = civData
        })
        serialCancellables.insert(serial?.connected.receive(on: DispatchQueue.main).sink { [weak self] connected in
            if connected {
            } else {
                self?.serial = nil
                self?.serialCancellables = []
            }
        })
    }
    
    private func setupRadioSinks() {
        serialCancellables.insert(serial?.civDecode.frequency.receive(on: DispatchQueue.main).sink { [weak self] frequency in
            self?.frequency = frequency
        })
    }
    
}

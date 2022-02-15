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
    @Published var frequency = 0
    @Published var modeFilter = ModeFilter(mode: .lsb, filter: .fil1)
    @Published var attenuation = Attenuation.attOff
    @Published var connected = false
    @Published var printDump = ""
    @Published var queueSize = 0

    private let host: String
    private let controlPort: UInt16
    private let serialPort: UInt16
    private let audioPort: UInt16
    private let user: String
    private let password: String
    private let computer: String
    private let hostCivAddr: UInt8

    var control: UDPControl?
    var serial: UDPSerial?
    
    init(host: String,
         controlPort: UInt16,
         serialPort: UInt16,
         audioPort: UInt16,
         user: String,
         password: String,
         computer: String,
         hostCivAddr: UInt8) {
        
        self.host = host
        self.controlPort = controlPort
        self.serialPort = serialPort
        self.audioPort = audioPort
        self.user = user
        self.password = password
        self.computer = computer
        self.hostCivAddr = hostCivAddr
    }
    
    private var controlCancellables: Set<AnyCancellable> = []
    func connectControl() {
        controlCancellables = []
        control = UDPControl(host: host,
                             port: controlPort,
                             user: user,
                             password: password,
                             computer: computer,
                             serialPort: serialPort,
                             audioPort: audioPort)
        control?.basePublished.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateControlBaseData(data)
        }.store(in: &controlCancellables)
        control?.published.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateControlData(data)
        }.store(in: &controlCancellables)
    }
    
    func disconnectControl() {
        if let serial = serial {
            serial.disconnect()
        } else {
            control?.disconnect()
        }
    }
        
    private func updateControlBaseData(_ data: UDPBase.BasePublished) {
        switch data {
        case .latency(let latency):
            self.controlLatency = latency
        case .state(let state):
            self.controlState = state
        case .retransmitCount(let count):
            self.controlRetransmitCount = count
        case .connected(let connected):
            self.connected = connected
            if connected {
                connectSerial()
            } else {
                control = nil
                controlCancellables = []
            }
        }
    }
    
    private func updateControlData(_ data: UDPControl.Published) {
        switch data {
        case .radioCivAddr(let addr):
            radioCivAddr = addr
        }
    }
    
    private var serialCancellables: Set<AnyCancellable> = []
    private func connectSerial() {
        serialCancellables = []
        serial = UDPSerial(host: host, port: serialPort,
                           user: user, password: password, computer: computer,
                           radioCivAddr: radioCivAddr,  hostCivAddr: hostCivAddr)
        serial?.basePublished.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateSerialBaseData(data)
        }.store(in: &serialCancellables)
        serial?.published.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateSerialData(data)
        }.store(in: &serialCancellables)
        serial?.civ.civPpublished.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateCIVData(data)
        }.store(in: &serialCancellables)
    }
    
    private func updateSerialBaseData(_ data: UDPBase.BasePublished) {
        switch data {
        case .latency(let latency):
            self.serialLatency = latency
        case .state(let state):
            self.serialState = state
        case .retransmitCount(let count):
            self.serialRetransmitCount = count
        case .connected(let connected):
            if connected {
            } else {
                serial = nil
                serialCancellables = []
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.control?.disconnect()
                }
                // control?.disconnect()
            }
        }
    }
    
    private func updateSerialData(_ data: UDPSerial.Published) {
        switch data {
            
        case .sendQueueSize(let size):
            self.queueSize = size
        }
    }
    
    private func updateCIVData(_ data: CIV.CIVPublished) {
        switch data {
        case .frequency(let frequency):
            self.frequency = frequency
        case .modeFilter(let modeFilter):
            self.modeFilter = modeFilter
        case .attenuation(let attenuation):
            self.attenuation = attenuation
        case .printDump(let p):
            self.printDump = p
        }
    }
}

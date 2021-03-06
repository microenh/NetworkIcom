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
    @Published var controlState = "Disconnected"
    @Published var controlRetransmitCount = 0
    @Published var radioCivAddr = UInt8(0)
    @Published var serialLatency = 0.0
    @Published var serialState = "Disconnected"
    @Published var audioState = "Disconnected"
    @Published var serialRetransmitCount = 0
    @Published var connected = false
    @Published var underrunCount = 0
    @Published var overrunCount = 0

    var control: UDPControl?
    var serial: UDPSerial?
    var audio: UDPAudio?
    
    var connectionInfo: ConnectionInfo
    var rxAudio: RxAudio
    var txAudio: TxAudio
    
    var civDecode: (Data) -> ()
    
    init(mConnectionInfo: ConnectionInfo,
         mRxAudio: RxAudio,
         mTxAudio: TxAudio,
         mCivDecode: @escaping (Data) -> ()) {
        
        connectionInfo = mConnectionInfo
        rxAudio = mRxAudio
        txAudio = mTxAudio
        civDecode = mCivDecode
    }
    
    private var controlCancellables: Set<AnyCancellable> = []
    func connectControl() {
        controlCancellables = []
        control = UDPControl(mConnectionInfo: connectionInfo,
                             mRxAudio: rxAudio,
                             mTxAudio: txAudio)
        control?.basePublished.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateControlBaseData(data)
        }.store(in: &controlCancellables)
        control?.published.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateControlData(data)
        }.store(in: &controlCancellables)
        control?.start()
    }
    
    func disconnectControl() {
        var disconnectControl = true
        if let audio = audio {
            audio.disconnect()
            disconnectControl = false
        }
        if let serial = serial {
            serial.disconnect()
            disconnectControl = false
        }
        if disconnectControl {
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
                connectAudio()
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
        serial = UDPSerial(mConnectionInfo: connectionInfo,
                           mRxAudio: rxAudio, mTxAudio: txAudio,
                           civDecode: civDecode)
        serial?.basePublished.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateSerialBaseData(data)
        }.store(in: &serialCancellables)
        serial?.published.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateSerialData(data)
        }.store(in: &serialCancellables)
        serial?.start()
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
                serial?.send(command: 0x03)  // frequency
                serial?.send(command: 0x04)  // mode-filter
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
//        switch data {
//
//        case .sendQueueSize(let size):
//            self.queueSize = size
//        }
    }
    
    private var audioCancellables: Set<AnyCancellable> = []
    private func connectAudio() {
        audioCancellables = []
        audio = UDPAudio(mConnectionInfo: connectionInfo, mPort: connectionInfo.audioPort,
                         mRxAudio: rxAudio, mTxAudio: txAudio)
        audio?.basePublished.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateAudioBaseData(data)
        }.store(in: &audioCancellables)
        audio?.published.receive(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateAudioData(data)
        }.store(in: &audioCancellables)
        audio?.start()
    }
    
    private func updateAudioBaseData(_ data: UDPBase.BasePublished) {
        switch data {
        case .state(let state):
            self.audioState = state
        case .retransmitCount(let count):
            self.serialRetransmitCount = count
        case .connected(let connected):
            if !connected {
                audio = nil
                audioCancellables = []
            }
        default:
            break
        }
    }
    
    private func updateAudioData(_ data: UDPAudio.Published) {
        switch data {
        case .underrunCount(let count):
            underrunCount = count
        case .overrunCount(let count):
            overrunCount = count
        }
    }
    
}

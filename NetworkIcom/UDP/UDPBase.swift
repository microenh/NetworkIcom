//
//  UDPBase.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/10/22.
//

import Foundation
import Network
import Combine

class UDPBase {
    private class Settings {
        static let pingInterval = 3.0
        static let idleInterval = 1.0
        static let retryInterval = 5.0
    }
    
    enum BasePublished {
        case latency(Double)
        case state(String)
        case retransmitCount(Int)
        case connected(Bool)
    }
    
    var basePublished = PassthroughSubject<BasePublished, Never>()
    
    var connection: NWConnection?
    var packetCreate: PacketCreate
    
    var idleTimer: Timer?
    var pingTimer: Timer?
    var resendTimer: Timer?
    
    var retryPacket = Data()
    
    var disconnecting = false
    
    init(host: String, port: UInt16,
         user: String, password: String, computer: String) {
        let portObject = NWEndpoint.Port(integerLiteral: port)
        let hostObject = NWEndpoint.Host(host)

        let params = NWParameters.udp
        params.allowFastOpen = true
        params.allowLocalEndpointReuse = true
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.any), port: portObject)
        
        packetCreate = PacketCreate(user: user, password: password, computer: computer)

        connection = NWConnection(host: hostObject, port: portObject, using: params)
        connection?.stateUpdateHandler = { [weak self] newState in self?.stateUpdateHandler(newState: newState) }
        connection?.start(queue: DispatchQueue.global())
        
        basePublished.send(.state("Connecting"))
    }
    
    func invalidateTimers() {
        pingTimer?.invalidate()
        idleTimer?.invalidate()
        resendTimer?.invalidate()
    }
    
    func stateUpdateHandler(newState: NWConnection.State) {
        switch newState {
        case .ready:
            startReceive()
            startConnection()
        case .failed(_), .cancelled:
            basePublished.send(.connected(false))
            connection = nil
            break
        default:
            break
        }
    }

    func startReceive() {
        connection?.receiveMessage { [weak self] content, context, isComplete, error in
            if let self = self {
                guard error == nil, let content = content else {
                    self.basePublished.send(.state(error?.localizedDescription ?? "connection error"))
                    self.connection?.cancel()
                    self.basePublished.send(.connected(false))
                    return
                }
                self.receive(data: content)
                self.startReceive()
            }
        }
    }
    
    func startConnection() {
        armResendTimer()
        retryPacket = packetCreate.areYouTherePacket()
        send(data: retryPacket)
    }
    
    var current = Data()
    func receive(data: Data) {}
    
    func armResendTimer() {
        resendTimer?.invalidate()
        let timer = Timer(timeInterval: Settings.retryInterval, repeats: false, block: onResendTimer(timer:))
        RunLoop.main.add(timer, forMode: .common)
        resendTimer = timer
    }
    
    func armIdleTimer() {
        idleTimer?.invalidate()
        let timer = Timer(timeInterval: Settings.idleInterval, repeats: false, block: onIdleTimer(timer:))
        RunLoop.main.add(timer, forMode: .common)
        idleTimer = timer
    }
    
    func armPingTimer() {
        pingTimer?.invalidate()
        let timer = Timer(timeInterval: Settings.pingInterval, repeats: false, block: onPingTimer(timer:))
        RunLoop.main.add(timer, forMode: .common)
        pingTimer = timer
    }

    func send(data: Data) {
        Locks.sendLock.lock()
        connection?.send(content: data, completion: .idempotent)
        Locks.sendLock.unlock()
    }
    
    private var lastPingRequestSentTime = Date()
    private var lastPingRequestSequence = UInt16(0)
    private func onPingTimer(timer: Timer) {
        typealias c = ControlDefinition
        typealias p = PingDefinition
        let packet = packetCreate.pingPacket()
        lastPingRequestSequence = packet[c.sequence].uint16
        lastPingRequestSentTime = Date()
        armIdleTimer()
        armPingTimer()
        send(data: packet)
    }
    
    func receivePing() {
        typealias c = ControlDefinition
        typealias p = PingDefinition
        if current[p.request].bool {
            // response to host ping
            if current[c.sequence].uint16 == lastPingRequestSequence {
                let lat = lastPingRequestSentTime.timeIntervalSinceNow * -500.0
                basePublished.send(.latency(lat))
            }
        } else {
            // Ping request from radio
            send(data: packetCreate.pingPacket(replyTo: current))
        }
    }
    
    private var totalRetransmit = 0
    func checkRetransmitRequest() -> Bool {
        typealias p = ControlDefinition
        if current.count < p.dataLength {
            return false
        }
        if current[p.type].uint16 == ControlPacketType.retransmit {
            let packets = parseRequest(data: current)
            packets.forEach { sequence in
                send(data: getTracked(sequence: sequence))
            }
            totalRetransmit &+= packets.count
            basePublished.send(.retransmitCount(totalRetransmit))
            return true
        }
        return false
    }
    
    private func onResendTimer(timer: Timer) {
        send(data: retryPacket)
        armIdleTimer()
        armResendTimer()
    }
    
    func onIdleTimer(timer: Timer) {
        if disconnecting {
            invalidateTimers()
            disconnecting = false
            basePublished.send(.state("Disconnected"))
            basePublished.send(.connected(false))
            connection?.cancel()
        } else {
            armIdleTimer()
            send(data: packetCreate.idlePacket())
        }
    }

    func parseRequest(data: Data) -> [UInt16] {
        var result = [UInt16]()
        typealias p = ControlDefinition
        if data.count == p.dataLength {
            result.append(data[p.sequence].uint16)
        } else {
            for i in stride(from: 16, to: data.count, by: 4) {
                result.append(data[i..<i+2].uint16)
            }
        }
        // print (result)
        return result
    }
    
    private static let queueSize = 20
    private var retransmitSequences = Queue<UInt16>()
    private var retransmitData = [UInt16: Data]()
    
    func track(data: Data) {
        typealias c = ControlDefinition
        let sequence = data[c.sequence].uint16
        if retransmitSequences.size == UDPBase.queueSize {
            if let oldSequence = retransmitSequences.dequeue() {
                _ = retransmitData.removeValue(forKey: oldSequence)
            }
        }
        retransmitSequences.enqueue(sequence)
        retransmitData[sequence] = data
    }
    
    func getTracked(sequence: UInt16) -> Data {
        retransmitData[sequence] ?? packetCreate.idlePacket(withSequence: sequence)
    }
    

}

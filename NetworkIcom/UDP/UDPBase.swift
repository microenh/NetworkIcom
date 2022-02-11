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
    
    var latency = CurrentValueSubject<Double, Never>(0.0)
    var state = CurrentValueSubject<String, Never>("")
    var retransmitCount = CurrentValueSubject<Int, Never>(0)
    var connected = PassthroughSubject<Bool, Never>()
    
    var connection: NWConnection?
    
    var idleTimer: Timer?
    var pingTimer: Timer?
    var resendTimer: Timer?
    
    var retryPacket = Data()
    
    var disconnecting = false


    // init() {}
    
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
            connected.send(false)
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
                    self.state.value = error?.localizedDescription ?? "connection error"
                    self.connection?.cancel()
                    self.connected.send(false)
                    return
                }
                self.receive(data: content)
                self.startReceive()
            }
        }
    }
    
    func startConnection() {
        armResendTimer()
        retryPacket = createAreYouTherePacket()
        send(data: retryPacket)
    }
    
    func createAreYouTherePacket() -> Data {Data()}
    
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
        let packet = createPingPacket()
        lastPingRequestSequence = packet[c.sequence].uint16
        lastPingRequestSentTime = Date()
        armIdleTimer()
        armPingTimer()
        send(data: packet)
    }
    
    func createPingPacket() -> Data {Data()}
    func createPingPacket(replyTo: Data) -> Data {Data()}
    func createIdlePacket() -> Data {Data()}
    func createIdlePacket(withSequence: UInt16) -> Data {Data()}

    func receivePing() {
        typealias c = ControlDefinition
        typealias p = PingDefinition
        if current[p.request].bool {
            // response to host ping
            if current[c.sequence].uint16 == lastPingRequestSequence {
                let lat = lastPingRequestSentTime.timeIntervalSinceNow * -500.0
                // notify(.latency(lat))
                latency.value = lat
            }
        } else {
            // Ping request from radio
            send(data: createPingPacket(replyTo: current))
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
            retransmitCount.value = totalRetransmit
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
            state.value = "Disconnected"
            connected.send(false)
            connection?.cancel()
        } else {
            armIdleTimer()
            send(data: createIdlePacket())
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
        retransmitData[sequence] ?? createIdlePacket(withSequence: sequence)
    }
    

}

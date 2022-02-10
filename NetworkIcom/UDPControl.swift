//
//  UDPClient.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/8/22.
//

import Foundation
import Network

class UDPControl {
    private class Settings {
        static let tokenRenewalInterval = 60.0
        static let pingInterval = 3.0
        static let idleInterval = 1.0
        static let retryInterval = 5.0
    }
    
    enum Notifications {
        case latency(Double)
        case state(String)
        case retransmitCount(Int)
        case disconnected
        case connected
    }

    
    private var connection: NWConnection?
    
    private var idleTimer: Timer?
    private var pingTimer: Timer?
    private var resendTimer: Timer?
    private var tokenRenewTimer: Timer?
    
    private var packetCreate: PacketCreateControl
    
    private var retryPacket = Data()
    
    private var disconnecting = false
    private var haveToken = false
    
    private var notify: (Notifications) -> ()
    
    init(host: String,
         port: UInt16,
         user: String,
         password: String,
         computer: String,
         notify: @escaping (Notifications) -> ()) {
        
        self.notify = notify
    
        let portObject = NWEndpoint.Port(integerLiteral: port)
        let hostObject = NWEndpoint.Host(host)

        let params = NWParameters.udp
        params.allowFastOpen = true
        params.allowLocalEndpointReuse = true
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.any), port: portObject)
        
        packetCreate = PacketCreateControl(user: user, password: password, computer: computer)

        connection = NWConnection(host: hostObject, port: portObject, using: params)
        connection?.stateUpdateHandler = { [weak self] newState in self?.stateUpdateHandler(newState: newState) }
        connection?.start(queue: DispatchQueue.global())
        
        updateState("Connecting...")
    }
    
    private func invalidateTimers() {
        pingTimer?.invalidate()
        idleTimer?.invalidate()
        resendTimer?.invalidate()
        tokenRenewTimer?.invalidate()
    }
    
    private var retryShutdown = false
    
    func disconnect() {
        updateState("Disconnecting...")
        if self.haveToken {
            send(data: packetCreate.tokenPacket(tokenType: TokenType.remove))
            self.armResendTimer()
            retryShutdown = true
        } else {
            self.invalidateTimers()
            self.disconnecting = true
            self.send(data: self.packetCreate.disconnectPacket())
            self.armIdleTimer()
        }
    }
    
    // force "Hard" disconnect, when normal disconnect fails.
//    func disconnectPacket() {
//        invalidateTimers()
//        send(data: packetCreate.disconnectPacket())
//    }
    
    private func updateState(_ state: String) {
        notify(.state(state))
    }
    
    private func stateUpdateHandler(newState: NWConnection.State) {
        switch newState {
        case .ready:
            startReceive()
            startConnection()
        case .failed(_), .cancelled:
            connection = nil
            break
        default:
            break
        }
    }
    
    private func startReceive() {
        connection?.receiveMessage { [weak self] content, context, isComplete, error in
            if let self = self {
                guard error == nil, let content = content else {
                    // self.updateState(error?.localizedDescription ?? "connection error")
                    // self.connection?.cancel()
                    return
                }
                self.receive(data: content)
                self.startReceive()
            }
        }
    }

    private let sendLock = NSLock()
    private func send(data: Data) {
        sendLock.lock()
        connection?.send(content: data, completion: .idempotent)
        sendLock.unlock()
    }
    
    
    private var current = Data()
    private func receive(data: Data) {
//        if disconnecting && !haveToken {
//            send(data: packetCreate.disconnectPacket())
//            armIdleTimer()
//            return
//        }
        current = data
        if checkRetransmitRequest() {
            return
        }
        switch current.count {
        case ControlDefinition.dataLength:
            typealias p = ControlDefinition
            switch current[p.type].uint16 {
            case ControlPacketType.iAmHere:
                packetCreate.remoteId = current[p.sendId].uint32
                armResendTimer()
                retryPacket = packetCreate.areYouReadyPacket()
                send(data: retryPacket)
            case ControlPacketType.iAmReady:
                armResendTimer()
                retryPacket = packetCreate.loginPacket()
                send(data: retryPacket)
                updateState("Logging in...")
            default:
                break
            }
        case WatchdogDefinition.dataLength:
            break
        case PingDefinition.dataLength:
            receivePing()
        case TokenDefinition.dataLength:
            receiveToken()
        case StatusDefinition.dataLength:
            typealias t = TokenDefinition
            if current[t.reqRep].uint8 == 0 {
                send(data: packetCreate.statusPacket(replyTo: current))
            }
            break
        case LoginResponseDefinition.dataLength:
            receiveLoginResponse()
        case ConnInfoDefinition.dataLength:
            typealias t = TokenDefinition
            if current[t.reqRep].uint8 == 0 {
                send(data: packetCreate.connInfoPacket(replyTo: current))
            }
        case CapabilitesDefinition.dataLength:
            haveToken = true
            armTokenRenewTimer()
            armPingTimer()
            armIdleTimer()
            updateState("Connected")
            resendTimer?.invalidate()
        default:
            break
        }
    }
    
    private var totalRetransmit = 0
    private func checkRetransmitRequest() -> Bool {
        typealias p = ControlDefinition
        if current.count < p.dataLength {
            return false
        }
        if current[p.type].uint16 == ControlPacketType.retransmit {
            let packets = packetCreate.parseRequest(data: current)
            packets.forEach { sequence in
                send(data: packetCreate.getTracked(sequence: sequence))
            }
            totalRetransmit &+= packets.count
            notify(.retransmitCount(totalRetransmit))
            return true
        }
        return false
    }
    
    private func receivePing() {
        typealias c = ControlDefinition
        typealias p = PingDefinition
        if current[p.request].bool {
            // response to host ping
            if current[c.sequence].uint16 == lastPingRequestSequence {
                let lat = lastPingRequestSentTime.timeIntervalSinceNow * -500.0
                notify(.latency(lat))
            }
        } else {
            // Ping request from radio
            send(data: packetCreate.pingPacket(replyTo: current))
        }
    }

    private func receiveToken() {
        typealias t = TokenDefinition
        resendTimer?.invalidate()
        switch current[t.res].uint16 {
        case TokenType.remove:
            invalidateTimers()
            haveToken = false
            disconnecting = true
            armIdleTimer()
            send(data: packetCreate.disconnectPacket())
        default:
            break
        }
    }
    
    private func receiveLoginResponse() {
        typealias c = ControlDefinition
        typealias t = TokenDefinition
        typealias l = LoginResponseDefinition
        packetCreate.token = current[t.token].uint32
        retryPacket = packetCreate.tokenPacket(tokenType: TokenType.acknowledge)
        packetCreate.track(data: retryPacket)
        send(data: retryPacket)
        armResendTimer()
        updateState("Getting Token")
    }

    private func startConnection() {
        armResendTimer()
        retryPacket = packetCreate.areYouTherePacket()
        send(data: retryPacket)
    }
    
    private func armResendTimer() {
        resendTimer?.invalidate()
        let timer = Timer(timeInterval: Settings.retryInterval, repeats: false, block: onResendTimer(timer:))
        RunLoop.main.add(timer, forMode: .common)
        resendTimer = timer
    }
    
    private func armIdleTimer() {
        idleTimer?.invalidate()
        let timer = Timer(timeInterval: Settings.idleInterval, repeats: false, block: onIdleTimer(timer:))
        RunLoop.main.add(timer, forMode: .common)
        idleTimer = timer
    }
    
    private func armPingTimer() {
        pingTimer?.invalidate()
        let timer = Timer(timeInterval: Settings.pingInterval, repeats: false, block: onPingTimer(timer:))
        RunLoop.main.add(timer, forMode: .common)
        pingTimer = timer
    }
    
    private func armTokenRenewTimer() {
        tokenRenewTimer?.invalidate()
        let timer = Timer(timeInterval: Settings.tokenRenewalInterval, repeats: false, block: onTokenRenewTimer(timer:))
        RunLoop.main.add(timer, forMode: .common)
        tokenRenewTimer = timer
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

    private func onResendTimer(timer: Timer) {
        send(data: retryShutdown ? packetCreate.tokenPacket(tokenType: TokenType.remove) : retryPacket)
        armIdleTimer()
        armResendTimer()
    }
    
    private func onIdleTimer(timer: Timer) {
        if disconnecting {
            invalidateTimers()
            disconnecting = false
            updateState("Disconnected")
            notify(.disconnected)
            connection?.cancel()
        } else {
            armIdleTimer()
            send(data: packetCreate.idlePacket())
        }
    }

    private func onTokenRenewTimer(timer: Timer) {
        retryPacket = packetCreate.tokenPacket(tokenType: TokenType.renew)
        packetCreate.track(data: retryPacket)
        armIdleTimer()
        send(data: retryPacket)
        armResendTimer()
        armTokenRenewTimer()
    }
}

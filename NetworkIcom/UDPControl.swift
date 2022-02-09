//
//  UDPClient.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/8/22.
//

import Foundation
import Network

fileprivate class Settings {
    static let tokenRenewalInterval = 60.0
    static let pingInterval = 3.0
    static let idleInterval = 1.0
    static let retryInterval = 0.5
    static let retryCount = 4  // resend packet if appropriate response not received
}

class UDPControl: ObservableObject {
    @Published var latency = 0.0
    @Published var state = ""
    @Published var retransmitCount = 0
    
    private var connection: NWConnection?
    
    private var idleTimer: Timer?
    private var pingTimer: Timer?
    private var resendTimer: Timer?
    private var tokenRenewTimer: Timer?
    
    private var packetCreate: PacketCreateControl
    
    private var retryPacket = Data()
    
    private var disconnected = false
    private var haveToken = false
    
    init(host: String, port: UInt16, user: String, password: String, computer: String) {
    
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
    
    func disconnect() {
        updateState("Disconnecting...")
        idleTimer?.invalidate()
        pingTimer?.invalidate()
        tokenRenewTimer?.invalidate()
        if haveToken {
            retryPacket = packetCreate.tokenPacket(tokenType: TokenType.remove)
            armResendTimer()
            send(data: retryPacket)
        } else {
            disconnected = true
            send(data: packetCreate.disconnectPacket())
            armIdleTimer()
        }
    }
    
    private func updateState(_ state: String) {
        DispatchQueue.main.async { [weak self] in
            self?.state = state
        }
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

    private func send(data: Data) {
        connection?.send(content: data, completion: .idempotent)
    }
    
    private var current = Data()
    private func receive(data: Data) {
        if disconnected {
            send(data: packetCreate.disconnectPacket())
            armIdleTimer()
        }
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
        case PingDefinition.dataLength:
            receivePing()
        case TokenDefinition.dataLength:
            receiveToken()
        case StatusDefinition.dataLength:
            break
        case LoginResponseDefinition.dataLength:
            receiveLoginResponse()
        case ConnInfoDefinition.dataLength:
            break
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
    
    private func checkRetransmitRequest() -> Bool {
        typealias p = ControlDefinition
        if current.count < p.dataLength || current[p.type].uint16 != ControlPacketType.retransmit {
            return false
        }
        let packets = packetCreate.parseRequest(data: current)
        packets.forEach { sequence in
            send(data: packetCreate.getTracked(sequence: sequence))
        }
        DispatchQueue.main.async { [weak self] in
            self?.retransmitCount += packets.count
        }
        
        return true
    }
    
    private func receivePing() {
        typealias c = ControlDefinition
        typealias p = PingDefinition
        if current[p.request].bool {
            // response to host ping
            if current[c.sequence].uint16 == lastPingRequestSequence {
                let lat = lastPingRequestSentTime.timeIntervalSinceNow * -500.0
                DispatchQueue.main.async { [weak self] in
                    self?.latency = lat
                }
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
            haveToken = false
            disconnected = true
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
        let packet = packetCreate.pingPacket()
        lastPingRequestSequence = packet[c.sequence].uint16
        lastPingRequestSentTime = Date()
        armIdleTimer()
        armPingTimer()
        send(data: packet)
    }

    private func onResendTimer(timer: Timer) {
        armIdleTimer()
        armResendTimer()
        send(data: retryPacket)
    }
    
    private func onIdleTimer(timer: Timer) {
        if disconnected {
            connection?.cancel()
            updateState("Disconnected")
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
    }
}

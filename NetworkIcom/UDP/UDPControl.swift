//
//  UDPClient.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/8/22.
//

import Foundation
import Network
import Combine

class UDPControl: UDPBase {
    private class ControlSettings {
        static let tokenRenewalInterval = 60.0
    }
    
    private(set) var radioCivAddr = CurrentValueSubject<UInt8, Never>(0)
    
    private var tokenRenewTimer: Timer?
    
    private var packetCreate: PacketCreateControl
    
    private var haveToken = false
    
    init(host: String,
         port: UInt16,
         user: String,
         password: String,
         computer: String) {
        
        packetCreate = PacketCreateControl(user: user, password: password, computer: computer)
        super.init(host: host, port: port)
    }
    
    override func invalidateTimers() {
        tokenRenewTimer?.invalidate()
        super.invalidateTimers()
    }
    
    private var retryShutdown = false
    
    func disconnect() {
        state.value = "Disconnecting..."
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
    
//    // force "Hard" disconnect, when normal disconnect fails.
//    func disconnectPacket() {
//        invalidateTimers()
//        send(data: packetCreate.disconnectPacket())
//    }
        
    
    override func receive(data: Data) {
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
                state.value = "Logging in..."
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
            typealias c = CapabilitesDefinition
            haveToken = true
            armTokenRenewTimer()
            armPingTimer()
            armIdleTimer()
            radioCivAddr.value = current[c.civAddr].uint8
            state.value = "Connected"
            connected.send(true)
            resendTimer?.invalidate()
        default:
            break
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
        track(data: retryPacket)
        send(data: retryPacket)
        armResendTimer()
        state.value = "Getting Token"
    }

    private func armTokenRenewTimer() {
        tokenRenewTimer?.invalidate()
        let timer = Timer(timeInterval: ControlSettings.tokenRenewalInterval, repeats: false, block: onTokenRenewTimer(timer:))
        RunLoop.main.add(timer, forMode: .common)
        tokenRenewTimer = timer
    }

    private func onTokenRenewTimer(timer: Timer) {
        retryPacket = packetCreate.tokenPacket(tokenType: TokenType.renew)
        track(data: retryPacket)
        armIdleTimer()
        send(data: retryPacket)
        armResendTimer()
        armTokenRenewTimer()
    }
    
    // -----
    
    override func createAreYouTherePacket() -> Data {
        packetCreate.areYouTherePacket()
    }
    
    override func createPingPacket() -> Data {
        packetCreate.pingPacket()
    }
    
    override func createPingPacket(replyTo: Data) -> Data {
        packetCreate.pingPacket(replyTo: replyTo)
    }
    
    override func createIdlePacket() -> Data {
        packetCreate.idlePacket()
    }

    override func createIdlePacket(withSequence: UInt16) -> Data {
        packetCreate.idlePacket(withSequence: withSequence)
    }

}

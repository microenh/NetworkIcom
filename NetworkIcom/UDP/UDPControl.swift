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
    
    enum Published {
        case radioCivAddr(UInt8)
    }
    
    var published = PassthroughSubject<Published, Never>()
    
    private var tokenRenewTimer: Timer?
    
    private var haveToken = false
    
    private var radioName = ""
    
    private let connectionInfo: ConnectionInfo
    private var civPort: UInt16
    private var audioPort: UInt16
    private var user: String
    
    init(mConnectionInfo: ConnectionInfo,
         mRxAudio: RxAudio, mTxAudio: TxAudio) {
        connectionInfo = mConnectionInfo
        civPort = connectionInfo.serialPort
        audioPort = connectionInfo.audioPort
        self.user = connectionInfo.user
        
        super.init(mConnectionInfo: connectionInfo,
                   mPort: mConnectionInfo.controlPort,
                   mRxAudio: mRxAudio, mTxAudio: mTxAudio)
    }
    
    override func invalidateTimers() {
        tokenRenewTimer?.invalidate()
        super.invalidateTimers()
    }
    
//    private var retryShutdown = false
    
    func disconnect() {
        basePublished.send(.state("Disconnecting..."))
        send(data: packetCreate.connInfoPacket(radioName: radioName, userName: user,
                                               civPort: civPort, audioPort: audioPort))
        send(data: packetCreate.disconnectPacket())
        invalidateTimers()
        disconnecting = true
        if haveToken {
            send(data: packetCreate.tokenPacket(tokenType: TokenType.remove))
            // self.armResendTimer()
            // retryShutdown = true
//        } else {
        }
        armIdleTimer()
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
                basePublished.send(.state("Logging in..."))
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
            } else {
                resendTimer?.invalidate()
            }
        case CapabilitesDefinition.dataLength:
            typealias c = CapabilitesDefinition
            haveToken = true
            armTokenRenewTimer()
            armPingTimer()
            armIdleTimer()
            radioName = current[c.radio].string
            published.send(.radioCivAddr(current[c.civAddr].uint8))
            basePublished.send(.state("Connected"))
            basePublished.send(.connected(true))
            resendTimer?.invalidate()
            let packet = packetCreate.connInfoPacket(radioName: radioName, userName: user,
                                                     civPort: civPort, audioPort: audioPort,
                                                     enableRx: true, enableTx: false)
            send(data: packet)
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
        send(data: retryPacket)
        armResendTimer()
        basePublished.send(.state("ACK Token"))
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
    
}

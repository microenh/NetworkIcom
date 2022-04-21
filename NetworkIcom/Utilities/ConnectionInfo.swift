//
//  ConnectionInfo.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 4/20/22.
//

import Foundation

/*
 host: "192.168.12.196",
                     controlPort: 50001, serialPort: 50002, audioPort: 50003,
                     user: "n8me", password: "msrkmsrk", computer: "MAC-MINI",
                     hostCivAddr: 0xe0,
 */

class ConnectionInfo {
    let radioAddr: String
    let controlPort: UInt16
    let serialPort: UInt16
    let audioPort: UInt16
    let user: String
    let password: String
    let computer: String
    let radioCIV: UInt8
    let hostCIV: UInt8
    
    init (mRadioAddr: String = Defaults.radioAddr,
          mControlPort: UInt16 = Defaults.controlPort,
          mSerialPort: UInt16 = Defaults.serialPort,
          mAudioPort: UInt16 = Defaults.audioPort,
          mUser: String = Defaults.user,
          mPassword: String = Defaults.password,
          mComputer: String = Defaults.computer,
          mRadioCIV: UInt8 = Defaults.raiodCIV,
          mHostCIV: UInt8 = Defaults.hostCIV) {
        radioAddr = mRadioAddr
        controlPort = mControlPort
        serialPort = mSerialPort
        audioPort = mAudioPort
        user = mUser
        password = mPassword
        computer = mComputer
        radioCIV = mRadioCIV
        hostCIV = mHostCIV
    }
}

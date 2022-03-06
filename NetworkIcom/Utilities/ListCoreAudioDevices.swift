//
//  ListCoreAudioDevices.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 3/5/22.
//

// from: https://gist.github.com/glaurent/b4e9a2a1bc5223977df428e03d465560
// cleaned up with deprecations fixes

import Foundation
import CoreAudio

func listCoreAudioDevices() {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var propertySize = UInt32(0)
    
    if AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize) == noErr {
        let numDevices = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: numDevices)
        
        if AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &deviceIDs) == noErr {
            var deviceAddress = AudioObjectPropertyAddress()
            var deviceNameCString = [CChar](repeating:0, count: 64)
            var manufacturerNameCString = [CChar](repeating:0, count: 64)
            
            for idx in (0..<numDevices) {
                print("\(deviceIDs[idx])\n")
                propertySize = UInt32(MemoryLayout<CChar>.size * 64)
                deviceAddress.mSelector = kAudioDevicePropertyDeviceName
                deviceAddress.mScope = kAudioObjectPropertyScopeGlobal
                deviceAddress.mElement = kAudioObjectPropertyElementMain
                
                if AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, nil, &propertySize, &deviceNameCString) == noErr {
                    let deviceName = String(cString:deviceNameCString)
                    
                    propertySize = UInt32(MemoryLayout<CChar>.size * 64)
                    deviceAddress.mSelector = kAudioDevicePropertyDeviceManufacturer
                    deviceAddress.mScope = kAudioObjectPropertyScopeGlobal
                    deviceAddress.mElement = kAudioObjectPropertyElementMain
                    
                    if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, nil, &propertySize, &manufacturerNameCString) == noErr) {
                        let manufacturerName = String(cString:manufacturerNameCString)
                        
                        var uidString = "" as CFString
                        propertySize = UInt32(MemoryLayout.size(ofValue: uidString))
                        
                        deviceAddress.mSelector = kAudioDevicePropertyDeviceUID
                        deviceAddress.mScope = kAudioObjectPropertyScopeGlobal
                        deviceAddress.mElement = kAudioObjectPropertyElementMain
                        
                        if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, nil, &propertySize, &uidString) == noErr) {
                            print("device \(deviceName)\nby \(manufacturerName)\nid \(uidString)\n\n")
                        }
                    }
                }
            }
        }
    }
}


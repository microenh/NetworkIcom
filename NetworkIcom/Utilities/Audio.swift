//
//  Audio.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 3/5/22.
//

// This appears to manipulate the system default devices, not set an individual device.

/*
 static func getOutputDevices() -> [AudioDeviceID: String]
 static func getInputDevices() -> [AudioDeviceID: String]
 static func isOutputDevice(deviceID: AudioDeviceID) -> Bool
 static func getAggregateDeviceSubDeviceList(deviceID: AudioDeviceID) -> [AudioDeviceID]
 static func isAggregateDevice(deviceID: AudioDeviceID) -> Bool
 static func setDeviceVolume(deviceID: AudioDeviceID, leftChannelLevel: Float, rightChannelLevel: Float)
 static func setOutputDevice(newDeviceID: AudioDeviceID)
 static func getDeviceVolume(deviceID: AudioDeviceID) -> [Float]
 static func getDefaultOutputDevice() -> AudioDeviceID
 */

import Foundation
import CoreAudio

public class Audio {
    
    static func getOutputDevices() -> [AudioDeviceID: String] {
        let devices = getAllDevices().filter{isOutputDevice(deviceID: $0)}
        return Dictionary(uniqueKeysWithValues: zip(devices, devices.map{getDeviceName(deviceID: $0)}))
    }
    
    static func getInputDevices() -> [AudioDeviceID: String] {
        let devices = getAllDevices().filter{!isOutputDevice(deviceID: $0)}
        return Dictionary(uniqueKeysWithValues: zip(devices, devices.map{getDeviceName(deviceID: $0)}))
    }
    
    static func isOutputDevice(deviceID: AudioDeviceID) -> Bool {
        var propertySize: UInt32 = 256
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyStreams),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        _ = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize)
        
        return propertySize > 0
    }
    
    static func getAggregateDeviceSubDeviceList(deviceID: AudioDeviceID) -> [AudioDeviceID] {
        let subDevicesCount = getNumberOfSubDevices(deviceID: deviceID)
        var subDevices = [AudioDeviceID](repeating: 0, count: Int(subDevicesCount))
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioAggregateDevicePropertyActiveSubDeviceList),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        var subDevicesSize = subDevicesCount * UInt32(MemoryLayout<UInt32>.size)
        
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &subDevicesSize, &subDevices)
        
        return subDevices
    }
    
    static func isAggregateDevice(deviceID: AudioDeviceID) -> Bool {
        let deviceType = getDeviceTransportType(deviceID: deviceID)
        return deviceType == kAudioDeviceTransportTypeAggregate
    }
    
    static func setDeviceVolume(deviceID: AudioDeviceID, leftChannelLevel: Float, rightChannelLevel: Float) {
        let channelsCount = 2
        var channels = [UInt32](repeating: 0, count: channelsCount)
        var propertySize = UInt32(MemoryLayout<UInt32>.size * channelsCount)
        var leftLevel = leftChannelLevel
        var rightLevel = rightChannelLevel
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyPreferredChannelsForStereo),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &channels)
        
        if status != noErr { return }
        
        propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
        propertySize = UInt32(MemoryLayout<Float32>.size)
        propertyAddress.mElement = channels[0]
        
        AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, propertySize, &leftLevel)
        
        propertyAddress.mElement = channels[1]
        
        AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, propertySize, &rightLevel)
    }
    
    static func setDefaultOutputDevice(newDeviceID: AudioDeviceID) {
        let propertySize = UInt32(MemoryLayout<UInt32>.size)
        var deviceID = newDeviceID
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, propertySize, &deviceID)
    }
    
    static func getDeviceVolume(deviceID: AudioDeviceID) -> [Float] {
        let channelsCount = 2
        var channels = [UInt32](repeating: 0, count: channelsCount)
        var propertySize = UInt32(MemoryLayout<UInt32>.size * channelsCount)
        var leftLevel = Float32(-1)
        var rightLevel = Float32(-1)
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyPreferredChannelsForStereo),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))

        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &channels)
        
        if status != noErr { return [-1] }
        
        propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
        propertySize = UInt32(MemoryLayout<Float32>.size)
        propertyAddress.mElement = channels[0]
        
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &leftLevel)
        
        propertyAddress.mElement = channels[1]
        
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &rightLevel)
        
        return [leftLevel, rightLevel]
    }
    
    static func getDefaultOutputDevice() -> AudioDeviceID {
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var deviceID = kAudioDeviceUnknown
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &deviceID)
        
        return deviceID
    }
    
    private static func getDeviceTransportType(deviceID: AudioDeviceID) -> AudioDevicePropertyID {
        var deviceTransportType = AudioDevicePropertyID()
        var propertySize = UInt32(MemoryLayout<AudioDevicePropertyID>.size)
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyTransportType),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &deviceTransportType)
        
        return deviceTransportType
    }
    
    private static func getNumberOfDevices() -> UInt32 {
        var propertySize: UInt32 = 0
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        _ = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize)
        
        return propertySize / UInt32(MemoryLayout<AudioDeviceID>.size)
    }
    
    private static func getNumberOfSubDevices(deviceID: AudioDeviceID) -> UInt32 {
        var propertySize: UInt32 = 0
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioAggregateDevicePropertyActiveSubDeviceList),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        _ = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize)
        
        return propertySize / UInt32(MemoryLayout<AudioDeviceID>.size)
    }
    
    private static func getDeviceName(deviceID: AudioDeviceID) -> String {
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyDeviceNameCFString),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        var result: CFString = "" as CFString
        
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &result)
        
        return result as String
    }
    
    private static func getAllDevices() -> [AudioDeviceID] {
        let devicesCount = getNumberOfDevices()
        var devices = [AudioDeviceID](repeating: 0, count: Int(devicesCount))
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        var devicesSize = devicesCount * UInt32(MemoryLayout<UInt32>.size)
        
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &devicesSize, &devices)
        
        return devices
    }
    
}



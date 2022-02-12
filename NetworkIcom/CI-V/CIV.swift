//
//  CIVDecode.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/10/22.
//

import Foundation
import Combine

class CIV {
    
    enum Published {
        case frequency(Int)
        case modeFilter(ModeFilter)
        case attenuation(Attenuation)
    }
    
    var published = PassthroughSubject<Published, Never>()
    
    private let radioCivAddr: UInt8
    private let hostCivAddr: UInt8
    
    init(radioCivAddr: UInt8, hostCivAddr: UInt8) {
        self.radioCivAddr = radioCivAddr
        self.hostCivAddr = hostCivAddr
    }
    
    /* sample packet: 1e000000    packet length 0x1e (30)    0
                      0000        type 0                     4
                      900f        sequence 0xf90             6
                      c5ad823e    send (my ID)               8
                      0c7fc352    recv (remote ID)           12
                      c1          civ message id 0xc1        16
                      0900        civ message length 0x09    17
                      000d        sequence                   19
                      (fefee09815020000fd)
                        fefe        civ header               21
                        e0          destination (0xe0)       23
                        98          source (0x98)            24
                        1502        command / sub (S-Meter)  25
                        0000        data (0000 - 0255)       27
                        fd          end                      29
    */

    func decode(_ d: Data) {
        typealias c = CIVDefinition
        switch d[c.civCmd].uint8 {
        case 0x00, 0x03:
            published.send(.frequency(Int(frequencyBuffer: d.dropFirst(c.dataStart))))
        case 0x01, 0x04:
            published.send(.modeFilter(ModeFilter(buffer: d.dropFirst(c.dataStart))))
        case 0x11:
            published.send(.attenuation(Attenuation(buffer: d.dropFirst(c.dataStart))))
        case 0xfa:  // NAK
            print ("NAK")
            break
        case 0xfb:  // ACK
            print ("ACK")
            break
            
        default:
            d.dump()
        }        
    }
    
    func buildRequest(command: UInt8,
                      subCommand: UInt8? = nil,
                      selector: UInt8? = nil,
                      data: [UInt8]? = nil) -> Data {
        var result = [0xfe, 0xfe, radioCivAddr, hostCivAddr, command]
        if let subCommand = subCommand {
            result.append(subCommand)
        }
        if let selector = selector {
            result.append(selector)
        }
        if let data = data {
            result.append(contentsOf: data)
        }
        result.append(0xfd)
        return Data(result)
    }
    
    /*
     Check to see if packet is a reponse from a request, or an
     unsolicited broadcast.
     
     if the hostID == 0x00, then general broadcast
     if the command is 0x27 and the subCommand is 0x00
     this is a scope data packet, unsolicited
     */
    func isUnsolicited(data: Data) -> Bool {
        if data.count > 2, data[2] == 0x00 {
            return true
        }
        if data.count > 5, data[4] == 0x27, data[5] == 0x00 {
            return true
        }
        return false
    }

}

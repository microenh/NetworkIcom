//
//  BuildRequest.swift
//  Icom7610USB
//
//  Created by Mark Erbaugh on 12/23/21.
//

import Foundation

struct CIVRequest {
    
    private let radioID: UInt8
    private let hostID: UInt8
    
    init(radioID: UInt8, hostID: UInt8) {
        self.radioID = radioID
        self.hostID = hostID
    }

    func buildRequest(command: UInt8,
                      subCommand: UInt8? = nil,
                      selector: UInt8? = nil,
                      data: [UInt8]? = nil) -> Data {
        var result = [0xfe, 0xfe, radioID, hostID, command]
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

//
//  MainView.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/8/22.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var icomVM = IcomVM(host: "192.168.12.196",
                                        controlPort: 50001,
                                        serialPort: 50002,
                                        user: "n8me",
                                        password: "msrkmsrk",
                                        computer: "MAC-MINI",
                                        hostCivAddr: 0xe0)
    
    var body: some View {
        VStack {
            VStack {
                Text("Control")
                    .font(.title)
                Text("State: \(icomVM.controlState)")
                Text("Latency: \(icomVM.controlLatency)")
                Text("Retransmit Count: \(icomVM.controlRetransmitCount)")
                Text("CI-V Addr: \(String(format: "0x%02x", icomVM.radioCivAddr))")
            }
            Divider()
            VStack {
                Text("Serial")
                    .font(.title)
                Text("State: \(icomVM.serialState)")
                Text("Latency: \(icomVM.serialLatency)")
                Text("Retransmit Count: \(icomVM.serialRetransmitCount)")
                Text("Frequency: \(icomVM.frequency)")
                    .onTapGesture {
                        icomVM.frequency = 0
                    }
                Text(icomVM.modeFilter.description)
                Text(icomVM.attenuation.description)
                Button("CIV-Command") {
                    icomVM.serial?.send(command: 0x03)
                }
                Text(icomVM.printDump)
                    .font(.system(size: 10, design: .monospaced))
                    .fixedSize()
            }
            Divider()
            VStack {
                Button(icomVM.connected ? "Disconnect" :"Connect") {
                    if icomVM.connected {
                        icomVM.disconnectControl()
                    } else {
                        icomVM.connectControl()
                    }
                }
            }
        }
        .frame(minWidth: 200)
        .padding()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

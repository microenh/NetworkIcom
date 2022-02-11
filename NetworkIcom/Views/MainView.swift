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
        
                Button("Connect") {
                    icomVM.connectControl()
                }
                Button("Disconnect") {
                    icomVM.disconnectControl()
                }
            }
            Divider()
            VStack {
                Text("Serial")
                    .font(.title)
                Text("State: \(icomVM.serialState)")
                Text("Latency: \(icomVM.serialLatency)")
                Text("Retransmit Count: \(icomVM.serialRetransmitCount)")
                Text("CI-V Data Len: \(icomVM.civData.count)")
                Text("Frequency: \(icomVM.frequency)")
                Button("Connect") {
                    icomVM.connectSerial()
                }
                Button("Disconnect") {
                    icomVM.disconnectSerial()
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

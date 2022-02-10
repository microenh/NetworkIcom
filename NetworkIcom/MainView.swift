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
                                    user: "n8me",
                                    password: "msrkmsrk",
                                    computer: "MAC-MINI")
    
    var body: some View {
        VStack {
            Text("State: \(icomVM.controlState)")
            Text("Latency: \(icomVM.controlLatency)")
            Text("Retransmit Count: \(icomVM.controlRetransmitCount)")
            Button("Connect") {
                icomVM.connect()
            }
            Button("Disconnect") {
                icomVM.disconnect()
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

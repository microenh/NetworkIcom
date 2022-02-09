//
//  MainView.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/8/22.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var control = UDPControl(host: "192.168.12.196",
                                    port: 50001,
                                    user: "n8me",
                                    password: "msrkmsrk",
                                    computer: "MAC-MINI")
    
    var body: some View {
        VStack {
            Text("State: \(control.state)")
            Text("Latency: \(control.latency)")
            Text("Retransmit Count: \(control.retransmitCount)")
            Button("Disconnect") {
                control.disconnect()
            }
        }
        .padding()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

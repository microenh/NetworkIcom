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
                                        audioPort: 50003,
                                        user: "n8me",
                                        password: "msrkmsrk",
                                        computer: "MAC-MINI",
                                        hostCivAddr: 0xe0)
    
    @State var state = false
    
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
                VStack {
                    Text("Serial")
                        .font(.title)
                    Text("State: \(icomVM.serialState)")
                    Text("Latency: \(icomVM.serialLatency)")
                    Text("Retransmit Count: \(icomVM.serialRetransmitCount)")
                    Text("Frequency: \(icomVM.civDecode.frequency)")
                        .onTapGesture {
                            icomVM.civDecode.frequency = 0
                        }
                    Text(icomVM.civDecode.modeFilter.description)
                    Text(icomVM.civDecode.attenuation.description)
                    Text("Queue size: \(icomVM.queueSize)")
                }
                VStack {
                    Button("CI-V") {
                        state.toggle()
                        icomVM.readOperatingFrequency()
                        // icomVM.setOperatingFrequency(frequency: 3_815_000)
                        // icomVM.readOperatingMode()
                        // icomVM.readAttenuation()
                        // icomVM.readSsbRxHpfLpf()
                        // icomVM.setOperatingMode(mode: .am, filter: .fil2)
                        // icomVM.exchangeMainSub()
                        // icomVM.equalizeMainSub()
                        // icomVM.dualWatch(on: state)
                        // icomVM.dualWatch()
                        // icomVM.subBand(on: state)
                        // icomVM.subBand()
                        // icomVM.selectMemory(channel: 100)
                        // icomVM.memoryToVFO()
                        // icomVM.memoryClear()
                    }
                    Text(icomVM.civDecode.printDump)
                        .font(.system(size: 10, design: .monospaced))
                        .fixedSize()
                }
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

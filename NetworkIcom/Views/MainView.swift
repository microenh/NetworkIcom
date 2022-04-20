//
//  MainView.swift
//  NetworkIcom
//
//  Created by Mark Erbaugh on 2/8/22.
//

import SwiftUI

struct MainView: View {
        
    @ObservedObject var civDecode: CIVDecode
    @ObservedObject var icomVM: IcomVM
    
    init() {
        let civDecode = CIVDecode(hostCivAddr: 0xe0)
        
        let icomVM = IcomVM(host: "192.168.12.196",
                            controlPort: 50001, serialPort: 50002, audioPort: 50003,
                            user: "n8me", password: "msrkmsrk", computer: "MAC-MINI",
                            hostCivAddr: 0xe0,
                            rxRate: 8000, rxChannels: 1, rxSize: 2, rxULaw: true, rxEnable: true,
                            txRate: 8000, txSize: 1, txULaw: false, txEnable: false,
                            civDecode: civDecode.decode)
        
        self.civDecode = civDecode
        self.icomVM = icomVM
    }
    
    @State var state = false
    @State var state2 = false
    @State var counter = ""
    @State var counter2 = ""
    
    var body: some View {
        VStack {
            VStack {
//                Text("Control")
//                    .font(.title)
                // Text("Retransmit Count: \(icomVM.controlRetransmitCount)")
                // Text("CI-V Addr: \(String(format: "0x%02x", icomVM.radioCivAddr))")
            }
//            Divider()
            VStack {
                VStack {
//                    Text("Serial")
//                        .font(.title)
                    // Text("State: \(icomVM.serialState)")
                    // Text("Latency: \(icomVM.serialLatency)")
                    // Text("Retransmit Count: \(icomVM.serialRetransmitCount)")
                    Text("\(String(format: "%0.3f", Double(civDecode.frequency) / 1_000_000)) MHz")
                        .font(.largeTitle)
//                        .onTapGesture {
//                            civDecode.frequency = 0
//                        }
                    Text(civDecode.modeFilter.description)
                    Text(civDecode.attenuation.description)
                    Text("Underrun: \(icomVM.underrunCount)")
                    Text("Overrun: \(icomVM.overrunCount)")
                }
                VStack {
                    HStack {
                        Text("Waterfall")
                        Button("Clear") {
                            civDecode.waterfallClear(which: 0)
                        }
//                        Button("Clear Sub") {
//                            civDecode.waterfallClear(which: 1)
//                        }
                        Button(state ? "Stop" : "Start") {
//                             icomVM.serial?.send(command: 0x1a, subCommand: 0x00, data: Data([UInt8(0), 0x01]))
                            state.toggle()
                            if !state {
                                state2.toggle()
                            }
                            icomVM.readSetScopeWaveOn(on: state)
                            icomVM.readSetScopeWaveOn()
                        }
//                        TextField("Value 1", text: $counter)
//                            .fixedSize()
//                        TextField("Value 2", text: $counter2)
//                            .fixedSize()
                    }
//                    Text(civDecode.printDump)
//                        .font(.system(size: 10, design: .monospaced))
//                        .fixedSize()
                }
            }
            VStack {
//                Text("Pan Timing: \(civDecode.panadapterMain.2)")
                BandscopeView(data: (civDecode.panadapterMain.panadapter, civDecode.panadapterMain.history))
                    .frame(width: 694, height: 200)
                HStack {
                    Text("\(String(format: "%0.4f", Double(civDecode.panadapterMain.panLower) / 1_000_000)) MHz")
                        .font(.footnote)
                    Spacer()
                    Text("\(String(format: "%0.4f", Double(civDecode.panadapterMain.panUpper) / 1_000_000)) MHz")
                        .font(.footnote)
                }
                Image(decorative: civDecode.waterfallContexts[0].makeImage()!, scale: 1.0)
                    .frame(width: 691, height: 100)
                    .background(BGGrid().stroke(.gray, lineWidth: 1.0))
                
//                Text("Pan Timing: \(civDecode.panadapterSub.2)")
//                BandscopeView(data: (civDecode.panadapterSub.0, civDecode.panadapterSub.1))
//                    .frame(width: 694, height: 200)
//                Image(decorative: civDecode.waterfallContexts[1].makeImage()!, scale: 1.0)
//                    .frame(width: 689, height: 100)
            }
            VStack {
                Button(icomVM.connected ? "Disconnect" : "Connect") {
                    if icomVM.connected {
                        icomVM.disconnectControl()
                    } else {
                        icomVM.connectControl()
                    }
                }
//                Button("Audio Info") {
//                    print(Audio.getOutputDevices())
//                    print(Audio.getInputDevices())
//                }
                VStack {
                    HStack {
                        Text("Control State: \(icomVM.controlState)")
                        if icomVM.connected {
                            Text("Latency: \(String(format: "%0.2f", icomVM.controlLatency)) msec")
                        }
                    }
                    Text("Serial State: \(icomVM.serialState)")
                    Text("Audio State: \(icomVM.audioState)")
                }
                .font(.footnote)

            }
        }
        .frame(width: 700)
        .padding()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

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
                        controlPort: 50001,
                        serialPort: 50002,
                        audioPort: 50003,
                        user: "n8me",
                        password: "msrkmsrk",
                        computer: "MAC-MINI",
                        hostCivAddr: 0xe0,
                        civDecode: civDecode.decode)
        
        self.civDecode = civDecode
        self.icomVM = icomVM
    }
    
    @State var state = false
    @State var state2 = false

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
                    Text("Frequency: \(civDecode.frequency)")
                        .onTapGesture {
                            civDecode.frequency = 0
                        }
                    Text(civDecode.modeFilter.description)
                    Text(civDecode.attenuation.description)
                    Text("Queue size: \(icomVM.queueSize)")
                }
                VStack {
                    Button("CI-V") {
                        // icomVM.serial?.send(command: 0x1a, subCommand: 0x00, data: Data([UInt8(0), 0x01]))
                        state.toggle()
                        if !state {
                            state2.toggle()
                        }
                        // icomVM.readOperatingFrequency()
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
                        // icomVM.startPgmMemoryScan()
                        // icomVM.selectΔFrequencySpan(span: .kHz100)
                        // icomVM.readSetSplit(on: state)
                        // icomVM.readSetTuneStep(step: state ? .hz100 : .off)
                        // icomVM.readSetAttenuation(attn: state ? .att18 : .attOff)
                        // icomVM.readSetRxAnt(ant2: state, rxOn: state2)
                        // icomVM.speak(speech: .mode)
                        // icomVM.readSetLevel0x14(which: .afGain, value: state ? 0 : 255)
                        // icomVM.readSetLevel0x14(which: .afGain)
                        // icomVM.readMeter(which: .current)
                        // icomVM.readSetPreamp(which: state ? 2 : 0)
                        // icomVM.readSetPreamp()
                        icomVM.readSetAGC(which: state ? 3 : 1)
                        icomVM.readSetAGC()
                    }
                    Text(civDecode.printDump)
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

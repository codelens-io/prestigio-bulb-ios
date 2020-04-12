//
//  ContentView.swift
//  prestigio-bulb
//
//  Created by Majki on 2020. 04. 11..
//  Copyright © 2020. CodeLens. All rights reserved.
//

import SwiftUI
import BlueCapKit

struct ContentView: View, BulbControlDelegate {
    
    private let bulbControl = BulbControl()
    
    @State private var pushed:Bool = false
    @State private var stateLabel:String = "Unknown"
    @State private var log:Array<String> = Array()
    
    private var endText:Text = Text("end")
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Prestigio Light bulb")
            
            HStack(spacing: 10) {
                Text("State:")
                Text(stateLabel)
            }
            
            HStack(spacing: 10) {
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.maxWhite)
                }, label: {
                    Text("Turn ON")
                        .frame(width: 90)
                        .padding(.all, 10)
                        .border(Color.black)
                        
                })
                
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.turnOff)
                }, label: {
                    Text("Turn OFF")
                        .frame(width: 90)
                        .padding(.all, 10)
                        .border(Color.black)
                })
                
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.defaultColor)
                }, label: {
                    Text("Default")
                        .frame(width: 90)
                        .padding(.all, 10)
                        .border(Color.black)
                        .background(Color(red: 1.0, green: 0.8, blue: 0.7))
                })
            }
            
            Spacer().frame(height: 30)
            
            Button(action: {
                self.pushed = true
            }, label: {
                Text("Test")
            })
                
            List {
                ForEach(log, id: \.self) { logLine in
                    Text("\(logLine)")
                }
            }
            
            Spacer()
            
            endText
                .padding(.bottom, 10)
                .foregroundColor(pushed ? .red : .black)
        }.onAppear {
            self.bulbControl.setDelegate(delegate: self)
            do {
                try self.bulbControl.start()
            } catch {
                self.stateLabel = "Error"
            }
        }
    }
    
    func didStateChanged(canScan: Bool) {
        stateLabel = canScan ? "OK" : "Failed"
    }
    
    func didBulbNotFound() {
        
    }

    func didBulbFound() {
        log.append("\(self.bulbControl.bulbPeripheral?.name ?? "-") \(self.bulbControl.bulbPeripheral?.identifier.uuidString ?? "-")")
        
        self.bulbControl.send(commands: BulbControlCodes.initCommands)
        log.append("Initialized")
    }
    
    func didConnect() {
        log.append("Connected")
    }
    
    func didNotConnect() {
        log.append("Not connected :(")
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

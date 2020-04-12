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
    
    private var colors: [UIColor] = {
        // 1
        let hueValues = Array(0...359)
        // 2
        return hueValues.map {
            UIColor(hue: CGFloat($0) / 359.0 ,
                    saturation: 1.0,
                    brightness: 1.0,
                    alpha: 1.0)
        }
    }()
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var stateLabel:String = "Searching..."
    @State private var log:Array<String> = Array()
    @State private var selectedColor:UIColor = UIColor.white
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Prestigio Light bulb")
                .font(Font.system(size: 24).bold())
                .frame(maxWidth: .infinity)
            
            Divider()
            
            HStack(spacing: 10) {
                Text("State:")
                Text(stateLabel)
                Spacer()
            }
            .padding(.horizontal, 10)
            
            HStack(spacing: 10) {
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.maxWhite)
                }, label: {
                    Text("Turn ON")
                        .frame(width: 90)
                        .padding(.all, 10)
                        .border(borderColor())
                        
                })
                
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.turnOff)
                }, label: {
                    Text("Turn OFF")
                        .frame(width: 90)
                        .padding(.all, 10)
                        .border(borderColor())
                })
                
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.defaultColor)
                }, label: {
                    Text("Default")
                        .frame(width: 90)
                        .padding(.all, 10)
                        .border(borderColor())
                        .background(Color(red: 1.0, green: 0.8, blue: 0.7))
                })
            }
            .padding(.top, 20)
            
            Spacer().frame(height: 30)
            
            Button(action: {
                self.bulbControl.send(command: BulbControlCodes.color(colr: self.selectedColor))
            }, label: {
                Text("Selected color")
                    .frame(width: 200)
                    .padding(.all, 10)
                    .border(borderColor())
                    .background(Color(self.selectedColor))
            })
            
            Spacer().frame(height: 30)
            
            LinearGradient(gradient: Gradient(colors: colors.map { uiColor -> Color in Color(uiColor) }), startPoint: .leading, endPoint: .trailing)
                .frame(width: 200, height: 10)
                .cornerRadius(5)
                .shadow(radius: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 2.0)
                )
                .gesture(
                    DragGesture().onChanged({ (value) in
                        print("dragOffset: \(value.translation), startLocation: \(value.startLocation.x)")
                        
                        var offset = value.startLocation.x + value.translation.width
                        offset = offset < 0 ? 0 : offset
                        offset = offset > 200 ? 200 : offset
                        
                        self.selectedColor = UIColor.init(hue: offset / 200, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                    })
                )
                
            List {
                ForEach(log, id: \.self) { logLine in
                    Text("\(logLine)")
                }
            }
            
            Spacer()
            
        }.onAppear {
            self.bulbControl.setDelegate(delegate: self)
            do {
                try self.bulbControl.start()
            } catch {
                self.stateLabel = "Error"
            }
        }
    }
    
    func borderColor() -> Color {
        return colorScheme == .light ? Color.black : Color.white
    }
    
    func didStateChanged(canScan: Bool) {
        stateLabel = canScan ? "OK" : "Failed"
    }
    
    func didBulbNotFound() {
        
    }

    func didBulbFound() {
//        log.append("\(self.bulbControl.bulbPeripheral?.name ?? "-") \(self.bulbControl.bulbPeripheral?.identifier.uuidString ?? "-")")
//
        self.stateLabel = "Initializing..."
        self.bulbControl.send(commands: BulbControlCodes.initCommands)
//        log.append("Initialized")
        self.stateLabel = "Connected"
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

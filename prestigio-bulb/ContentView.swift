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
    
    private let colors: [UIColor] = {
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
    @State private var enabled:Bool = false
    
    var body: some View {
        VStack(spacing: 10) {
            VStack() {
                ZStack() {
                    Text("Prestigio Light bulb")
                        .font(Font.system(size: 24).bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "light.max")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(Font.system(size: 42).bold())
                        .offset(y: -8)
                }
                .padding(.horizontal, 10)
                
                Divider()

                HStack(spacing: 10) {
                    Text("State:")
                    Text(stateLabel)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .background(enabled ? Color(red: 0, green: 0.2, blue: 0) : backgroundColor())
            }
            
            Divider()
            
            HStack(spacing: 10) {
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.maxWhite)
                }, label: {
                    HStack() {
                        Image(systemName: "lightbulb.fill")
                        Text("ON")
                    }
                    .frame(width: 60)
                    .padding(.all, 10)
                    .border(borderColor())
                        
                })
                
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.turnOff)
                }, label: {
                    HStack() {
                        Image(systemName: "lightbulb")
                        Text("OFF")
                    }
                    .frame(width: 60)
                    .padding(.all, 10)
                    .border(borderColor())
                })
                
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.defaultColor)
                }, label: {
                    Text("Default")
                        .frame(width: 80)
                        .padding(.all, 10)
                        .border(borderColor())
                        .background(Color(red: 1.0, green: 0.8, blue: 0.7))
                })
            }.disabled(!enabled)
            
            Spacer().frame(height: 10)
            
            VStack() {
                Button(action: {
                    self.bulbControl.send(command: BulbControlCodes.color(colr: self.selectedColor))
                }, label: {
                    HStack() {
                        Image(systemName: "paintbrush")
                        Text("Selected color")
                    }
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
            }.disabled(!enabled)
            
            Divider()
                .padding(.top, 10)
        
            VStack(spacing: 10) {
                Text("Log:")
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView(.vertical) {
                    Text(log.joined(separator: "\n"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }.padding(.horizontal, 10)
            
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
    
    func backgroundColor() -> Color {
        return colorScheme == .light ? Color.white : Color.black
    }
    
    func willBulbFound() {
        self.stateLabel = "Initializing..."
        log.append("Searching...")
    }
    
    func didBulbFound() {
        log.append("Found peripheral")
        log.append("          - Name: \(self.bulbControl.bulbPeripheral?.name ?? "-")")
        log.append("          - UUID: \(self.bulbControl.bulbPeripheral?.identifier.uuidString ?? "-")")
        log.append("Found writeable characteristics")
        log.append("          - UUID: \(self.bulbControl.bulbWriteCharacteristics?.uuid.uuidString ?? "-")")
        
        self.bulbControl.send(commands: BulbControlCodes.initCommands, identifier: BulbCommandKey.initializers)
    }
    
    func didBulbNotFound() {
        self.stateLabel = "Not found"
        log.append("Peripheral not found :(")
    }
    
    func didSendCommand(identifier: Any?, commandHex: String) {
        log.append("Sent: \(commandHex)")
        
        
        if (identifier as? BulbCommandKey == BulbCommandKey.initializers) {
            enabled = true
            log.append("Initialized, accepting commands")
            self.stateLabel = "Connected"
        }
    }
    
    func didSendCommandFailed(identifier: Any?, commandHex: String, error: Error) {
        log.append("Sent failed: \(commandHex)")
        if (identifier as? BulbCommandKey == BulbCommandKey.initializers) {
            enabled = false
            log.append("Could not initialize :(")
            self.stateLabel = "Error"
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

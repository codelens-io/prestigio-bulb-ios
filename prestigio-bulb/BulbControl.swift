//
//  BulbControl.swift
//  prestigio-bulb
//
//  Created by Majki on 2020. 04. 11..
//  Copyright © 2020. CodeLens. All rights reserved.
//

import Foundation
import BlueCapKit
import SwiftUI

public class BulbControl {
    
    private var manager:CentralManager?
    private(set) var bulbPeripheral:Peripheral?
    private(set) var bulbWriteCharacteristics:Characteristic?
    
    private var delegate:BulbControlDelegate?
    private var canScan:Bool
    
    init(delegate: BulbControlDelegate? = nil) {
        self.delegate = delegate
        self.canScan = false
    }
    
    func setDelegate(delegate: BulbControlDelegate) {
        self.delegate = delegate
    }
    
    func start() throws {
        manager = CentralManager()
        guard let manager = manager else {
            throw BulbControlError.unlikely
        }
        
        let stateChangeFuture = manager.whenStateChanges()
        let scanFuture = stateChangeFuture.flatMap { state -> FutureStream<Peripheral> in
            switch state {
            case .poweredOn:
                return manager.startScanning()
            case .poweredOff:
                throw BulbControlError.poweredOff
            case .unauthorized, .unsupported:
                throw BulbControlError.invalidState
            case .resetting:
                throw BulbControlError.resetting
            case .unknown:
                throw BulbControlError.unknown
            }
        }
        
        scanFuture.onFailure { error in
            guard let appError = error as? BulbControlError else {
                return
            }
            switch appError {
            case .invalidState:
            break
            case .resetting:
                manager.reset()
            case .poweredOff:
                break
            case .unknown, .unlikely, .serviceNotFound:
                break
            }
        }
        
        let connectionFuture = scanFuture
            .withFilter(filter: { discoveredPeripheral -> Bool in
                discoveredPeripheral.name == "Prestigio RGB Light"
            })
            .flatMap { discoveredPeripheral  -> FutureStream<Void> in
                manager.stopScanning()
                self.bulbPeripheral = discoveredPeripheral
                return (self.bulbPeripheral?.connect(connectionTimeout: 10.0))!
            }
        
        let discoveryFuture = connectionFuture.flatMap { () -> Future<Void> in
            guard let peripheral = self.bulbPeripheral else {
                throw BulbControlError.unlikely
            }
            return peripheral.discoverAllServices()
        }.flatMap { () -> Future<Void> in
            guard let peripheral = self.bulbPeripheral else {
                throw BulbControlError.invalidState
            }
            for service in peripheral.services {
                let characteristicsFuture = service.discoverAllCharacteristics()
                characteristicsFuture.flatMap { () -> Future<Void> in
                    for characteristic in service.characteristics {
                        if (characteristic.canWrite) {
                            self.bulbWriteCharacteristics = characteristic
                            self.delegate?.didBulbFound()
                        }
                    }
                    return Future()
                }
            }
            return Future()
        }

        discoveryFuture.onFailure { error in
            switch error {
            case PeripheralError.disconnected:
                self.bulbPeripheral?.reconnect()
            case BulbControlError.serviceNotFound:
                break
            default:
            break
            }
        }
    }
    
    func send(commands: [Data], identifier:Any? = nil) {
        commands.forEach { command in
            self.send(command: command, identifier: identifier)
        }
    }
    
    func send(command: Data, identifier:Any? = nil) {
        let resultFuture = (bulbWriteCharacteristics?.write(data: command))!
        resultFuture.onFailure { e in
            self.delegate?.didSendCommandFailed(identifier: identifier as Any, commandHex: command.hexStringValue(), error: e)
        }
        resultFuture.onSuccess {
            self.delegate?.didSendCommand(identifier: identifier as Any, commandHex: command.hexStringValue())
        }
    }
    
}

enum BulbCommandKey {
    case initializers
}

struct BulbControlCodes {
    
    static let initCommands:[Data] = [Data([0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
                                      Data([0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])]
    static let turnOff:Data = Data([0x14, 0x00, 0x00, 0x00, 0x25, 0x00, 0x00, 0x00, 0x00])
    static let maxWhite:Data = Data([0x14, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00])
    static let defaultColor:Data = Data([0x14, 0xff, 0xab, 0x25, 0x00, 0x00, 0x00, 0x00, 0x00])
    
    static func color(colr: UIColor) -> Data {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        colr.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return color(red: Double(red), green: Double(green), blue: Double(blue))
    }
    
    static func color(red: Double?, green: Double?, blue: Double?, intensity: Double? = nil) -> Data {
        let uint8Red:UInt8 = toUint8(double: red)
        let uint8Green:UInt8 = toUint8(double: green)
        let uint8Blue:UInt8 = toUint8(double: blue)
        let uint8Intensity:UInt8 = toUint8(double: intensity)
        print("Sending color: \(uint8Red) \(uint8Green) \(uint8Blue) \(uint8Intensity)")
        return Data([0x14, uint8Red, uint8Green, uint8Blue, uint8Intensity, 0x00, 0x00, 0x00, 0x00])
    }
    
    private static func toDouble(colorHash: String, startOffset: Int) -> Double {
        let r1 = colorHash.index(colorHash.startIndex, offsetBy: startOffset)
        let r2 = colorHash.index(colorHash.startIndex, offsetBy: startOffset + 1)
        return Double(Int(colorHash[r1...r2], radix: 16)!) / 255.0
    }
    
    private static func toUint8(double: Double?) -> UInt8 {
        guard let presentDouble = double else {
            print("Received nil double, returning 0")
            return 0
        }
        let max:Double = 255-25
        let uint8 = (UInt8(max * presentDouble) + 25)
        print("Converting double \(presentDouble) to \(uint8)")
        return uint8
    }
    
}

public enum BulbControlError : Error {
    case invalidState
    case resetting
    case poweredOff
    case unknown
    case unlikely
    case serviceNotFound
}


//
//  BulbControl.swift
//  prestigio-bulb
//
//  Created by Majki on 2020. 04. 11..
//  Copyright © 2020. CodeLens. All rights reserved.
//

import Foundation
import BlueCapKit

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
    
    func send(commands: [Data]) -> Bool {
        var success:Bool = true
        commands.forEach { command in
            bulbWriteCharacteristics?.write(data: command)
            sleep(2)
        }
        return success
    }
    
    func send(command: Data) -> Bool {
        var success:Bool = true
        bulbWriteCharacteristics?.write(data: command).onFailure { error in
            success = false
        }
        return success
    }
    
}

struct BulbControlCodes {
    
    static let initCommands:[Data] = [Data([0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
                              Data([0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])]
    static let turnOff:Data = Data([0x14, 0x00, 0x00, 0x00, 0x25, 0x00, 0x00, 0x00, 0x00])
    static let maxWhite:Data = Data([0x14, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00])

    static let defaultColor:Data = Data([0x14, 0xff, 0xab, 0x25, 0x00, 0x00, 0x00, 0x00, 0x00])
    
}

public enum BulbControlError : Error {
    case invalidState
    case resetting
    case poweredOff
    case unknown
    case unlikely
    case serviceNotFound
}


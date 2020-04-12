//
//  BulbControlDelegate.swift
//  prestigio-bulb
//
//  Created by Majki on 2020. 04. 11..
//  Copyright © 2020. CodeLens. All rights reserved.
//

import BlueCapKit

protocol BulbControlDelegate {
    
    func willBulbFound()
    func didBulbFound()
    func didBulbNotFound()
    
    func didSendCommand(identifier:Any?, commandHex:String)
    func didSendCommandFailed(identifier:Any?, commandHex:String, error:Error)
    
}


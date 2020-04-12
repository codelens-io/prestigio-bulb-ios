//
//  BulbControlDelegate.swift
//  prestigio-bulb
//
//  Created by Majki on 2020. 04. 11..
//  Copyright © 2020. CodeLens. All rights reserved.
//

import BlueCapKit

protocol BulbControlDelegate {
    
    func didStateChanged(canScan: Bool)
    
    func didBulbFound()
    func didBulbNotFound()
    
    func didConnect()
    func didNotConnect()
    
}


//
//  CarPeripheral.swift
//  Remote
//
//  Created by Ben Guericke on 2/14/20.
//  Copyright © 2020 Ben Guericke. All rights reserved.
//

import Foundation
import CoreBluetooth

let kBLEService_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
let kBLE_Characteristic_uuid_Tx = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
let kBLE_Characteristic_uuid_Rx = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
class CarPeripheral: NSObject {
    public static let BLEService_UUID = CBUUID(string: kBLEService_UUID)
    public static let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
    public static let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)
}

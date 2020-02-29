//
//  ViewController.swift
//  Remote
//
//  Created by Ben Guericke on 2/11/20.
//  Copyright © 2020 Ben Guericke. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    //Characteristics
    private var txCharacteristic : CBCharacteristic?
    private var rxCharacteristic : CBCharacteristic?
    //private var blePeripheral : CBPeripheral!
    private var characteristicASCIIValue = NSString()
    
    
    // Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    //UI Elements
    @IBOutlet weak var ledToggle: UISwitch!
    @IBOutlet weak var motorSlider: UISlider!
    @IBOutlet weak var lightsToggle: UISwitch!
    @IBOutlet weak var turningSlider: UISlider!
    
    //Value changed
    //    @IBAction func MotorSliderChanged(_ sender: Any) {
    //        if peripheral != nil {
    //            print("Motor:", motorSlider.value);
    //            let slider:UInt8 = UInt8(motorSlider.value)
    //            writeValueToChar( withCharacteristic: motorChar!, withValue: Data([slider]))
    //        }
    //    }
    //    @IBAction func TurningSliderChanged(_ sender: Any) {
    //        if peripheral != nil {
    //
    //        }
    //    }
    @IBAction func LedToggleChanged(_ sender: Any) {
        if peripheral != nil {
            print("Headlights:", ledToggle.isOn)
            writeValue(data: "!B31")
        }
    }
    
    let isPressed = true;
    let tag = 1
    @IBAction func LightsToggleChanged(_ sender: Any) {
        if peripheral != nil {
            print("Headlights:", lightsToggle.isOn)
            let message = "!B\(tag)\(isPressed ? "1" : "0")"
            print(message)
            writeValue(data: message)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //Writing functions
    func writeValue(data: String){
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        //change the "data" to valueString
        if let blePeripheral = peripheral{
            if let txCharacteristic = txCharacteristic {
                blePeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    
    func writeCharacteristic(val: Int8){
        var val = val
        let ns = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
        peripheral.writeValue(ns as Data, for: txCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    
    //Checks if the devices bluetooth is enabled
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            // We will just handle it the easy way here: if Bluetooth is on, proceed...start scan!
            print("Bluetooth Enabled")
            centralManager.scanForPeripherals(withServices: [CarPeripheral.BLEService_UUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
            
        } else {
            //If Bluetooth is off, display a UI alert message saying "Bluetooth is not enable" and "Make sure that your bluetooth is turned on"
            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")
            
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    
    //The brains of the bluetooth communciation
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //Device found stop scan
        self.centralManager.stopScan()
        
        // Copy the peripheral instance
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
        // Connect!
        self.centralManager?.connect(self.peripheral, options: nil)
        
    }
    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Connected to your car")
            peripheral.discoverServices([CarPeripheral.BLEService_UUID])
        }
    }
    
    
    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics {
            //looks for the right characteristic
            
            if characteristic.uuid.isEqual(CarPeripheral.BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                print(String(describing: rxCharacteristic?.value))
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(CarPeripheral.BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    // Getting Values From Characteristic
    
    /*After you've found a characteristic of a service that you are interested in, you can read the characteristic's value by calling the peripheral "readValueForCharacteristic" method within the "didDiscoverCharacteristicsFor service" delegate.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        if characteristic == rxCharacteristic {
//            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
//                characteristicASCIIValue = ASCIIstring
//                print("Value Recieved: \((characteristicASCIIValue as String))")
//                NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: nil)
//
//            }
//        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        if ((characteristic.descriptors) != nil) {
            
            for x in characteristic.descriptors!{
                let descript = x as CBDescriptor
                print("function name: DidDiscoverDescriptorForChar \(String(describing: descript.description))")
                print("Rx Value \(String(describing: self.rxCharacteristic?.value))")
                print("Tx Value \(String(describing: self.txCharacteristic?.value))")
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        } else {
            print("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
            // bleService = service
        }
        print("Discovered Services: \(services)")
    }
    
}


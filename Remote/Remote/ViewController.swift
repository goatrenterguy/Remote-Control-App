//
//  ViewController.swift
//  Remote
//
//  Created by Ben Guericke on 2/11/20.
//  Copyright © 2020 Ben Guericke. All rights reserved.
//

import UIKit
import CoreBluetooth

var txCharacteristic : CBCharacteristic?
var rxCharacteristic : CBCharacteristic?
var blePeripheral : CBPeripheral?
var characteristicASCIIValue = NSString()


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    //Data
    var centralManager : CBCentralManager!
    var characteristicValue = [CBUUID: NSData]()
    var timer = Timer()
    var characteristics = [String : CBCharacteristic]()
    
    //UI Elements
    @IBOutlet weak var ledToggle: UISwitch!
    @IBOutlet weak var motorSlider: UISlider!
    @IBOutlet weak var lightsToggle: UISwitch!
    @IBOutlet weak var turningSlider: UISlider!
    @IBOutlet weak var reconnectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var StatusLabel: UILabel!
    @IBOutlet weak var forwardButt: UIButton!
    @IBOutlet weak var backButt: UIButton!
    
    //Control movement forwards and backwards
    @IBAction func motorValueChanged(_ sender: Any) {
        let message = "!M\(motorSlider.value)1"
        let output = message.data(using: String.Encoding.utf8)
        sendCrcData(output!)
    }
    
    //Turn motor
    @IBAction func turningVlaueChanged(_ sender: Any) {
        let message = "!S\(turningSlider.value)1"
        let output = message.data(using: String.Encoding.utf8)
        sendCrcData(output!)
    }
    //Make UI elements exicute commands
    @IBAction func reconnectButtTouchedDown(_ sender: Any) {
        print("Disconnecting from all devices...")
        disconnectAllConnection()
        print("Restarting scan...")
        startScan()
    }
    
    @IBAction func disconnectButtTouchedDown(_ sender: Any) {
        print("Disconnecting from all devices...")
        disconnectAllConnection()
    }
    @IBAction func forwardButtDown(_ sender: Any) {
        let message = "!B31"
        let output = message.data(using: String.Encoding.utf8)
        sendCrcData(output!)
    }
    @IBAction func forwardButtUp(_ sender: Any) {
        let message = "!B30"
        let output = message.data(using: String.Encoding.utf8)
        sendCrcData(output!)
    }
    @IBAction func backButtDown(_ sender: Any) {
        let message = "!B41"
        let output = message.data(using: String.Encoding.utf8)
        sendCrcData(output!)
    }
    @IBAction func backButtUp(_ sender: Any) {
        let message = "!B40"
        let output = message.data(using: String.Encoding.utf8)
        sendCrcData(output!)
    }
    //Send turn value when changed
    @IBAction func turningSliderChanged(_ sender: Any) {
        let message = "!S\(turningSlider.value)1"
        let output = message.data(using: String.Encoding.utf8)
               sendCrcData(output!)
    }
    //Led switch toggled
    @IBAction func ledValueChanged(_ sender: Any) {
        var on = 0;
        if (ledToggle.isOn) {
            on = 1
        } else {
            on = 0
        }
        let message = "!B1\(on)"
        let output = message.data(using: String.Encoding.utf8)
        sendCrcData(output!)
    }
    
    //Lights swithc toggled
    @IBAction func lightsValueChanged(_ sender: Any) {
        var on = 0;
        if (lightsToggle.isOn) {
            on = 1
        } else {
            on = 0
        }
        let message = "!B2\(on)"
        let output = message.data(using: String.Encoding.utf8)
        sendCrcData(output!)
    }
    
    //Send command data
    func sendCrcData(_ data: Data) {
        var crcData = data
        crcData.appendCrc()
        if let blePeripheral = blePeripheral{
            if let txCharacteristic = txCharacteristic {
                blePeripheral.writeValue(crcData, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*Our key player in this app will be our CBCentralManager. CBCentralManager objects are used to manage discovered or connected remote peripheral devices (represented by CBPeripheral objects), including scanning for, discovering, and connecting to advertising peripherals.
         */
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    /*Okay, now that we have our CBCentalManager up and running, it's time to start searching for devices. You can do this by calling the "scanForPeripherals" method.*/
    
    func startScan() {
        print("Now Scanning...")
        self.timer.invalidate()
        centralManager?.scanForPeripherals(withServices: [BLEService_UUID] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        Timer.scheduledTimer(withTimeInterval: 17, repeats: false) {_ in
            self.cancelScan()
        }
    }
    
    /*We also need to stop scanning at some point so we'll also create a function that calls "stopScan"*/
    func cancelScan() {
        self.centralManager?.stopScan()
        print("Scan Stopped")
    }
    
    
    //-Terminate all Peripheral Connection
    /*
     Call this when things either go wrong, or you're done with the connection.
     This cancels any subscriptions if there are any, or straight disconnects if not.
     (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    func disconnectFromDevice () {
        if blePeripheral != nil {
            // We have a connection to the device but we are not subscribed to the Transfer Characteristic for some reason.
            // Therefore, we will just disconnect from the peripheral
            centralManager?.cancelPeripheralConnection(blePeripheral!)
        }
    }
    
    
    func restoreCentralManager() {
        //Restores Central Manager delegate if something went wrong
        centralManager?.delegate = self
    }
    
    /*
     Called when the central manager discovers a peripheral while scanning. Also, once peripheral is connected, cancel scanning.
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        blePeripheral = peripheral
        peripheral.delegate = self
        connectToDevice()
        if blePeripheral == nil {
            print("Found new pheripheral devices with services")
            print("Peripheral name: \(String(describing: peripheral.name))")
            print("**********************************")
            print ("Advertisement Data : \(advertisementData)")
        }
    }
    
    //Peripheral Connections: Connecting, Connected, Disconnected
    
    //-Connection
    func connectToDevice () {
        centralManager?.connect(blePeripheral!, options: nil)
        StatusLabel.text = "Connected!"
    }
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     This method is invoked when a call to connect(_:options:) is successful. You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    //-Connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*****************************")
        print("Connection complete")
        print("Peripheral info: \(String(describing: blePeripheral))")
        
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        centralManager?.stopScan()
        self.cancelScan()
        
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices([BLEService_UUID])
    }
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     */
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Failed to connect to peripheral")
            return
        }
    }
    
    func disconnectAllConnection() {
        centralManager.cancelPeripheralConnection(blePeripheral!)
        StatusLabel.text = "Disconnected!"
    }
    
    /*
     Invoked when you discover the peripheral’s available services.
     This method is invoked when your app calls the discoverServices(_:) method. If the services of the peripheral are successfully discovered, you can access them through the peripheral’s services property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
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
    
    /*
     Invoked when you discover the characteristics of a specified service.
     This method is invoked when your app calls the discoverCharacteristics(_:for:) method. If the characteristics of the specified service are successfully discovered, you can access them through the service's characteristics property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    
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
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    
    // Getting Values From Characteristic
    
    /*After you've found a characteristic of a service that you are interested in, you can read the characteristic's value by calling the peripheral "readValueForCharacteristic" method within the "didDiscoverCharacteristicsFor service" delegate.
     */
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("\(error.debugDescription)")
            return
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
    
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Message sent")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Succeeded!")
    }
    
    /*
     Invoked when the central manager’s state is updated.
     This is where we kick off the scan if Bluetooth is turned on.
     */
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            // We will just handle it the easy way here: if Bluetooth is on, proceed...start scan!
            print("Bluetooth Enabled")
            startScan()
            
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
    
}

extension Data {
    //Makes sure that the information being sent adds up to 0xFF
    mutating func appendCrc() {
        var dataBytes = [UInt8](repeating: 0, count: count)
        copyBytes(to: &dataBytes, count: count)
        
        var crc: UInt8 = 0
        for i in dataBytes {    //add all bytes
            crc = crc &+ i
        }
        crc = ~crc  //invert
        
        append(&crc, count: 1)
    }
}


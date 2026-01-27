import Foundation
import CoreBluetooth
import Combine

/// Manages Bluetooth Low Energy communication with the XBee module
@Observable
final class BluetoothService: NSObject {
    
    // MARK: - Published State
    
    private(set) var state: DeviceState = .disconnected
    private(set) var discoveredDevices: [CBPeripheral] = []
    private(set) var receivedData: String = ""
    
    // MARK: - Callbacks
    
    var onAttitudeReceived: ((Attitude) -> Void)?
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic?
    
    private var receiveBuffer = ""
    
    // XBee BLE Service and Characteristic UUIDs
    // These are typical for XBee Bluetooth modules - may need adjustment
    private let xbeeServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let txCharUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")  // Write to this
    private let rxCharUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")  // Receive notifications
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for XBee devices
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            state = .error("Bluetooth not available")
            return
        }
        
        discoveredDevices.removeAll()
        state = .scanning
        
        // Scan for devices with the XBee service, or all devices if we don't know the UUID
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.state == .scanning {
                self?.stopScanning()
            }
        }
    }
    
    /// Stop scanning for devices
    func stopScanning() {
        centralManager.stopScan()
        if state == .scanning {
            state = .disconnected
        }
    }
    
    /// Connect to a specific peripheral
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        state = .connecting
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Disconnect from the current peripheral
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        txCharacteristic = nil
        rxCharacteristic = nil
        state = .disconnected
    }
    
    /// Send a command to the robot
    func send(_ command: Command) {
        guard let characteristic = txCharacteristic,
              let peripheral = connectedPeripheral else {
            print("Cannot send: not connected")
            return
        }
        
        peripheral.writeValue(command.data, for: characteristic, type: .withResponse)
    }

    func startStreaming() {
        sendRaw("START\n")
    }

    func stopStreaming() {
        sendRaw("STOP\n")
    }
    
    /// Send raw string data
    func sendRaw(_ string: String) {
        guard let characteristic = txCharacteristic,
              let peripheral = connectedPeripheral,
              let data = string.data(using: .utf8) else {
            return
        }
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth powered on")
        case .poweredOff:
            state = .error("Bluetooth is off")
        case .unauthorized:
            state = .error("Bluetooth unauthorized")
        case .unsupported:
            state = .error("Bluetooth unsupported")
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Filter for devices that look like XBee or have a name
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        
        // Only add devices with names (filter out unnamed devices)
        if name != nil && !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown")")
        peripheral.discoverServices([xbeeServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        state = .error(error?.localizedDescription ?? "Connection failed")
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        state = .disconnected
        connectedPeripheral = nil
        txCharacteristic = nil
        rxCharacteristic = nil
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothService: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            state = .error(error.localizedDescription)
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics([txCharUUID, rxCharUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            state = .error(error.localizedDescription)
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == txCharUUID {
                txCharacteristic = characteristic
                print("Found TX characteristic")
            } else if characteristic.uuid == rxCharUUID {
                rxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("Found RX characteristic, subscribed to notifications")
            }
        }
        
        // Mark as connected once we have both characteristics
        if txCharacteristic != nil && rxCharacteristic != nil {
            state = .connected
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == rxCharUUID,
              let data = characteristic.value,
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        
        // Accumulate data in buffer and process complete lines
        receiveBuffer += string
        processBuffer()
    }
    
    private func processBuffer() {
        // Split by newlines and process complete lines
        while let newlineIndex = receiveBuffer.firstIndex(of: "\n") {
            let line = String(receiveBuffer[..<newlineIndex])
            receiveBuffer = String(receiveBuffer[receiveBuffer.index(after: newlineIndex)...])
            
            // Try to parse as attitude data
            if let attitude = AttitudeParser.parse(line) {
                onAttitudeReceived?(attitude)
            }
            
            // Store for debugging
            receivedData = line
        }
    }
}

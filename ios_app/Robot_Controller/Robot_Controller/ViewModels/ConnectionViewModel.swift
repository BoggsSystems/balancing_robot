import Foundation
import CoreBluetooth

/// ViewModel for managing Bluetooth connection state and device discovery
@Observable
final class ConnectionViewModel {
    
    // MARK: - Dependencies
    
    private let bluetoothService: BluetoothService
    
    // MARK: - State
    
    var state: DeviceState { bluetoothService.state }
    var discoveredDevices: [CBPeripheral] { bluetoothService.discoveredDevices }
    
    // MARK: - Initialization
    
    init(bluetoothService: BluetoothService) {
        self.bluetoothService = bluetoothService
    }
    
    // MARK: - Actions
    
    func startScanning() {
        bluetoothService.startScanning()
    }
    
    func stopScanning() {
        bluetoothService.stopScanning()
    }
    
    func connect(to peripheral: CBPeripheral) {
        bluetoothService.connect(to: peripheral)
    }
    
    func disconnect() {
        bluetoothService.disconnect()
    }
}

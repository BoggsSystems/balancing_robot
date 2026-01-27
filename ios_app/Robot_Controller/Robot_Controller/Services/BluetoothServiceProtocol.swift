import Foundation
import CoreBluetooth

/// Protocol for Bluetooth service (real or mock)
protocol BluetoothServiceProtocol: AnyObject {
    var state: DeviceState { get }
    var onAttitudeReceived: ((Attitude) -> Void)? { get set }
    
    func send(_ command: Command)
    func disconnect()
}

// Conform both services to the protocol
extension BluetoothService: BluetoothServiceProtocol {}
extension MockBluetoothService: BluetoothServiceProtocol {}

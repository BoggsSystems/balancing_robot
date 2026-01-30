import Foundation
import CoreBluetooth

/// Protocol for Bluetooth service (real or mock)
protocol BluetoothServiceProtocol: AnyObject {
    var state: DeviceState { get }
    var onAttitudeReceived: ((Attitude) -> Void)? { get set }
    var onTelemetryReceived: ((Telemetry) -> Void)? { get set }
    
    func send(_ command: Command)
    func disconnect()
    
    /// Start IMU streaming (R: P: Y:). No effect until after connect. Separates connection from initiation.
    func startStreaming()
    /// Stop IMU streaming. Connection remains; use disconnect() to close.
    func stopStreaming()
}

// Conform both services to the protocol
extension BluetoothService: BluetoothServiceProtocol {}
extension MockBluetoothService: BluetoothServiceProtocol {}

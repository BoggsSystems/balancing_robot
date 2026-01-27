import Foundation

/// ViewModel for managing attitude display and robot control
@Observable
final class AttitudeViewModel {
    
    // MARK: - Dependencies
    
    private let bluetoothService: any BluetoothServiceProtocol
    
    // MARK: - State
    
    private(set) var attitude: Attitude = .zero
    private(set) var ledState: Bool = false
    private(set) var lastUpdateTime: Date?
    /// IMU streaming on/off. Connection is separate; tap Start to begin R: P: Y:.
    private(set) var isStreaming: Bool = false
    
    var isConnected: Bool { bluetoothService.state.isConnected }
    var connectionState: DeviceState { bluetoothService.state }
    
    // MARK: - Initialization
    
    init(bluetoothService: BluetoothService) {
        self.bluetoothService = bluetoothService
        setupCallback(bluetoothService)
    }
    
    init(mockService: MockBluetoothService) {
        self.bluetoothService = mockService
        setupCallback(mockService)
    }
    
    init(bluetoothService: any BluetoothServiceProtocol) {
        self.bluetoothService = bluetoothService
        setupCallback(bluetoothService)
    }
    
    private func setupCallback(_ service: any BluetoothServiceProtocol) {
        // Subscribe to attitude updates
        service.onAttitudeReceived = { [weak self] attitude in
            DispatchQueue.main.async {
                self?.attitude = attitude
                self?.lastUpdateTime = Date()
            }
        }
    }
    
    // MARK: - Actions
    
    /// Toggle the onboard LED
    func toggleLED() {
        ledState.toggle()
        bluetoothService.send(.ledToggle)
    }
    
    /// Send motor command (for future use)
    func sendMotorCommand(throttle: Float, turn: Float) {
        bluetoothService.send(.motor(throttle: throttle, turn: turn))
    }

    /// Start IMU streaming (R: P: Y:). Call after connect; separates connection from initiation.
    func startStreaming() {
        guard isConnected else { return }
        bluetoothService.startStreaming()
        isStreaming = true
    }

    /// Stop IMU streaming. Connection stays open; use disconnect to close.
    func stopStreaming() {
        bluetoothService.stopStreaming()
        isStreaming = false
    }
    
    /// Reset attitude to zero (for calibration reference)
    func resetAttitude() {
        attitude = .zero
    }
}

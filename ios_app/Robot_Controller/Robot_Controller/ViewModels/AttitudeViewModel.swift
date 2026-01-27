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
    
    /// Send motor command. Used by the joystick; throttled to ~20 Hz except 0,0.
    func sendMotorCommand(throttle: Float, turn: Float) {
        bluetoothService.send(.motor(throttle: throttle, turn: turn))
    }

    private var lastDriveSendTime: Date?
    private let driveSendInterval: TimeInterval = 0.05

    /// Update drive from joystick. Throttled to ~20 Hz; 0,0 is sent immediately.
    func setDriveInput(throttle: Float, turn: Float) {
        let now = Date()
        if throttle == 0 && turn == 0 {
            sendMotorCommand(throttle: 0, turn: 0)
            lastDriveSendTime = now
            return
        }
        if let last = lastDriveSendTime, now.timeIntervalSince(last) < driveSendInterval {
            return
        }
        sendMotorCommand(throttle: throttle, turn: turn)
        lastDriveSendTime = now
    }

    /// E‑Stop: send M:0,0 immediately. Does not disconnect.
    func eStop() {
        sendMotorCommand(throttle: 0, turn: 0)
        lastDriveSendTime = Date()
    }

    /// Start IMU streaming (R: P: Y:). Call after connect; separates connection from initiation.
    func startStreaming() {
        guard isConnected else { return }
        bluetoothService.startStreaming()
        isStreaming = true
    }

    /// Stop IMU streaming. Connection stays open; use disconnect to close. Sends M:0,0 to clear drive.
    func stopStreaming() {
        sendMotorCommand(throttle: 0, turn: 0)
        bluetoothService.stopStreaming()
        isStreaming = false
    }
    
    /// Reset attitude to zero (for calibration reference)
    func resetAttitude() {
        attitude = .zero
    }
}

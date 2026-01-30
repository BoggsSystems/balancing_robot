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
    private(set) var currentMovement: MovementPattern = .manual
    private(set) var queuedMovement: MovementPattern?
    private(set) var movementStartTime: Date?
    private(set) var telemetrySamples: [Telemetry] = []
    private(set) var latestTelemetry: Telemetry?
    
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
        service.onTelemetryReceived = { [weak self] telemetry in
            DispatchQueue.main.async {
                self?.latestTelemetry = telemetry
                self?.attitude = telemetry.attitude
                self?.lastUpdateTime = Date()
                self?.appendTelemetry(telemetry)
            }
        }
        // Fallback for older telemetry format
        service.onAttitudeReceived = { [weak self] attitude in
            DispatchQueue.main.async {
                if self?.latestTelemetry == nil {
                    self?.attitude = attitude
                    self?.lastUpdateTime = Date()
                }
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
    private var movementTimer: Timer?
    private let telemetryLimit = 300

    /// Update drive from joystick. Throttled to ~20 Hz; 0,0 is sent immediately.
    func setDriveInput(throttle: Float, turn: Float) {
        let now = Date()
        if currentMovement != .manual {
            cancelMovementTimer()
            currentMovement = .manual
            queuedMovement = nil
            bluetoothService.send(.movementMode(MovementPattern.manual.mode))
        }
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

    /// Arm/Ready: enable balance and retract arm (if present).
    func arm() {
        bluetoothService.send(.arm)
        cancelMovementTimer()
        currentMovement = .manual
        queuedMovement = nil
        bluetoothService.send(.movementMode(MovementPattern.manual.mode))
    }

    /// Ready: arm + manual + clear drive (standby).
    func ready() {
        arm()
        sendMotorCommand(throttle: 0, turn: 0)
    }

    /// Disarm (stop balance): send DISARM so firmware runs arm down → wait → disable balance.
    func disarm() {
        bluetoothService.send(.disarm)
        cancelMovementTimer()
        currentMovement = .manual
        queuedMovement = nil
        bluetoothService.send(.movementMode(MovementPattern.manual.mode))
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
        cancelMovementTimer()
        currentMovement = .manual
        queuedMovement = nil
        bluetoothService.send(.movementMode(MovementPattern.manual.mode))
        telemetrySamples.removeAll()
    }
    
    /// Reset attitude to zero (for calibration reference)
    func resetAttitude() {
        attitude = .zero
    }

    // MARK: - Scripted movement queue

    func selectMovement(_ movement: MovementPattern) {
        guard isStreaming else { return }
        if movement == currentMovement {
            queuedMovement = nil
            return
        }
        if currentMovement == .manual {
            startMovement(movement)
        } else {
            queuedMovement = movement
        }
    }

    private func startMovement(_ movement: MovementPattern) {
        currentMovement = movement
        queuedMovement = nil
        movementStartTime = Date()
        bluetoothService.send(.movementMode(movement.mode))

        cancelMovementTimer()
        guard let duration = movement.duration, duration > 0 else {
            return
        }
        movementTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.advanceMovementQueue()
        }
    }

    private func advanceMovementQueue() {
        if let next = queuedMovement {
            startMovement(next)
        } else {
            currentMovement = .manual
            movementStartTime = nil
            bluetoothService.send(.movementMode(MovementPattern.manual.mode))
        }
    }

    private func cancelMovementTimer() {
        movementTimer?.invalidate()
        movementTimer = nil
    }

    private func appendTelemetry(_ telemetry: Telemetry) {
        telemetrySamples.append(telemetry)
        if telemetrySamples.count > telemetryLimit {
            telemetrySamples.removeFirst(telemetrySamples.count - telemetryLimit)
        }
    }

    func exportTelemetryCSV() -> URL? {
        guard !telemetrySamples.isEmpty else { return nil }
        var lines = ["t,roll,pitch,yaw,left,right,balance,target_pitch,mode,enabled,state"]
        for sample in telemetrySamples {
            let t = sample.timestamp.map { String(format: "%.3f", $0) } ?? ""
            let left = sample.left.map { String(format: "%.2f", $0) } ?? ""
            let right = sample.right.map { String(format: "%.2f", $0) } ?? ""
            let bal = sample.balance.map { String(format: "%.2f", $0) } ?? ""
            let tp = sample.targetPitchDeg.map { String(format: "%.2f", $0) } ?? ""
            let mode = sample.mode.map(String.init) ?? ""
            let enabled = sample.enabled.map { $0 ? "1" : "0" } ?? ""
            let state = sample.state.map(String.init) ?? ""
            lines.append([
                t,
                String(format: "%.2f", sample.roll),
                String(format: "%.2f", sample.pitch),
                String(format: "%.2f", sample.yaw),
                left,
                right,
                bal,
                tp,
                mode,
                enabled,
                state
            ].joined(separator: ","))
        }

        let filename = "telemetry_\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

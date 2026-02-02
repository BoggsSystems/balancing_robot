import Foundation
import CoreGraphics

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
    /// Overhead path (x,y) in meters, integrated from velocity + yaw (or distance delta) for all movements. Clear when cluttered.
    private(set) var pathPoints: [CGPoint] = []
    private var lastPathTime: Date?
    private var lastPathDistance: Double?
    private var telemetryLogCount = 0
    private var pathAppendLogCount = 0
    
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
                guard let self else { return }
                self.latestTelemetry = telemetry
                self.attitude = telemetry.attitude
                self.lastUpdateTime = Date()
                self.appendTelemetry(telemetry)
                self.telemetryLogCount += 1
                if self.telemetryLogCount % 20 == 0 {
                    let d = telemetry.distanceM.map { String(format: "%.3f", $0) } ?? "nil"
                    let v = telemetry.velocityMps.map { String(format: "%.2f", $0) } ?? "nil"
                    print("[AttitudeVM] telemetry DIST=\(d) VEL=\(v) pathPoints=\(self.pathPoints.count) currentMovement=\(self.currentMovement.name)")
                }
                if self.currentMovement != .manual {
                    self.appendPathFromTelemetry(telemetry)
                }
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

    /// Clear the overhead path plot (e.g. after successive movements).
    func clearPath() {
        pathPoints = []
        lastPathTime = nil
        lastPathDistance = nil
    }

    /// Integrate one telemetry sample into path. Uses distance delta when available (reliable); else velocity + yaw.
    /// Called when currentMovement != .manual.
    private func appendPathFromTelemetry(_ t: Telemetry) {
        if pathPoints.isEmpty {
            pathPoints.append(CGPoint(x: 0, y: 0))
            lastPathDistance = t.distanceM
        }
        let yawRad = (t.yaw * .pi / 180)
        let now = Date()
        let dtRaw = lastPathTime.map { now.timeIntervalSince($0) } ?? 0.05
        let dt = (dtRaw > 0 && dtRaw < 1) ? dtRaw : 0.05
        lastPathTime = now

        let dx: Double
        let dy: Double
        if let dist = t.distanceM, let prev = lastPathDistance {
            let delta = dist - prev
            lastPathDistance = dist
            dx = delta * cos(yawRad)
            dy = delta * sin(yawRad)
        } else {
            let v = t.velocityMps ?? 0
            dx = v * cos(yawRad) * dt
            dy = v * sin(yawRad) * dt
        }

        let last = pathPoints.last ?? CGPoint(x: 0, y: 0)
        pathPoints.append(CGPoint(x: last.x + CGFloat(dx), y: last.y + CGFloat(dy)))
        pathAppendLogCount += 1
        if pathAppendLogCount % 10 == 0 {
            print("[AttitudeVM] path append count=\(pathPoints.count) last=(\(last.x + CGFloat(dx)), \(last.y + CGFloat(dy)))")
        }
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
    /// Also sends ARM so scripted movements (MODE:n) execute; sim requires rc.enabled=1.
    func startStreaming() {
        guard isConnected else { return }
        bluetoothService.startStreaming()
        bluetoothService.send(.arm)
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

    /// - Parameter duration: Optional override (e.g. scale-dependent from path scale); nil uses movement.duration.
    func selectMovement(_ movement: MovementPattern, duration: TimeInterval? = nil) {
        guard isStreaming else { return }
        if movement == currentMovement {
            queuedMovement = nil
            return
        }
        if currentMovement == .manual {
            startMovement(movement, duration: duration)
        } else {
            queuedMovement = movement
        }
    }

    private func startMovement(_ movement: MovementPattern, duration overrideDuration: TimeInterval? = nil) {
        currentMovement = movement
        queuedMovement = nil
        movementStartTime = Date()
        bluetoothService.send(.movementMode(movement.mode))

        cancelMovementTimer()
        let duration = overrideDuration ?? movement.duration ?? 0
        guard duration > 0 else {
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
        var lines = ["t,roll,pitch,yaw,left,right,balance,target_pitch,mode,enabled,state,distance_m,velocity_mps,accel_fwd"]
        for sample in telemetrySamples {
            let t = sample.timestamp.map { String(format: "%.3f", $0) } ?? ""
            let left = sample.left.map { String(format: "%.2f", $0) } ?? ""
            let right = sample.right.map { String(format: "%.2f", $0) } ?? ""
            let bal = sample.balance.map { String(format: "%.2f", $0) } ?? ""
            let tp = sample.targetPitchDeg.map { String(format: "%.2f", $0) } ?? ""
            let mode = sample.mode.map(String.init) ?? ""
            let enabled = sample.enabled.map { $0 ? "1" : "0" } ?? ""
            let state = sample.state.map(String.init) ?? ""
            let dist = sample.distanceM.map { String(format: "%.3f", $0) } ?? ""
            let vel = sample.velocityMps.map { String(format: "%.2f", $0) } ?? ""
            let acc = sample.accelFwd.map { String(format: "%.2f", $0) } ?? ""
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
                state,
                dist,
                vel,
                acc
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

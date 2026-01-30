import Foundation
import CoreBluetooth

/// Mock Bluetooth service that simulates robot connection and IMU data
/// Use this for testing the app without hardware
@Observable
final class MockBluetoothService: NSObject {
    
    // MARK: - Published State (same interface as BluetoothService)
    
    private(set) var state: DeviceState = .disconnected
    private(set) var discoveredDevices: [CBPeripheral] = []
    private(set) var receivedData: String = ""
    
    // MARK: - Callbacks
    
    var onAttitudeReceived: ((Attitude) -> Void)?
    var onTelemetryReceived: ((Telemetry) -> Void)?
    
    // MARK: - Simulation State
    
    private var simulationTimer: Timer?
    private var time: Double = 0
    private var ledState: Bool = false
    
    // Simulated motion: last M: values drive a bias in the fake attitude
    private var lastThrottle: Double = 0
    private var lastTurn: Double = 0
    
    // MARK: - Public Methods (same interface as BluetoothService)
    
    func startScanning() {
        state = .scanning
        
        // Simulate finding a device after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.state = .disconnected
            // Note: We can't create real CBPeripheral objects, so we'll auto-connect
        }
    }
    
    func stopScanning() {
        if state == .scanning {
            state = .disconnected
        }
    }
    
    /// Simulate connecting (call this directly in mock mode). Does not start streaming; call startStreaming() to receive data.
    func simulateConnect() {
        state = .connecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.state = .connected
        }
    }

    func startStreaming() {
        guard state == .connected else { return }
        startSimulation()
    }

    func stopStreaming() {
        stopSimulation()
    }
    
    func connect(to peripheral: CBPeripheral) {
        // In mock mode, just simulate connection
        simulateConnect()
    }
    
    func disconnect() {
        stopSimulation()
        state = .disconnected
    }
    
    func send(_ command: Command) {
        switch command {
        case .ledToggle:
            ledState.toggle()
            print("[Mock] LED toggled: \(ledState ? "ON" : "OFF")")
        case .motor(let throttle, let turn):
            print("[Mock] Motor command: throttle=\(throttle), turn=\(turn)")
            lastThrottle = Double(throttle)
            lastTurn = Double(turn)
        case .disarm:
            print("[Mock] DISARM (arm down, then balance off)")
        case .arm:
            print("[Mock] ARM (arm up, balance on)")
        case .movementMode(let mode):
            print("[Mock] Movement mode: \(mode)")
        }
    }
    
    func sendRaw(_ string: String) {
        print("[Mock] Raw send: \(string)")
    }
    
    // MARK: - Simulation
    
    private func startSimulation() {
        time = 0
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.generateSimulatedData()
        }
    }
    
    private func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
    
    private func generateSimulatedData() {
        time += 0.1

        // Bias from last M: (throttle → pitch, turn → roll)
        let basePitch = lastThrottle * 3.0
        let baseRoll = lastTurn * 3.0

        let noise = { Double.random(in: -0.5...0.5) }
        let roll = baseRoll + 5.0 * sin(time * 0.5) + noise()
        let pitch = basePitch + 3.0 * sin(time * 0.7 + 1.0) + noise()
        let yaw = 2.0 * sin(time * 0.3) + noise()

        let attitude = Attitude(roll: roll, pitch: pitch, yaw: yaw)
        
        // Format like real UART data
        receivedData = String(format: "R:%.1f P:%.1f Y:%.1f", roll, pitch, yaw)
        
        onAttitudeReceived?(attitude)
        let telemetry = Telemetry(
            timestamp: time,
            roll: roll,
            pitch: pitch,
            yaw: yaw,
            left: nil,
            right: nil,
            balance: nil,
            targetPitchDeg: nil,
            mode: nil,
            enabled: true,
            state: nil
        )
        onTelemetryReceived?(telemetry)
    }
}

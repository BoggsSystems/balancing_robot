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
    
    // MARK: - Simulation State
    
    private var simulationTimer: Timer?
    private var time: Double = 0
    private var ledState: Bool = false
    
    // Simulated motion parameters
    private var baseRoll: Double = 0
    private var basePitch: Double = 0
    
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
            // Simulate motor effect on attitude
            basePitch += Double(throttle) * 0.1
            baseRoll += Double(turn) * 0.1
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
        
        // Simulate gentle oscillation like a balancing robot
        // Plus some noise to make it look realistic
        let noise = { Double.random(in: -0.5...0.5) }
        
        // Slow sine wave for base motion
        let roll = baseRoll + 5.0 * sin(time * 0.5) + noise()
        let pitch = basePitch + 3.0 * sin(time * 0.7 + 1.0) + noise()
        let yaw = 2.0 * sin(time * 0.3) + noise()
        
        // Decay the base offsets (simulate returning to center)
        baseRoll *= 0.98
        basePitch *= 0.98
        
        let attitude = Attitude(roll: roll, pitch: pitch, yaw: yaw)
        
        // Format like real UART data
        receivedData = String(format: "R:%.1f P:%.1f Y:%.1f", roll, pitch, yaw)
        
        onAttitudeReceived?(attitude)
    }
}

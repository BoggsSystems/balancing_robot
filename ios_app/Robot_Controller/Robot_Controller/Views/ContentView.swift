import SwiftUI

/// Root view that switches between connection and attitude views
struct ContentView: View {
    @State private var bluetoothService = BluetoothService()
    @State private var connectionViewModel: ConnectionViewModel?
    @State private var attitudeViewModel: AttitudeViewModel?
    
    var body: some View {
        Group {
            if bluetoothService.state.isConnected {
                if let viewModel = attitudeViewModel {
                    CommandControlView(viewModel: viewModel) {
                        viewModel.stopStreaming()
                        bluetoothService.disconnect()
                    }
                }
            } else {
                if let viewModel = connectionViewModel {
                    ConnectionView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
            connectionViewModel = ConnectionViewModel(bluetoothService: bluetoothService)
            attitudeViewModel = AttitudeViewModel(bluetoothService: bluetoothService)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Simulator Mode Content View

/// Use this view to test the app in simulator without real Bluetooth
struct SimulatorContentView: View {
    @State private var mockService = MockBluetoothService()
    @State private var attitudeViewModel: AttitudeViewModel?
    @State private var isConnected = false
    
    var body: some View {
        Group {
            if isConnected {
                if let viewModel = attitudeViewModel {
                    CommandControlView(viewModel: viewModel) {
                        viewModel.stopStreaming()
                        mockService.disconnect()
                        isConnected = false
                    }
                }
            } else {
                SimulatorConnectionView {
                    mockService.simulateConnect()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isConnected = true
                    }
                }
            }
        }
        .onAppear {
            attitudeViewModel = AttitudeViewModel(mockService: mockService)
        }
        .preferredColorScheme(.dark)
    }
}

/// Simplified connection view for simulator
struct SimulatorConnectionView: View {
    let onConnect: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Simulator Mode")
                .font(.title2.bold())
            
            Text("No real Bluetooth — using mock data")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Connect to Simulated Robot") {
                onConnect()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, 40)
        }
    }
}

// MARK: - E2E Mode Content View

/// Connects to e2e-bridge (imu-streamer | sim) for end-to-end testing.
struct E2EContentView: View {
    private let config = AppConfig.shared
    @State private var e2eService: E2EBluetoothService
    @State private var attitudeViewModel: AttitudeViewModel?
    @State private var showConfig = false

    init() {
        let c = AppConfig.shared
        _e2eService = State(initialValue: E2EBluetoothService(host: c.e2eHost, port: c.e2ePort))
    }

    var body: some View {
        Group {
            if e2eService.state.isConnected {
                if let viewModel = attitudeViewModel {
                    CommandControlView(viewModel: viewModel) {
                        viewModel.stopStreaming()
                        e2eService.disconnect()
                    }
                }
            } else {
                E2EConnectionView(
                    state: e2eService.state,
                    host: config.e2eHost,
                    port: config.e2ePort,
                    onConnect: { e2eService.connect() },
                    onReconfigure: { showConfig = true }
                )
            }
        }
        .onAppear {
            attitudeViewModel = AttitudeViewModel(bluetoothService: e2eService)
        }
        .sheet(isPresented: $showConfig) {
            NavigationStack {
                ConfigurationView(onSave: {
                    showConfig = false
                    applyConfigAndReconnect()
                })
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showConfig = false }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func applyConfigAndReconnect() {
        e2eService.disconnect()
        e2eService = E2EBluetoothService(host: config.e2eHost, port: config.e2ePort)
        attitudeViewModel = AttitudeViewModel(bluetoothService: e2eService)
    }
}

/// Connection view for E2E: connect to e2e-bridge on host; shows status; Reconfigure opens config sheet.
struct E2EConnectionView: View {
    let state: DeviceState
    let host: String
    let port: UInt16
    let onConnect: () -> Void
    let onReconfigure: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ConnectionStatusView(
                state: state,
                host: host,
                port: port
            )

            if case .connecting = state {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding()
            }

            Spacer()

            switch state {
            case .disconnected:
                Button("Connect to E2E Bridge") {
                    onConnect()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
            case .error:
                Button("Retry") {
                    onConnect()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
            case .connecting, .scanning, .connected:
                EmptyView()
            }

            Button("Reconfigure host & port") {
                onReconfigure()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.bottom, 40)
        }
    }
}

#Preview("Real Bluetooth") {
    ContentView()
}

#Preview("Simulator Mode") {
    SimulatorContentView()
}

#Preview("E2E Mode") {
    E2EContentView()
}

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
                    AttitudeView(viewModel: viewModel) {
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
                    AttitudeView(viewModel: viewModel) {
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
    @State private var e2eService = E2EBluetoothService()
    @State private var attitudeViewModel: AttitudeViewModel?
    
    var body: some View {
        Group {
            if e2eService.state.isConnected {
                if let viewModel = attitudeViewModel {
                    AttitudeView(viewModel: viewModel) {
                        viewModel.stopStreaming()
                        e2eService.disconnect()
                    }
                }
            } else {
                E2EConnectionView {
                    e2eService.connect()
                }
            }
        }
        .onAppear {
            attitudeViewModel = AttitudeViewModel(bluetoothService: e2eService)
        }
        .preferredColorScheme(.dark)
    }
}

/// Connection view for E2E: connect to e2e-bridge on host.
struct E2EConnectionView: View {
    let onConnect: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "cable.connector")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("E2E Mode")
                .font(.title2.bold())
            
            Text("Connect to e2e-bridge (imu-streamer | sim)")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button("Connect to E2E Bridge") {
                onConnect()
            }
            .buttonStyle(PrimaryButtonStyle())
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

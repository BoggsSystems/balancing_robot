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

#Preview("Real Bluetooth") {
    ContentView()
}

#Preview("Simulator Mode") {
    SimulatorContentView()
}

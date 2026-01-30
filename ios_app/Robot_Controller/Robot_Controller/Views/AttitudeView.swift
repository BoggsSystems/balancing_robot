import SwiftUI

/// Main view displaying live attitude data
struct AttitudeView: View {
    @Bindable var viewModel: AttitudeViewModel
    var onDisconnect: () -> Void
    @State private var joystickResetId = UUID()

    var body: some View {
        VStack(spacing: 24) {
            // Header with connection status
            HStack {
                Text("BalanceBot")
                    .font(.title2.bold())
                
                Spacer()
                
                StatusBadgeView(state: viewModel.connectionState)
            }
            .padding(.horizontal)

            // Start/Stop IMU streaming (connection is separate from initiation)
            Button(viewModel.isStreaming ? "Stop" : "Start") {
                if viewModel.isStreaming {
                    viewModel.stopStreaming()
                } else {
                    viewModel.startStreaming()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.isConnected)
            .opacity(viewModel.isConnected ? 1 : 0.6)
            
            // Horizon indicator
            HorizonView(roll: viewModel.attitude.roll, pitch: viewModel.attitude.pitch)
                .frame(height: 200)
                .padding(.horizontal)
            
            // Angle gauges
            HStack(spacing: 16) {
                AngleGaugeView(
                    label: "Roll",
                    angle: viewModel.attitude.roll,
                    severity: viewModel.attitude.rollSeverity
                )
                
                AngleGaugeView(
                    label: "Pitch",
                    angle: viewModel.attitude.pitch,
                    severity: viewModel.attitude.pitchSeverity
                )
                
                AngleGaugeView(
                    label: "Yaw",
                    angle: viewModel.attitude.yaw,
                    severity: viewModel.attitude.yawSeverity
                )
            }
            .padding(.horizontal)

            // Drive: E-Stop, Ready, Arm, Disarm, Joystick (enabled when streaming)
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Button("E-STOP") {
                        viewModel.eStop()
                        joystickResetId = UUID()
                    }
                    .buttonStyle(PrimaryButtonStyle(isDestructive: true))
                    .disabled(!viewModel.isConnected)

                    Button("Ready") {
                        viewModel.ready()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!viewModel.isConnected)

                    Button("Arm") {
                        viewModel.arm()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!viewModel.isConnected)

                    Button("Disarm") {
                        viewModel.disarm()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!viewModel.isConnected)
                }
                Text("Disarm: arm down, then balance off.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                JoystickView(
                    onChange: { viewModel.setDriveInput(throttle: $0, turn: $1) },
                    disabled: !viewModel.isStreaming
                )
                .id(joystickResetId)
            }
            .padding(.horizontal)

            MovementSelectionView(
                current: viewModel.currentMovement,
                queued: viewModel.queuedMovement,
                patterns: MovementPattern.all,
                isEnabled: viewModel.isStreaming,
                onSelect: { viewModel.selectMovement($0) }
            )
            .padding(.horizontal)

            Spacer()

            // Control panel
            ControlPanelView(
                ledState: viewModel.ledState,
                onToggleLED: { viewModel.toggleLED() }
            )
            .padding()
            
            // Disconnect button
            Button("Disconnect") {
                onDisconnect()
            }
            .buttonStyle(PrimaryButtonStyle(isDestructive: true))
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    let service = BluetoothService()
    let viewModel = AttitudeViewModel(bluetoothService: service)
    
    return AttitudeView(viewModel: viewModel, onDisconnect: {})
}

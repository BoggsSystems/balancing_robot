import SwiftUI

/// Command & Control screen: big green Start, joystick (manual default), movement selection.
struct CommandControlView: View {
    @Bindable var viewModel: AttitudeViewModel
    var onDisconnect: () -> Void
    @State private var joystickResetId = UUID()
    @State private var showMovementSelection = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with status
                HStack {
                    Text("Command & Control")
                        .font(.title2.bold())

                    Spacer()

                    StatusBadgeView(state: viewModel.connectionState)
                }
                .padding(.horizontal)

                // Big green Start button (initiates startup / streaming)
                if !viewModel.isStreaming {
                    Button("Start") {
                        viewModel.startStreaming()
                    }
                    .buttonStyle(StartButtonStyle())
                    .disabled(!viewModel.isConnected)
                    .opacity(viewModel.isConnected ? 1 : 0.6)
                    .padding(.horizontal)
                } else {
                    Button("Stop") {
                        viewModel.stopStreaming()
                        joystickResetId = UUID()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)
                }

                // Horizon and gauges (when streaming)
                if viewModel.isStreaming {
                    HorizonView(roll: viewModel.attitude.roll, pitch: viewModel.attitude.pitch)
                        .frame(height: 180)
                        .padding(.horizontal)

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
                }

                // Joystick (manual by default)
                VStack(spacing: 12) {
                    Text("Manual control")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    JoystickView(
                        onChange: { viewModel.setDriveInput(throttle: $0, turn: $1) },
                        disabled: !viewModel.isStreaming
                    )
                    .id(joystickResetId)
                }
                .padding(.horizontal)

                // Current movement + Select movement button
                VStack(spacing: 12) {
                    HStack {
                        Text("Movement")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        MovementBadgeCompact(pattern: viewModel.currentMovement)
                    }

                    Button {
                        showMovementSelection = true
                    } label: {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                            Text("Select movement")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!viewModel.isStreaming)
                    .opacity(viewModel.isStreaming ? 1 : 0.6)
                }
                .padding(.horizontal)

                // Safety controls
                VStack(spacing: 12) {
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
                }
                .padding(.horizontal)

                ControlPanelView(
                    ledState: viewModel.ledState,
                    onToggleLED: { viewModel.toggleLED() }
                )
                .padding(.horizontal)

                if viewModel.isStreaming {
                    TelemetryDashboardView(viewModel: viewModel)
                        .padding(.horizontal)
                }

                Button("Disconnect") {
                    onDisconnect()
                }
                .buttonStyle(PrimaryButtonStyle(isDestructive: true))
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(isPresented: $showMovementSelection) {
            MovementFlowView(
                viewModel: viewModel,
                onDismiss: { showMovementSelection = false }
            )
        }
        .preferredColorScheme(.dark)
    }
}

private struct MovementBadgeCompact: View {
    let pattern: MovementPattern

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: pattern.icon)
                .foregroundStyle(.blue)
            Text(pattern.name)
                .font(.subheadline.bold())
            Text(pattern.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    let service = MockBluetoothService()
    let viewModel = AttitudeViewModel(mockService: service)
    return CommandControlView(viewModel: viewModel, onDisconnect: {})
}

import SwiftUI

/// Main view displaying live attitude data
struct AttitudeView: View {
    @Bindable var viewModel: AttitudeViewModel
    var onDisconnect: () -> Void
    
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

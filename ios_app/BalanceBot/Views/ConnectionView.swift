import SwiftUI
import CoreBluetooth

/// View for scanning and connecting to Bluetooth devices
struct ConnectionView: View {
    @Bindable var viewModel: ConnectionViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Connect to Robot")
                    .font(.title2.bold())
                
                StatusBadgeView(state: viewModel.state)
            }
            .padding(.top, 40)
            
            // Device List
            if viewModel.discoveredDevices.isEmpty {
                VStack(spacing: 16) {
                    if viewModel.state == .scanning {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Searching for devices...")
                            .foregroundColor(.secondary)
                    } else {
                        Text("No devices found")
                            .foregroundColor(.secondary)
                        Text("Make sure your robot is powered on")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                List(viewModel.discoveredDevices, id: \.identifier) { device in
                    DeviceRow(device: device) {
                        viewModel.connect(to: device)
                    }
                }
                .listStyle(.insetGrouped)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if viewModel.state == .scanning {
                    Button("Stop Scanning") {
                        viewModel.stopScanning()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button("Scan for Devices") {
                        viewModel.startScanning()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.bottom, 40)
        }
    }
}

/// Row for displaying a discovered device
struct DeviceRow: View {
    let device: CBPeripheral
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name ?? "Unknown Device")
                    .font(.headline)
                
                Text(device.identifier.uuidString.prefix(8) + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Connect") {
                onConnect()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConnectionView(viewModel: ConnectionViewModel(bluetoothService: BluetoothService()))
}

import SwiftUI

/// Connection status display: icon, label, and optional detail.
struct ConnectionStatusView: View {
    let state: DeviceState
    let host: String?
    let port: UInt16?

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: statusIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(statusColor)
            }

            VStack(spacing: 4) {
                Text(statusTitle)
                    .font(.title2.bold())

                Text(statusSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let host, let port {
                    Text("\(host):\(port)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
    }

    private var statusColor: Color {
        switch state {
        case .connected: return .green
        case .scanning, .connecting: return .blue
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private var statusIcon: String {
        switch state {
        case .connected: return "checkmark.circle.fill"
        case .scanning, .connecting: return "antenna.radiowaves.left.and.right"
        case .disconnected: return "cable.connector"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var statusTitle: String {
        switch state {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .scanning: return "Scanning..."
        case .disconnected: return "Not connected"
        case .error(let msg): return "Error"
        }
    }

    private var statusSubtitle: String {
        switch state {
        case .connected: return "Ready to start"
        case .connecting, .scanning: return "Please wait"
        case .disconnected: return "Tap below to connect"
        case .error(let msg): return msg
        }
    }
}

#Preview("Disconnected") {
    ConnectionStatusView(state: .disconnected, host: "127.0.0.1", port: 9001)
}

#Preview("Connecting") {
    ConnectionStatusView(state: .connecting, host: nil, port: nil)
}

#Preview("Connected") {
    ConnectionStatusView(state: .connected, host: "127.0.0.1", port: 9001)
}

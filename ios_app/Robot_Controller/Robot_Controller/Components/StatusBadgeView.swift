import SwiftUI

/// Displays connection status with colored indicator
struct StatusBadgeView: View {
    let state: DeviceState
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.5), lineWidth: 2)
                        .scaleEffect(isPulsing ? 1.5 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                        .animation(
                            isPulsing ? .easeOut(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: isPulsing
                        )
                )
            
            Text(state.displayText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .connected:
            return .green
        case .scanning, .connecting:
            return .blue
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
    
    private var isPulsing: Bool {
        switch state {
        case .scanning, .connecting:
            return true
        default:
            return false
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusBadgeView(state: .disconnected)
        StatusBadgeView(state: .scanning)
        StatusBadgeView(state: .connecting)
        StatusBadgeView(state: .connected)
        StatusBadgeView(state: .error("Test error"))
    }
    .padding()
}

import SwiftUI

/// Control panel with LED toggle
struct ControlPanelView: View {
    let ledState: Bool
    let onToggleLED: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Controls")
                .font(.headline)
                .foregroundColor(.secondary)

            Button(action: onToggleLED) {
                VStack(spacing: 8) {
                    Image(systemName: ledState ? "lightbulb.fill" : "lightbulb")
                        .font(.system(size: 32))
                        .foregroundColor(ledState ? .yellow : .gray)

                    Text(ledState ? "LED ON" : "LED OFF")
                        .font(.caption.bold())
                        .foregroundColor(ledState ? .yellow : .secondary)
                }
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .shadow(color: ledState ? .yellow.opacity(0.3) : .clear, radius: 10)
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
}

#Preview {
    HStack(spacing: 24) {
        ControlPanelView(ledState: false, onToggleLED: {})
        ControlPanelView(ledState: true, onToggleLED: {})
    }
    .padding()
    .background(Color(.systemGray5))
}

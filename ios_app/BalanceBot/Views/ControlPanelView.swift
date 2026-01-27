import SwiftUI

/// Control panel with LED toggle and future motor controls
struct ControlPanelView: View {
    let ledState: Bool
    let onToggleLED: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Controls")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 24) {
                // LED Toggle Button
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
                
                // Placeholder for future controls
                VStack(spacing: 8) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Motors")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundColor(.gray.opacity(0.3))
                        )
                )
            }
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
    VStack(spacing: 40) {
        ControlPanelView(ledState: false, onToggleLED: {})
        ControlPanelView(ledState: true, onToggleLED: {})
    }
    .padding()
    .background(Color(.systemGray5))
}

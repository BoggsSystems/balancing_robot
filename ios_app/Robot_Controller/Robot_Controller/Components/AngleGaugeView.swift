import SwiftUI

/// Displays a single angle value with label and color coding
struct AngleGaugeView: View {
    let label: String
    let angle: Double
    let severity: AngleSeverity
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f°", angle))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(severityColor)
        }
        .frame(minWidth: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var severityColor: Color {
        switch severity {
        case .normal:
            return .green
        case .warning:
            return .yellow
        case .critical:
            return .red
        }
    }
}

#Preview {
    HStack {
        AngleGaugeView(label: "Roll", angle: 5.2, severity: .normal)
        AngleGaugeView(label: "Pitch", angle: -18.7, severity: .warning)
        AngleGaugeView(label: "Yaw", angle: 45.0, severity: .critical)
    }
    .padding()
}

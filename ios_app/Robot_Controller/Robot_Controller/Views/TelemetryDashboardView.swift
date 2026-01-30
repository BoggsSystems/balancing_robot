import SwiftUI

struct TelemetryDashboardView: View {
    @Bindable var viewModel: AttitudeViewModel
    @State private var exportURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Telemetry")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                if let url = exportURL {
                    ShareLink(item: url) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        exportURL = viewModel.exportTelemetryCSV()
                    } label: {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.telemetrySamples.isEmpty)
                }
            }

            HStack(spacing: 12) {
                TelemetryPill(title: "Mode", value: modeText)
                TelemetryPill(title: "Enabled", value: enabledText)
                TelemetryPill(title: "State", value: stateText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Pitch vs Target")
                    .font(.caption)
                    .foregroundColor(.secondary)
                LineChartView(values: pitchValues, lineColor: .blue)
                LineChartView(values: targetPitchValues, lineColor: .green)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Motor Commands (Left / Right)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                LineChartView(values: leftValues, lineColor: .orange)
                LineChartView(values: rightValues, lineColor: .purple)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Balance Output")
                    .font(.caption)
                    .foregroundColor(.secondary)
                LineChartView(values: balanceValues, lineColor: .pink)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }

    private var samples: [Telemetry] {
        viewModel.telemetrySamples
    }

    private var pitchValues: [Double] {
        samples.map { $0.pitch }
    }

    private var targetPitchValues: [Double] {
        samples.map { $0.targetPitchDeg ?? 0.0 }
    }

    private var leftValues: [Double] {
        samples.map { $0.left ?? 0.0 }
    }

    private var rightValues: [Double] {
        samples.map { $0.right ?? 0.0 }
    }

    private var balanceValues: [Double] {
        samples.map { $0.balance ?? 0.0 }
    }

    private var modeText: String {
        if let mode = viewModel.latestTelemetry?.mode {
            return "\(mode)"
        }
        return "-"
    }

    private var enabledText: String {
        if let enabled = viewModel.latestTelemetry?.enabled {
            return enabled ? "1" : "0"
        }
        return "-"
    }

    private var stateText: String {
        if let st = viewModel.latestTelemetry?.state {
            return "\(st)"
        }
        return "-"
    }
}

private struct TelemetryPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    let vm = AttitudeViewModel(mockService: MockBluetoothService())
    return TelemetryDashboardView(viewModel: vm)
        .padding()
}

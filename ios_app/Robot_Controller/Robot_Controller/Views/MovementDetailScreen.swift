import SwiftUI

/// Dedicated screen for a scripted movement: path, explanation, Execute, running feedback, complete.
struct MovementDetailScreen: View {
    let pattern: MovementPattern
    let viewModel: AttitudeViewModel
    let onBackToManual: () -> Void
    let onChooseAnother: () -> Void

    enum Phase {
        case ready
        case running
        case complete
    }

    @State private var phase: Phase = .ready
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 32) {
                Spacer()

                // Path visualization
                MovementPathView(pattern: pattern, isAnimating: phase == .running)
                .padding()

            // Name and explanation
            VStack(spacing: 8) {
                Text(pattern.name)
                    .font(.title.bold())

                Text(pattern.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let duration = pattern.duration {
                    Text("Duration: \(Int(duration)) seconds")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            Spacer()

            // Phase-specific content
            switch phase {
            case .ready:
                Button("Execute") {
                    executeMovement()
                }
                .buttonStyle(StartButtonStyle())
                .disabled(!viewModel.isStreaming)
                .opacity(viewModel.isStreaming ? 1 : 0.6)
                .padding(.horizontal, 32)

            case .running:
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Executing \(pattern.name)...")
                            .font(.headline)
                    }
                    if let duration = pattern.duration {
                        Text("\(Int(max(0, duration - elapsed)))s remaining")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

            case .complete:
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Complete")
                        .font(.title2.bold())
                }
                .padding()
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                if phase == .complete {
                    Button("Back to manual") {
                        viewModel.selectMovement(.manual)
                        onBackToManual()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)

                    Button("Choose another movement") {
                        onChooseAnother()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                } else if phase == .ready {
                    Button("Choose another movement") {
                        onChooseAnother()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Button("Back to manual") {
                        onBackToManual()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 40)
            }

            // Small attitude indicator (top-right)
            CompactAttitudeIndicator(roll: viewModel.attitude.roll, pitch: viewModel.attitude.pitch)
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if phase == .ready {
                    Button("Back") {
                        onChooseAnother()
                    }
                } else {
                    Button("Cancel") {
                        stopTimer()
                        onBackToManual()
                    }
                }
            }
        }
        .onDisappear {
            stopTimer()
        }
        .preferredColorScheme(.dark)
    }

    private func executeMovement() {
        viewModel.selectMovement(pattern)
        phase = .running
        elapsed = 0

        let duration = pattern.duration ?? 4
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            elapsed += 0.1
            if elapsed >= duration {
                stopTimer()
                DispatchQueue.main.async {
                    phase = .complete
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Compact Attitude Indicator

private struct CompactAttitudeIndicator: View {
    let roll: Double
    let pitch: Double

    var body: some View {
        VStack(spacing: 4) {
            HorizonView(roll: roll, pitch: pitch)
                .frame(width: 72, height: 72)

            HStack(spacing: 12) {
                Text("R:\(formatAngle(roll))")
                Text("P:\(formatAngle(pitch))")
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6).opacity(0.9))
        )
    }

    private func formatAngle(_ deg: Double) -> String {
        String(format: "%+.1f", deg)
    }
}

#Preview {
    NavigationStack {
        MovementDetailScreen(
            pattern: .circle,
            viewModel: AttitudeViewModel(mockService: MockBluetoothService()),
            onBackToManual: {},
            onChooseAnother: {}
        )
    }
}

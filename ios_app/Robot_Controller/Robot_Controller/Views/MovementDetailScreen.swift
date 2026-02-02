import SwiftUI
import CoreGraphics

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
    @State private var timer: Timer?
    @State private var movementStartDistance: Double?
    @StateObject private var movementRecorder = MovementRecorder()
    /// Path scale in meters for overhead plot; persisted per movement via UserDefaults.
    @State private var pathScaleM: Double = 1.0

    private static let pathScalePresets: [Double] = [0.5, 1, 2, 3]
    private static let pathScaleCustomRange: ClosedRange<Double> = 0.1...5.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 32) {
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

                        if let duration = effectiveDuration {
                            Text("Duration: \(Int(duration)) seconds")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                    // Phase-specific content
                    switch phase {
                    case .ready:
                        overheadPathSection
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
                            if let duration = effectiveDuration {
                                Text("\(Int(max(0, duration - movementRecorder.elapsed)))s remaining")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            movementTelemetryView(live: true)
                            if !movementChartValues.isEmpty {
                                movementChartSection
                            }
                            overheadPathSection
                        }
                        .padding()

                    case .complete:
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.green)

                            Text("Complete")
                                .font(.title2.bold())

                            movementTelemetryView(live: false)
                            if !movementChartValues.isEmpty {
                                movementChartSection
                            }
                            overheadPathSection
                        }
                        .padding()
                    }

                    // Actions
                    VStack(spacing: 12) {
                        if phase == .complete {
                            HStack(spacing: 12) {
                                Button("Repeat") {
                                    executeMovement()
                                }
                                .buttonStyle(StartButtonStyle())
                                .disabled(!viewModel.isStreaming)
                                .opacity(viewModel.isStreaming ? 1 : 0.6)
                                .frame(maxWidth: .infinity)

                                Button("Back to manual") {
                                    viewModel.selectMovement(.manual)
                                    onBackToManual()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .frame(maxWidth: .infinity)
                            }
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
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if phase == .running {
                        stopTimer()
                        viewModel.selectMovement(.manual)
                    }
                    onChooseAnother()
                } label: {
                    Label("Change movement", systemImage: "square.grid.2x2")
                }
            }
        }
        .onAppear {
            loadPathScale()
        }
        .onChange(of: pattern.id) { _, _ in
            loadPathScale()
        }
        .onChange(of: pathScaleM) { _, _ in
            savePathScale()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .complete {
                let dist = (viewModel.latestTelemetry?.distanceM ?? 0) - (movementStartDistance ?? 0)
                let pts = movementPathPoints
                print("[MovementDetail] complete samples=\(movementRecorder.samples.count) pathPoints=\(pts.count) displayedDist=\(String(format: "%.3f", dist)) firstDist=\(movementRecorder.samples.first?.distanceM.map { String(format: "%.3f", $0) } ?? "nil")")
            }
        }
        .preferredColorScheme(.dark)
    }

    /// Duration in seconds for this movement; scales with pathScaleM for distance-based patterns.
    private var effectiveDuration: TimeInterval? {
        let base = pattern.duration ?? 4
        guard pattern != .manual else { return nil }
        // Target speed ~0.5 m/s for distance-based movements
        let targetSpeedMps = 0.5
        switch pattern.mode {
        case 7:  // Square: perimeter = 4 * side
            return max(4, 4 * pathScaleM / targetSpeedMps)
        case 1:  // Circle: circumference = π * diameter
            return max(4, .pi * pathScaleM / targetSpeedMps)
        case 2, 3, 4, 8:  // Figure-8, Slalom: ~2π * extent
            return max(4, 2 * .pi * pathScaleM / targetSpeedMps)
        default:  // Spin, Stop-and-Go, Balance: fixed duration
            return base
        }
    }

    private func executeMovement() {
        viewModel.selectMovement(pattern, duration: effectiveDuration)
        phase = .running
        movementStartDistance = viewModel.latestTelemetry?.distanceM
        movementRecorder.clear()

        let duration = effectiveDuration ?? pattern.duration ?? 4
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [viewModel, movementRecorder] _ in
            movementRecorder.tick(interval: 0.1)
            if let t = viewModel.latestTelemetry {
                movementRecorder.append(t)
            }
            if movementRecorder.elapsed >= duration {
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

    private func loadPathScale() {
        let key = "pathScale_\(pattern.mode)"
        let saved = UserDefaults.standard.double(forKey: key)
        pathScaleM = saved > 0 ? saved : MovementPattern.defaultPathScaleM(for: pattern)
    }

    private func savePathScale() {
        UserDefaults.standard.set(pathScaleM, forKey: "pathScale_\(pattern.mode)")
    }

    private var movementChartValues: [Double] {
        let start = movementStartDistance ?? 0
        return movementRecorder.samples.map { ($0.distanceM ?? 0) - start }
    }

    private var movementVelocityValues: [Double] {
        movementRecorder.samples.map { $0.velocityMps ?? 0 }
    }

    /// Path points for this movement only. Uses the same distance values as the Distance-travelled chart so the plot always matches.
    private var movementPathPoints: [CGPoint] {
        let startDist = movementStartDistance ?? 0
        let distValues = movementRecorder.samples.map { ($0.distanceM ?? 0) - startDist }
        guard !distValues.isEmpty else { return [CGPoint(x: 0, y: 0)] }
        var pts: [CGPoint] = [CGPoint(x: 0, y: 0)]
        var lastX = 0.0
        var lastY = 0.0
        for (i, d) in distValues.enumerated() {
            let yawDeg = movementRecorder.samples[i].yaw
            let yawRad = yawDeg * .pi / 180
            let delta = (i == 0) ? d : (d - distValues[i - 1])
            lastX += delta * cos(yawRad)
            lastY += delta * sin(yawRad)
            pts.append(CGPoint(x: lastX, y: lastY))
        }
        return pts
    }

    private func movementTelemetryView(live: Bool) -> some View {
        let dist = (viewModel.latestTelemetry?.distanceM ?? 0) - (movementStartDistance ?? 0)
        let vel = viewModel.latestTelemetry?.velocityMps ?? 0
        let acc = viewModel.latestTelemetry?.accelFwd ?? 0
        return HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Distance")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.3f m", dist))
                    .font(.subheadline.bold().monospacedDigit())
            }
            VStack(spacing: 4) {
                Text("Velocity")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.2f m/s", vel))
                    .font(.subheadline.bold().monospacedDigit())
            }
            VStack(spacing: 4) {
                Text("Accel")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.2f m/s²", acc))
                    .font(.subheadline.bold().monospacedDigit())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private var movementChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Movement")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Text("Distance travelled")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                LineChartView(values: movementChartValues, lineColor: .cyan)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Velocity")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                LineChartView(values: movementVelocityValues, lineColor: .orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private var pathPointsToShow: [CGPoint] {
        let useMovementPath = !movementRecorder.samples.isEmpty && (phase == .running || phase == .complete)
        let displayedDist = (viewModel.latestTelemetry?.distanceM ?? 0) - (movementStartDistance ?? 0)
        let pts = useMovementPath ? movementPathPoints : viewModel.pathPoints
        if useMovementPath && pts.count >= 2 && pathIsInPlace(pts) && displayedDist > 0.005 {
            return [CGPoint(x: 0, y: 0), CGPoint(x: displayedDist, y: 0)]
        }
        return pts
    }

    private var overheadPathSection: some View {
        let useMovementPath = !movementRecorder.samples.isEmpty && (phase == .running || phase == .complete)
        let displayedDist = (viewModel.latestTelemetry?.distanceM ?? 0) - (movementStartDistance ?? 0)
        let isCustomScale = !Self.pathScalePresets.contains(pathScaleM)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Path (overhead)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if useMovementPath {
                    Text("(this movement)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if !useMovementPath && viewModel.pathPoints.count >= 2 {
                    Button("Clear path") {
                        viewModel.clearPath()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            pathScalePicker(isCustomScale: isCustomScale)
            OverheadPathView(
                points: pathPointsToShow,
                expectedWorldSizeM: pattern != .manual ? pathScaleM : nil
            )
            if pathPointsToShow.count >= 2 && pathIsInPlace(pathPointsToShow) && displayedDist <= 0.005 {
                Text("In place (no translation). Try Circle or Figure-8 for a visible path.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private func pathScalePicker(isCustomScale: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Path scale")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            HStack(spacing: 8) {
                ForEach(Self.pathScalePresets, id: \.self) { preset in
                    let isSelected = abs(pathScaleM - preset) < 0.01
                    Button {
                        pathScaleM = preset
                    } label: {
                        Text(preset >= 1 ? "\(Int(preset)) m" : String(format: "%.1f m", preset))
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.accentColor : Color(.systemGray5))
                            .foregroundColor(isSelected ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                if isCustomScale {
                    HStack(spacing: 8) {
                        Text("Custom")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f m", pathScaleM))
                            .font(.caption.monospacedDigit())
                            .frame(minWidth: 36, alignment: .trailing)
                        Stepper("", value: $pathScaleM, in: Self.pathScaleCustomRange, step: 0.1)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Button("Custom") {
                        let last = Self.pathScalePresets.last ?? 3
                        pathScaleM = min(last + 0.5, Self.pathScaleCustomRange.upperBound)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// True if path has no meaningful extent (e.g. Spin in place).
    private func pathIsInPlace(_ pts: [CGPoint]) -> Bool {
        guard pts.count >= 2 else { return false }
        let xs = pts.map(\.x)
        let ys = pts.map(\.y)
        let spanX = (xs.max() ?? 0) - (xs.min() ?? 0)
        let spanY = (ys.max() ?? 0) - (ys.min() ?? 0)
        return spanX < 0.01 && spanY < 0.01
    }
}

// MARK: - Overhead path (feedback from telemetry: velocity + yaw)

private struct OverheadPathView: View {
    let points: [CGPoint]
    /// When set (e.g. for a movement like Square), the plot is scaled so this world size fits; small paths stay visible.
    var expectedWorldSizeM: CGFloat? = nil

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let (scale, midX, midY) = scaleAndCenter(in: size)
            let cx = size.width / 2
            let cy = size.height / 2
            ZStack {
                // Grid (axes through center)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: cy))
                    path.addLine(to: CGPoint(x: size.width, y: cy))
                    path.move(to: CGPoint(x: cx, y: 0))
                    path.addLine(to: CGPoint(x: cx, y: size.height))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                // Path from feedback (overhead: x right, y up in world → y up on screen)
                Path { path in
                    guard points.count >= 2 else { return }
                    let p0 = screenPoint(points[0], cx: cx, cy: cy, scale: scale, midX: midX, midY: midY)
                    path.move(to: p0)
                    for i in 1..<points.count {
                        path.addLine(to: screenPoint(points[i], cx: cx, cy: cy, scale: scale, midX: midX, midY: midY))
                    }
                }
                .stroke(Color.cyan, lineWidth: 2)
                // Current position dot
                if let last = points.last {
                    let p = screenPoint(last, cx: cx, cy: cy, scale: scale, midX: midX, midY: midY)
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .position(p)
                }
            }
        }
        .frame(height: 180)
    }

    private func screenPoint(_ w: CGPoint, cx: CGFloat, cy: CGFloat, scale: CGFloat, midX: CGFloat, midY: CGFloat) -> CGPoint {
        CGPoint(x: cx + (w.x - midX) * scale, y: cy - (w.y - midY) * scale)
    }

    private func scaleAndCenter(in size: CGSize) -> (scale: CGFloat, midX: CGFloat, midY: CGFloat) {
        guard points.count >= 2 else { return (1, 0, 0) }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 0
        var spanX = max(maxX - minX, 0.01)
        var spanY = max(maxY - minY, 0.01)
        if let expected = expectedWorldSizeM, expected > 0 {
            spanX = max(spanX, expected)
            spanY = max(spanY, expected)
        }
        let pad: CGFloat = 24
        let scaleX = (size.width - 2 * pad) / spanX
        let scaleY = (size.height - 2 * pad) / spanY
        var scale = min(scaleX, scaleY)
        if expectedWorldSizeM == nil {
            scale = min(scale, 80)
        }
        let midX = (minX + maxX) / 2
        let midY = (minY + maxY) / 2
        return (scale, midX, midY)
    }
}

// MARK: - Movement telemetry recorder

private final class MovementRecorder: ObservableObject {
    @Published private(set) var samples: [Telemetry] = []
    @Published private(set) var elapsed: TimeInterval = 0
    private let maxSamples = 80

    func append(_ t: Telemetry) {
        samples.append(t)
        if samples.count > maxSamples {
            samples.removeFirst()
        }
    }

    func tick(interval: TimeInterval) {
        elapsed += interval
    }

    func clear() {
        samples = []
        elapsed = 0
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

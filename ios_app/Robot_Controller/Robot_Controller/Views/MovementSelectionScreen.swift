import SwiftUI

/// Full-screen movement picker: tiles for scripted movements. Select one to open detail screen.
struct MovementSelectionScreen: View {
    let current: MovementPattern
    let patterns: [MovementPattern]
    let onSelect: (MovementPattern) -> Void
    let onCancel: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(patterns) { pattern in
                    MovementTileView(
                        pattern: pattern,
                        isActive: pattern == current
                    )
                    .onTapGesture {
                        onSelect(pattern)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Select movement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
        }
    }
}

private struct MovementTileView: View {
    let pattern: MovementPattern
    let isActive: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: pattern.icon)
                .font(.system(size: 32))
                .foregroundStyle(isActive ? .green : .blue)

            Text(pattern.name)
                .font(.headline)

            Text(pattern.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if isActive {
                Text("Active")
                    .font(.caption2.bold())
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    MovementSelectionScreen(
        current: .manual,
        patterns: MovementPattern.all,
        onSelect: { _ in },
        onCancel: {}
    )
}

import SwiftUI

struct MovementSelectionView: View {
    let current: MovementPattern
    let queued: MovementPattern?
    let patterns: [MovementPattern]
    let isEnabled: Bool
    let onSelect: (MovementPattern) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Movements")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                MovementTile(
                    title: "Now Playing",
                    pattern: current,
                    isActive: true,
                    isQueued: false
                )
                MovementTile(
                    title: "Next Up",
                    pattern: queued ?? .manual,
                    isActive: false,
                    isQueued: queued != nil
                )
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(patterns) { pattern in
                    MovementCard(
                        pattern: pattern,
                        isActive: pattern == current,
                        isQueued: pattern == queued
                    )
                    .onTapGesture {
                        onSelect(pattern)
                    }
                    .opacity(isEnabled ? 1.0 : 0.5)
                    .allowsHitTesting(isEnabled)
                }
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

private struct MovementTile: View {
    let title: String
    let pattern: MovementPattern
    let isActive: Bool
    let isQueued: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            MovementBadge(pattern: pattern, isActive: isActive, isQueued: isQueued)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

private struct MovementCard: View {
    let pattern: MovementPattern
    let isActive: Bool
    let isQueued: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: pattern.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isActive ? .green : .blue)

            Text(pattern.name)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Text(pattern.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)

            if isActive {
                Text("Active")
                    .font(.caption2.bold())
                    .foregroundColor(.green)
            } else if isQueued {
                Text("Queued")
                    .font(.caption2.bold())
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

private struct MovementBadge: View {
    let pattern: MovementPattern
    let isActive: Bool
    let isQueued: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: pattern.icon)
                .foregroundColor(isActive ? .green : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(pattern.name)
                    .font(.subheadline.bold())
                Text(pattern.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isActive {
                Text("Live")
                    .font(.caption2.bold())
                    .foregroundColor(.green)
            } else if isQueued {
                Text("Next")
                    .font(.caption2.bold())
                    .foregroundColor(.orange)
            }
        }
    }
}

#Preview {
    MovementSelectionView(
        current: .circle,
        queued: .figure8Default,
        patterns: MovementPattern.all,
        isEnabled: true,
        onSelect: { _ in }
    )
    .padding()
    .background(Color(.systemGray5))
}

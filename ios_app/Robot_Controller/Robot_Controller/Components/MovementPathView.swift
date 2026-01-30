import SwiftUI

/// Path visualization for scripted movements (circle, figure-8, square, etc.)
struct MovementPathView: View {
    let pattern: MovementPattern
    var isAnimating: Bool = false

    var body: some View {
        ZStack {
            switch pattern.mode {
            case 1:
                CirclePathView(isAnimating: isAnimating)
            case 2, 3, 4:
                Figure8PathView(isAnimating: isAnimating)
            case 5:
                SpinPathView(isAnimating: isAnimating)
            case 6:
                StopGoPathView(isAnimating: isAnimating)
            case 7:
                SquarePathView(isAnimating: isAnimating)
            case 8:
                SlalomPathView(isAnimating: isAnimating)
            case 9, 10, 11:
                BalancePathView(pattern: pattern, isAnimating: isAnimating)
            default:
                Image(systemName: pattern.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
            }
        }
        .frame(width: 140, height: 140)
    }
}

private struct CirclePathView: View {
    let isAnimating: Bool

    var body: some View {
        Circle()
            .stroke(Color.blue, lineWidth: 4)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(isAnimating ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: isAnimating)
    }
}

private struct Figure8PathView: View {
    let isAnimating: Bool

    var body: some View {
        Figure8Shape()
            .stroke(Color.blue, lineWidth: 4)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(isAnimating ? .linear(duration: 3).repeatForever(autoreverses: false) : .default, value: isAnimating)
    }
}

private struct Figure8Shape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY
        let r = min(w, h) * 0.35
        return Path { path in
            path.move(to: CGPoint(x: cx, y: cy - r))
            path.addCurve(to: CGPoint(x: cx, y: cy + r),
                         control1: CGPoint(x: cx + r, y: cy - r),
                         control2: CGPoint(x: cx + r, y: cy + r))
            path.addCurve(to: CGPoint(x: cx, y: cy - r),
                         control1: CGPoint(x: cx - r, y: cy + r),
                         control2: CGPoint(x: cx - r, y: cy - r))
        }
    }
}

private struct SpinPathView: View {
    let isAnimating: Bool

    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 64))
            .foregroundStyle(.blue)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(isAnimating ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isAnimating)
    }
}

private struct StopGoPathView: View {
    let isAnimating: Bool

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isAnimating ? Color.blue : Color.blue.opacity(0.5))
                .frame(width: 24, height: 40)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.blue.opacity(0.3))
                .frame(width: 24, height: 40)
        }
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
    }
}

private struct SquarePathView: View {
    let isAnimating: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.blue, lineWidth: 4)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(isAnimating ? .linear(duration: 6).repeatForever(autoreverses: false) : .default, value: isAnimating)
    }
}

private struct SlalomPathView: View {
    let isAnimating: Bool

    var body: some View {
        SlalomShape()
            .stroke(Color.blue, lineWidth: 4)
    }
}

private struct SlalomShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let step = w / 4
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h * 0.2))
        p.addLine(to: CGPoint(x: step, y: h * 0.5))
        p.addLine(to: CGPoint(x: step * 2, y: h * 0.2))
        p.addLine(to: CGPoint(x: step * 3, y: h * 0.5))
        p.addLine(to: CGPoint(x: w, y: h * 0.2))
        return p
    }
}

private struct BalancePathView: View {
    let pattern: MovementPattern
    let isAnimating: Bool

    var body: some View {
        Image(systemName: pattern.icon)
            .font(.system(size: 64))
            .foregroundStyle(.blue)
    }
}

#Preview("Circle") {
    MovementPathView(pattern: .circle, isAnimating: true)
        .padding()
}

#Preview("Figure-8") {
    MovementPathView(pattern: .figure8Default, isAnimating: true)
        .padding()
}

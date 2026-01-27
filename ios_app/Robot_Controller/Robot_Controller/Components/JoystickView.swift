import SwiftUI

/// Virtual joystick: drag for throttle (up/down) and turn (left/right).
/// Release returns to center and reports 0,0. Disabled when !streaming.
struct JoystickView: View {
    var onChange: (Float, Float) -> Void
    var disabled: Bool = false

    private let size: CGFloat = 160
    private let thumbRadius: CGFloat = 24
    private var maxTravel: CGFloat { size / 2 - thumbRadius - 4 }

    @State private var thumbOffset: CGSize = .zero

    private var throttle: Float {
        Float(-thumbOffset.height / maxTravel)
    }
    private var turn: Float {
        Float(thumbOffset.width / maxTravel)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(Color(.systemGray3), lineWidth: 2)
                )

            // Thumb
            Circle()
                .fill(disabled ? Color(.systemGray3) : Color(.systemBlue))
                .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                .offset(thumbOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if disabled { return }
                            let dx = value.translation.width
                            let dy = value.translation.height
                            let d = sqrt(dx * dx + dy * dy)
                            if d > maxTravel {
                                let s = maxTravel / d
                                thumbOffset = CGSize(width: dx * s, height: dy * s)
                            } else {
                                thumbOffset = CGSize(width: dx, height: dy)
                            }
                            onChange(throttle, turn)
                        }
                        .onEnded { _ in
                            if disabled { return }
                            withAnimation(.easeOut(duration: 0.15)) {
                                thumbOffset = .zero
                            }
                            onChange(0, 0)
                        }
                )
        }
        .frame(width: size, height: size)
        .opacity(disabled ? 0.5 : 1)
        .allowsHitTesting(!disabled)
    }
}

#Preview("Enabled") {
    JoystickView(onChange: { t, r in print(" throttle:", t, " turn:", r) }, disabled: false)
}

#Preview("Disabled") {
    JoystickView(onChange: { _, _ in }, disabled: true)
}

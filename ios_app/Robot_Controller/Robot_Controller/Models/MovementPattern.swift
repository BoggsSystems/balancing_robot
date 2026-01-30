import Foundation

struct MovementPattern: Identifiable, Equatable {
    let id: Int
    let name: String
    let subtitle: String
    let mode: Int
    let duration: TimeInterval?
    let icon: String

    static let manual = MovementPattern(
        id: 0,
        name: "Manual",
        subtitle: "Joystick control",
        mode: 0,
        duration: nil,
        icon: "hand.tap"
    )

    static let circle = MovementPattern(
        id: 1,
        name: "Circle",
        subtitle: "Constant arc",
        mode: 1,
        duration: 4.0,
        icon: "arrow.triangle.2.circlepath"
    )

    static let figure8Default = MovementPattern(
        id: 2,
        name: "Figure-8",
        subtitle: "Default",
        mode: 2,
        duration: 4.0,
        icon: "infinity"
    )

    static let figure8Slow = MovementPattern(
        id: 3,
        name: "Figure-8",
        subtitle: "Slow / wide",
        mode: 3,
        duration: 6.0,
        icon: "infinity"
    )

    static let figure8Fast = MovementPattern(
        id: 4,
        name: "Figure-8",
        subtitle: "Fast / tight",
        mode: 4,
        duration: 3.0,
        icon: "infinity"
    )

    static let spin = MovementPattern(
        id: 5,
        name: "Spin",
        subtitle: "In place",
        mode: 5,
        duration: 3.0,
        icon: "arrow.clockwise"
    )

    static let stopAndGo = MovementPattern(
        id: 6,
        name: "Stop-and-Go",
        subtitle: "Burst / pause",
        mode: 6,
        duration: 4.0,
        icon: "pause.circle"
    )

    static let square = MovementPattern(
        id: 7,
        name: "Square",
        subtitle: "Hard turns",
        mode: 7,
        duration: 6.0,
        icon: "square"
    )

    static let slalom = MovementPattern(
        id: 8,
        name: "Slalom",
        subtitle: "Wide weave",
        mode: 8,
        duration: 4.0,
        icon: "waveform.path"
    )

    static let balanceHoldUp = MovementPattern(
        id: 9,
        name: "Balance",
        subtitle: "Hold +5°",
        mode: 9,
        duration: 6.0,
        icon: "level"
    )

    static let balanceHoldDown = MovementPattern(
        id: 10,
        name: "Balance",
        subtitle: "Hold -5°",
        mode: 10,
        duration: 6.0,
        icon: "level"
    )

    static let balanceOscillate = MovementPattern(
        id: 11,
        name: "Balance",
        subtitle: "Slow oscillation",
        mode: 11,
        duration: 10.0,
        icon: "waveform.path.ecg"
    )

    static let all: [MovementPattern] = [
        manual,
        circle,
        figure8Default,
        figure8Slow,
        figure8Fast,
        spin,
        stopAndGo,
        square,
        slalom,
        balanceHoldUp,
        balanceHoldDown,
        balanceOscillate
    ]
}

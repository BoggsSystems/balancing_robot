import Foundation

struct TelemetryParser {
    static func parse(_ line: String) -> Telemetry? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("R:") || trimmed.contains("P:") else {
            return nil
        }

        var roll: Double?
        var pitch: Double?
        var yaw: Double = 0.0
        var timestamp: Double?
        var left: Double?
        var right: Double?
        var balance: Double?
        var targetPitch: Double?
        var mode: Int?
        var enabled: Bool?
        var state: Int?

        let tokens = trimmed.split(separator: " ")
        for token in tokens {
            let str = String(token)
            if str.hasPrefix("T:") {
                timestamp = Double(str.dropFirst(2))
            } else if str.hasPrefix("R:") {
                roll = Double(str.dropFirst(2))
            } else if str.hasPrefix("P:") {
                pitch = Double(str.dropFirst(2))
            } else if str.hasPrefix("Y:") {
                yaw = Double(str.dropFirst(2)) ?? 0.0
            } else if str.hasPrefix("LM:") {
                left = Double(str.dropFirst(3))
            } else if str.hasPrefix("RM:") {
                right = Double(str.dropFirst(3))
            } else if str.hasPrefix("BAL:") {
                balance = Double(str.dropFirst(4))
            } else if str.hasPrefix("TP:") {
                targetPitch = Double(str.dropFirst(3))
            } else if str.hasPrefix("MODE:") {
                mode = Int(str.dropFirst(5))
            } else if str.hasPrefix("EN:") {
                if let val = Int(str.dropFirst(3)) {
                    enabled = (val != 0)
                }
            } else if str.hasPrefix("ST:") {
                state = Int(str.dropFirst(3))
            }
        }

        guard let r = roll, let p = pitch else {
            return nil
        }

        return Telemetry(
            timestamp: timestamp,
            roll: r,
            pitch: p,
            yaw: yaw,
            left: left,
            right: right,
            balance: balance,
            targetPitchDeg: targetPitch,
            mode: mode,
            enabled: enabled,
            state: state
        )
    }
}

import Foundation

/// Represents the orientation of the robot in 3D space
struct Attitude: Equatable {
    var roll: Double   // Rotation around X-axis (degrees)
    var pitch: Double  // Rotation around Y-axis (degrees)
    var yaw: Double    // Rotation around Z-axis (degrees)
    
    static let zero = Attitude(roll: 0, pitch: 0, yaw: 0)
    
    /// Color intensity based on angle magnitude (for UI)
    var rollSeverity: AngleSeverity { AngleSeverity(for: roll) }
    var pitchSeverity: AngleSeverity { AngleSeverity(for: pitch) }
    var yawSeverity: AngleSeverity { AngleSeverity(for: yaw) }
}

enum AngleSeverity {
    case normal    // Near zero (balanced)
    case warning   // Moderate tilt (10-30°)
    case critical  // Extreme tilt (>30°)
    
    init(for angle: Double) {
        let absAngle = abs(angle)
        if absAngle < 10 {
            self = .normal
        } else if absAngle < 30 {
            self = .warning
        } else {
            self = .critical
        }
    }
}

import Foundation

/// Commands that can be sent to the robot
enum Command {
    case ledToggle
    case motor(throttle: Float, turn: Float)
    /// Safe shutdown: firmware runs arm down → wait → disable balance.
    case disarm
    /// Ready/arm: retract arm and enable balance.
    case arm
    /// Scripted movement mode (0 = manual).
    case movementMode(Int)

    /// Convert command to string for UART transmission
    var serialized: String {
        switch self {
        case .ledToggle:
            return "LED\n"
        case .motor(let throttle, let turn):
            return String(format: "M:%.1f,%.1f\n", throttle, turn)
        case .disarm:
            return "DISARM\n"
        case .arm:
            return "ARM\n"
        case .movementMode(let mode):
            return "MODE:\(mode)\n"
        }
    }
    
    /// Convert to Data for Bluetooth transmission
    var data: Data {
        Data(serialized.utf8)
    }
}

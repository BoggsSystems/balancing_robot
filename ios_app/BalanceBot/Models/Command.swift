import Foundation

/// Commands that can be sent to the robot
enum Command {
    case ledToggle
    case motor(throttle: Float, turn: Float)
    
    /// Convert command to string for UART transmission
    var serialized: String {
        switch self {
        case .ledToggle:
            return "LED\n"
        case .motor(let throttle, let turn):
            return String(format: "M:%.1f,%.1f\n", throttle, turn)
        }
    }
    
    /// Convert to Data for Bluetooth transmission
    var data: Data {
        Data(serialized.utf8)
    }
}

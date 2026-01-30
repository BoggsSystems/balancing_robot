import Foundation

struct Telemetry: Equatable {
    var timestamp: Double?
    var roll: Double
    var pitch: Double
    var yaw: Double
    var left: Double?
    var right: Double?
    var balance: Double?
    var targetPitchDeg: Double?
    var mode: Int?
    var enabled: Bool?
    var state: Int?

    var attitude: Attitude {
        Attitude(roll: roll, pitch: pitch, yaw: yaw)
    }
}

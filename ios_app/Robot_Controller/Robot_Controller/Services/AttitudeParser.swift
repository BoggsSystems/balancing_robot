import Foundation

/// Parses attitude data from UART string format
/// Expected format: "R:12.3 P:-4.5\r\n" or "R:12.3 P:-4.5 Y:0.0\r\n"
struct AttitudeParser {
    
    /// Parse a line of attitude data
    /// - Parameter line: Raw string from UART (e.g., "R:12.3 P:-4.5")
    /// - Returns: Attitude if parsing succeeds, nil otherwise
    static func parse(_ line: String) -> Attitude? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var roll: Double?
        var pitch: Double?
        var yaw: Double = 0.0
        
        // Split by whitespace and parse each component
        let components = trimmed.split(separator: " ")
        
        for component in components {
            let str = String(component)
            
            if str.hasPrefix("R:") {
                roll = Double(str.dropFirst(2))
            } else if str.hasPrefix("P:") {
                pitch = Double(str.dropFirst(2))
            } else if str.hasPrefix("Y:") {
                yaw = Double(str.dropFirst(2)) ?? 0.0
            }
        }
        
        // Roll and Pitch are required
        guard let r = roll, let p = pitch else {
            return nil
        }
        
        return Attitude(roll: r, pitch: p, yaw: yaw)
    }
}

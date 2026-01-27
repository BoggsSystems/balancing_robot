import SwiftUI

@main
struct BalanceBotApp: App {
    
    /// Set to true to use simulated data (for iOS Simulator or testing)
    /// In production, set to false to use real Bluetooth
    #if targetEnvironment(simulator)
    private let useSimulator = true
    #else
    private let useSimulator = false
    #endif
    
    var body: some Scene {
        WindowGroup {
            if useSimulator {
                SimulatorContentView()
            } else {
                ContentView()
            }
        }
    }
}

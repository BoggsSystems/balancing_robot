import SwiftUI

@main
struct BalanceBotApp: App {
    
    /// Set to true to use E2E bridge (for iOS Simulator or testing). Real Bluetooth on device.
    #if targetEnvironment(simulator)
    private let useSimulator = true
    #else
    private let useSimulator = false
    #endif
    
    var body: some Scene {
        WindowGroup {
            if useSimulator {
                E2EContentView()
            } else {
                ContentView()
            }
        }
    }
}

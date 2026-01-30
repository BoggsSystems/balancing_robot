import Foundation

/// App-wide configuration persisted in UserDefaults (onboarding state, E2E host/port).
@Observable
final class AppConfig {

    static let shared = AppConfig()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasCompletedOnboarding = "AppConfig.hasCompletedOnboarding"
        static let e2eHost = "AppConfig.e2eHost"
        static let e2ePort = "AppConfig.e2ePort"
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    var e2eHost: String {
        get { defaults.string(forKey: Keys.e2eHost) ?? "127.0.0.1" }
        set { defaults.set(newValue, forKey: Keys.e2eHost) }
    }

    var e2ePort: UInt16 {
        get {
            let p = defaults.integer(forKey: Keys.e2ePort)
            return p > 0 ? UInt16(p) : 9001
        }
        set { defaults.set(Int(newValue), forKey: Keys.e2ePort) }
    }

    private init() {}
}

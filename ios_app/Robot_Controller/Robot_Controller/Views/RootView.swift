import SwiftUI

/// Root view: onboarding or main content based on AppConfig.hasCompletedOnboarding.
struct RootView: View {
    /// Use @State so Save triggers a re-render; @Observable doesn't track computed props that write to UserDefaults.
    @State private var hasCompletedOnboarding = AppConfig.shared.hasCompletedOnboarding

    #if targetEnvironment(simulator)
    private let useSimulator = true
    #else
    private let useSimulator = false
    #endif

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                if useSimulator {
                    E2EContentView()
                } else {
                    ContentView()
                }
            } else {
                OnboardingContainerView(onComplete: {
                    AppConfig.shared.hasCompletedOnboarding = true
                    hasCompletedOnboarding = true
                })
            }
        }
    }
}

#Preview {
    RootView()
}

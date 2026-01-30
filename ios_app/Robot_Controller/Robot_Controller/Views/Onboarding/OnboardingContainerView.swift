import SwiftUI

/// Onboarding flow: Capabilities carousel (intro to features) → Configuration → Main.
struct OnboardingContainerView: View {
    var onComplete: () -> Void

    enum Step: Int, CaseIterable {
        case capabilities
        case configuration
    }

    @State private var step: Step = .capabilities

    var body: some View {
        Group {
            switch step {
            case .capabilities:
                CapabilitiesCarouselView(onGetStarted: { step = .configuration })
            case .configuration:
                NavigationStack {
                    ConfigurationView(
                        onSave: finish,
                        onBack: { step = .capabilities }
                    )
                }
            }
        }
        .animation(.easeInOut, value: step)
    }

    private func finish() {
        onComplete()
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
}

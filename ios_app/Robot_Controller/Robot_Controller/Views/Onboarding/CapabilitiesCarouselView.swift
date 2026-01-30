import SwiftUI

/// Carousel introducing the robot's features first. User explores capabilities before configuration.
struct CapabilitiesCarouselView: View {
    var onGetStarted: () -> Void

    @State private var currentPage = 0

    private let pages: [(title: String, subtitle: String, icon: String)] = [
        ("Robot Controller", "Your balancing robot companion. Swipe to explore what it can do.", "figure.stand.line.dotted.figure.stand"),
        ("Manual", "Drive with the joystick: throttle (forward/back) and turn (left/right).", "hand.tap"),
        ("Scripted", "Circle, Figure-8, Spin, Square, Slalom, Stop-and-Go — pre-programmed motions.", "arrow.triangle.2.circlepath"),
        ("Balance challenge", "Hold tilt +5°, −5°, or slow oscillation — no drive, just balance.", "level"),
        ("Safety", "E-Stop zeros drive immediately. Disarm: arm down, then balance off.", "exclamationmark.triangle.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Image(systemName: page.icon)
                            .font(.system(size: 56))
                            .foregroundStyle(.orange.gradient)

                        Text(page.title)
                            .font(.title2.bold())

                        Text(page.subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            HStack(spacing: 16) {
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        onGetStarted()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                Button(currentPage == pages.count - 1 ? "Get started" : "Next") {
                    if currentPage == pages.count - 1 {
                        onGetStarted()
                    } else {
                        currentPage += 1
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
            }
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    CapabilitiesCarouselView(onGetStarted: {})
}

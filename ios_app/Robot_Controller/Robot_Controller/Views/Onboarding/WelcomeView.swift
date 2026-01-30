import SwiftUI

/// Intro screen: app name, short description, Get started.
struct WelcomeView: View {
    var onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.stand.line.dotted.figure.stand")
                .font(.system(size: 72))
                .foregroundStyle(.orange.gradient)

            VStack(spacing: 12) {
                Text("Robot Controller")
                    .font(.title.bold())

                Text("Connect to your balancing robot via the E2E bridge (simulator) or Bluetooth (hardware). Start streaming, drive with the joystick, and use scripted movements.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Get started") {
                onGetStarted()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    WelcomeView(onGetStarted: {})
}

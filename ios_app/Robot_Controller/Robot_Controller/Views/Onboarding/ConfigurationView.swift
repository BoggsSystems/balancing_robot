import SwiftUI

/// Configuration: E2E host and port. Save persists to AppConfig.
struct ConfigurationView: View {
    @Bindable private var config = AppConfig.shared
    var onSave: () -> Void
    var onBack: (() -> Void)? = nil

    @State private var hostText: String = ""
    @State private var portText: String = ""

    var body: some View {
        Form {
            Section {
                Text("Connect to the e2e-bridge running on your Mac (e.g. `make e2e-bridge`). Use 127.0.0.1 when running the app in the Simulator.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("E2E Bridge")
            }

            Section {
                TextField("Host", text: $hostText)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                TextField("Port", text: $portText)
                    .keyboardType(.numberPad)
            } header: {
                Text("Connection")
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hostText = config.e2eHost
            portText = String(config.e2ePort)
        }
        .toolbar {
            if let onBack {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { onBack() }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    saveAndContinue()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveAndContinue() {
        if !hostText.isEmpty { config.e2eHost = hostText.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let p = UInt16(portText), p > 0 { config.e2ePort = p }
        onSave()
    }
}

#Preview {
    NavigationStack {
        ConfigurationView(onSave: {})
    }
}

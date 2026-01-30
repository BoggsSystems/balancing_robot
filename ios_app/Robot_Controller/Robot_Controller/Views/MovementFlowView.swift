import SwiftUI

/// Coordinates movement selector → detail → execute flow. Selector shows tiles; selecting navigates to detail screen.
struct MovementFlowView: View {
    let viewModel: AttitudeViewModel
    let onDismiss: () -> Void

    @State private var selectedPattern: MovementPattern?

    private var scriptedPatterns: [MovementPattern] {
        MovementPattern.all.filter { $0 != .manual }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let pattern = selectedPattern {
                    MovementDetailScreen(
                        pattern: pattern,
                        viewModel: viewModel,
                        onBackToManual: {
                            selectedPattern = nil
                            onDismiss()
                        },
                        onChooseAnother: {
                            selectedPattern = nil
                        }
                    )
                } else {
                    MovementSelectionScreen(
                        current: viewModel.currentMovement,
                        patterns: scriptedPatterns,
                        onSelect: { pattern in
                            selectedPattern = pattern
                        },
                        onCancel: onDismiss
                    )
                }
            }
            .navigationBarBackButtonHidden(selectedPattern != nil)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MovementFlowView(
        viewModel: AttitudeViewModel(mockService: MockBluetoothService()),
        onDismiss: {}
    )
}

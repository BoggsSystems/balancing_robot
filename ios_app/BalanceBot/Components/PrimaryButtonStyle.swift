import SwiftUI

/// Consistent button styling for primary actions
struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDestructive ? Color.red : Color.blue)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style for less prominent actions
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

#Preview {
    VStack(spacing: 20) {
        Button("Connect") {}
            .buttonStyle(PrimaryButtonStyle())
        
        Button("Disconnect") {}
            .buttonStyle(PrimaryButtonStyle(isDestructive: true))
        
        Button("Scan Again") {}
            .buttonStyle(SecondaryButtonStyle())
    }
    .padding()
}

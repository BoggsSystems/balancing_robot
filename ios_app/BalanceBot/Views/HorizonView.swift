import SwiftUI

/// Artificial horizon indicator showing roll and pitch visually
struct HorizonView: View {
    let roll: Double   // degrees
    let pitch: Double  // degrees
    
    // Scale factor for pitch visualization (pixels per degree)
    private let pitchScale: CGFloat = 3.0
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 10
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                
                // Clipped horizon
                Circle()
                    .fill(Color.clear)
                    .overlay(
                        HorizonGradient(pitch: pitch, pitchScale: pitchScale)
                            .rotationEffect(.degrees(-roll))
                    )
                    .clipShape(Circle().inset(by: 2))
                
                // Center crosshair (fixed reference)
                CrosshairView()
                    .frame(width: 60, height: 60)
                
                // Roll indicator arc
                RollIndicatorView(roll: roll, radius: radius)
                
                // Pitch ladder (rotates with roll)
                PitchLadderView(pitch: pitch, pitchScale: pitchScale)
                    .rotationEffect(.degrees(-roll))
                    .frame(width: radius * 1.5, height: radius * 1.5)
            }
            .position(center)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Gradient background representing sky and ground
struct HorizonGradient: View {
    let pitch: Double
    let pitchScale: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let offset = CGFloat(pitch) * pitchScale
            
            VStack(spacing: 0) {
                // Sky
                LinearGradient(
                    colors: [Color.blue.opacity(0.7), Color.cyan.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Horizon line
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 2)
                
                // Ground
                LinearGradient(
                    colors: [Color.brown.opacity(0.6), Color.brown.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .offset(y: offset)
        }
    }
}

/// Fixed center crosshair
struct CrosshairView: View {
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 40, height: 3)
            
            // Wing tips
            HStack(spacing: 30) {
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 15, height: 3)
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 15, height: 3)
            }
            
            // Center dot
            Circle()
                .fill(Color.yellow)
                .frame(width: 8, height: 8)
        }
    }
}

/// Roll indicator marks around the edge
struct RollIndicatorView: View {
    let roll: Double
    let radius: CGFloat
    
    var body: some View {
        ZStack {
            // Roll scale marks at standard angles
            ForEach([-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60], id: \.self) { angle in
                RollMark(angle: Double(angle), radius: radius, isLarge: angle % 30 == 0)
            }
            
            // Current roll indicator (triangle)
            Triangle()
                .fill(Color.white)
                .frame(width: 12, height: 10)
                .rotationEffect(.degrees(180))
                .offset(y: -radius + 15)
                .rotationEffect(.degrees(-roll))
        }
    }
}

struct RollMark: View {
    let angle: Double
    let radius: CGFloat
    let isLarge: Bool
    
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 2, height: isLarge ? 15 : 8)
            .offset(y: -radius + (isLarge ? 7 : 4))
            .rotationEffect(.degrees(angle))
    }
}

/// Pitch ladder showing degree markers
struct PitchLadderView: View {
    let pitch: Double
    let pitchScale: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let center = geometry.size.height / 2
            let offset = CGFloat(pitch) * pitchScale
            
            ZStack {
                ForEach([-20, -10, 10, 20], id: \.self) { angle in
                    PitchLine(angle: angle)
                        .position(x: geometry.size.width / 2,
                                  y: center - CGFloat(angle) * pitchScale + offset)
                }
            }
        }
    }
}

struct PitchLine: View {
    let angle: Int
    
    var body: some View {
        HStack(spacing: 20) {
            Text("\(angle)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: angle == 0 ? 80 : 40, height: 2)
            
            Text("\(angle)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

/// Simple triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack {
        HorizonView(roll: 15, pitch: -10)
            .frame(width: 250, height: 250)
        
        HorizonView(roll: -30, pitch: 20)
            .frame(width: 250, height: 250)
    }
    .background(Color.black)
}

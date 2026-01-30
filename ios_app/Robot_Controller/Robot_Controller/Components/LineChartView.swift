import SwiftUI

struct LineChartView: View {
    let values: [Double]
    let lineColor: Color

    var body: some View {
        GeometryReader { geo in
            let points = normalizedPoints(in: geo.size)
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for p in points.dropFirst() {
                    path.addLine(to: p)
                }
            }
            .stroke(lineColor, lineWidth: 2)
        }
        .frame(height: 80)
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 1
        let range = max(maxVal - minVal, 1e-6)

        return values.enumerated().map { idx, v in
            let x = size.width * CGFloat(idx) / CGFloat(max(values.count - 1, 1))
            let y = size.height * (1.0 - CGFloat((v - minVal) / range))
            return CGPoint(x: x, y: y)
        }
    }
}

#Preview {
    LineChartView(values: [0, 1, 0.5, 1.2, 0.8], lineColor: .blue)
        .padding()
}

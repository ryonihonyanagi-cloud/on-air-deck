import SwiftUI

struct WaveformView: View {
    let url: URL?
    let color: Color
    var progress: Double = 0
    var barCount: Int = 64
    @State private var peaks: [Double] = Array(repeating: 0.25, count: 64)

    var body: some View {
        GeometryReader { geometry in
            let gap: CGFloat = 2
            let width = max(1, (geometry.size.width - gap * CGFloat(peaks.count - 1)) / CGFloat(peaks.count))
            HStack(alignment: .center, spacing: gap) {
                ForEach(Array(peaks.enumerated()), id: \.offset) { index, peak in
                    Capsule()
                        .fill(Double(index) / Double(max(1, peaks.count - 1)) <= progress ? color : color.opacity(0.38))
                        .frame(width: width, height: max(2, geometry.size.height * peak))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: url) {
            guard let url else { return }
            let count = barCount
            let values = await Task.detached(priority: .utility) {
                WaveformAnalyzer.peaks(url: url, count: count)
            }.value
            peaks = values
        }
        .accessibilityHidden(true)
    }
}


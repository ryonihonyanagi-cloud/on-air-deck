import AVFoundation
import Foundation

enum WaveformAnalyzer {
    static func peaks(url: URL, count: Int = 72) -> [Double] {
        guard let file = try? AVAudioFile(forReading: url) else { return Array(repeating: 0.18, count: count) }
        let format = file.processingFormat
        let capacity = AVAudioFrameCount(min(file.length, 12_000_000))
        guard capacity > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            return Array(repeating: 0.18, count: count)
        }
        do { try file.read(into: buffer, frameCount: capacity) } catch {
            return Array(repeating: 0.18, count: count)
        }
        guard let channels = buffer.floatChannelData else { return Array(repeating: 0.18, count: count) }
        let frames = Int(buffer.frameLength)
        let stride = max(1, frames / count)
        var values: [Double] = []
        values.reserveCapacity(count)
        for bucket in 0..<count {
            let start = min(frames, bucket * stride)
            let end = min(frames, start + stride)
            guard start < end else { values.append(0.05); continue }
            var peak: Float = 0
            var index = start
            let sampleStep = max(1, stride / 256)
            while index < end {
                peak = max(peak, abs(channels[0][index]))
                index += sampleStep
            }
            values.append(Double(min(1, max(0.04, sqrt(peak)))))
        }
        let maxValue = values.max() ?? 1
        return values.map { maxValue > 0 ? $0 / maxValue : $0 }
    }
}


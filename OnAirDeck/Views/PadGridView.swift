import AVFoundation
import SwiftUI

struct PadGridView: View {
    @EnvironmentObject private var store: DeckStore
    let compact: Bool

    var body: some View {
        VStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 7) {
                    ForEach(0..<4, id: \.self) { column in
                        let index = row * 4 + column
                        if store.pads.indices.contains(index) {
                            SoundPadView(pad: store.pads[index], number: index + 1, compact: compact)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}

struct SoundPadView: View {
    @EnvironmentObject private var store: DeckStore
    @EnvironmentObject private var audio: AudioController
    let pad: SoundPad
    let number: Int
    let compact: Bool
    @State private var isHovered = false
    @State private var isDropTarget = false
    @State private var duration: TimeInterval = 0

    private var isPlaying: Bool { audio.activePadIDs.contains(pad.id) }
    private var progress: Double { audio.padProgress[pad.id] ?? 0 }
    private var fileURL: URL? { store.url(for: pad) }

    var body: some View {
        Button {
            if isPlaying { audio.stopPad(pad.id) }
            else { audio.playPad(pad, url: fileURL) }
        } label: {
            VStack(alignment: .leading, spacing: compact ? 5 : 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%02d", number))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(isPlaying ? pad.category.color : DeckPalette.live)
                    Text(pad.title)
                        .font(.system(size: compact ? 14 : 16, weight: .bold, design: .rounded))
                        .tracking(0.7)
                        .foregroundStyle(DeckPalette.ivory)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(pad.hotkey)
                        .font(.system(size: compact ? 24 : 31, weight: .black, design: .rounded))
                        .foregroundStyle(isPlaying ? pad.category.color : DeckPalette.ivory.opacity(0.92))
                }

                HStack(spacing: 10) {
                    Text(L10n.text(pad.category.rawValue))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.1)
                        .foregroundStyle(pad.category.color)
                    Spacer()
                    Text(duration.shortTime)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(DeckPalette.muted)
                }

                WaveformView(url: fileURL, color: pad.category.color, progress: progress, barCount: compact ? 48 : 64)
                    .frame(height: compact ? 25 : 36)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.10))
                        Capsule()
                            .fill(pad.category.color)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 3)
            }
            .padding(.horizontal, compact ? 14 : 17)
            .padding(.vertical, compact ? 10 : 13)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                ZStack {
                    DeckPalette.surface
                    if isDropTarget { pad.category.color.opacity(0.16) }
                    else if isPlaying { pad.category.color.opacity(0.09) }
                    else if isHovered { Color.white.opacity(0.025) }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        isDropTarget ? pad.category.color : (isPlaying ? pad.category.color : (isHovered ? DeckPalette.ivory.opacity(0.28) : DeckPalette.border)),
                        lineWidth: isDropTarget ? 2 : (isPlaying ? 1.5 : 1)
                    )
            )
            .overlay {
                if isDropTarget {
                    ZStack {
                        DeckPalette.background.opacity(0.86)
                        VStack(spacing: 5) {
                            Image(systemName: "waveform.badge.plus")
                                .font(.system(size: compact ? 19 : 23, weight: .bold))
                            Text(L10n.text("DROP AUDIO"))
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .tracking(1.1)
                        }
                        .foregroundStyle(pad.category.color)
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .shadow(color: isPlaying ? pad.category.color.opacity(0.22) : .clear, radius: 12)
            .scaleEffect(isHovered && !isPlaying ? 1.008 : 1)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.12), value: isPlaying)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button(L10n.text("Change Audio…")) { store.chooseAudio(for: pad.id) }
            if isPlaying { Button(L10n.text("Stop")) { audio.stopPad(pad.id) } }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            store.importFile(url, for: pad.id)
            return true
        } isTargeted: { isDropTarget = $0 }
        .task(id: fileURL) {
            guard let fileURL else { duration = 0; return }
            duration = await Task.detached(priority: .utility) {
                (try? AVAudioPlayer(contentsOf: fileURL).duration) ?? 0
            }.value
        }
        .accessibilityLabel(L10n.format("%@, %@, shortcut %@", pad.title, L10n.text(pad.category.rawValue), pad.hotkey))
        .accessibilityValue(L10n.text(isPlaying ? "Playing" : "Ready"))
    }
}

private extension TimeInterval {
    var shortTime: String {
        let total = max(0, Int(self.rounded()))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

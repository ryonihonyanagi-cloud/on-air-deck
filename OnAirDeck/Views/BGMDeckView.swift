import AVFoundation
import SwiftUI

struct BGMDeckView: View {
    @EnvironmentObject private var store: DeckStore
    @EnvironmentObject private var audio: AudioController
    let compact: Bool
    @State private var loadedDuration: TimeInterval = 0
    @State private var isDropTarget = false
    @State private var showLibrary = false

    private var track: BGMTrack? { store.selectedTrack }
    private var trackURL: URL? { track.flatMap(store.url(for:)) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Text("BGM DECK")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(DeckPalette.gold)

                Button {
                    showLibrary.toggle()
                } label: {
                    HStack(spacing: 7) {
                        Text(track?.title ?? L10n.text("SELECT TRACK"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(DeckPalette.ivory)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DeckPalette.gold)
                    }
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help("Open BGM library")
                .popover(isPresented: $showLibrary, arrowEdge: .bottom) {
                    BGMLibraryPopover(isPresented: $showLibrary)
                        .environmentObject(store)
                        .environmentObject(audio)
                }

                Text(track?.subtitle ?? "")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DeckPalette.gold.opacity(0.85))

                Text("\(store.bgmTracks.count) TRACKS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(DeckPalette.muted)

                Button {
                    store.chooseBGM()
                } label: {
                    Label("ADD", systemImage: "plus")
                }
                .buttonStyle(DeckTextButtonStyle())
                .help("Add multiple BGM files")

                Button {
                    guard let track else { return }
                    audio.stopBGM()
                    store.removeBGM(track.id)
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 14)
                }
                .buttonStyle(DeckTextButtonStyle())
                .disabled(track == nil)
                .opacity(track == nil ? 0.35 : 1)
                .help("Remove selected BGM from library")

                Spacer()

                Button { audio.setLoop(!audio.loopBGM) } label: {
                    Label("LOOP", systemImage: "repeat")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(audio.loopBGM ? DeckPalette.gold : DeckPalette.muted)
                }
                .buttonStyle(.plain)

                Button { if let track { audio.fadeInBGM(track, url: trackURL) } } label: {
                    Text("FADE IN  2s")
                }
                .buttonStyle(DeckTextButtonStyle())

                Button { audio.fadeOutBGM() } label: {
                    Text("FADE OUT  2s")
                }
                .buttonStyle(DeckTextButtonStyle())
            }
            .frame(height: compact ? 38 : 46)

            Divider().overlay(DeckPalette.border)

            WaveformView(url: trackURL, color: DeckPalette.gold, progress: audio.bgmProgress, barCount: compact ? 100 : 128)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 8)

            Divider().overlay(DeckPalette.border)

            HStack(spacing: 16) {
                Button {
                    if let track { audio.toggleBGM(track, url: trackURL) }
                } label: {
                    Image(systemName: audio.isBGMPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(DeckPalette.background)
                        .frame(width: 74, height: compact ? 34 : 42)
                        .background(DeckPalette.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .buttonStyle(.plain)

                Text(audio.bgmCurrentTime.shortDeckTime)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeckPalette.gold)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.10))
                        Capsule().fill(DeckPalette.gold).frame(width: geometry.size.width * audio.bgmProgress)
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        audio.seekBGM(to: value.location.x / max(1, geometry.size.width))
                    })
                }
                .frame(height: 5)

                Text((audio.bgmDuration > 0 ? audio.bgmDuration : loadedDuration).shortDeckTime)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeckPalette.gold)

                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(DeckPalette.ivory)
                Slider(value: $audio.bgmVolume, in: 0...1)
                    .tint(DeckPalette.gold)
                    .frame(width: 160)
                Text(audio.bgmVolume.decibelString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeckPalette.muted)
                    .frame(width: 56, alignment: .trailing)
            }
            .frame(height: compact ? 44 : 52)
        }
        .padding(.horizontal, 15)
        .background(DeckPalette.raised)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(isDropTarget ? DeckPalette.gold : DeckPalette.border, lineWidth: isDropTarget ? 2 : 1)
        )
        .overlay {
            if isDropTarget {
                ZStack {
                    DeckPalette.background.opacity(0.88)
                    VStack(spacing: 7) {
                        Image(systemName: "waveform.badge.plus")
                            .font(.system(size: 25, weight: .semibold))
                        Text("DROP BGM TO ADD")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .tracking(1.2)
                        Text("You can add multiple files at once")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(DeckPalette.gold)
                }
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            if audio.isBGMPlaying { audio.stopBGM() }
            return store.importBGMFiles(urls) > 0
        } isTargeted: { isDropTarget = $0 }
        .task(id: trackURL) {
            guard let trackURL else { loadedDuration = 0; return }
            loadedDuration = await Task.detached(priority: .utility) {
                (try? AVAudioPlayer(contentsOf: trackURL).duration) ?? 0
            }.value
        }
    }
}

private struct BGMLibraryPopover: View {
    @EnvironmentObject private var store: DeckStore
    @EnvironmentObject private var audio: AudioController
    @Binding var isPresented: Bool
    @State private var query = ""

    private var filteredTracks: [BGMTrack] {
        guard !query.isEmpty else { return store.bgmTracks }
        return store.bgmTracks.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("BGM LIBRARY")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .tracking(1.3)
                        .foregroundStyle(DeckPalette.gold)
                    Text("\(store.bgmTracks.count) TRACKS · DROP OR ADD FILES")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(DeckPalette.muted)
                }
                Spacer()
                Button {
                    store.chooseBGM()
                } label: {
                    Label("ADD FILES", systemImage: "plus")
                }
                .buttonStyle(DeckTextButtonStyle())
            }
            .padding(14)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DeckPalette.muted)
                TextField("SEARCH TRACKS", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DeckPalette.ivory)
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(DeckPalette.surface)
            .overlay(Rectangle().stroke(DeckPalette.border, lineWidth: 1))
            .padding(.horizontal, 14)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filteredTracks) { candidate in
                        trackRow(candidate)
                    }
                    if filteredTracks.isEmpty {
                        Text("NO MATCHING TRACKS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(DeckPalette.muted)
                            .padding(.top, 42)
                    }
                }
                .padding(14)
            }
        }
        .frame(width: 440, height: 420)
        .background(DeckPalette.background)
    }

    private func trackRow(_ candidate: BGMTrack) -> some View {
        let selected = store.selectedTrackID == candidate.id
        return HStack(spacing: 10) {
            Button {
                if audio.currentBGMID != candidate.id { audio.stopBGM() }
                store.selectedTrackID = candidate.id
                isPresented = false
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(selected ? DeckPalette.gold : DeckPalette.surface)
                        Image(systemName: selected ? "checkmark" : "waveform")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(selected ? DeckPalette.background : DeckPalette.gold)
                    }
                    .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.title)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(0.4)
                            .foregroundStyle(DeckPalette.ivory)
                            .lineLimit(1)
                        Text(candidate.subtitle)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(selected ? DeckPalette.gold : DeckPalette.muted)
                    }
                    Spacer()
                    WaveformView(url: store.url(for: candidate), color: DeckPalette.gold, barCount: 24)
                        .frame(width: 92, height: 24)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                if audio.currentBGMID == candidate.id { audio.stopBGM() }
                store.removeBGM(candidate.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DeckPalette.muted)
                    .frame(width: 26, height: 34)
            }
            .buttonStyle(.plain)
            .help("Remove from library")
        }
        .padding(.horizontal, 9)
        .frame(height: 54)
        .background(selected ? DeckPalette.gold.opacity(0.08) : DeckPalette.raised)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(selected ? DeckPalette.gold.opacity(0.65) : DeckPalette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

private struct DeckTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(configuration.isPressed ? DeckPalette.background : DeckPalette.ivory)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(configuration.isPressed ? DeckPalette.gold : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(DeckPalette.border, lineWidth: 1))
    }
}

private extension TimeInterval {
    var shortDeckTime: String {
        let total = max(0, Int(self.rounded()))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private extension Double {
    var decibelString: String {
        guard self > 0.001 else { return "−∞ dB" }
        return String(format: "%+.1f dB", 20 * log10(self))
    }
}

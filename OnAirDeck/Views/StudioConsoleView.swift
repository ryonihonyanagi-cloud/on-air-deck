import AppKit
import SwiftUI

struct StudioConsoleView: View {
    @EnvironmentObject private var audio: AudioController
    @Binding var showModeSelect: Bool
    @Binding var showZoomGuide: Bool

    var body: some View {
        VStack(spacing: 0) {
            StudioTransportHeader(showModeSelect: $showModeSelect, showZoomGuide: $showZoomGuide)
            Rectangle().fill(DeckPalette.border).frame(height: 1)

            GeometryReader { geometry in
                let gap: CGFloat = 10
                let available = max(0, geometry.size.width - 32 - gap * 2)
                let samplerWidth = available * 0.32
                let voiceWidth = available * 0.29
                let deckWidth = available - samplerWidth - voiceWidth

                HStack(spacing: gap) {
                    StudioSamplerRack()
                        .frame(width: samplerWidth)
                    StudioBGMDeck()
                        .frame(width: deckWidth)
                    StudioVoiceRack(showZoomGuide: $showZoomGuide)
                        .frame(width: voiceWidth)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            StudioFooter()
                .frame(height: 58)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                colors: [DeckPalette.background, Color.black.opacity(0.97)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .top) {
            if let error = audio.recordingError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(DeckPalette.live)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.top, 94)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

private struct StudioTransportHeader: View {
    @EnvironmentObject private var audio: AudioController
    @Binding var showModeSelect: Bool
    @Binding var showZoomGuide: Bool

    private var running: Bool { audio.isOnAir || audio.isRecording }

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ON AIR DECK")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(4.2)
                    .foregroundStyle(DeckPalette.ivory)
                Text(L10n.text(audio.studioMode == .live ? "LIVE BROADCAST" : "STUDIO RECORDING"))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(2.3)
                    .foregroundStyle(DeckPalette.muted)
            }
            .frame(width: 250, alignment: .leading)

            modeControl

            Spacer(minLength: 8)

            Button { audio.performPrimaryAction() } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DeckPalette.live.opacity(0.96), DeckPalette.liveDark],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(Circle().stroke(DeckPalette.live.opacity(0.95), lineWidth: 2))
                        .shadow(color: DeckPalette.live.opacity(running ? 0.68 : 0.34), radius: running ? 22 : 11)
                    VStack(spacing: 3) {
                        Image(systemName: running ? "stop.fill" : (audio.studioMode == .live ? "antenna.radiowaves.left.and.right" : "record.circle"))
                            .font(.system(size: 18, weight: .black))
                        Text(L10n.text(running ? "STOP" : (audio.studioMode == .live ? "ON AIR" : "REC")))
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(1.2)
                    }
                    .foregroundStyle(.white)
                }
                .frame(width: 74, height: 74)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text(running ? "Stop session" : "Start session"))

            VStack(alignment: .leading, spacing: 4) {
                Text((audio.isRecording ? audio.recordingElapsed : audio.sessionElapsed).studioClock)
                    .font(.system(size: 29, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeckPalette.ivory)
                HStack(spacing: 6) {
                    Circle()
                        .fill(running ? DeckPalette.live : DeckPalette.green)
                        .frame(width: 6, height: 6)
                    Text(statusLine)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(0.7)
                        .foregroundStyle(running ? DeckPalette.live : DeckPalette.muted)
                }
            }
            .frame(width: 178, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("48 kHz · 24-bit WAV")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DeckPalette.ivory)
                Text(audio.studioMode == .live ? audio.virtualMicStatus : L10n.text("AUTO SAVE READY"))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(audio.studioMode == .live && !audio.virtualMicAvailable ? DeckPalette.gold : DeckPalette.muted)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(width: 176, height: 48, alignment: .leading)
            .background(DeckPalette.raised)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(DeckPalette.border, lineWidth: 1))

            Button { audio.stopAll() } label: {
                Label("STOP ALL", systemImage: "stop.fill")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(DeckPalette.ivory)
                    .frame(width: 118, height: 42)
                    .background(DeckPalette.surface)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(DeckPalette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.space, modifiers: [])
        }
        .padding(.horizontal, 18)
        .padding(.top, 23)
        .padding(.bottom, 12)
        .frame(height: 104)
        .background(DeckPalette.background)
    }

    private var modeControl: some View {
        HStack(spacing: 0) {
            ForEach(StudioMode.allCases) { mode in
                Button {
                    audio.setStudioMode(mode)
                    if mode == .live, !audio.virtualMicAvailable { showZoomGuide = true }
                } label: {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(audio.studioMode == mode ? DeckPalette.live : DeckPalette.muted.opacity(0.4))
                            .frame(width: 7, height: 7)
                        Text(mode.title)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(1.1)
                    }
                    .foregroundStyle(audio.studioMode == mode ? DeckPalette.live : DeckPalette.muted)
                    .frame(width: 76, height: 38)
                    .background(audio.studioMode == mode ? DeckPalette.live.opacity(0.08) : Color.clear)
                    .overlay(Rectangle().stroke(audio.studioMode == mode ? DeckPalette.live : DeckPalette.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(running)
            }
        }
        .overlay(alignment: .bottom) {
            Button("CHANGE MODE") { showModeSelect = true }
                .buttonStyle(.plain)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(DeckPalette.muted)
                .offset(y: 16)
                .disabled(running)
        }
        .padding(.bottom, 8)
    }

    private var statusLine: String {
        if audio.isRecording { return L10n.text(audio.studioMode == .live ? "BACKUP RECORDING" : "RECORDING") }
        if audio.isOnAir { return L10n.text("VIRTUAL MIC ON AIR") }
        return L10n.text(audio.studioMode == .live ? "READY TO BROADCAST" : "RECORDING READY")
    }
}

private struct StudioSamplerRack: View {
    @EnvironmentObject private var store: DeckStore
    @EnvironmentObject private var audio: AudioController

    var body: some View {
        VStack(spacing: 8) {
            rackTitle("SAMPLER", detail: "12 PADS · Q–V")

            GeometryReader { geometry in
                let rowHeight = max(72, (geometry.size.height - 18) / 4)
                VStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { column in
                                let index = row * 3 + column
                                if store.pads.indices.contains(index) {
                                    SoundPadView(pad: store.pads[index], number: index + 1, compact: true)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: rowHeight)
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(DeckPalette.ivory)
                Text("PAD PREVIEW")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(DeckPalette.muted)
                Slider(value: $audio.masterVolume, in: 0...1)
                    .tint(DeckPalette.ivory)
                Text(audio.masterVolume.deckDB)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeckPalette.muted)
                    .frame(width: 48, alignment: .trailing)
            }
            .frame(height: 34)
        }
        .padding(10)
        .studioPanel()
    }
}

private struct StudioBGMDeck: View {
    @EnvironmentObject private var store: DeckStore
    @EnvironmentObject private var audio: AudioController
    @State private var isDropTarget = false

    private var track: BGMTrack? { store.selectedTrack }
    private var trackURL: URL? { track.flatMap(store.url(for:)) }

    var body: some View {
        VStack(spacing: 10) {
            rackTitle("BGM DECK", detail: "DROP TRACKS TO QUEUE")

            HStack(spacing: 12) {
                ZStack {
                    LinearGradient(
                        colors: [DeckPalette.gold.opacity(0.75), DeckPalette.live.opacity(0.55), DeckPalette.raised],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "waveform")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(DeckPalette.ivory.opacity(0.86))
                }
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(DeckPalette.ivory.opacity(0.35), lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text("NOW PLAYING")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(1.1)
                        .foregroundStyle(DeckPalette.gold)
                    Text(track?.title ?? L10n.text("SELECT TRACK"))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(DeckPalette.ivory)
                        .lineLimit(1)
                    Text(track?.subtitle ?? L10n.text("ADD A BGM FILE"))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(DeckPalette.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Button("FADE OUT  2s") { audio.fadeOutBGM() }
                    .buttonStyle(ConsoleTextButtonStyle(accent: DeckPalette.gold))
            }

            WaveformView(url: trackURL, color: DeckPalette.gold, progress: audio.bgmProgress, barCount: 92)
                .frame(height: 108)
                .padding(.vertical, 4)

            HStack(spacing: 12) {
                Text(audio.bgmCurrentTime.deckTime)
                    .consoleSmall(color: DeckPalette.muted)
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
                .frame(height: 4)
                Text((audio.bgmDuration > 0 ? audio.bgmDuration : 0).deckTime)
                    .consoleSmall(color: DeckPalette.muted)
            }

            HStack(spacing: 11) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(DeckPalette.ivory)
                Slider(value: $audio.bgmVolume, in: 0...1)
                    .tint(DeckPalette.ivory)
                Button {
                    if let track { audio.toggleBGM(track, url: trackURL) }
                } label: {
                    Image(systemName: audio.isBGMPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(DeckPalette.gold)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(DeckPalette.surface))
                        .overlay(Circle().stroke(DeckPalette.gold, lineWidth: 1))
                }
                .buttonStyle(.plain)
                Button { audio.setLoop(!audio.loopBGM) } label: {
                    Image(systemName: "repeat")
                        .foregroundStyle(audio.loopBGM ? DeckPalette.gold : DeckPalette.muted)
                }
                .buttonStyle(.plain)
            }

            Rectangle().fill(DeckPalette.border).frame(height: 1)
            HStack {
                Text("QUEUE")
                    .consoleSmall(color: DeckPalette.ivory)
                Spacer()
                Button { store.chooseBGM() } label: { Label("ADD", systemImage: "plus") }
                    .buttonStyle(ConsoleTextButtonStyle(accent: DeckPalette.gold))
            }

            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach(Array(store.bgmTracks.enumerated()), id: \.element.id) { index, candidate in
                        queueRow(candidate, number: index + 1)
                    }
                }
            }

            HStack(spacing: 10) {
                Text("BGM LEVEL").consoleSmall(color: DeckPalette.ivory)
                Slider(value: $audio.bgmVolume, in: 0...1).tint(DeckPalette.ivory)
                Text(audio.bgmVolume.deckDB).consoleSmall(color: DeckPalette.gold)
                Toggle("DUCKING", isOn: $audio.autoDuck)
                    .toggleStyle(.switch)
                    .tint(DeckPalette.gold)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
            .frame(height: 34)
        }
        .padding(10)
        .studioPanel(border: isDropTarget ? DeckPalette.gold : DeckPalette.border)
        .dropDestination(for: URL.self) { urls, _ in store.importBGMFiles(urls) > 0 } isTargeted: { isDropTarget = $0 }
    }

    private func queueRow(_ candidate: BGMTrack, number: Int) -> some View {
        let selected = store.selectedTrackID == candidate.id
        return Button {
            if audio.currentBGMID != candidate.id { audio.stopBGM() }
            store.selectedTrackID = candidate.id
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(DeckPalette.muted)
                Text("\(number)").consoleSmall(color: DeckPalette.ivory)
                VStack(alignment: .leading, spacing: 2) {
                    Text(candidate.title)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(DeckPalette.ivory)
                        .lineLimit(1)
                    Text(candidate.subtitle)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(DeckPalette.muted)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: selected ? "waveform" : "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(selected ? DeckPalette.gold : DeckPalette.muted)
            }
            .padding(.horizontal, 9)
            .frame(height: 39)
            .background(selected ? DeckPalette.ivory.opacity(0.08) : DeckPalette.surface.opacity(0.55))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(selected ? DeckPalette.gold.opacity(0.32) : DeckPalette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct StudioVoiceRack: View {
    @EnvironmentObject private var audio: AudioController
    @Binding var showZoomGuide: Bool

    var body: some View {
        VStack(spacing: 10) {
            rackTitle("VOICE", detail: audio.studioMode == .live ? "VIRTUAL MIC + MASTER" : "MIC + REC MASTER")

            HStack(spacing: 7) {
                micChannel
                fxChannel
                masterChannel
            }

            Button {
                showZoomGuide = true
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(audio.studioMode == .live && audio.virtualMicAvailable ? DeckPalette.green : DeckPalette.gold)
                        .frame(width: 7, height: 7)
                    Text(audio.studioMode == .live ? audio.virtualMicStatus : L10n.text("WAV MIX READY"))
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(0.6)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(DeckPalette.ivory)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(DeckPalette.surface)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(DeckPalette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .studioPanel()
    }

    private var micChannel: some View {
        VStack(spacing: 8) {
            Text("MIC INPUT").consoleSmall(color: DeckPalette.ivory)
            Menu {
                ForEach(audio.microphoneDevices) { device in
                    Button(device.name) { audio.selectMicrophone(device) }
                }
                if audio.microphoneChannelCount > 1 {
                    Divider()
                    ForEach(0..<audio.microphoneChannelCount, id: \.self) { channel in
                        Button("IN \(channel + 1)") { audio.selectMicrophoneChannel(channel) }
                    }
                }
                Divider()
                Button("RESCAN INPUTS") { audio.refreshMicrophones(force: true) }
            } label: {
                VStack(spacing: 2) {
                    Text(audio.selectedMicrophoneName)
                        .font(.system(size: 8, weight: .bold))
                        .lineLimit(1)
                    Text("IN \(audio.selectedMicrophoneChannel + 1)")
                        .font(.system(size: 7, weight: .black, design: .monospaced))
                        .foregroundStyle(DeckPalette.teal)
                }
                .foregroundStyle(DeckPalette.ivory)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(DeckPalette.surface)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(DeckPalette.border, lineWidth: 1))
            }
            .menuStyle(.borderlessButton)

            HStack(spacing: 6) {
                VerticalMeter(value: audio.microphoneMeter, accent: DeckPalette.teal)
                meterScale
            }
            Text(L10n.text(audio.microphoneMeter > 0.012 ? "SIGNAL" : "SPEAK TO TEST"))
                .consoleSmall(color: audio.microphoneMeter > 0.012 ? DeckPalette.green : DeckPalette.muted)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DeckPalette.raised)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(DeckPalette.border, lineWidth: 1))
    }

    private var fxChannel: some View {
        VStack(spacing: 12) {
            Text("MIC FX").consoleSmall(color: DeckPalette.ivory)
            Spacer(minLength: 6)
            Button {
                let presets = MicEffectPreset.allCases
                let current = presets.firstIndex(of: audio.micEffectPreset) ?? 0
                audio.micEffectPreset = presets[(current + 1) % presets.count]
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [DeckPalette.gold, DeckPalette.gold.opacity(0.46)], startPoint: .top, endPoint: .bottom)
                        )
                        .overlay(Circle().stroke(DeckPalette.gold.opacity(0.95), lineWidth: 2))
                        .shadow(color: DeckPalette.gold.opacity(audio.micEffectPreset == .off ? 0.18 : 0.58), radius: 14)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 27, weight: .medium))
                        .foregroundStyle(DeckPalette.background)
                }
                .frame(width: 74, height: 74)
            }
            .buttonStyle(.plain)
            Menu {
                ForEach(MicEffectPreset.allCases) { preset in
                    Button(preset.rawValue) { audio.micEffectPreset = preset }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(audio.micEffectPreset.rawValue)
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(audio.micEffectPreset == .off ? DeckPalette.muted : DeckPalette.gold)
                .lineLimit(1)
            }
            .menuStyle(.borderlessButton)
            Text("VOICE ONLY")
                .consoleSmall(color: DeckPalette.muted)
            Toggle("76 COMP", isOn: $audio.voiceCompressorEnabled)
                .toggleStyle(.switch)
                .tint(DeckPalette.gold)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
            Spacer()
            Toggle("VOICE MON", isOn: Binding(
                get: { audio.voiceMonitorEnabled },
                set: { audio.setVoiceMonitorEnabled($0) }
            ))
            .toggleStyle(.switch)
            .tint(DeckPalette.teal)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DeckPalette.raised)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(DeckPalette.border, lineWidth: 1))
    }

    private var masterChannel: some View {
        VStack(spacing: 8) {
            Text("MASTER").consoleSmall(color: DeckPalette.ivory)
            HStack(spacing: 6) {
                VerticalMeter(value: max(audio.masterMeter, audio.microphoneMeter * audio.masterVolume), accent: DeckPalette.gold)
                meterScale
            }
            Slider(value: $audio.masterVolume, in: 0...1)
                .tint(DeckPalette.gold)
                .rotationEffect(.degrees(-90))
                .frame(width: 96, height: 26)
                .padding(.vertical, 30)
            Text(audio.masterVolume.deckDB)
                .consoleSmall(color: DeckPalette.gold)
            Toggle("LIMITER", isOn: .constant(true))
                .toggleStyle(.switch)
                .tint(DeckPalette.live)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .disabled(true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DeckPalette.raised)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(DeckPalette.border, lineWidth: 1))
    }

    private var meterScale: some View {
        VStack {
            ForEach(["0", "−6", "−12", "−18", "−30", "−60"], id: \.self) { value in
                Text(value)
                    .font(.system(size: 6, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeckPalette.muted)
                if value != "−60" { Spacer() }
            }
        }
        .frame(width: 23)
    }
}

private struct StudioFooter: View {
    @EnvironmentObject private var audio: AudioController

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "headphones")
                .foregroundStyle(DeckPalette.ivory)
            Text("HEADPHONES ONLY")
                .consoleSmall(color: DeckPalette.gold)
            Slider(value: $audio.voiceMonitorVolume, in: 0...1)
                .tint(DeckPalette.ivory)
                .frame(width: 120)
                .disabled(!audio.voiceMonitorEnabled)
            Text(audio.voiceMonitorVolume.deckDB)
                .consoleSmall(color: DeckPalette.muted)

            Rectangle().fill(DeckPalette.border).frame(width: 1, height: 28)

            Text("REC FORMAT").consoleSmall(color: DeckPalette.ivory)
            Text("48 kHz · 24-bit WAV")
                .consoleSmall(color: DeckPalette.muted)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(DeckPalette.surface)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(DeckPalette.border, lineWidth: 1))

            Text("SAVE TO").consoleSmall(color: DeckPalette.ivory)
            Button {
                if let directory = AudioController.recordingDirectory() { NSWorkspace.shared.open(directory) }
            } label: {
                Label("ON AIR DECK RECORDINGS", systemImage: "folder.fill")
                    .consoleSmall(color: DeckPalette.muted)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(DeckPalette.surface)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(DeckPalette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            if audio.studioMode == .live {
                Button {
                    audio.isRecording ? audio.stopRecording() : audio.startRecording()
                } label: {
                    Label(L10n.text(audio.isRecording ? "STOP BACKUP" : "BACKUP REC"), systemImage: audio.isRecording ? "stop.fill" : "record.circle")
                }
                .buttonStyle(ConsoleTextButtonStyle(accent: audio.isRecording ? DeckPalette.live : DeckPalette.gold))
            }

            Image(systemName: "waveform.path.ecg")
                .foregroundStyle(max(audio.masterMeter, audio.microphoneMeter) > 0.01 ? DeckPalette.teal : DeckPalette.muted)
        }
        .padding(.horizontal, 14)
        .studioPanel()
    }
}

struct ModeSelectionOverlay: View {
    @EnvironmentObject private var audio: AudioController
    @Binding var isPresented: Bool
    @Binding var showZoomGuide: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 26) {
                VStack(spacing: 7) {
                    Text("ON AIR DECK")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(5)
                        .foregroundStyle(DeckPalette.ivory)
                    Text("HOW ARE YOU RECORDING TODAY?")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(.white)
                    Text("用途を選ぶだけで、必要な設定と操作だけを表示します。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DeckPalette.muted)
                }

                HStack(spacing: 18) {
                    modeCard(.live, icon: "antenna.radiowaves.left.and.right")
                    modeCard(.record, icon: "record.circle")
                }
                .frame(maxWidth: 850)

                HStack(spacing: 18) {
                    readiness("MIC", ready: audio.selectedMicrophoneUID != nil)
                    readiness("BGM + SFX", ready: true)
                    readiness("VIRTUAL MIC", ready: audio.virtualMicAvailable)
                }
            }
            .padding(42)
        }
    }

    private func modeCard(_ mode: StudioMode, icon: String) -> some View {
        Button {
            audio.setStudioMode(mode)
            isPresented = false
            if mode == .live, !audio.virtualMicAvailable { showZoomGuide = true }
        } label: {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(mode == .live ? DeckPalette.green : DeckPalette.live)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DeckPalette.muted)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.text(mode == .live ? "LIVE BROADCAST" : "STUDIO RECORDING"))
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(DeckPalette.ivory)
                    Text(L10n.text(mode.subtitle))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DeckPalette.muted)
                }
                Rectangle().fill(DeckPalette.border).frame(height: 1)
                Text(L10n.text(mode == .live ? "マイク・BGM・ジングル・SEをひとつの入力として配信" : "RECを押すだけで、演出ごと48 kHz / 24-bit WAVへ保存"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DeckPalette.ivory.opacity(0.85))
                    .multilineTextAlignment(.leading)
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
            .background(DeckPalette.raised)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(mode == .live ? DeckPalette.green.opacity(0.55) : DeckPalette.live.opacity(0.55), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func readiness(_ label: String, ready: Bool) -> some View {
        HStack(spacing: 7) {
            Circle().fill(ready ? DeckPalette.green : DeckPalette.gold).frame(width: 7, height: 7)
            Text("\(L10n.text(label)) · \(L10n.text(ready ? "READY" : "SETUP"))")
                .consoleSmall(color: ready ? DeckPalette.green : DeckPalette.gold)
        }
    }
}

struct RecordingResultView: View {
    @EnvironmentObject private var audio: AudioController
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle().fill(DeckPalette.green.opacity(0.14)).frame(width: 72, height: 72)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(DeckPalette.green)
            }
            VStack(spacing: 6) {
                Text("RECORDING SAVED")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(DeckPalette.ivory)
                Text(audio.lastRecordingURL?.lastPathComponent ?? L10n.text("WAV SAVED"))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeckPalette.muted)
            }
            HStack(spacing: 12) {
                Button("FINDERで表示") { audio.revealLastRecording() }
                    .buttonStyle(ConsoleTextButtonStyle(accent: DeckPalette.gold))
                Button("もう一度録る") {
                    isPresented = false
                    audio.setStudioMode(.record)
                    audio.startRecording()
                }
                    .buttonStyle(ConsoleTextButtonStyle(accent: DeckPalette.live))
                Button("完了") { isPresented = false }
                    .buttonStyle(ConsoleTextButtonStyle(accent: DeckPalette.ivory))
            }
        }
        .padding(34)
        .frame(width: 520, height: 310)
        .background(DeckPalette.background)
    }
}

private struct VerticalMeter: View {
    let value: Double
    let accent: Color

    var body: some View {
        GeometryReader { geometry in
            let segments = 32
            VStack(spacing: 2) {
                ForEach((0..<segments).reversed(), id: \.self) { index in
                    let fraction = Double(index + 1) / Double(segments)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(fraction <= value ? meterColor(fraction) : Color.white.opacity(0.055))
                        .frame(height: max(2, (geometry.size.height - CGFloat(segments - 1) * 2) / CGFloat(segments)))
                }
            }
        }
        .frame(maxWidth: 24)
        .accessibilityLabel(L10n.text("Audio level"))
        .accessibilityValue(L10n.format("%d percent", Int(value * 100)))
    }

    private func meterColor(_ fraction: Double) -> Color {
        if fraction > 0.86 { return DeckPalette.live }
        if fraction > 0.68 { return DeckPalette.gold }
        return accent
    }
}

private func rackTitle(_ title: String, detail: String) -> some View {
    HStack {
        Text(L10n.text(title))
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .tracking(1.2)
            .foregroundStyle(DeckPalette.ivory)
        Spacer()
        Text(L10n.text(detail))
            .font(.system(size: 7, weight: .bold, design: .monospaced))
            .tracking(0.7)
            .foregroundStyle(DeckPalette.muted)
    }
    .frame(height: 22)
}

private extension View {
    func studioPanel(border: Color = DeckPalette.border) -> some View {
        background(DeckPalette.background.opacity(0.82))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    func consoleSmall(color: Color) -> some View {
        font(.system(size: 8, weight: .bold, design: .monospaced))
            .tracking(0.7)
            .foregroundStyle(color)
    }
}

private struct ConsoleTextButtonStyle: ButtonStyle {
    let accent: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 8, weight: .black, design: .monospaced))
            .tracking(0.7)
            .foregroundStyle(configuration.isPressed ? DeckPalette.background : accent)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(configuration.isPressed ? accent : DeckPalette.surface)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(accent.opacity(0.48), lineWidth: 1))
    }
}

private extension TimeInterval {
    var studioClock: String {
        let total = max(0, Int(self))
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    var deckTime: String {
        let total = max(0, Int(self.rounded()))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private extension Double {
    var deckDB: String {
        guard self > 0.001 else { return "−∞ dB" }
        return String(format: "%+.1f dB", 20 * log10(self))
    }
}

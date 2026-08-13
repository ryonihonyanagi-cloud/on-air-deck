import SwiftUI

struct MasterStripView: View {
    @EnvironmentObject private var audio: AudioController

    var body: some View {
        HStack(spacing: 18) {
            Menu {
                ForEach(audio.microphoneDevices) { device in
                    Button {
                        audio.selectMicrophone(device)
                    } label: {
                        if device.uid == audio.selectedMicrophoneUID {
                            Label(device.name, systemImage: "checkmark")
                        } else {
                            Text(device.name)
                        }
                    }
                }
                if audio.microphoneChannelCount > 1 {
                    Divider()
                    Menu("INPUT CHANNEL · IN \(audio.selectedMicrophoneChannel + 1)") {
                        ForEach(0..<audio.microphoneChannelCount, id: \.self) { channel in
                            Button {
                                audio.selectMicrophoneChannel(channel)
                            } label: {
                                if channel == audio.selectedMicrophoneChannel {
                                    Label("IN \(channel + 1)", systemImage: "checkmark")
                                } else {
                                    Text("IN \(channel + 1)")
                                }
                            }
                        }
                    }
                }
                Divider()
                Button("Refresh input devices") {
                    audio.refreshMicrophones()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(audio.microphoneMeter > 0.015 ? DeckPalette.teal : DeckPalette.muted)
                    Text(microphoneLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DeckPalette.ivory)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(DeckPalette.muted)
                }
                .frame(width: 170, alignment: .leading)
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .layoutPriority(2)
            .help("Select the voice input mixed into the virtual microphone")

            LevelMeter(value: audio.microphoneMeter, segments: 10, accessibilityName: "Microphone input level")
                .frame(width: 58)

            Divider().overlay(DeckPalette.border).frame(height: 32)

            Toggle(isOn: Binding(
                get: { audio.voiceMonitorEnabled },
                set: { audio.setVoiceMonitorEnabled($0) }
            )) {
                HStack(spacing: 6) {
                    Image(systemName: audio.voiceMonitorEnabled ? "headphones.circle.fill" : "headphones")
                        .foregroundStyle(audio.voiceMonitorEnabled ? DeckPalette.teal : DeckPalette.muted)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("VOICE MON")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(1)
                        Text("HEADPHONES ONLY")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(DeckPalette.live)
                    }
                }
            }
            .toggleStyle(.switch)
            .tint(DeckPalette.teal)
            .help("Return your voice to the local output. Use only with headphones to prevent feedback")

            Slider(value: $audio.voiceMonitorVolume, in: 0...1)
                .tint(DeckPalette.teal)
                .frame(width: 62)
                .disabled(!audio.voiceMonitorEnabled)
                .opacity(audio.voiceMonitorEnabled ? 1 : 0.35)
                .help("Voice monitor volume. This does not affect the level sent to Zoom")

            Text(audio.voiceMonitorVolume.masterPercent)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(DeckPalette.muted)
                .frame(width: 30, alignment: .trailing)

            Divider().overlay(DeckPalette.border).frame(height: 32)

            Text("MASTER")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(DeckPalette.ivory)

            Slider(value: $audio.masterVolume, in: 0...1)
                .tint(DeckPalette.ivory)
                .frame(width: 88)

            Text(audio.masterVolume.masterPercent)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(DeckPalette.muted)
                .frame(width: 34, alignment: .trailing)

            LevelMeter(value: audio.masterMeter)
                .frame(maxWidth: .infinity)

            Divider().overlay(DeckPalette.border).frame(height: 32)

            Toggle(isOn: $audio.autoDuck) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("AUTO-DUCK")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(1.2)
                    Text("Automatically lower BGM while a pad is playing")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DeckPalette.muted)
                }
            }
            .toggleStyle(.switch)
            .tint(DeckPalette.teal)
        }
        .padding(.horizontal, 18)
        .background(DeckPalette.raised)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(DeckPalette.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var microphoneLabel: String {
        guard audio.microphoneChannelCount > 2 else { return audio.selectedMicrophoneName }
        return "\(audio.selectedMicrophoneName) · IN \(audio.selectedMicrophoneChannel + 1)"
    }
}

private struct LevelMeter: View {
    let value: Double
    var segments = 42
    var accessibilityName = "Master level"

    var body: some View {
        GeometryReader { geometry in
            let gap: CGFloat = 2
            let segmentWidth = max(2, (geometry.size.width - gap * CGFloat(segments - 1)) / CGFloat(segments))
            HStack(spacing: gap) {
                ForEach(0..<segments, id: \.self) { index in
                    let fraction = Double(index + 1) / Double(segments)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(fraction <= value ? color(for: fraction) : Color.white.opacity(0.055))
                        .frame(width: segmentWidth)
                }
            }
        }
        .frame(height: 13)
        .accessibilityLabel(L10n.text(accessibilityName))
        .accessibilityValue(L10n.format("%d percent", Int(value * 100)))
    }

    private func color(for fraction: Double) -> Color {
        if fraction > 0.84 { return DeckPalette.live }
        if fraction > 0.63 { return DeckPalette.gold }
        return DeckPalette.teal
    }
}

private extension Double {
    var masterPercent: String { "\(Int(self * 100))%" }
}

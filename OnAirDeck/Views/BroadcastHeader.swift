import SwiftUI

struct BroadcastHeader: View {
    @EnvironmentObject private var store: DeckStore
    @EnvironmentObject private var audio: AudioController
    @Binding var showZoomGuide: Bool

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ON AIR DECK")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(DeckPalette.ivory)
                Text("RADIO BROADCAST SAMPLER")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2.4)
                    .foregroundStyle(DeckPalette.muted)
            }
            .frame(width: 280, alignment: .leading)

            headerDivider

            Button { audio.toggleOnAir() } label: {
                HStack(spacing: 11) {
                    Circle()
                        .fill(audio.isOnAir ? DeckPalette.live : DeckPalette.muted.opacity(0.55))
                        .frame(width: 13, height: 13)
                        .shadow(color: audio.isOnAir ? DeckPalette.live.opacity(0.8) : .clear, radius: 8)
                    Text(L10n.text(audio.isOnAir ? "ON AIR" : "STANDBY"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .tracking(1.6)
                }
                .foregroundStyle(audio.isOnAir ? DeckPalette.live : DeckPalette.muted)
                .padding(.horizontal, 18)
                .frame(height: 48)
                .background(audio.isOnAir ? DeckPalette.live.opacity(0.08) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(audio.isOnAir ? DeckPalette.live : DeckPalette.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text(audio.isOnAir ? "End on air session" : "Start on air session"))
            .frame(width: 184)

            headerDivider

            Button { showZoomGuide = true } label: {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                    Circle()
                        .fill(audio.isOnAir ? DeckPalette.live : (audio.virtualMicAvailable ? DeckPalette.green : DeckPalette.gold))
                        .frame(width: 7, height: 7)
                        Text(L10n.text(audio.isOnAir ? "VIRTUAL MIC LIVE" : (audio.virtualMicAvailable ? "VIRTUAL MIC READY" : "AUDIO SETUP")))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.1)
                            .foregroundStyle(audio.isOnAir ? DeckPalette.live : (audio.virtualMicAvailable ? DeckPalette.green : DeckPalette.gold))
                    }
                    Text("ON AIR Deck · 48 kHz")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DeckPalette.ivory)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .frame(minWidth: 220, maxWidth: .infinity)

            headerDivider

            VStack(alignment: .leading, spacing: 3) {
                Text("SESSION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(DeckPalette.muted)
                Text(audio.sessionElapsed.clockString)
                    .font(.system(size: 23, weight: .medium, design: .monospaced))
                    .foregroundStyle(DeckPalette.ivory)
            }
            .frame(width: 146, alignment: .leading)
            .padding(.leading, 20)

            Button { audio.stopAll() } label: {
                HStack(spacing: 11) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 13, weight: .black))
                    Text("STOP ALL")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .tracking(1.1)
                }
                .foregroundStyle(.white)
                .frame(width: 164, height: 48)
                .background(DeckPalette.live)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .shadow(color: DeckPalette.live.opacity(0.25), radius: 12, y: 3)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.space, modifiers: [])
            .padding(.leading, 14)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 14)
        .background(DeckPalette.background)
    }

    private var headerDivider: some View {
        Rectangle()
            .fill(DeckPalette.border)
            .frame(width: 1, height: 52)
            .padding(.horizontal, 18)
    }
}

private extension TimeInterval {
    var clockString: String {
        let total = max(0, Int(self))
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}

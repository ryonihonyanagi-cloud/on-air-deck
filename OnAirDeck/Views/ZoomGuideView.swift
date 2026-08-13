import SwiftUI

struct ZoomGuideView: View {
    @EnvironmentObject private var audio: AudioController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("ZOOM BROADCAST SETUP")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(DeckPalette.ivory)
                    Text("初回だけ仮想マイクを設定。以降はサウンドを1回押すだけです。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DeckPalette.muted)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(DeckPalette.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(28)

            Divider().overlay(DeckPalette.border)

            VStack(spacing: 0) {
                setupRow(number: "01", title: "ON AIR Deck Audio Driverをインストール", detail: "同梱インストーラを一度だけ実行します。BlackHoleや外部機器は不要です。", icon: "waveform.badge.plus")
                setupRow(number: "02", title: "Zoomのマイクを「ON AIR Deck」に変更", detail: "Zoom設定の［オーディオ］で、マイク入力にON AIR Deckを選びます。", icon: "mic.fill")
                setupRow(number: "03", title: "画面下部で声の入力マイクを選択", detail: "MacBook、USBマイク、iPhoneなど、実際に話すマイク名を選びます。隣のメーターで入力を確認できます。", icon: "slider.horizontal.3")
                setupRow(number: "04", title: "BGM・ジングル・SEを1回押してサウンドチェック", detail: "再生と同時にON AIRが自動開始し、声とサウンドが48 kHzで参加者と録音へ届きます。", icon: "dot.radiowaves.left.and.right")
            }

            Divider().overlay(DeckPalette.border)

            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(audio.virtualMicAvailable ? DeckPalette.green : DeckPalette.gold)
                        .frame(width: 8, height: 8)
                    Text(L10n.text(audio.virtualMicAvailable ? "仮想マイクは使用できます" : "音声ドライバをインストールしてください"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(audio.virtualMicAvailable ? DeckPalette.green : DeckPalette.gold)
                }
                Spacer()
                Button(L10n.text(audio.virtualMicAvailable ? "ZOOMを開く" : "ドライバを開く")) {
                    if audio.virtualMicAvailable { audio.launchZoom() } else { audio.openDriverInstaller() }
                }
                    .buttonStyle(PrimaryDeckButtonStyle())
            }
            .padding(28)
        }
        .frame(width: 680)
        .background(DeckPalette.background)
    }

    private func setupRow(number: String, title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 20) {
            Text(number)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(DeckPalette.live)
                .frame(width: 28)
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(DeckPalette.gold)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text(title))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DeckPalette.ivory)
                Text(L10n.text(detail))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(DeckPalette.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .overlay(alignment: .bottom) { Divider().overlay(DeckPalette.border).padding(.leading, 78) }
    }
}

private struct PrimaryDeckButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .black, design: .monospaced))
            .tracking(1)
            .foregroundStyle(DeckPalette.background)
            .padding(.horizontal, 20)
            .frame(height: 38)
            .background(configuration.isPressed ? DeckPalette.ivory.opacity(0.7) : DeckPalette.ivory)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

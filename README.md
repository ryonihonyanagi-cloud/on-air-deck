# ON AIR Deck

**A native macOS broadcast desk for podcasts, radio-style recording, and live streams.**

[日本語](docs/README.ja.md) · [简体中文](docs/README.zh-Hans.md) · [한국어](docs/README.ko.md)

![ON AIR Deck recording console](docs/assets/on-air-deck-console.png)

ON AIR Deck mixes a microphone, BGM, jingles, and sound effects in one 48 kHz audio graph.
Use `LIVE` to send that mix to Zoom, Google Meet, or OBS through the bundled virtual microphone.
Use `REC` to record the same performance directly as a 48 kHz, 24-bit stereo WAV file.

No external audio interface, BlackHole routing, OBS setup, or computer-audio screen sharing is required.

## Highlights

- Equal-first `LIVE` and `REC` workflows.
- One-click WAV recording and optional backup recording during LIVE sessions.
- A dedicated virtual microphone named `ON AIR Deck`.
- Twelve drag-and-drop sample pads with generated waveforms and keyboard shortcuts.
- A persistent multi-track BGM library with search, looping, and two-second fades.
- Voice-only `SLAP`, `ECHO`, and `BIG TITLE` effects.
- A restrained 76-style voice compressor enabled by default and switchable at any time.
- BGM ducking, a final peak limiter, independent monitoring, and live level meters.
- Multi-channel interface input selection, including explicit input-channel routing.
- English, Japanese, Simplified Chinese, and Korean user interfaces.
- Universal Binary support for Apple Silicon and Intel Macs.

## Requirements

- macOS 14 or later.
- Wired headphones are strongly recommended when voice monitoring is enabled.
- Administrator access is required to install or remove the virtual audio driver.
- A notarized public build requires valid Developer ID Application and Developer ID Installer certificates.

## Quick start

### Record on this Mac

1. Open ON AIR Deck and choose `REC`.
2. Select the microphone you actually speak into.
3. Press `REC`.
4. Perform with BGM, jingles, sound effects, and voice effects.
5. Stop the session and reveal the WAV file in Finder.

Recordings are saved to `~/Music/ON AIR Deck Recordings` by default.

### Send audio to Zoom, Meet, or OBS

1. Install `ON AIR Deck Audio Driver.pkg` from the signed release package.
2. Open ON AIR Deck and choose `LIVE`.
3. Select the microphone you actually speak into.
4. In the destination app, select `ON AIR Deck` as its microphone.
5. Speak and play a pad to confirm that both meters move in the destination app.

For Zoom, use Original Sound for Musicians when high-fidelity music playback matters.

## Build from source

Install [XcodeGen](https://github.com/yonaskolb/XcodeGen), then run:

```bash
xcodegen generate
./scripts/test.sh
```

Build the app:

```bash
xcodebuild \
  -project OnAirDeck.xcodeproj \
  -scheme OnAirDeck \
  -configuration Release \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  build
```

The virtual audio driver is a separate Xcode project under `AudioDriver/`.
Installing that driver writes to `/Library/Audio/Plug-Ins/HAL`, so read its README and inspect the package scripts before testing it.

## Project status

Version 2.1 adds four-language localization to the 2.0 LIVE and REC architecture.
The app and driver build locally, and the automated app tests pass.
Public distribution remains gated on bundled-audio and artwork rights confirmation, Developer ID signing, Apple notarization, and clean-Mac verification.

See the [release checklist](docs/OSS_RELEASE_CHECKLIST.md) for the exact status.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Brand assets](docs/BRAND_ASSETS.md)
- [Localization](docs/LOCALIZATION.md)
- [Launch kit](docs/LAUNCH_KIT.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Release process](docs/RELEASING.md)
- [Latest validation report](docs/VALIDATION_REPORT_2026-08-11.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Changelog](CHANGELOG.md)

## License

ON AIR Deck source code is licensed under the [MIT License](LICENSE).
Apple-derived code under `AudioDriver/` retains Apple’s included MIT license notice.
Bundled demo audio and artwork are separate assets and are not automatically covered by the project license.
See [Third-party notices](THIRD_PARTY_NOTICES.md) and the [asset ledger](docs/ASSET_LEDGER.md) before redistribution.

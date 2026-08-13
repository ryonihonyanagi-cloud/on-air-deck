# Changelog

All notable user-visible changes will be documented in this file.

## [Unreleased]

### Added

- English, Japanese, Simplified Chinese, and Korean application localization.
- Localized microphone permission descriptions.
- Localization-catalog validation.
- GitHub Actions build and test workflow.
- OSS community, security, contribution, and release documentation.
- Repository-wide MIT License.

### Changed

- Version advanced to 2.1.0 build 10 for the localization release candidate.
- The virtual audio driver now declares macOS 14.0 as its deployment target instead of inheriting the build machine's latest SDK version.
- CI now builds both arm64 and x86_64 slices of the app and virtual audio driver.
- Demo audio with unresolved redistribution rights is excluded from the public-source file set.
- Driver packaging now rebuilds from current source instead of reusing a stale binary with the build machine’s SDK as its minimum OS.
- Project and Apple sample-code license notices are embedded in the virtual audio driver bundle.

### Verified

- Isolated public-source build without bundled demo audio.
- Nine unit tests and Xcode static analysis for the app and driver.
- REC capture with microphone, BGM, and jingle to 48 kHz / 24-bit stereo WAV.
- LIVE delivery of BGM and sound effects through the virtual microphone to an independent receiver.
- Microphone, deck, pad, compressor, and mix-state restoration after app restart.

### Pending before public release

- Bundled demo-audio rights confirmation or replacement.
- Final GitHub owner and repository URLs.
- Developer ID signing, installer signing, notarization, and clean-Mac validation.

## [2.0.1] - 2026-08-11

### Added

- A voice-only 76-style compressor using Apple’s Dynamics Processor.
- A persistent on/off switch with the compressor enabled by default.

### Verified

- Nine unit tests.
- A 48 kHz, 24-bit, stereo WAV smoke recording.
- Universal Release output for arm64 and x86_64.

## [2.0.0-preview] - 2026-08-11

### Added

- Equal-first LIVE and REC launch modes.
- One-click master WAV recording and LIVE backup recording.
- Voice-only SLAP, ECHO, and BIG TITLE effects.
- A final peak limiter before recording and broadcast output.
- A redesigned radio-console interface.

## [1.0.6] - 2026-08-10

### Fixed

- Explicit input-channel routing for multi-channel audio interfaces.
- Stereo conversion of the selected microphone channel for broadcast output.

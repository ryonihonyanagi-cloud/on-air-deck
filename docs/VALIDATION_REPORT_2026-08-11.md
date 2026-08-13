# Validation report — 2026-08-11

This report records local verification of the ON AIR Deck 2.1.0 preview and its public-source candidate.
It does not represent Apple notarization, clean-Mac acceptance, or a public release.

## Passed

### Public-source candidate

- Built and tested from an isolated copy containing only the 90 files eligible for publication.
- Confirmed that the isolated source contains no bundled WAV, AIFF, MP3, M4A, or FLAC demo files.
- Found no private-key files, common API-key patterns, notarization passwords, or literal email addresses in the publication candidate.
- Validated four localization catalogs with 125 matching keys each.
- Passed all nine unit tests from the isolated source copy.
- Passed Xcode static analysis for the app and virtual audio driver.

### App and driver binaries

- Built both the app and virtual audio driver as Universal Binaries containing `arm64` and `x86_64`.
- Confirmed macOS 14.0 as the minimum OS for both current-source builds.
- Confirmed the project MIT License, third-party notices, and Apple sample-code license inside the app bundle.
- Confirmed the project and Apple license texts inside the virtual audio driver bundle.

### REC end-to-end smoke test

- Selected REC, observed physical microphone input, and started recording with one click.
- Played BGM and a jingle while recording.
- Saved a readable 21.2-second WAV.
- Confirmed 48 kHz, 24-bit signed PCM, stereo output.
- Measured `-21.9 dB` mean volume and `-2.7 dB` maximum volume.
- Confirmed valid audio in both left and right channels.

### LIVE end-to-end smoke test

- Started LIVE and observed `48 kHz virtual microphone transmitting` state.
- Played BGM and two sound effects.
- Captured the `ON AIR Deck` virtual input from an independent receiving process.
- Confirmed 48 kHz, 24-bit signed PCM, stereo output.
- Measured `-18.9 dB` mean volume, `-5.9 dB` maximum volume, and `-17.6 LUFS` integrated loudness.
- Confirmed valid audio in both left and right channels.

### Restart persistence

- Quit and relaunched the app.
- Confirmed that the selected physical microphone, BGM queue, pad assignments, compressor state, and mix controls were restored.

### Driver package

- Replaced the stale package payload that declared macOS 26.5 with a fresh build declaring macOS 14.0.
- Confirmed package identifier `jp.ryonihonyanagi.OnAirDeckAudio` and driver version `1.0.1`.
- Confirmed that the payload installs only `OnAirDeckAudio.driver` under `/Library/Audio/Plug-Ins/HAL`.
- Confirmed that the postinstall script only reloads Core Audio.
- Confirmed that the uninstaller removes only `/Library/Audio/Plug-Ins/HAL/OnAirDeckAudio.driver` before reloading Core Audio.
- Added a reproducible package builder and CI validation for architecture, minimum OS, licenses, and payload path.
- Backed up the previously installed driver, installed the rebuilt package on the development Mac, and confirmed the installed binary now declares macOS 14.0.
- Confirmed the installed driver receipt reports version `1.0.1` and that Core Audio rediscovered the `ON AIR Deck` input.
- Repeated the LIVE receiver test after installation with time-separated BGM and sound effects.
- Measured `-19.6 dB` mean volume, `-7.1 dB` maximum volume, and `-18.2 LUFS` integrated loudness from the newly installed driver.

## Local artifact hashes

```text
c17e317ee3225a5359cb1c91f92de2366243df56c15c06e7c92be06ca249567f  ON AIR Deck 2.1.0 Preview.zip
18292ae2d45698f39806e9490928ad8bcb04f49ae31c74ed54cb42973a428e59  ON AIR Deck Audio Driver.pkg
```

These hashes apply only to the current unsigned local preview artifacts and will change after Developer ID signing and notarization.

## Still required before public release

- Resolve or replace every bundled audio and artwork asset with unclear redistribution rights.
- GitHub owner is `ryonihonyanagi-cloud`; private security reports use GitHub Private Vulnerability Reporting.
- Sign the app with Developer ID Application and the package with Developer ID Installer.
- Notarize, staple, and validate the final distribution.
- Install the rebuilt driver package on a clean test Mac and verify first-install, upgrade, and uninstall behavior.
- Complete a recording of at least 60 minutes plus device disconnect, sleep/wake, disk-full, and abnormal-termination tests.
- Verify the final signed build directly in Zoom, Google Meet, and OBS.
- Re-scan the dedicated repository’s complete Git history after repository separation.

The current app is ad-hoc signed and the current package is unsigned, so Gatekeeper rejection is expected.
Neither artifact is approved for public distribution yet.

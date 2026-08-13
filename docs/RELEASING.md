# Release process

This document separates reproducible build work from credentialed public distribution.

## 1. Prepare the source

1. Confirm that `CHANGELOG.md` matches the target version.
2. Set `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`.
3. Confirm that `.github/` links point to the final GitHub owner, `ryonihonyanagi-cloud`.
4. Confirm the root license and the bundled-asset ledger.
5. Run `./scripts/test.sh`.
6. Regenerate and review `OnAirDeck.xcodeproj`.

## 2. Build release artifacts

Build a universal app for `arm64` and `x86_64`.
Build and package the HAL driver as a universal binary with:

```bash
./scripts/build-driver-package.sh
```

This creates an unsigned local package for verification.
Its embedded driver must report macOS 14.0 as the minimum OS and contain both the project and Apple sample-code license notices.
Sign the final package separately with a Developer ID Installer identity.
Keep the version-matched uninstaller beside the package.

Do not put signing identities, notarization profiles, API keys, or passwords in source files or CI logs.

## 3. Sign

Sign the app and every nested executable with a Developer ID Application identity, Hardened Runtime, and secure timestamp.
Preserve the microphone entitlement on the final app signature.
Sign the flat installer package with a Developer ID Installer identity.

Verify every signature independently before creating the final disk image.

## 4. Notarize and staple

Submit the supported distributable artifact with `xcrun notarytool`.
Wait for an accepted result and inspect the log even when submission succeeds.
Staple the ticket with `xcrun stapler` and validate the staple.

Apple’s current notarization guidance requires Developer ID signing and recommends the modern `notarytool` workflow.

## 5. Clean-Mac acceptance test

Use a clean macOS user or machine with no development certificates and no previous ON AIR Deck installation.

Verify:

1. Gatekeeper accepts the downloaded artifact.
2. The driver installer shows the expected publisher and target files.
3. The app launches and requests microphone access in the selected system language.
4. REC creates a readable 48 kHz, 24-bit, stereo WAV.
5. LIVE sends microphone, BGM, and a pad to Zoom, Meet, and OBS.
6. Voice effects and the compressor affect only the microphone.
7. The uninstaller removes only the ON AIR Deck driver.
8. Reinstall and upgrade paths preserve the user’s imported library.

## 6. Publish

1. Create a signed Git tag matching the app version.
2. Generate SHA-256 checksums for every artifact.
3. Create a GitHub Release from the changelog entry.
4. Upload only the verified, notarized artifacts.
5. Test the public download URL in a logged-out browser session.
6. Confirm that the checksum, signature, staple, and app version still match after download.

Publishing a draft, upload progress indicator, or local release folder does not count as a completed release.

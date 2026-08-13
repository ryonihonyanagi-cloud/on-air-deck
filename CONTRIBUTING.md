# Contributing to ON AIR Deck

Thank you for improving ON AIR Deck.
Contributions should make real podcast, radio, and streaming sessions safer or easier.

## Before opening a change

1. Search existing issues and discussions.
2. Open an issue before large audio-architecture, driver, UI-flow, or file-format changes.
3. Keep private recordings, signing identities, notarization credentials, and machine-specific paths out of the repository.
4. Confirm that your contribution can be distributed under the project’s MIT License.

## Local setup

Requirements:

- macOS 14 or later.
- A current Xcode installation.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen).

Run the default validation suite:

```bash
./scripts/test.sh
```

The script validates all localization catalogs, regenerates the Xcode project, and runs the unit tests without code signing.

## Change boundaries

### App-only changes

Most UI, recording, sampler, BGM, and voice-effect changes live under `OnAirDeck/`.
Verify both `LIVE` and `REC` when a shared audio path changes.

### Virtual audio driver changes

The driver under `AudioDriver/` installs system-wide and can interrupt active audio applications.
Do not run installer or uninstall scripts on a contributor’s machine without an explicit, informed action.
Preserve the Apple copyright and license notices in derived driver files.

### Localization changes

Every UI key must exist in `en`, `ja`, `zh-Hans`, and `ko`.
Run `./scripts/validate-localizations.sh` before opening a pull request.
See `docs/LOCALIZATION.md` for the language test procedure.

### Audio assets

Do not submit commercial samples, copyrighted music, voice recordings without consent, or assets with unclear redistribution rights.
State the author, source, license, and modifications for every new asset.
CC0, original commissioned work with written redistribution permission, or procedurally generated test audio is preferred.

## Pull requests

Keep each pull request focused.
Describe the production problem, the user-visible result, and the verification performed.
Attach screenshots for UI changes and technical measurements for audio-path changes when useful.
Do not attach private session audio.

All tests must pass, and user-visible strings must be localized in all four supported languages.

## Commit messages

Use short imperative subjects, for example:

```text
Add Korean setup guidance
Prevent recorder double start
Restore microphone after device reconnect
```

## Reporting security problems

Do not open a public issue for a vulnerability.
Follow `SECURITY.md` instead.

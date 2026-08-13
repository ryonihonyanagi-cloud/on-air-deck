# Security policy

## Supported versions

Security updates are planned for the latest stable release only.
Preview builds are for evaluation and may not receive backported fixes.

## Report a vulnerability

Do not open a public issue.

After the GitHub repository is created, use GitHub Private Vulnerability Reporting from the repository’s Security tab.
Include the affected version, macOS version, impact, reproduction steps, and any safe proof of concept.
Remove private audio, credentials, signing material, and unrelated personal information.

The maintainer will acknowledge a valid report as soon as practical, investigate it privately, and coordinate disclosure after a fix or mitigation is available.

## Security-sensitive areas

ON AIR Deck includes components that require additional care:

- A system-wide Core Audio HAL plug-in installed under `/Library/Audio/Plug-Ins/HAL`.
- Package scripts that require administrator authorization.
- Microphone capture and local audio recording.
- Developer ID signing and Apple notarization credentials used only during release.

The application is designed to process audio locally.
The current source contains no analytics, account system, cloud upload, or remote-control feature.

## Release integrity

Official releases should provide:

- Developer ID signatures for the app and nested executable code.
- A Developer ID Installer signature for the PKG.
- Apple notarization tickets stapled to distributable artifacts.
- A SHA-256 checksum for each downloadable artifact.
- A tag and changelog entry matching the app version.

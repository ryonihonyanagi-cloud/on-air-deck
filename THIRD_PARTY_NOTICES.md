# Third-party notices and bundled assets

## Apple Audio Server Driver sample

Files under `AudioDriver/` are derived from Apple’s Audio Server Driver sample code.
The original copyright and MIT license text are preserved in:

- `AudioDriver/APPLE-SAMPLE-LICENSE.txt`
- `AudioDriver/LICENSE.txt`

Those notices must remain with copies or substantial portions of the derived driver software.

## XcodeGen

XcodeGen is a development-time tool used to generate the Xcode project from `project.yml`.
It is not embedded in the ON AIR Deck application.
Refer to the XcodeGen project for its current license and notices.

## Apple platform frameworks

ON AIR Deck uses public macOS frameworks including SwiftUI, AppKit, AVFoundation, AudioToolbox, CoreAudio, and Accelerate.
These frameworks are supplied by Apple and are not redistributed as project source.

## Bundled demo audio

The application currently contains demo BGM, jingles, sound effects, and short voice clips under `OnAirDeck/Resources/Audio/`.
File metadata identifies `yanagi_amaryllis` as the author of several music files, but metadata alone does not prove the redistribution rights for every asset.

The demo audio is not covered by Apple’s driver license and is not automatically covered by the project’s MIT License.
Before a public repository or binary release, the project owner must complete one of these actions for every bundled audio file:

1. Confirm ownership and grant an explicit redistribution license.
2. Record the third-party source, license, attribution, and permitted modifications.
3. Replace the file with original, commissioned, CC0, or procedurally generated audio whose redistribution terms are documented.
4. Remove the file from public source and release artifacts.

Until that review is complete, bundled demo audio is a public-release blocker.

## Artwork

The application icon and the `DeepClubhouse` artwork also require an owner, source, and redistribution statement before public release.
They should be recorded in the same asset ledger as the audio files.

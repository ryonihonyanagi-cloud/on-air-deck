# ON AIR Deck architecture

## Product boundary

ON AIR Deck is a native macOS application with an optional Core Audio HAL virtual-device driver.
The app performs microphone capture, media playback, voice processing, metering, monitoring, broadcast output, and WAV recording locally.

## Major components

| Component | Responsibility |
| --- | --- |
| `DeckStore` | Pads, BGM library, user imports, selected tracks, and persistent preferences. |
| `AudioController` | UI-facing playback, recording, meter, session, and error state. |
| `VirtualBroadcastEngine` | Shared microphone/media graph, voice effects, compressor, limiter, monitoring, and virtual-device output. |
| `WaveformAnalyzer` | Waveform peak extraction for imported audio. |
| `StudioConsoleView` | LIVE and REC console, mode selection, transport, and mixer controls. |
| `ZoomGuideView` | Guided destination-app setup and readiness checks. |
| `AudioDriver/` | System-wide Core Audio HAL plug-in exposing the `ON AIR Deck` virtual microphone. |

## Audio flow

```text
Physical microphone
    -> selected input channel
    -> stereo conversion
    -> 76 voice compressor
    -> optional voice delay effect
    -> Voice bus -----------+
                            |
BGM deck -----------------> Media bus -> ducking --+
Sample pads --------------> Media bus -> ducking --+-> Master limiter
                                                     |     +-> WAV recorder
                                                     |     +-> virtual microphone
                                                     |     +-> local media monitor
Voice bus -------------------------------------------+     +-> optional voice monitor
```

The compressor and microphone effects must affect only the Voice bus.
The recorder and virtual microphone should receive the same post-limiter master mix.
Voice monitoring is independent from broadcast gain and defaults to off to reduce feedback risk.

## Runtime modes

`LIVE` routes the master mix to the virtual microphone and can optionally record a backup WAV.

`REC` does not require the virtual driver and records the master mix directly to a local WAV file.

Both modes share the same pads, BGM deck, voice effects, compressor, limiter, meters, and emergency stop behavior.

## Persistence and privacy

Imported audio is copied into the user’s ON AIR Deck library directory.
Preferences and library references are stored locally.
The current application has no account, analytics, cloud upload, or remote-control subsystem.

## Driver boundary

The HAL plug-in is intentionally separate from the app project because it is installed system-wide and has a different lifecycle.
Installer changes must preserve the Apple sample-code license and be reviewed for exact installation and removal targets.

## Architecture invariants

- LIVE and REC must not use separate creative-audio implementations.
- The selected microphone channel must remain audible in both stereo output channels.
- Voice effects and compression must never process BGM or pads.
- The final limiter must precede broadcast and WAV capture.
- Recording start and stop must be idempotent from the UI.
- Driver absence must not block REC mode.
- Device reconnects must not silently switch to an unrelated input when the saved device is available again.

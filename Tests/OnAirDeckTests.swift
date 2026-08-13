import AVFoundation
import XCTest
@testable import OnAirDeck

final class OnAirDeckTests: XCTestCase {
    func testStudioModesStaySymmetricAtLaunch() {
        XCTAssertEqual(StudioMode.allCases.map(\.title), ["LIVE", "REC"])
        XCTAssertEqual(StudioMode.live.subtitle, "Zoom / Meet / OBSへ送る")
        XCTAssertEqual(StudioMode.record.subtitle, "このMacへWAV録音")
    }

    func testMicrophoneEffectPresetsRemainWithinFeedbackSafetyLimit() {
        XCTAssertEqual(MicEffectPreset.off.wetDryMix, 0)
        XCTAssertTrue(MicEffectPreset.allCases.allSatisfy { $0.feedback <= 55 })
        XCTAssertGreaterThan(MicEffectPreset.bigTitle.delayTime, MicEffectPreset.echo.delayTime)
    }

    func testBroadcast76CompressorProfileIsFastAndRestrained() {
        let profile = VoiceCompressorProfile.broadcast76
        XCTAssertEqual(profile.threshold, -18)
        XCTAssertLessThanOrEqual(profile.attackTime, 0.005)
        XCTAssertGreaterThanOrEqual(profile.releaseTime, 0.08)
        XCTAssertLessThanOrEqual(profile.releaseTime, 0.2)
        XCTAssertGreaterThan(profile.headroom, 3)
        XCTAssertLessThanOrEqual(profile.makeupGain, 3)
        XCTAssertEqual(profile.expansionRatio, 1)
    }

    @MainActor
    func testBroadcast76ParametersReachAppleDynamicsProcessorAndCanBypass() throws {
        let compressor = AVAudioUnitEffect(
            audioComponentDescription: AudioComponentDescription(
                componentType: kAudioUnitType_Effect,
                componentSubType: kAudioUnitSubType_DynamicsProcessor,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0
            )
        )
        VirtualBroadcastEngine.configureVoiceCompressor(compressor, enabled: true)
        XCTAssertFalse(compressor.bypass)

        func value(_ parameter: AudioUnitParameterID) throws -> Float {
            var result: AudioUnitParameterValue = 0
            let status = AudioUnitGetParameter(
                compressor.audioUnit,
                parameter,
                kAudioUnitScope_Global,
                0,
                &result
            )
            XCTAssertEqual(status, noErr)
            return result
        }

        XCTAssertEqual(try value(AudioUnitParameterID(kDynamicsProcessorParam_Threshold)), -18, accuracy: 0.01)
        XCTAssertEqual(try value(AudioUnitParameterID(kDynamicsProcessorParam_AttackTime)), 0.003, accuracy: 0.0001)
        XCTAssertEqual(try value(AudioUnitParameterID(kDynamicsProcessorParam_ReleaseTime)), 0.12, accuracy: 0.001)

        VirtualBroadcastEngine.configureVoiceCompressor(compressor, enabled: false)
        XCTAssertTrue(compressor.bypass)
    }

    func testPadCategoryLabelsRemainBroadcastSafe() {
        XCTAssertEqual(PadCategory.allCases.map(\.rawValue), ["JINGLE", "SFX", "VOICE"])
    }

    func testWaveformFallbackHasRequestedSize() {
        let values = WaveformAnalyzer.peaks(url: URL(fileURLWithPath: "/does/not/exist.wav"), count: 37)
        XCTAssertEqual(values.count, 37)
        XCTAssertTrue(values.allSatisfy { $0 >= 0 && $0 <= 1 })
    }

    @MainActor
    func testMultichannelMicrophoneIsCollapsedToStereo() throws {
        let layout = try XCTUnwrap(AVAudioChannelLayout(
            layoutTag: kAudioChannelLayoutTag_DiscreteInOrder | 8
        ))
        let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channelLayout: layout)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 64))
        buffer.frameLength = 64
        let channels = try XCTUnwrap(buffer.floatChannelData)
        for frame in 0..<64 {
            channels[0][frame] = 0.001
            channels[2][frame] = 0.65
        }

        let stereo = try XCTUnwrap(VirtualBroadcastEngine.stereoMicrophoneBuffer(
            from: buffer,
            channel: 2
        ))
        let stereoChannels = try XCTUnwrap(stereo.floatChannelData)
        XCTAssertEqual(stereo.format.channelCount, 2)
        XCTAssertEqual(stereo.frameLength, 64)
        XCTAssertEqual(stereoChannels[0][20], Float(0.65), accuracy: Float(0.0001))
        XCTAssertEqual(stereoChannels[1][20], Float(0.65), accuracy: Float(0.0001))
    }

    @MainActor
    func testPadImportUsesOriginalFilenameAndProducesWaveform() throws {
        let fixture = try makeFixtureDirectory()
        defer {
            UserDefaults.standard.removeObject(forKey: fixture.defaultsKey)
            try? FileManager.default.removeItem(at: fixture.root)
        }
        let source = fixture.root.appendingPathComponent("My_Air_Horn.wav")
        try writeTone(to: source, frequency: 440)

        let store = DeckStore(defaultsKey: fixture.defaultsKey, libraryDirectory: fixture.library)
        let padID = try XCTUnwrap(store.pads.first?.id)
        store.importFile(source, for: padID)

        let importedPad = try XCTUnwrap(store.pads.first)
        XCTAssertEqual(importedPad.title, "MY AIR HORN")
        XCTAssertNotEqual(importedPad.localPath, source.path)
        let copiedURL = try XCTUnwrap(store.url(for: importedPad))
        XCTAssertTrue(FileManager.default.fileExists(atPath: copiedURL.path))
        let peaks = WaveformAnalyzer.peaks(url: copiedURL, count: 48)
        XCTAssertEqual(peaks.count, 48)
        XCTAssertTrue(peaks.contains { $0 > 0.3 })
    }

    @MainActor
    func testMultipleBGMImportSelectionRemovalAndPersistence() throws {
        let fixture = try makeFixtureDirectory()
        defer {
            UserDefaults.standard.removeObject(forKey: fixture.defaultsKey)
            try? FileManager.default.removeItem(at: fixture.root)
        }
        let first = fixture.root.appendingPathComponent("Daytime_Cafe.wav")
        let second = fixture.root.appendingPathComponent("News_Bed.wav")
        try writeTone(to: first, frequency: 220)
        try writeTone(to: second, frequency: 330)

        let store = DeckStore(defaultsKey: fixture.defaultsKey, libraryDirectory: fixture.library)
        let initialCount = store.bgmTracks.count
        XCTAssertEqual(store.importBGMFiles([first, second]), 2)
        XCTAssertEqual(store.bgmTracks.count, initialCount + 2)
        XCTAssertEqual(store.bgmTracks.suffix(2).map(\.title), ["DAYTIME CAFE", "NEWS BED"])
        XCTAssertTrue(store.selectedTrack?.subtitle.hasPrefix("IMPORTED · ") == true)

        let selectedID = try XCTUnwrap(store.selectedTrackID)
        store.removeBGM(selectedID)
        XCTAssertEqual(store.bgmTracks.count, initialCount + 1)
        XCTAssertNotEqual(store.selectedTrackID, selectedID)

        let restored = DeckStore(defaultsKey: fixture.defaultsKey, libraryDirectory: fixture.library)
        XCTAssertEqual(restored.bgmTracks.count, initialCount + 1)
        XCTAssertEqual(restored.selectedTrackID, store.selectedTrackID)
    }

    private func makeFixtureDirectory() throws -> (root: URL, library: URL, defaultsKey: String) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("OnAirDeckTests-\(UUID().uuidString)", isDirectory: true)
        let library = root.appendingPathComponent("Library", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let defaultsKey = "on-air-deck.tests.\(UUID().uuidString)"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        return (root, library, defaultsKey)
    }

    private func writeTone(to url: URL, frequency: Double) throws {
        let sampleRate = 48_000.0
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
        let frameCount = AVAudioFrameCount(sampleRate / 4)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount))
        buffer.frameLength = frameCount
        let channel = try XCTUnwrap(buffer.floatChannelData?[0])
        for frame in 0..<Int(frameCount) {
            channel[frame] = Float(sin(2 * .pi * frequency * Double(frame) / sampleRate) * 0.55)
        }
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
    }
}

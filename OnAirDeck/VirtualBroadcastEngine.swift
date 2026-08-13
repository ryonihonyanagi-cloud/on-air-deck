@preconcurrency import AVFoundation
import AudioToolbox
import CoreAudio
import Foundation

struct AudioInputDevice: Identifiable, Equatable {
    let uid: String
    let name: String

    var id: String { uid }
}

/// Sends the deck mix to the bundled ON AIR Deck Core Audio loopback driver.
/// The existing AVAudioPlayer instances remain the zero-latency local monitor.
@MainActor
final class VirtualBroadcastEngine: ObservableObject {
    enum OutputMode: Equatable {
        case virtualMic
        case silentRecording
    }

    static let deviceUID = "jp.ryonihonyanagi.OnAirDeckAudio.Device"
    private static var developmentDeviceName: String? {
        ProcessInfo.processInfo.environment["ON_AIR_DECK_DEVICE_NAME"]
    }
    private static var developmentMonitorDeviceName: String? {
        ProcessInfo.processInfo.environment["ON_AIR_DECK_MONITOR_DEVICE_NAME"]
    }
    private static var developmentMicrophoneDeviceName: String? {
        ProcessInfo.processInfo.environment["ON_AIR_DECK_MIC_DEVICE_NAME"]
    }

    @Published private(set) var driverAvailable = false
    @Published private(set) var isActive = false
    @Published private(set) var micLevel: Double = 0
    @Published private(set) var status = L10n.text("VIRTUAL MIC OFFLINE")
    @Published private(set) var microphoneChannelCount = 1
    @Published private(set) var selectedMicrophoneChannel = 0

    private let engine = AVAudioEngine()
    private let micCaptureEngine = AVAudioEngine()
    private let micNode = AVAudioPlayerNode()
    private let micCompressor = AVAudioUnitEffect(
        audioComponentDescription: AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_DynamicsProcessor,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
    )
    private let micDelay = AVAudioUnitDelay()
    private let voiceMonitorEngine = AVAudioEngine()
    private let voiceMonitorNode = AVAudioPlayerNode()
    private let voiceMonitorCompressor = AVAudioUnitEffect(
        audioComponentDescription: AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_DynamicsProcessor,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
    )
    private let voiceMonitorDelay = AVAudioUnitDelay()
    private let outputGainNode = AVAudioMixerNode()
    private let limiterNode = AVAudioUnitEffect(
        audioComponentDescription: AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_PeakLimiter,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
    )
    private var padNodes: [UUID: AVAudioPlayerNode] = [:]
    private var bgmNode: AVAudioPlayerNode?
    private var bgmBuffer: AVAudioPCMBuffer?
    private var retiredNodes: [AVAudioPlayerNode] = []
    private var micTapInstalled = false
    private var microphoneRelayFormat: AVAudioFormat?
    private var selectedMicrophoneUID: String?
    private var voiceMonitorRequested = false
    private var voiceMonitorVolume: Double = 0.30
    private var lastRecoveryAttempt = Date.distantPast
    private var outputMode: OutputMode = .virtualMic
    private var micEffectPreset: MicEffectPreset = .off
    private var voiceCompressorEnabled = true
    private var recordingFile: AVAudioFile?
    private var recordingTapInstalled = false

    init() {
        refreshDriverStatus()
    }

    func refreshDriverStatus() {
        driverAvailable = Self.findDeviceID(uid: Self.deviceUID, fallbackName: Self.developmentDeviceName) != nil
        if !isActive {
            status = L10n.text(driverAvailable ? "VIRTUAL MIC READY" : "DRIVER REQUIRED")
        }
    }

    func availableMicrophones() -> [AudioInputDevice] {
        Self.audioInputDevices().filter { $0.uid != Self.deviceUID }
    }

    func preferredMicrophoneUID() -> String? {
        let devices = availableMicrophones()
        if let developmentMicrophoneDeviceName = Self.developmentMicrophoneDeviceName,
           let developmentDevice = devices.first(where: { $0.name == developmentMicrophoneDeviceName }) {
            return developmentDevice.uid
        }
        if let selectedMicrophoneUID, devices.contains(where: { $0.uid == selectedMicrophoneUID }) {
            return selectedMicrophoneUID
        }
        return Self.defaultInputDeviceUID().flatMap { defaultUID in
            devices.contains(where: { $0.uid == defaultUID }) ? defaultUID : nil
        } ?? devices.first?.uid
    }

    @discardableResult
    func selectMicrophone(uid: String) -> Bool {
        selectedMicrophoneUID = uid
        guard isActive else { return true }
        do {
            stopMicrophoneCapture()
            try configureMicrophoneCapture()
            if !micCaptureEngine.isRunning { try micCaptureEngine.start() }
            if !micNode.isPlaying { micNode.play() }
            status = activeStatus
            return true
        } catch {
            micLevel = 0
            status = L10n.text("MIC INPUT ERROR")
            return false
        }
    }

    @discardableResult
    func selectMicrophoneChannel(_ channel: Int) -> Bool {
        selectedMicrophoneChannel = max(0, min(channel, microphoneChannelCount - 1))
        guard isActive else { return true }
        do {
            stopMicrophoneCapture()
            try configureMicrophoneCapture()
            if !micCaptureEngine.isRunning { try micCaptureEngine.start() }
            if !micNode.isPlaying { micNode.play() }
            status = activeStatus
            return true
        } catch {
            micLevel = 0
            status = L10n.text("MIC INPUT ERROR")
            return false
        }
    }

    @discardableResult
    func start(captureMicrophone: Bool = true, outputMode requestedMode: OutputMode = .virtualMic) -> Bool {
        if isActive, outputMode == requestedMode { return true }
        if isActive { stop() }
        outputMode = requestedMode
        refreshDriverStatus()

        do {
            switch requestedMode {
            case .virtualMic:
                guard let deviceID = Self.findDeviceID(uid: Self.deviceUID, fallbackName: Self.developmentDeviceName) else {
                    status = L10n.text("INSTALL AUDIO DRIVER")
                    return false
                }
                try configureOutput(deviceID: deviceID, silent: false)
            case .silentRecording:
                try configureOutput(deviceID: nil, silent: true)
            }
            if captureMicrophone { try configureMicrophoneCapture() }
            if !engine.isRunning { try engine.start() }
            if captureMicrophone {
                if !micCaptureEngine.isRunning { try micCaptureEngine.start() }
                micNode.play()
            }
            isActive = true
            status = activeStatus
            return true
        } catch {
            stop()
            status = L10n.text("AUDIO ENGINE ERROR")
            return false
        }
    }

    func stop() {
        stopRecording()
        stopAllSounds()
        voiceMonitorRequested = false
        stopMicrophoneCapture()
        micNode.stop()
        engine.stop()
        for node in retiredNodes { engine.detach(node) }
        retiredNodes.removeAll()
        isActive = false
        micLevel = 0
        refreshDriverStatus()
    }

    func setMicEffect(_ preset: MicEffectPreset) {
        micEffectPreset = preset
        applyMicEffect(to: micDelay, preset: preset)
        applyMicEffect(to: voiceMonitorDelay, preset: preset)
    }

    func setVoiceCompressorEnabled(_ enabled: Bool) {
        voiceCompressorEnabled = enabled
        applyVoiceCompressor(to: micCompressor, enabled: enabled)
        applyVoiceCompressor(to: voiceMonitorCompressor, enabled: enabled)
    }

    func startRecording(to url: URL) throws {
        guard isActive else { throw BroadcastError.engineNotRunning }
        stopRecording()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 48_000,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 24,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let file = try AVAudioFile(
            forWriting: url,
            settings: settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: 48_000,
            channels: 2
        ) else { throw BroadcastError.invalidRecordingFormat }
        // Capture the same post-limiter master that is sent to LIVE output.
        limiterNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            do { try file.write(from: buffer) }
            catch {
#if DEBUG
                print("REC_WRITE_ERROR=\(error)")
#endif
            }
        }
        recordingFile = file
        recordingTapInstalled = true
    }

    func stopRecording() {
        if recordingTapInstalled {
            limiterNode.removeTap(onBus: 0)
            recordingTapInstalled = false
        }
        recordingFile = nil
    }

    @discardableResult
    func setVoiceMonitorEnabled(_ enabled: Bool) -> Bool {
        voiceMonitorRequested = enabled
        guard enabled else {
            stopVoiceMonitorOutput()
            return true
        }
        guard micTapInstalled, let microphoneRelayFormat else { return false }
        do {
            try startVoiceMonitorOutput(format: microphoneRelayFormat)
            return true
        } catch {
            voiceMonitorRequested = false
            stopVoiceMonitorOutput()
            return false
        }
    }

    func setVoiceMonitorVolume(_ volume: Double) {
        voiceMonitorVolume = max(0, min(1, volume))
        voiceMonitorNode.volume = Float(voiceMonitorVolume)
    }

    /// Core Audio can stop an engine when a USB interface, virtual device, or
    /// conferencing app changes its I/O configuration. Keep an active session
    /// honest and recover the audio path instead of leaving the UI stuck on LIVE.
    func maintainActiveAudioPath() {
        guard isActive, Date().timeIntervalSince(lastRecoveryAttempt) >= 0.75 else { return }
        guard !engine.isRunning || !micCaptureEngine.isRunning ||
                (voiceMonitorRequested && !voiceMonitorEngine.isRunning) else { return }
        lastRecoveryAttempt = Date()

        do {
            let relayNeedsReset = !engine.isRunning || !micCaptureEngine.isRunning
            if relayNeedsReset {
                micNode.stop()
                micNode.reset()
            }
            if !engine.isRunning { try engine.start() }
            if !micCaptureEngine.isRunning { try micCaptureEngine.start() }
            if !micNode.isPlaying { micNode.play() }
            if voiceMonitorRequested {
                if !voiceMonitorEngine.isRunning { try voiceMonitorEngine.start() }
                if !voiceMonitorNode.isPlaying { voiceMonitorNode.play() }
            }
            status = activeStatus
        } catch {
            status = L10n.text("RECONNECTING AUDIO")
        }
    }

    func playOneShot(id: UUID, url: URL, volume: Double) {
        guard isActive, let buffer = Self.loadBuffer(url: url) else { return }
        if let oldNode = padNodes.removeValue(forKey: id) {
            oldNode.stop()
            retiredNodes.append(oldNode)
        }

        let node = AVAudioPlayerNode()
        padNodes[id] = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: buffer.format)
        node.volume = Float(max(0, min(1, volume)))
        node.scheduleBuffer(buffer, at: nil, options: []) { [weak self, weak node] in
            Task { @MainActor in
                guard let self, let node, self.padNodes[id] === node else { return }
                self.padNodes[id] = nil
                node.stop()
                self.retiredNodes.append(node)
            }
        }
        node.play()
    }

    func stopOneShot(id: UUID) {
        guard let node = padNodes.removeValue(forKey: id) else { return }
        node.stop()
        retiredNodes.append(node)
    }

    func playBGM(url: URL, volume: Double, loop: Bool) {
        guard isActive, let buffer = Self.loadBuffer(url: url) else { return }
        stopBGM()
        let node = AVAudioPlayerNode()
        bgmNode = node
        bgmBuffer = buffer
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: buffer.format)
        node.volume = Float(max(0, min(1, volume)))
        node.scheduleBuffer(buffer, at: nil, options: loop ? [.loops] : [])
        node.play()
    }

    func pauseBGM() { bgmNode?.pause() }
    func resumeBGM() { bgmNode?.play() }

    func setBGMVolume(_ volume: Double) {
        bgmNode?.volume = Float(max(0, min(1, volume)))
    }

    func setPadVolume(_ volume: Double) {
        let value = Float(max(0, min(1, volume)))
        for node in padNodes.values { node.volume = value }
    }

    func stopBGM() {
        guard let node = bgmNode else { return }
        node.stop()
        retiredNodes.append(node)
        bgmNode = nil
        bgmBuffer = nil
    }

    func stopAllSounds() {
        for node in padNodes.values {
            node.stop()
            retiredNodes.append(node)
        }
        padNodes.removeAll()
        stopBGM()
    }

    private func configureOutput(deviceID: AudioDeviceID?, silent: Bool) throws {
        if !engine.attachedNodes.contains(micNode) { engine.attach(micNode) }
        if !engine.attachedNodes.contains(micCompressor) { engine.attach(micCompressor) }
        if !engine.attachedNodes.contains(micDelay) { engine.attach(micDelay) }
        if !engine.attachedNodes.contains(limiterNode) { engine.attach(limiterNode) }
        if !engine.attachedNodes.contains(outputGainNode) { engine.attach(outputGainNode) }

        if let deviceID {
            guard let outputUnit = engine.outputNode.audioUnit else {
                throw BroadcastError.missingOutputUnit
            }
            var mutableID = deviceID
            let status = AudioUnitSetProperty(
                outputUnit,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global,
                0,
                &mutableID,
                UInt32(MemoryLayout<AudioDeviceID>.size)
            )
            guard status == noErr else { throw BroadcastError.coreAudio(status) }
        }

        engine.disconnectNodeOutput(engine.mainMixerNode)
        engine.disconnectNodeOutput(limiterNode)
        engine.disconnectNodeOutput(outputGainNode)
        guard let mixFormat = AVAudioFormat(
            standardFormatWithSampleRate: 48_000,
            channels: 2
        ) else { throw BroadcastError.invalidRecordingFormat }
        engine.connect(engine.mainMixerNode, to: limiterNode, format: mixFormat)
        engine.connect(limiterNode, to: outputGainNode, format: mixFormat)
        engine.connect(outputGainNode, to: engine.outputNode, format: nil)
        outputGainNode.outputVolume = silent ? 0 : 1
        applyVoiceCompressor(to: micCompressor, enabled: voiceCompressorEnabled)
        applyMicEffect(to: micDelay, preset: micEffectPreset)
        engine.prepare()
    }

    private func configureMicrophoneCapture() throws {
        guard !micTapInstalled else { return }
        let input = micCaptureEngine.inputNode
        let selectedUID = preferredMicrophoneUID()
        selectedMicrophoneUID = selectedUID
        if let selectedUID,
           let deviceID = Self.findDeviceID(uid: selectedUID),
           let inputUnit = input.audioUnit {
            var mutableID = deviceID
            let status = AudioUnitSetProperty(
                inputUnit,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global,
                0,
                &mutableID,
                UInt32(MemoryLayout<AudioDeviceID>.size)
            )
            guard status == noErr else { throw BroadcastError.coreAudio(status) }
        }
        let format = input.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw BroadcastError.missingMicrophone
        }
        microphoneChannelCount = Int(format.channelCount)
        selectedMicrophoneChannel = max(0, min(selectedMicrophoneChannel, microphoneChannelCount - 1))
        let relayChannel = selectedMicrophoneChannel
        guard let relayFormat = AVAudioFormat(
            standardFormatWithSampleRate: format.sampleRate,
            channels: 2
        ) else {
            throw BroadcastError.missingMicrophone
        }
        microphoneRelayFormat = relayFormat
        engine.disconnectNodeOutput(micNode)
        engine.disconnectNodeOutput(micCompressor)
        engine.disconnectNodeOutput(micDelay)
        engine.connect(micNode, to: micCompressor, format: relayFormat)
        engine.connect(micCompressor, to: micDelay, format: relayFormat)
        engine.connect(micDelay, to: engine.mainMixerNode, format: relayFormat)
        applyVoiceCompressor(to: micCompressor, enabled: voiceCompressorEnabled)
        applyMicEffect(to: micDelay, preset: micEffectPreset)
        if voiceMonitorRequested {
            try startVoiceMonitorOutput(format: relayFormat)
        }

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self, weak micNode, weak voiceMonitorNode] buffer, _ in
            guard let self, let micNode,
                  let relayBuffer = Self.stereoMicrophoneBuffer(
                    from: buffer,
                    channel: relayChannel
                  ) else { return }
            let level = Self.peakLevel(buffer: relayBuffer)
            micNode.scheduleBuffer(relayBuffer)
            if !micNode.isPlaying { micNode.play() }
            if let voiceMonitorNode,
               voiceMonitorNode.isPlaying,
               let monitorCopy = Self.copy(buffer: relayBuffer) {
                voiceMonitorNode.scheduleBuffer(monitorCopy)
            }
            Task { @MainActor [weak self] in
                self?.micLevel = max((self?.micLevel ?? 0) * 0.72, level)
            }
        }
        micTapInstalled = true
        micCaptureEngine.prepare()
    }

    private func stopMicrophoneCapture() {
        stopVoiceMonitorOutput()
        if micTapInstalled {
            micCaptureEngine.inputNode.removeTap(onBus: 0)
            micTapInstalled = false
        }
        micCaptureEngine.stop()
        micNode.stop()
        micNode.reset()
        if engine.attachedNodes.contains(micNode) {
            engine.disconnectNodeOutput(micNode)
        }
        if engine.attachedNodes.contains(micCompressor) {
            engine.disconnectNodeOutput(micCompressor)
        }
        if engine.attachedNodes.contains(micDelay) {
            engine.disconnectNodeOutput(micDelay)
        }
        microphoneRelayFormat = nil
    }

    private func startVoiceMonitorOutput(format: AVAudioFormat) throws {
        stopVoiceMonitorOutput()
        if !voiceMonitorEngine.attachedNodes.contains(voiceMonitorNode) {
            voiceMonitorEngine.attach(voiceMonitorNode)
        }
        if !voiceMonitorEngine.attachedNodes.contains(voiceMonitorCompressor) {
            voiceMonitorEngine.attach(voiceMonitorCompressor)
        }
        if !voiceMonitorEngine.attachedNodes.contains(voiceMonitorDelay) {
            voiceMonitorEngine.attach(voiceMonitorDelay)
        }
        voiceMonitorEngine.disconnectNodeOutput(voiceMonitorNode)
        voiceMonitorEngine.disconnectNodeOutput(voiceMonitorCompressor)
        voiceMonitorEngine.disconnectNodeOutput(voiceMonitorDelay)
        voiceMonitorEngine.connect(voiceMonitorNode, to: voiceMonitorCompressor, format: format)
        voiceMonitorEngine.connect(voiceMonitorCompressor, to: voiceMonitorDelay, format: format)
        voiceMonitorEngine.connect(voiceMonitorDelay, to: voiceMonitorEngine.mainMixerNode, format: format)
        applyVoiceCompressor(to: voiceMonitorCompressor, enabled: voiceCompressorEnabled)
        applyMicEffect(to: voiceMonitorDelay, preset: micEffectPreset)

        if let monitorDeviceName = Self.developmentMonitorDeviceName,
           let monitorDeviceID = Self.findDeviceID(uid: "", fallbackName: monitorDeviceName),
           let outputUnit = voiceMonitorEngine.outputNode.audioUnit {
            var mutableID = monitorDeviceID
            let status = AudioUnitSetProperty(
                outputUnit,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global,
                0,
                &mutableID,
                UInt32(MemoryLayout<AudioDeviceID>.size)
            )
            guard status == noErr else { throw BroadcastError.coreAudio(status) }
        }

        voiceMonitorNode.volume = Float(voiceMonitorVolume)
        voiceMonitorEngine.prepare()
        try voiceMonitorEngine.start()
        voiceMonitorNode.play()
    }

    private func stopVoiceMonitorOutput() {
        voiceMonitorNode.stop()
        voiceMonitorEngine.stop()
        if voiceMonitorEngine.attachedNodes.contains(voiceMonitorNode) {
            voiceMonitorEngine.disconnectNodeOutput(voiceMonitorNode)
        }
        if voiceMonitorEngine.attachedNodes.contains(voiceMonitorCompressor) {
            voiceMonitorEngine.disconnectNodeOutput(voiceMonitorCompressor)
        }
        if voiceMonitorEngine.attachedNodes.contains(voiceMonitorDelay) {
            voiceMonitorEngine.disconnectNodeOutput(voiceMonitorDelay)
        }
    }

    private func applyMicEffect(to delay: AVAudioUnitDelay, preset: MicEffectPreset) {
        delay.delayTime = preset.delayTime
        delay.feedback = min(55, preset.feedback)
        delay.wetDryMix = preset.wetDryMix
        delay.lowPassCutoff = preset == .bigTitle ? 7_000 : 12_000
    }

    private func applyVoiceCompressor(to compressor: AVAudioUnitEffect, enabled: Bool) {
        Self.configureVoiceCompressor(compressor, enabled: enabled)
    }

    static func configureVoiceCompressor(
        _ compressor: AVAudioUnitEffect,
        enabled: Bool,
        profile: VoiceCompressorProfile = .broadcast76
    ) {
        compressor.bypass = !enabled
        guard enabled else { return }
        let unit = compressor.audioUnit
        let parameters: [(AudioUnitParameterID, AudioUnitParameterValue)] = [
            (AudioUnitParameterID(kDynamicsProcessorParam_Threshold), profile.threshold),
            (AudioUnitParameterID(kDynamicsProcessorParam_HeadRoom), profile.headroom),
            (AudioUnitParameterID(kDynamicsProcessorParam_ExpansionRatio), profile.expansionRatio),
            (AudioUnitParameterID(kDynamicsProcessorParam_ExpansionThreshold), profile.expansionThreshold),
            (AudioUnitParameterID(kDynamicsProcessorParam_AttackTime), profile.attackTime),
            (AudioUnitParameterID(kDynamicsProcessorParam_ReleaseTime), profile.releaseTime),
            (AudioUnitParameterID(kDynamicsProcessorParam_OverallGain), profile.makeupGain)
        ]
        for (parameter, value) in parameters {
            let status = AudioUnitSetParameter(unit, parameter, kAudioUnitScope_Global, 0, value, 0)
#if DEBUG
            if status != noErr { print("VOICE_COMP_PARAMETER_ERROR=\(parameter):\(status)") }
#endif
        }
    }

    private var activeStatus: String {
        switch outputMode {
        case .virtualMic: return L10n.text("48 kHz VIRTUAL MIC LIVE")
        case .silentRecording: return L10n.text("48 kHz RECORDING ENGINE READY")
        }
    }

    private static func loadBuffer(url: URL) -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        guard file.length > 0, file.length <= Int64(UInt32.max),
              let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
              ) else { return nil }
        do {
            try file.read(into: buffer)
            return buffer
        } catch {
            return nil
        }
    }

    private static func copy(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) else { return nil }
        copy.frameLength = buffer.frameLength
        let source = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        let destination = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        for index in 0..<min(source.count, destination.count) {
            guard let src = source[index].mData, let dst = destination[index].mData else { continue }
            memcpy(dst, src, Int(min(source[index].mDataByteSize, destination[index].mDataByteSize)))
        }
        return copy
    }

    /// Conference apps expect a two-channel microphone even when a professional
    /// interface exposes many hardware channels. Send the selected hardware input
    /// equally to left and right so Zoom always receives a centered voice.
    static func stereoMicrophoneBuffer(
        from buffer: AVAudioPCMBuffer,
        channel requestedChannel: Int
    ) -> AVAudioPCMBuffer? {
        guard let sourceChannels = buffer.floatChannelData,
              buffer.format.channelCount > 0,
              let stereoFormat = AVAudioFormat(
                standardFormatWithSampleRate: buffer.format.sampleRate,
                channels: 2
              ),
              let stereoBuffer = AVAudioPCMBuffer(
                pcmFormat: stereoFormat,
                frameCapacity: buffer.frameLength
              ),
              let destinationChannels = stereoBuffer.floatChannelData else { return nil }

        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        let selectedChannel = max(0, min(requestedChannel, channelCount - 1))
        stereoBuffer.frameLength = buffer.frameLength
        for frame in 0..<frameCount {
            let sample = sourceChannels[selectedChannel][frame]
            destinationChannels[0][frame] = sample
            destinationChannels[1][frame] = sample
        }
        return stereoBuffer
    }

    private static func peakLevel(buffer: AVAudioPCMBuffer) -> Double {
        guard let channels = buffer.floatChannelData else { return 0 }
        var peak: Float = 0
        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        for channel in 0..<channelCount {
            for frame in stride(from: 0, to: frameCount, by: 8) {
                peak = max(peak, abs(channels[channel][frame]))
            }
        }
        return min(1, Double(peak))
    }

    private static func findDeviceID(uid: String, fallbackName: String? = nil) -> AudioDeviceID? {
        var property = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &property, 0, nil, &size) == noErr else { return nil }
        var devices = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &property, 0, nil, &size, &devices) == noErr else { return nil }

        for device in devices {
            var uidProperty = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var value: Unmanaged<CFString>?
            var valueSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            if AudioObjectGetPropertyData(device, &uidProperty, 0, nil, &valueSize, &value) == noErr,
               value?.takeUnretainedValue() as String? == uid {
                return device
            }

            if let fallbackName {
                var nameProperty = AudioObjectPropertyAddress(
                    mSelector: kAudioObjectPropertyName,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                var nameValue: Unmanaged<CFString>?
                var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
                if AudioObjectGetPropertyData(device, &nameProperty, 0, nil, &nameSize, &nameValue) == noErr,
                   nameValue?.takeUnretainedValue() as String? == fallbackName {
                    return device
                }
            }
        }
        return nil
    }

    private static func audioInputDevices() -> [AudioInputDevice] {
        allDeviceIDs().compactMap { deviceID in
            guard inputChannelCount(deviceID: deviceID) > 0,
                  let uid = stringProperty(
                    deviceID: deviceID,
                    selector: kAudioDevicePropertyDeviceUID
                  ),
                  let name = stringProperty(
                    deviceID: deviceID,
                    selector: kAudioObjectPropertyName
                  ) else { return nil }
            return AudioInputDevice(uid: uid, name: name)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func allDeviceIDs() -> [AudioDeviceID] {
        var property = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &property,
            0,
            nil,
            &size
        ) == noErr else { return [] }
        var devices = [AudioDeviceID](
            repeating: 0,
            count: Int(size) / MemoryLayout<AudioDeviceID>.size
        )
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &property,
            0,
            nil,
            &size,
            &devices
        ) == noErr else { return [] }
        return devices
    }

    private static func inputChannelCount(deviceID: AudioDeviceID) -> Int {
        var property = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &property, 0, nil, &size) == noErr,
              size >= UInt32(MemoryLayout<AudioBufferList>.size) else { return 0 }
        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { raw.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &property, 0, nil, &size, raw) == noErr else { return 0 }
        let list = raw.assumingMemoryBound(to: AudioBufferList.self)
        return UnsafeMutableAudioBufferListPointer(list).reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private static func stringProperty(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector
    ) -> String? {
        var property = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(deviceID, &property, 0, nil, &size, &value) == noErr else { return nil }
        return value?.takeUnretainedValue() as String?
    }

    private static func defaultInputDeviceUID() -> String? {
        var property = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &property,
            0,
            nil,
            &size,
            &deviceID
        ) == noErr,
        deviceID != kAudioObjectUnknown else { return nil }
        return stringProperty(deviceID: deviceID, selector: kAudioDevicePropertyDeviceUID)
    }

    private enum BroadcastError: Error {
        case missingOutputUnit
        case missingMicrophone
        case engineNotRunning
        case invalidRecordingFormat
        case coreAudio(OSStatus)
    }
}

import AppKit
import AVFoundation
import Combine

@MainActor
final class AudioController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var activePadIDs: Set<UUID> = []
    @Published private(set) var padProgress: [UUID: Double] = [:]
    @Published private(set) var bgmProgress: Double = 0
    @Published private(set) var bgmDuration: TimeInterval = 0
    @Published private(set) var bgmCurrentTime: TimeInterval = 0
    @Published private(set) var isBGMPlaying = false
    @Published private(set) var currentBGMID: UUID?
    @Published private(set) var masterMeter: Double = 0
    @Published private(set) var zoomIsRunning = false
    @Published private(set) var virtualMicAvailable = false
    @Published private(set) var virtualMicStatus = L10n.text("DRIVER REQUIRED")
    @Published private(set) var microphoneMeter: Double = 0
    @Published private(set) var microphoneDevices: [AudioInputDevice] = []
    @Published private(set) var selectedMicrophoneUID: String?
    @Published private(set) var selectedMicrophoneName = L10n.text("SYSTEM DEFAULT")
    @Published private(set) var microphoneChannelCount = 1
    @Published private(set) var selectedMicrophoneChannel = 0
    @Published var masterVolume: Double = 0.82 { didSet { applyVolumes() } }
    @Published var bgmVolume: Double = 0.60 { didSet { applyVolumes() } }
    @Published var autoDuck = true { didSet { applyVolumes() } }
    @Published var loopBGM = true
    @Published var isOnAir = false
    @Published private(set) var isRecording = false
    @Published private(set) var recordingElapsed: TimeInterval = 0
    @Published private(set) var recordingURL: URL?
    @Published private(set) var lastRecordingURL: URL?
    @Published private(set) var recordingError: String?
    @Published var studioMode: StudioMode = .record
    @Published var micEffectPreset: MicEffectPreset = .off {
        didSet { virtualBroadcast.setMicEffect(micEffectPreset) }
    }
    @Published var voiceCompressorEnabled = true {
        didSet {
            virtualBroadcast.setVoiceCompressorEnabled(voiceCompressorEnabled)
            UserDefaults.standard.set(voiceCompressorEnabled, forKey: voiceCompressorDefaultsKey)
        }
    }
    @Published private(set) var voiceMonitorEnabled = false
    @Published var voiceMonitorVolume: Double = 0.30 {
        didSet { virtualBroadcast.setVoiceMonitorVolume(voiceMonitorVolume) }
    }
    @Published private(set) var sessionElapsed: TimeInterval = 0

    private var padPlayers: [UUID: AVAudioPlayer] = [:]
    private var playerPadMap: [ObjectIdentifier: UUID] = [:]
    private var bgmPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var sessionStartedAt: Date?
    private var recordingStartedAt: Date?
    private var lastMicrophoneScanAt = Date.distantPast
    private var lastAudioPathCheckAt = Date.distantPast
    private var fadeGeneration = UUID()
    private let virtualBroadcast = VirtualBroadcastEngine()
    private let microphoneDefaultsKey = "on-air-deck.microphone-uid.v1"
    private let voiceCompressorDefaultsKey = "on-air-deck.voice-compressor-enabled.v1"

    override init() {
        super.init()
        if UserDefaults.standard.object(forKey: voiceCompressorDefaultsKey) != nil {
            voiceCompressorEnabled = UserDefaults.standard.bool(forKey: voiceCompressorDefaultsKey)
        } else {
            virtualBroadcast.setVoiceCompressorEnabled(true)
        }
        refreshMicrophones(force: true)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 24.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        timer?.tolerance = 0.01
    }

    deinit { timer?.invalidate() }

    func toggleOnAir() {
        studioMode = .live
        if isOnAir {
            stopAll()
            setVoiceMonitorEnabled(false)
            virtualBroadcast.stop()
            isOnAir = false
            sessionStartedAt = nil
            sessionElapsed = 0
        } else {
            _ = ensureVirtualMicLive()
        }
    }

    func setStudioMode(_ mode: StudioMode) {
        guard !isRecording, !isOnAir else { return }
        if virtualBroadcast.isActive { virtualBroadcast.stop() }
        studioMode = mode
        sessionStartedAt = nil
        sessionElapsed = 0
        recordingError = nil
    }

    func performPrimaryAction() {
        switch studioMode {
        case .live:
            toggleOnAir()
        case .record:
            isRecording ? stopRecording() : startRecording()
        }
    }

    func startRecording() {
        guard !isRecording else { return }
        recordingError = nil
        guard ensureVirtualMicLive() else {
            recordingError = L10n.text("録音エンジンを開始できませんでした。マイク入力を確認してください。")
            NSSound.beep()
            return
        }
        guard let url = Self.nextRecordingURL() else {
            recordingError = L10n.text("録音フォルダを作成できませんでした。")
            NSSound.beep()
            return
        }
        do {
            try virtualBroadcast.startRecording(to: url)
            recordingURL = url
            isRecording = true
            recordingStartedAt = Date()
            sessionStartedAt = recordingStartedAt
            recordingElapsed = 0
        } catch {
            recordingError = L10n.text("WAV録音を開始できませんでした。保存先と空き容量を確認してください。")
            recordingURL = nil
            NSSound.beep()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        virtualBroadcast.stopRecording()
        isRecording = false
        recordingStartedAt = nil
        let fileSize = recordingURL.flatMap {
            try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize
        } ?? 0
        if let recordingURL, fileSize > 44 {
            lastRecordingURL = recordingURL
        } else {
            recordingError = L10n.text("録音ファイルに音声を書き込めませんでした。")
        }
        self.recordingURL = nil
        if studioMode == .record {
            stopAll()
            setVoiceMonitorEnabled(false)
            virtualBroadcast.stop()
            sessionStartedAt = nil
        }
    }

    func revealLastRecording() {
        guard let lastRecordingURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([lastRecordingURL])
    }

    func setVoiceMonitorEnabled(_ enabled: Bool) {
        guard enabled else {
            _ = virtualBroadcast.setVoiceMonitorEnabled(false)
            voiceMonitorEnabled = false
            return
        }
        guard ensureVirtualMicLive(), virtualBroadcast.setVoiceMonitorEnabled(true) else {
            voiceMonitorEnabled = false
            NSSound.beep()
            return
        }
        virtualBroadcast.setVoiceMonitorVolume(voiceMonitorVolume)
        voiceMonitorEnabled = true
    }

    func refreshMicrophones(force: Bool = false) {
        lastMicrophoneScanAt = Date()
        let detectedDevices = virtualBroadcast.availableMicrophones()
        let savedUID = ProcessInfo.processInfo.environment["ON_AIR_DECK_MIC_DEVICE_NAME"] == nil
            ? UserDefaults.standard.string(forKey: microphoneDefaultsKey)
            : nil
        let selectedDeviceStillExists = selectedMicrophoneUID.map { selectedUID in
            detectedDevices.contains(where: { $0.uid == selectedUID })
        } ?? false
        if !force, detectedDevices == microphoneDevices, selectedDeviceStillExists {
            return
        }

        microphoneDevices = detectedDevices
        let resolvedUID = savedUID.flatMap { uid in
            microphoneDevices.contains(where: { $0.uid == uid }) ? uid : nil
        } ?? virtualBroadcast.preferredMicrophoneUID()

        guard let resolvedUID,
              let device = microphoneDevices.first(where: { $0.uid == resolvedUID }) else {
            selectedMicrophoneUID = nil
            selectedMicrophoneName = L10n.text("NO INPUT DEVICE")
            return
        }
        selectedMicrophoneUID = resolvedUID
        selectedMicrophoneName = device.name
        _ = virtualBroadcast.selectMicrophone(uid: resolvedUID)
        syncMicrophoneChannelState()
    }

    func selectMicrophone(_ device: AudioInputDevice) {
        guard microphoneDevices.contains(device) else { return }
        selectedMicrophoneUID = device.uid
        selectedMicrophoneName = device.name
        UserDefaults.standard.set(device.uid, forKey: microphoneDefaultsKey)
        _ = virtualBroadcast.selectMicrophone(uid: device.uid)
        syncMicrophoneChannelState()
    }

    func selectMicrophoneChannel(_ channel: Int) {
        _ = virtualBroadcast.selectMicrophoneChannel(channel)
        syncMicrophoneChannelState()
    }

    func playPad(_ pad: SoundPad, url: URL?) {
        guard let url else { NSSound.beep(); return }
        let broadcastReady = ensureVirtualMicLive()
        do {
            if let existing = padPlayers[pad.id] {
                existing.stop()
                activePadIDs.remove(pad.id)
            }
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.enableRate = false
            player.isMeteringEnabled = true
            player.volume = Float(pad.volume * masterVolume)
            player.prepareToPlay()
            playerPadMap[ObjectIdentifier(player)] = pad.id
            padPlayers[pad.id] = player
            activePadIDs.insert(pad.id)
            padProgress[pad.id] = 0
            player.play()
            if broadcastReady {
                virtualBroadcast.playOneShot(id: pad.id, url: url, volume: pad.volume * masterVolume)
            }
            applyVolumes()
        } catch {
            NSSound.beep()
        }
    }

    func stopPad(_ id: UUID) {
        padPlayers[id]?.stop()
        padPlayers[id] = nil
        activePadIDs.remove(id)
        padProgress[id] = 0
        virtualBroadcast.stopOneShot(id: id)
        applyVolumes()
    }

    func toggleBGM(_ track: BGMTrack, url: URL?) {
        if currentBGMID == track.id, let bgmPlayer, bgmPlayer.isPlaying {
            bgmPlayer.pause()
            virtualBroadcast.pauseBGM()
            isBGMPlaying = false
            return
        }
        if currentBGMID == track.id, let bgmPlayer, bgmPlayer.currentTime > 0 {
            bgmPlayer.play()
            virtualBroadcast.resumeBGM()
            isBGMPlaying = true
            return
        }
        playBGM(track, url: url)
    }

    func playBGM(_ track: BGMTrack, url: URL?, fadeIn: Bool = false) {
        guard let url else { NSSound.beep(); return }
        let broadcastReady = ensureVirtualMicLive()
        do {
            bgmPlayer?.stop()
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loopBGM ? -1 : 0
            player.isMeteringEnabled = true
            player.volume = fadeIn ? 0 : Float(effectiveBGMVolume)
            player.prepareToPlay()
            bgmPlayer = player
            currentBGMID = track.id
            bgmDuration = player.duration
            bgmCurrentTime = 0
            bgmProgress = 0
            isBGMPlaying = player.play()
            if broadcastReady {
                virtualBroadcast.playBGM(url: url, volume: fadeIn ? 0 : effectiveBGMVolume, loop: loopBGM)
            }
            if fadeIn {
                player.setVolume(Float(effectiveBGMVolume), fadeDuration: 2.0)
                virtualBroadcast.setBGMVolume(effectiveBGMVolume)
            }
        } catch {
            NSSound.beep()
        }
    }

    func fadeInBGM(_ track: BGMTrack, url: URL?) {
        if currentBGMID == track.id, let bgmPlayer {
            bgmPlayer.volume = 0
            if !bgmPlayer.isPlaying { bgmPlayer.play() }
            virtualBroadcast.resumeBGM()
            virtualBroadcast.setBGMVolume(effectiveBGMVolume)
            bgmPlayer.setVolume(Float(effectiveBGMVolume), fadeDuration: 2.0)
            isBGMPlaying = true
        } else {
            playBGM(track, url: url, fadeIn: true)
        }
    }

    func fadeOutBGM() {
        guard let player = bgmPlayer, player.isPlaying else { return }
        let generation = UUID()
        fadeGeneration = generation
        player.setVolume(0, fadeDuration: 2.0)
        virtualBroadcast.setBGMVolume(0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.05) { [weak self, weak player] in
            guard let self, self.fadeGeneration == generation, let player else { return }
            player.pause()
            self.isBGMPlaying = false
            self.applyVolumes()
        }
    }

    func seekBGM(to fraction: Double) {
        guard let player = bgmPlayer else { return }
        player.currentTime = max(0, min(1, fraction)) * player.duration
    }

    func setLoop(_ enabled: Bool) {
        loopBGM = enabled
        bgmPlayer?.numberOfLoops = enabled ? -1 : 0
    }

    func stopAll() {
        fadeGeneration = UUID()
        for player in padPlayers.values { player.stop() }
        padPlayers.removeAll()
        activePadIDs.removeAll()
        padProgress.removeAll()
        virtualBroadcast.stopAllSounds()
        bgmPlayer?.stop()
        bgmPlayer = nil
        currentBGMID = nil
        isBGMPlaying = false
        bgmProgress = 0
        bgmCurrentTime = 0
        masterMeter = 0
    }

    func stopBGM() {
        fadeGeneration = UUID()
        bgmPlayer?.stop()
        virtualBroadcast.stopBGM()
        bgmPlayer = nil
        currentBGMID = nil
        isBGMPlaying = false
        bgmProgress = 0
        bgmCurrentTime = 0
        bgmDuration = 0
    }

    func launchZoom() {
        if let zoom = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "us.zoom.xos") {
            NSWorkspace.shared.openApplication(at: zoom, configuration: .init())
        } else if let url = URL(string: "https://zoom.us/start/videomeeting") {
            NSWorkspace.shared.open(url)
        }
    }

    func openDriverInstaller() {
        let installer = Bundle.main.url(
            forResource: "ON AIR Deck Audio Driver",
            withExtension: "pkg",
            subdirectory: "Installer"
        ) ?? Bundle.main.url(forResource: "ON AIR Deck Audio Driver", withExtension: "pkg")
        if let installer {
            NSWorkspace.shared.open(installer)
        } else {
            NSSound.beep()
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let key = ObjectIdentifier(player)
            guard let padID = self.playerPadMap.removeValue(forKey: key) else { return }
            self.padPlayers[padID] = nil
            self.activePadIDs.remove(padID)
            self.padProgress[padID] = 0
            self.applyVolumes()
        }
    }

    private var effectiveBGMVolume: Double {
        let duck = autoDuck && !activePadIDs.isEmpty ? 0.22 : 1.0
        return bgmVolume * masterVolume * duck
    }

    @discardableResult
    private func ensureVirtualMicLive() -> Bool {
        let outputMode: VirtualBroadcastEngine.OutputMode = studioMode == .live ? .virtualMic : .silentRecording
        guard virtualBroadcast.start(outputMode: outputMode) else { return false }
        isOnAir = studioMode == .live
        if studioMode == .live, sessionStartedAt == nil { sessionStartedAt = Date() }
        return true
    }

    private func applyVolumes() {
        bgmPlayer?.setVolume(Float(effectiveBGMVolume), fadeDuration: autoDuck ? 0.16 : 0.04)
        virtualBroadcast.setBGMVolume(effectiveBGMVolume)
        virtualBroadcast.setPadVolume(masterVolume)
        for player in padPlayers.values {
            player.volume = Float(masterVolume)
        }
    }

    private func tick() {
        if Date().timeIntervalSince(lastAudioPathCheckAt) >= 0.5 {
            lastAudioPathCheckAt = Date()
            virtualBroadcast.maintainActiveAudioPath()
        }
        if Date().timeIntervalSince(lastMicrophoneScanAt) >= 2 {
            refreshMicrophones()
        }
        zoomIsRunning = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "us.zoom.xos" }
        virtualMicAvailable = virtualBroadcast.driverAvailable
        virtualMicStatus = virtualBroadcast.status
        microphoneMeter = virtualBroadcast.micLevel
        syncMicrophoneChannelState()
        if isOnAir && !virtualBroadcast.isActive {
            isOnAir = false
            voiceMonitorEnabled = false
            sessionStartedAt = nil
        }
        if let sessionStartedAt { sessionElapsed = Date().timeIntervalSince(sessionStartedAt) }
        if let recordingStartedAt { recordingElapsed = Date().timeIntervalSince(recordingStartedAt) }

        if let bgmPlayer {
            bgmPlayer.updateMeters()
            bgmCurrentTime = bgmPlayer.currentTime
            bgmDuration = bgmPlayer.duration
            bgmProgress = bgmPlayer.duration > 0 ? bgmPlayer.currentTime / bgmPlayer.duration : 0
            if isBGMPlaying && !bgmPlayer.isPlaying && bgmPlayer.numberOfLoops == 0 {
                isBGMPlaying = false
            }
        }

        var peakLinear = bgmPlayer.map { pow(10, Double($0.peakPower(forChannel: 0)) / 20) } ?? 0
        var finishedPadIDs: [UUID] = []
        for (id, player) in padPlayers {
            player.updateMeters()
            padProgress[id] = player.duration > 0 ? player.currentTime / player.duration : 0
            peakLinear = max(peakLinear, pow(10, Double(player.peakPower(forChannel: 0)) / 20))
            if !player.isPlaying && player.currentTime >= player.duration {
                finishedPadIDs.append(id)
            }
        }
        for id in finishedPadIDs {
            padPlayers[id] = nil
            activePadIDs.remove(id)
            padProgress[id] = 0
        }
        masterMeter = max(masterMeter * 0.82, min(1, peakLinear))
    }

    private func syncMicrophoneChannelState() {
        microphoneChannelCount = virtualBroadcast.microphoneChannelCount
        selectedMicrophoneChannel = virtualBroadcast.selectedMicrophoneChannel
    }

    static func recordingDirectory() -> URL? {
        FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ON AIR Deck Recordings", isDirectory: true)
    }

    private static func nextRecordingURL(now: Date = Date()) -> URL? {
        guard let directory = recordingDirectory() else { return nil }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let base = "ON-AIR-Deck_\(formatter.string(from: now))"
        var candidate = directory.appendingPathComponent("\(base).wav")
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(base)-\(suffix).wav")
            suffix += 1
        }
        return candidate
    }
}

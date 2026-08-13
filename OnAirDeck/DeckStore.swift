import AppKit
import AVFoundation
import Foundation
import UniformTypeIdentifiers

@MainActor
final class DeckStore: ObservableObject {
    @Published var pads: [SoundPad] { didSet { save() } }
    @Published var bgmTracks: [BGMTrack] { didSet { save() } }
    @Published var selectedTrackID: UUID? { didSet { save() } }

    private let defaultsKey: String
    private let libraryDirectory: URL?

    private struct Snapshot: Codable {
        let pads: [SoundPad]
        let bgmTracks: [BGMTrack]
        let selectedTrackID: UUID?
    }

    init(defaultsKey: String = "on-air-deck.library.v1", libraryDirectory: URL? = nil) {
        self.defaultsKey = defaultsKey
        self.libraryDirectory = libraryDirectory
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            pads = snapshot.pads
            bgmTracks = snapshot.bgmTracks
            selectedTrackID = snapshot.selectedTrackID
        } else {
            let defaults = Self.defaultLibrary()
            pads = defaults.pads
            bgmTracks = defaults.tracks
            selectedTrackID = defaults.tracks.first?.id
        }
    }

    var selectedTrack: BGMTrack? {
        guard let selectedTrackID else { return bgmTracks.first }
        return bgmTracks.first { $0.id == selectedTrackID } ?? bgmTracks.first
    }

    func url(for pad: SoundPad) -> URL? {
        resolve(resourceName: pad.resourceName, localPath: pad.localPath)
    }

    func url(for track: BGMTrack) -> URL? {
        resolve(resourceName: track.resourceName, localPath: track.localPath)
    }

    func chooseAudio(for padID: UUID) {
        let panel = audioOpenPanel(prompt: "Assign to Pad")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        importFile(url, for: padID)
    }

    func importFile(_ url: URL, for padID: UUID) {
        guard isReadableAudio(url) else { NSSound.beep(); return }
        guard let savedURL = copyToLibrary(url) else { return }
        guard let index = pads.firstIndex(where: { $0.id == padID }) else { return }
        pads[index].localPath = savedURL.path
        pads[index].resourceName = nil
        pads[index].title = displayTitle(for: url)
    }

    func chooseBGM() {
        let panel = audioOpenPanel(prompt: "Add BGM")
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        importBGMFiles(panel.urls)
    }

    @discardableResult
    func importBGMFiles(_ urls: [URL]) -> Int {
        var imported: [BGMTrack] = []
        for url in urls where isReadableAudio(url) {
            guard let savedURL = copyToLibrary(url) else { continue }
            imported.append(
                BGMTrack(
                    title: displayTitle(for: url),
                    subtitle: importedSubtitle(for: savedURL),
                    localPath: savedURL.path
                )
            )
        }
        guard !imported.isEmpty else { NSSound.beep(); return 0 }
        bgmTracks.append(contentsOf: imported)
        selectedTrackID = imported.last?.id
        return imported.count
    }

    func removeBGM(_ id: UUID) {
        guard let index = bgmTracks.firstIndex(where: { $0.id == id }) else { return }
        let wasSelected = selectedTrackID == id
        bgmTracks.remove(at: index)
        if wasSelected {
            guard !bgmTracks.isEmpty else { selectedTrackID = nil; return }
            selectedTrackID = bgmTracks[min(index, bgmTracks.count - 1)].id
        }
    }

    func resetLibrary() {
        let defaults = Self.defaultLibrary()
        pads = defaults.pads
        bgmTracks = defaults.tracks
        selectedTrackID = defaults.tracks.first?.id
    }

    private func audioOpenPanel(prompt: String) -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.title = prompt
        panel.prompt = prompt
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel
    }

    private func isReadableAudio(_ url: URL) -> Bool {
        (try? AVAudioFile(forReading: url)) != nil
    }

    private func displayTitle(for url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .uppercased()
    }

    private func importedSubtitle(for url: URL) -> String {
        guard let file = try? AVAudioFile(forReading: url), file.fileFormat.sampleRate > 0 else {
            return "IMPORTED AUDIO"
        }
        let seconds = Int((Double(file.length) / file.fileFormat.sampleRate).rounded())
        return String(format: "IMPORTED · %02d:%02d", seconds / 60, seconds % 60)
    }

    private func resolve(resourceName: String?, localPath: String?) -> URL? {
        if let localPath, FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath)
        }
        guard let resourceName else { return nil }
        let resource = URL(fileURLWithPath: resourceName)
        return Bundle.main.url(
            forResource: resource.deletingPathExtension().lastPathComponent,
            withExtension: resource.pathExtension.isEmpty ? nil : resource.pathExtension,
            subdirectory: "Audio"
        ) ?? Bundle.main.url(
            forResource: resource.deletingPathExtension().lastPathComponent,
            withExtension: resource.pathExtension.isEmpty ? nil : resource.pathExtension
        )
    }

    private func copyToLibrary(_ source: URL) -> URL? {
        let fileManager = FileManager.default
        let directory: URL
        if let libraryDirectory {
            directory = libraryDirectory
        } else {
            guard let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
            directory = root.appendingPathComponent("ON AIR Deck/Sounds", isDirectory: true)
        }
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let filename = "\(UUID().uuidString.prefix(8))-\(source.lastPathComponent)"
            let destination = directory.appendingPathComponent(filename)
            try fileManager.copyItem(at: source, to: destination)
            return destination
        } catch {
            NSSound.beep()
            return nil
        }
    }

    private func save() {
        let snapshot = Snapshot(pads: pads, bgmTracks: bgmTracks, selectedTrackID: selectedTrackID)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private static func defaultLibrary() -> (pads: [SoundPad], tracks: [BGMTrack]) {
        let pads = [
            SoundPad(title: "OPENING SIGNAL", category: .jingle, hotkey: "Q", resourceName: bundledResourceName("Clubhouse Signal.mp3")),
            SoundPad(title: "NEXT ROOM", category: .jingle, hotkey: "W", resourceName: bundledResourceName("Next Room Ping.mp3")),
            SoundPad(title: "APPLAUSE", category: .sfx, hotkey: "E", resourceName: bundledResourceName("Applause.wav")),
            SoundPad(title: "AIR HORN", category: .sfx, hotkey: "R", resourceName: bundledResourceName("Air Horn.wav")),
            SoundPad(title: "SHORT SWEEP", category: .sfx, hotkey: "A", resourceName: bundledResourceName("Short Sweep.wav")),
            SoundPad(title: "IMPACT", category: .sfx, hotkey: "S", resourceName: bundledResourceName("Impact.wav")),
            SoundPad(title: "TRANSITION", category: .jingle, hotkey: "D", resourceName: bundledResourceName("Transition.wav")),
            SoundPad(title: "CROWD HYPE", category: .sfx, hotkey: "F", resourceName: bundledResourceName("Crowd Hype.wav")),
            SoundPad(title: "BELL", category: .sfx, hotkey: "Z", resourceName: bundledResourceName("Bell.wav")),
            SoundPad(title: "DIGITAL PING", category: .sfx, hotkey: "X", resourceName: bundledResourceName("Digital Ping.wav")),
            SoundPad(title: "BACK TO YOU", category: .voice, hotkey: "C", resourceName: bundledResourceName("Back To You.wav")),
            SoundPad(title: "THANK YOU", category: .voice, hotkey: "V", resourceName: bundledResourceName("Thank You.wav"))
        ]
        let tracks = [
            BGMTrack(title: "CLUBHOUSE MORNING", subtitle: "BRIGHT LO-FI · 90 SEC", resourceName: "Clubhouse Morning Loop.mp3"),
            BGMTrack(title: "DA DA GROOVE", subtitle: "WARM GROOVE · 2:18", resourceName: "Da Da Groove.mp3"),
            BGMTrack(title: "AFTER HOURS", subtitle: "DEEP CLUBHOUSE · 2:40", resourceName: "After Hours Clubhouse.mp3")
        ].filter { track in
            guard let resourceName = track.resourceName else { return false }
            return bundledResourceName(resourceName) != nil
        }
        return (pads, tracks)
    }

    private static func bundledResourceName(_ resourceName: String) -> String? {
        let resource = URL(fileURLWithPath: resourceName)
        let baseName = resource.deletingPathExtension().lastPathComponent
        let fileExtension = resource.pathExtension.isEmpty ? nil : resource.pathExtension
        let exists = Bundle.main.url(forResource: baseName, withExtension: fileExtension, subdirectory: "Audio") != nil
            || Bundle.main.url(forResource: baseName, withExtension: fileExtension) != nil
        return exists ? resourceName : nil
    }
}

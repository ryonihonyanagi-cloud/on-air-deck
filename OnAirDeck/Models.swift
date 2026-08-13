import Foundation
import SwiftUI

enum StudioMode: String, Codable, CaseIterable, Identifiable {
    case live
    case record

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: return "LIVE"
        case .record: return "REC"
        }
    }

    var subtitle: String {
        switch self {
        case .live: return "Zoom / Meet / OBSへ送る"
        case .record: return "このMacへWAV録音"
        }
    }
}

enum MicEffectPreset: String, Codable, CaseIterable, Identifiable {
    case off = "OFF"
    case slap = "SLAP"
    case echo = "ECHO"
    case bigTitle = "BIG TITLE"

    var id: String { rawValue }

    var delayTime: TimeInterval {
        switch self {
        case .off: return 0
        case .slap: return 0.105
        case .echo: return 0.34
        case .bigTitle: return 0.52
        }
    }

    var feedback: Float {
        switch self {
        case .off: return 0
        case .slap: return 12
        case .echo: return 31
        case .bigTitle: return 46
        }
    }

    var wetDryMix: Float {
        switch self {
        case .off: return 0
        case .slap: return 24
        case .echo: return 34
        case .bigTitle: return 48
        }
    }
}

/// A restrained, fast voice compressor inspired by classic 76-style broadcast
/// compression. Apple's dynamics processor expresses compression through
/// threshold + headroom rather than a fixed ratio.
struct VoiceCompressorProfile: Equatable {
    let threshold: Float
    let headroom: Float
    let attackTime: Float
    let releaseTime: Float
    let makeupGain: Float
    let expansionThreshold: Float
    let expansionRatio: Float

    static let broadcast76 = VoiceCompressorProfile(
        threshold: -18,
        headroom: 4.5,
        attackTime: 0.003,
        releaseTime: 0.12,
        makeupGain: 3,
        expansionThreshold: -60,
        expansionRatio: 1
    )
}

enum PadCategory: String, Codable, CaseIterable {
    case jingle = "JINGLE"
    case sfx = "SFX"
    case voice = "VOICE"

    var color: Color {
        switch self {
        case .jingle: return DeckPalette.live
        case .sfx: return DeckPalette.teal
        case .voice: return DeckPalette.gold
        }
    }
}

struct SoundPad: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var category: PadCategory
    var hotkey: String
    var resourceName: String?
    var localPath: String?
    var volume: Double

    init(id: UUID = UUID(), title: String, category: PadCategory, hotkey: String, resourceName: String? = nil, localPath: String? = nil, volume: Double = 1) {
        self.id = id
        self.title = title
        self.category = category
        self.hotkey = hotkey
        self.resourceName = resourceName
        self.localPath = localPath
        self.volume = volume
    }
}

struct BGMTrack: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var subtitle: String
    var resourceName: String?
    var localPath: String?

    init(id: UUID = UUID(), title: String, subtitle: String, resourceName: String? = nil, localPath: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.resourceName = resourceName
        self.localPath = localPath
    }
}

enum DeckPalette {
    static let background = Color(red: 0.035, green: 0.038, blue: 0.037)
    static let raised = Color(red: 0.075, green: 0.078, blue: 0.075)
    static let surface = Color(red: 0.105, green: 0.108, blue: 0.102)
    static let border = Color.white.opacity(0.12)
    static let ivory = Color(red: 0.91, green: 0.86, blue: 0.76)
    static let muted = Color(red: 0.60, green: 0.58, blue: 0.53)
    static let live = Color(red: 1.0, green: 0.22, blue: 0.12)
    static let liveDark = Color(red: 0.53, green: 0.045, blue: 0.02)
    static let gold = Color(red: 0.94, green: 0.63, blue: 0.16)
    static let teal = Color(red: 0.20, green: 0.72, blue: 0.67)
    static let green = Color(red: 0.34, green: 0.82, blue: 0.43)
}

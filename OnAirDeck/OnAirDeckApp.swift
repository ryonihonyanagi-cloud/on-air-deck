import SwiftUI

@main
struct OnAirDeckApp: App {
    @StateObject private var deckStore = DeckStore()
    @StateObject private var audio = AudioController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deckStore)
                .environmentObject(audio)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .defaultSize(width: 1440, height: 960)
        .commands {
            CommandMenu("Broadcast") {
                Button("Stop All") { audio.stopAll() }
                    .keyboardShortcut(.space, modifiers: [])
                Divider()
                Button("Fade BGM Out") { audio.fadeOutBGM() }
                    .keyboardShortcut(".", modifiers: [.command])
            }
        }
    }
}


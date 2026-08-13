import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: DeckStore
    @EnvironmentObject private var audio: AudioController
    @State private var showModeSelect = true
    @State private var showZoomGuide = false
    @State private var showRecordingResult = false

    var body: some View {
        ZStack {
            StudioConsoleView(
                showModeSelect: $showModeSelect,
                showZoomGuide: $showZoomGuide
            )

            if showModeSelect {
                ModeSelectionOverlay(isPresented: $showModeSelect, showZoomGuide: $showZoomGuide)
                    .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.985)))
                    .zIndex(10)
            }
        }
        .background(DeckPalette.background)
        .frame(minWidth: 1240, minHeight: 780)
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showZoomGuide) {
            ZoomGuideView()
                .environmentObject(audio)
        }
        .sheet(isPresented: $showRecordingResult) {
            RecordingResultView(isPresented: $showRecordingResult)
                .environmentObject(audio)
        }
        .onChange(of: audio.lastRecordingURL) { _, newValue in
            if newValue != nil { showRecordingResult = true }
        }
        .background(
            KeyboardMonitor { key in handleKey(key) }
        )
        .background(WindowConfigurator())
        .animation(.easeOut(duration: 0.18), value: showModeSelect)
        .task {
#if DEBUG
            await runAutomationIfRequested()
#endif
        }
    }

    private func handleKey(_ key: String) {
        if key == " " {
            audio.stopAll()
            return
        }
        let shortcuts = ["q", "w", "e", "r", "a", "s", "d", "f", "z", "x", "c", "v"]
        guard let index = shortcuts.firstIndex(of: key.lowercased()), store.pads.indices.contains(index) else { return }
        let pad = store.pads[index]
        if audio.activePadIDs.contains(pad.id) { audio.stopPad(pad.id) }
        else { audio.playPad(pad, url: store.url(for: pad)) }
    }

#if DEBUG
    private func runAutomationIfRequested() async {
        guard ProcessInfo.processInfo.environment["ON_AIR_DECK_REC_SMOKE_TEST"] == "1" else { return }
        showModeSelect = false
        audio.setStudioMode(.record)
        try? await Task.sleep(for: .milliseconds(700))
        audio.startRecording()
        if let track = store.selectedTrack {
            audio.playBGM(track, url: store.url(for: track))
        }
        try? await Task.sleep(for: .seconds(3))
        audio.stopRecording()
        if let url = audio.lastRecordingURL {
            print("REC_SMOKE_RESULT=\(url.path)")
        } else {
            print("REC_SMOKE_ERROR=\(audio.recordingError ?? "unknown")")
        }
    }
#endif
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = NSColor(red: 0.025, green: 0.028, blue: 0.027, alpha: 1)
            window.minSize = NSSize(width: 1240, height: 780)
            window.isMovableByWindowBackground = false
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

private struct KeyboardMonitor: NSViewRepresentable {
    let onKey: (String) -> Void

    final class Coordinator {
        var monitor: Any?
        let onKey: (String) -> Void

        init(onKey: @escaping (String) -> Void) {
            self.onKey = onKey
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                guard modifiers.isEmpty, !event.isARepeat,
                      let key = event.charactersIgnoringModifiers?.lowercased() else { return event }
                let supported = ["q", "w", "e", "r", "a", "s", "d", "f", "z", "x", "c", "v", " "]
                guard supported.contains(key) else { return event }
                onKey(key)
                return nil
            }
        }

        deinit { if let monitor { NSEvent.removeMonitor(monitor) } }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onKey: onKey) }
    func makeNSView(context: Context) -> NSView { NSView(frame: .zero) }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

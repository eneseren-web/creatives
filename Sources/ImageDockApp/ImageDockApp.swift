import AppKit
import SwiftUI

@main
struct ImageDockApp: App {
    @StateObject private var windowManager = WindowManager()
    @StateObject private var imageStore: ImageStore
    private let hotkeyManager = HotkeyManager()
    @State private var hotkeyRegistered = false

    init() {
        let isDemo = CommandLine.arguments.contains("--demo")
        _imageStore = StateObject(wrappedValue: ImageStore(loadDemo: isDemo))
    }

    var body: some Scene {
        WindowGroup {
            DockContentView(windowManager: windowManager, imageStore: imageStore)
                .frame(minWidth: 320, minHeight: 400)
                .onAppear { registerHotkeyIfNeeded() }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .pasteboard) {
                Button("Paste into Dock") {
                    imageStore.handlePasteboard(NSPasteboard.general)
                }
                .keyboardShortcut("v", modifiers: .command)

                Button("Delete Selected") {
                    imageStore.deleteSelected()
                }
                .keyboardShortcut(.delete, modifiers: [])
            }
        }
    }

    private func registerHotkeyIfNeeded() {
        guard !hotkeyRegistered else { return }
        hotkeyRegistered = true
        hotkeyManager.registerToggleHotkey { [weak windowManager] in
            DispatchQueue.main.async {
                windowManager?.toggleVisibility()
            }
        }
    }
}

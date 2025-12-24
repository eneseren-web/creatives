import AppKit
import Combine

final class WindowManager: ObservableObject {
    @Published var isVisible: Bool = true
    @Published var isAlwaysOnTop: Bool = false
    @Published var transparency: Double = 0.0

    private weak var window: NSWindow?

    func attach(window: NSWindow) {
        self.window = window
        configureWindow()
    }

    func toggleVisibility() {
        guard let window else { return }
        isVisible.toggle()
        if isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            window.orderOut(nil)
        }
    }

    func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
        window?.level = isAlwaysOnTop ? .floating : .normal
    }

    func updateTransparency(_ value: Double) {
        transparency = value
        window?.alphaValue = 1.0 - value
    }

    private func configureWindow() {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior.insert(.fullScreenAuxiliary)
        window.isReleasedWhenClosed = false
        window.level = isAlwaysOnTop ? .floating : .normal
    }
}

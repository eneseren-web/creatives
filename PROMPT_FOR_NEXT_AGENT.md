# Handoff Prompt for Next AI Agent

You are taking over a macOS SwiftUI/AppKit project called **ImageDock** that implements a floating “Image Dock” panel for collecting and reusing images from the web. Below is the distilled context of all work completed after the initial request to design the app.

## Current state
- Codebase is a Swift Package targeting **macOS 13+** with an executable target `ImageDockApp`. App entry is in `Sources/ImageDockApp/ImageDockApp.swift` and wires the window manager, image store, plugin host, and Carbon-based global hotkey (⌘⇧⌥I). A demo mode flag `--demo` bootstraps sample images without persistence.
- Window management supports floating/always-on-top behavior, visibility toggling, edge snapping/collapsing, and transparency controls via `WindowManager`, `WindowAccessor`, and header UI.
- Image handling (`ImageStore`) covers drag/drop, paste (including URL download), selection, copy/delete, and drag-out export. Demo images and plugin templates are bundled in `Sources/Resources`.
- UI is SwiftUI-driven (`DockContentView`, `DockTileView`, `HeaderView`, `SettingsView`) with tile grid, delete buttons, selection outline, transparency toggle, settings button, and demo banner.
- Plugin infrastructure is scaffolded (`PluginHost`, sample manifest in `Sources/Resources/PluginTemplates/sample-manifest.json`). Browser bridge placeholder exists (`BrowserBridge.swift`) for native messaging payloads.
- Full technical/UX specification lives in `ImageDock_Spec.md` and describes architecture, window behavior, clipboard/drag flows, plugin API, browser integration, data model, and UX flows.
- README documents features, build/run steps, demo command, plugin manifest location, macOS-only note, and GitHub publishing instructions. A helper script `scripts/push-to-github.sh` adds an origin remote and pushes the current branch.

## Running locally
- Build/run on macOS 13+ in Xcode 15+ by opening `Package.swift` and launching the `ImageDock` scheme.
- Instant demo: `swift run ImageDock --demo` (preloads sample tiles, disables persistence) on macOS.

## Repository/infra notes
- There is **no Git remote configured**. Use `./scripts/push-to-github.sh git@github.com:<you>/ImageDock.git work` to add a remote and push, or run `git remote add origin ...` then `git push -u origin work`.
- The container environment here cannot run the macOS app; tests haven’t been executed.

## If continuing development
- Honor the existing SwiftUI/AppKit hybrid architecture and window behaviors described in `ImageDock_Spec.md`.
- Keep macOS-only APIs; do not add try/catch around imports. Ensure demo mode stays non-persistent and ships sample assets from `Sources/Resources`.
- Update README if user-facing behaviors change, and maintain helper scripts/instructions for pushing to GitHub.

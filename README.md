# ImageDock

A macOS SwiftUI + AppKit floating dock for collecting product images from anywhere. The executable target `ImageDock` lives in a Swift package targeting macOS 13+ and provides a draggable, always-on-top panel with a simple image grid, delete controls, paste handling, and a demo mode for quick previews.

## Status
This repository now includes buildable Swift sources for macOS. The container cannot run the app (no AppKit runtime here), so compile and run on macOS 13+ using Xcode 15 or newer.

## Building & Running
1. Open `Package.swift` in Xcode 15+.
2. Select the **ImageDock** scheme.
3. Run on macOS 13 or later.
4. Optional demo content: run with `--demo` to preload sample tiles and skip persistence.

## Features (implemented baseline)
- Floating SwiftUI UI hosted in an AppKit window with hidden title bar.
- Header controls for toggling visibility and always-on-top level.
- Adaptive grid of image tiles with per-tile delete and selection outline.
- Pasteboard ingestion for images or image URLs; URLs download the image asynchronously.
- Global hotkey (⌘⇧⌥I) registers via Carbon and toggles dock visibility.
- Demo assets generated from system symbols for quick testing.

## Notes
- The code uses AppKit APIs that require macOS; they will not compile or run on Linux.
- No persistence layer is wired yet; imports live in-memory for the session.
- Browser extension and plugin hosts are not implemented in this baseline and can be added following the `IMAGE_DOCK_SPEC.md` plan.

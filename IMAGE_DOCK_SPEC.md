# Image Dock for macOS — Technical & UX Specification

## 1. Architecture Summary
- **Primary stack:** AppKit for window management + NSPanel behaviors; SwiftUI for view hierarchy inside a hosting view. Hybrid approach uses AppKit window controller hosting SwiftUI content for rich drag/clipboard handling and transparency control.
- **Targets:**
  - **macOS app** (main deliverable).
  - **Browser extension** (Chrome/Safari) communicating via native messaging/`NSXPCListener` or local HTTP on `localhost` with random high port and app-signed token.
  - **Plugin host**: sandboxed helper executing plugins with JSON I/O.
- **Persistence:** Core Data or SQLite via `FileManager`-backed directory of images; metadata persisted as JSON sidecar or Core Data entities. Images stored as original bytes plus generated thumbnail cache.
- **Concurrency:** Swift Concurrency (`async/await`) with structured tasks for downloads, plugin calls, drag/clipboard import/export.
- **Security:** Hardened runtime, sandbox exceptions for screen positioning; App Sandbox with `com.apple.security.files.user-selected.read-write` for storage, `com.apple.security.temporary-exception.files.home-relative-path.read-write` if needed for plugin dir.

## 2. Components (Detailed)
- **`ImageDockWindowController` (AppKit)**
  - Manages NSPanel style, always-on-top (floating), translucency, snapping, partial-offscreen collapse, Spaces behavior.
  - Coordinates global hotkey show/hide and persists frame to `UserDefaults`.
- **`DockContainerView` (SwiftUI)**
  - Hosts the top strip (drag handle, settings, transparency toggle) and the image grid/list with selectable tiles.
  - Uses `@StateObject ImageStore` for data.
- **`ImageStore` (ObservableObject)**
  - CRUD for `ImageAsset` models, persistence, thumbnail generation, auto-clean.
  - Clipboard bridge and drag/drop handlers.
- **`HotkeyManager`**
  - Uses Carbon or `RegisterEventHotKey` bridged into Swift for global shortcuts.
  - Publishes notifications to toggle visibility.
- **`DragDropController`**
  - Handles NSDraggingSource/NSDraggingDestination interop for Finder/browser drag-in/out, including promised files for exports.
- **`TransparencyController`**
  - Animates window/background alpha while keeping image layers opaque via composition.
- **`PluginManager`**
  - Discovers plugins from configured directory, reads manifest, exposes importer/exporter/utility execution pipeline, and manages enable/disable state.
- **`SettingsView` (SwiftUI)**
  - Hotkey assignment, transparency settings, window behavior, storage path picker, auto-clean rules, plugin management UI.
- **`NativeMessagingServer`**
  - Handles messages from browser extensions; verifies token, writes images/URLs into `ImageStore`.

## 3. Window Behavior Implementation
- **Window type:** `NSPanel` with `hudWindow` or `utilityWindow` style mask; `nonactivatingPanel` when needed to allow clicks through to underlying app optionally.
- **Draggable & snapping:**
  - Track mouse-drag on top strip via `NSTrackingArea`/gesture recognizer; update frame while constraining within screen unions.
  - On drag end, compute nearest screen edge with configurable snap tolerance (e.g., 12–20 px). Animate to snap position.
- **Partial off-screen collapse:**
  - Allow dragging past edge; when more than threshold off-screen, store collapsed state with only 8–12 px tab visible. Tab acts as hit target to pull out (animate to last full frame).
- **Always on top:** `level = .floating` toggle. Support “all Spaces” by setting `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]` or toggling off to follow current Space only.
- **Transparency modes:** Adjust window background color/alpha and set `isOpaque = false`; keep image tiles drawn at full opacity via SwiftUI overlays. Provide hover or focus-based fade in/out animations using `NSVisualEffectView` for vibrancy.
- **Hide/Show & hotkeys:**
  - Register global hotkey; on trigger, if window is key/visible, animate fade/scale to hidden and store frame; else restore frame and orderFront regardless of Space mode.
- **Position persistence:** Store frame origin/size and collapsed state in `UserDefaults` keyed by screen identifier; restore on launch.

## 4. Clipboard & Drag-and-Drop Architecture
- **Import:**
  - Accept pasteboard types: `NSPasteboard.PasteboardType.tiff`, `.png`, `.fileURL`, `.URL`, custom `public.jpeg`, etc.
  - On paste or drop: detect if item is image data -> import; if URL -> attempt direct image download; if html paste -> parse for `<img>` tags.
  - If download fails or URL unresolved, present mini prompt requesting user to click/drag the desired image (opens transient capture overlay listening for drag from browser).
- **Export:**
  - Selected tile supports ⌘C; write both bitmap representation and temporary file promise (`NSFilePromiseProvider`) so Finder receives a file.
  - Drag-out from tile uses `NSItemProvider` with `kUTTypePNG`/`public.file-url` and file promise to export cached original or user-selected format.
- **Selection model:** Single or multi-select with keyboard navigation; delete key removes selected.

## 5. Browser Extension Integration
- **Extension actions:** Alt-click or context menu “Send to Image Dock”.
- **Image detection:** Content script inspects target element, resolves `src/srcset` for highest density, falls back to computed CSS background-image. Fetches actual binary to send, or sends URL for app-side download (prefer binary to avoid CORS). For Safari, use `safari.application` messaging equivalents.
- **Transport:**
  - Chrome: Native Messaging host registered via `com.company.imagedock.host.json` pointing to app helper. Messages use newline-delimited JSON (UTF-8).
  - Safari: App Extension using `SFSafariApplication.dispatchMessage` to containing app via App Groups/shared container.
- **Message schema:** `{ "action": "import", "source": "chrome", "token": "...", "items": [ { "url": "...", "filename": "...", "dataBase64": "..." } ] }`.
- **Host handling:** `NativeMessagingServer` validates token, decodes base64 if present, writes files to storage, and replies with `{ "status": "ok", "imported": n }`.

## 6. Plugin System
- **Discovery:** Plugins placed in `~/Library/Application Support/ImageDock/Plugins` or user-selected directory. Each plugin contains manifest `plugindesc.json` and executable (binary, script with shebang, or bundle).
- **Manifest schema (JSON):**
```json
{
  "id": "com.example.watermarker",
  "name": "Watermarker",
  "version": "1.0.0",
  "author": "ACME",
  "type": ["importer", "exporter", "utility"],
  "entry": "run.sh",
  "inputs": ["image", "url", "metadata"],
  "outputs": ["image", "metadata"],
  "permissions": ["network", "filesystem"],
  "description": "Adds watermark to images"
}
```
- **Execution contract:**
  - App spawns plugin with JSON on stdin and expects JSON on stdout. Example input:
```json
{
  "contextVersion": 1,
  "type": "importer",
  "images": [ { "id": "uuid", "path": "/tmp/img.png", "url": "https://...", "metadata": {"title":"..."} } ],
  "settings": {"watermarkText": "..."}
}
```
  - Output example:
```json
{
  "status": "ok",
  "images": [ { "id": "uuid2", "path": "/tmp/out.png", "metadata": {"note": "watermarked"} } ],
  "messages": ["Applied watermark"]
}
```
- **Isolation:** Run plugins in a helper process with timeouts, limited environment, and optional sandbox profile. Communicate results back to `ImageStore`.
- **Plugin lifecycle:** Enable/disable via settings; failure events logged; versioned API contract with semantic version checks.

## 7. Data Model
- **`ImageAsset` entity**
  - `id: UUID`
  - `originalURL: URL?`
  - `filename: String`
  - `storagePath: URL` (on-disk location)
  - `createdAt: Date`
  - `lastAccessedAt: Date`
  - `sizeBytes: Int`
  - `thumbnailPath: URL`
  - `metadata: [String: String]`
- **Storage layout:**
  - Root folder configurable (default `~/Library/Application Support/ImageDock/Images`).
  - Each asset in subfolder by UUID: `/root/UUID/original.ext`, `/root/UUID/thumbnail.png`, metadata JSON.
- **Auto-clean rules:** optional max age or max size; background task prunes older assets.

## 8. UX Wireframe-Level Description
- **Popup (expanded):**
  - **Top strip (24–32 px):** left drag handle (grip icon), center title or slot count, right icons: transparency toggle (eye/opacity slider), settings (gear), close/hide.
  - **Body:** grid of tiles (2–4 columns adaptive). Each tile: image thumbnail, overlay delete “×” top-right, subtle selection ring on focus; bottom mini-label optional filename.
  - **Collapsed tab:** thin bar showing app icon and count; clicking/dragging pulls out.
  - **Empty state:** dashed border area with instructions: “Drag images here or press ⌘V.”
  - **Status toasts:** small overlay near bottom for import success/failure.
- **Settings panel:** tabbed view: Hotkeys, Window, Storage, Plugins. Hotkey recorder control; transparency slider; switches for “Snap to edges”, “Show on all Spaces”, “Always on top”, storage path picker, auto-clean toggles, plugin list with enable checkboxes and detail popovers.
- **Prompt for manual capture:** temporary bar explaining “Couldn’t find original image. Drag it into the dock or click the image.” with cancel button.

## 9. Workflows
- **Add via paste:** user copies image/URL → presses ⌘V in dock → app detects pasteboard → if URL, download → create ImageAsset → tile appears with import toast.
- **Drag from browser:** user drags image onto dock → drop target highlights → image stored and tile added.
- **Drag out to Finder:** user drags tile → file promise created → Finder receives actual file in Downloads/temporary export.
- **Toggle transparency:** user clicks opacity icon → window background fades to 40% while tiles remain opaque; clicking again restores solid.
- **Hide/Show:** user hits global hotkey → panel fades out/in, retaining last location; stays on chosen Spaces behavior.
- **Plugin run:** user selects tiles → chooses plugin action (e.g., exporter) from context menu → app packages JSON to plugin → plugin output re-imported or exported per type → status toast.


import AppKit
import Foundation

struct ImageAsset: Identifiable, Hashable {
    let id: UUID
    var title: String
    var sourceURL: URL?
    var createdAt: Date
    var thumbnail: NSImage
    var originalData: Data
}

extension ImageAsset {
    static func demoAssets() -> [ImageAsset] {
        guard let demoImage = NSImage(systemSymbolName: "photo", accessibilityDescription: nil),
              let data = demoImage.tiffRepresentation else { return [] }
        return (1...6).map { index in
            ImageAsset(
                id: UUID(),
                title: "Sample \(index)",
                sourceURL: nil,
                createdAt: Date(),
                thumbnail: demoImage,
                originalData: data
            )
        }
    }
}

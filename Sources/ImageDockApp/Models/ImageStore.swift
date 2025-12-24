import AppKit
import Combine
import Foundation

final class ImageStore: ObservableObject {
    @Published private(set) var assets: [ImageAsset]
    @Published var selection: Set<UUID> = []

    init(loadDemo: Bool = false) {
        if loadDemo {
            assets = ImageAsset.demoAssets()
        } else {
            assets = []
        }
    }

    func addImage(data: Data, title: String = "Imported", sourceURL: URL? = nil) {
        guard let nsImage = NSImage(data: data) else { return }
        let asset = ImageAsset(
            id: UUID(),
            title: title,
            sourceURL: sourceURL,
            createdAt: Date(),
            thumbnail: nsImage,
            originalData: data
        )
        assets.insert(asset, at: 0)
    }

    func deleteSelected() {
        guard !selection.isEmpty else { return }
        assets.removeAll { selection.contains($0.id) }
        selection.removeAll()
    }

    func toggleSelection(_ asset: ImageAsset) {
        if selection.contains(asset.id) {
            selection.remove(asset.id)
        } else {
            selection.insert(asset.id)
        }
    }

    func isSelected(_ asset: ImageAsset) -> Bool {
        selection.contains(asset.id)
    }

    func handlePasteboard(_ pasteboard: NSPasteboard) {
        if let data = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            addImage(data: data)
            return
        }
        if let string = pasteboard.string(forType: .string), let url = URL(string: string) {
            downloadImage(from: url)
        }
    }

    private func downloadImage(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, !data.isEmpty else { return }
            DispatchQueue.main.async {
                self?.addImage(data: data, title: url.lastPathComponent, sourceURL: url)
            }
        }
        task.resume()
    }
}

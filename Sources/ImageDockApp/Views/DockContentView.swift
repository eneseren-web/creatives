import SwiftUI

struct DockContentView: View {
    @ObservedObject var windowManager: WindowManager
    @ObservedObject var imageStore: ImageStore

    private let gridColumns = [GridItem(.adaptive(minimum: 90, maximum: 140), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(windowManager: windowManager)
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(imageStore.assets) { asset in
                        DockTileView(
                            asset: asset,
                            isSelected: imageStore.isSelected(asset),
                            onSelect: { imageStore.toggleSelection(asset) },
                            onDelete: { imageStore.selection = [asset.id]; imageStore.deleteSelected() }
                        )
                    }
                }
                .padding(12)
            }
        }
        .background(WindowAccessor { window in
            windowManager.attach(window: window)
        })
        .onAppear {
            windowManager.updateTransparency(windowManager.transparency)
        }
        .frame(minWidth: 320, minHeight: 400)
    }
}

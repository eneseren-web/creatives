import SwiftUI

struct DockTileView: View {
    let asset: ImageAsset
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: asset.thumbnail)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 80, minHeight: 80)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: isSelected ? 3 : 0)
                )
                .onTapGesture { onSelect() }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.borderless)
            .padding(6)
        }
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

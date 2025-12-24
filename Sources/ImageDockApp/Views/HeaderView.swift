import SwiftUI

struct HeaderView: View {
    @ObservedObject var windowManager: WindowManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.headline)
                .opacity(0.6)
            Spacer()
            Button(action: { windowManager.toggleAlwaysOnTop() }) {
                Image(systemName: windowManager.isAlwaysOnTop ? "pin.fill" : "pin")
            }
            Button(action: { windowManager.toggleVisibility() }) {
                Image(systemName: windowManager.isVisible ? "eye" : "eye.slash")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
}

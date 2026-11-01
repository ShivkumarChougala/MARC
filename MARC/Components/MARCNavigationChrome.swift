import SwiftUI

extension View {
    /// Use the system's feathered top scroll transition instead of an automatic hard edge.
    /// Scoped to the top so the floating dock and custom bottom fades are unaffected.
    @ViewBuilder
    func marcSoftScrollEdge(enabled: Bool = true) -> some View {
        if enabled {
            if #available(iOS 26.0, *) {
                self.scrollEdgeEffectStyle(.soft, for: .top)
            } else {
                self
            }
        } else {
            self
        }
    }

    func marcNavigationTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .marcSoftScrollEdge()
    }
}

// Older systems have no shared glass toolbar background to hide.
extension ToolbarContent {
    @ToolbarContentBuilder
    func marcToolbarBackgroundHidden() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            self.sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}

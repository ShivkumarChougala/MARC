import SwiftUI

extension View {
    /// Fade only above the list viewport; keep pinned controls and resting rows clear.
    func marcListHeaderFade() -> some View {
        mask {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .white],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 8)
                    Rectangle()
                }
                .padding(.top, -8)
                .padding(.bottom, -geometry.safeAreaInsets.bottom)
            }
        }
    }

    func marcNavigationTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
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

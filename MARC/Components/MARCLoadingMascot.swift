import SwiftUI

/// Connecting-only sprite atlas; no GIF decoder or per-frame image allocation.
struct MARCLoadingMascot: View {
    let size: CGFloat
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12,
                                paused: reduceMotion || scenePhase != .active)) { context in
            let interval = 0.12
            let frame = reduceMotion ? 0 : Int(context.date.timeIntervalSinceReferenceDate / interval) % 24
            ZStack(alignment: .topLeading) {
                Image("MARCConnectingAtlas")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size * 6, height: size * 4)
                    .offset(x: -CGFloat(frame % 6) * size,
                            y: -CGFloat(frame / 6) * size)
            }
            .frame(width: size, height: size, alignment: .topLeading)
            .clipped()
            .modifier(MARCMascotAppearance(dark: scheme == .dark))
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MARCMascotAppearance: ViewModifier {
    let dark: Bool
    func body(content: Content) -> some View {
        Group {
            if dark { content.blendMode(.screen) }
            else { content.colorInvert().blendMode(.multiply) }
        }
    }
}

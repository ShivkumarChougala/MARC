import SwiftUI

// Quiet, noninteractive placeholders. No timers, shimmer or extra data requests.
struct MARCLoadingRows: View {
    enum Layout: Equatable { case services, overviewProcesses, processes, files }
    let layout: Layout
    let count: Int
    let palette: MARCPalette

    // Bound work while allowing tall phone/tablet viewports to be covered.
    static func rowsToFill(_ height: CGFloat, rowHeight: CGFloat) -> Int {
        guard height.isFinite, rowHeight.isFinite, height > 0, rowHeight > 0 else { return 1 }
        return Int(ceil(min(64, max(1, height / rowHeight))))
    }

    private var rowHeight: CGFloat {
        switch layout {
        case .services: return 48
        case .overviewProcesses: return 44
        case .processes: return 56
        case .files: return 68
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<max(1, min(count, 64)), id: \.self) { index in
                HStack(spacing: layout == .files ? 12 : 8) {
                    if layout == .services || layout == .files {
                        RoundedRectangle(cornerRadius: layout == .files ? 12 : 7)
                            .fill(palette.muted.opacity(0.18))
                            .frame(width: layout == .files ? 42 : 28,
                                   height: layout == .files ? 44 : 28)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        bar(width: index.isMultiple(of: 2) ? 108 : 86)
                        if layout != .overviewProcesses { bar(width: 60, height: 5) }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    if layout == .overviewProcesses { bar(width: 28).frame(width: 44, alignment: .trailing) }
                    if layout == .processes || layout == .overviewProcesses {
                        bar(width: 30).frame(width: layout == .processes ? 52 : 48, alignment: .trailing)
                        bar(width: 44).frame(width: layout == .processes ? 72 : 64, alignment: .trailing)
                    } else {
                        bar(width: layout == .files ? 18 : 42)
                    }
                }
                .frame(minHeight: rowHeight)
                .overlay(alignment: .bottom) {
                    if index < max(1, min(count, 64)) - 1 {
                        Rectangle().fill(palette.border.opacity(0.5)).frame(height: 0.5)
                            .padding(.leading, layout == .files ? 54 : layout == .services ? 38 : 0)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading \(layout == .files ? "folder contents" : layout == .services ? "services" : "processes")")
    }

    private func bar(width: CGFloat, height: CGFloat = 7) -> some View {
        Capsule().fill(palette.muted.opacity(0.26)).frame(width: width, height: height)
    }
}

// Fade only an observed loading-to-content handoff. Live row/digit transactions retain
// their existing policy; Reduce Motion gets an immediate handoff.
struct MARCLoadingReveal: ViewModifier {
    let isLoading: Bool
    // Already-ready screens must not fade again when SwiftUI recreates them.
    @State private var revealed = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isLoading || revealed || reduceMotion ? 1 : 0)
            .onAppear {
                // Prepare a genuine loading handoff without animating mounting.
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) { revealed = !isLoading }
            }
            .onChange(of: isLoading) { _, loading in
                var transaction = Transaction(animation: !loading && !reduceMotion ? .easeOut(duration: 0.18) : nil)
                transaction.disablesAnimations = loading || reduceMotion
                withTransaction(transaction) { revealed = !loading }
            }
    }
}

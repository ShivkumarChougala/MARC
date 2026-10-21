import SwiftUI
import UIKit

// String keys avoid actor-isolated Hashable conformances in SwiftUI preferences.
private struct MARCLearnAnchors: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func marcLearnTarget(_ hint: MARCLearningHint, enabled: Bool = true) -> some View {
        anchorPreference(key: MARCLearnAnchors.self, value: .bounds) { enabled ? [hint.rawValue: $0] : [:] }
    }
    func marcLearnOverlay(_ hint: MARCLearningHint, enabled: Bool) -> some View {
        marcLearnOverlay([hint], enabled: enabled)
    }
    func marcLearnOverlay(_ hints: [MARCLearningHint], enabled: Bool) -> some View {
        modifier(MARCContextualHint(hints: hints, enabled: enabled))
    }
}

private struct MARCContextualHint: ViewModifier {
    let hints: [MARCLearningHint]
    let enabled: Bool
    @AppStorage("marc.learn.revision") private var revision = 0
    @Environment(\.marcGuidedTour) private var tour
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue
    @ScaledMetric(relativeTo: .subheadline) private var cardHeight: CGFloat = 158
    @State private var announced: Set<String> = []

    init(hints: [MARCLearningHint], enabled: Bool) {
        self.hints = hints; self.enabled = enabled
    }

    private var visible: Bool {
        MARCLearningHint.canPresent(dismissed: false, enabled: enabled,
            active: scenePhase == .active, setupActive: tour?.active == true,
            blocked: tour?.hasBlockingPresentation == true, keyboardVisible: tour?.keyboardVisible == true)
    }

    func body(content: Content) -> some View {
        content.overlayPreferenceValue(MARCLearnAnchors.self) { anchors in
            if visible {
                GeometryReader { geometry in
                    let _ = revision
                    let viewport = CGRect(origin: .zero, size: geometry.size)
                    let visibleIDs = Set(hints.compactMap { hint -> String? in
                        guard let anchor = anchors[hint.rawValue] else { return nil }
                        let rect = geometry[anchor]
                        guard rect.width > 1, rect.height > 1, viewport.contains(rect) else { return nil }
                        if hint == .filesActions, let folder = anchors[MARCLearningHint.filesFolders.rawValue],
                           rect.minY < geometry[folder].maxY { return nil }
                        return hint.rawValue
                    })
                    let dismissedIDs = Set(hints.filter {
                        UserDefaults.standard.bool(forKey: $0.preferenceKey)
                    }.map(\.rawValue))
                    if let hint = MARCLearningHint.next(in: hints, dismissed: dismissedIDs, visible: visibleIDs),
                       let anchor = anchors[hint.rawValue] {
                        let target = geometry[anchor]
                        let layout = MARCGuidePlacement.resolve(size: geometry.size, target: target,
                                                               preferredHeight: cardHeight)
                        // An off-screen or partially scrolled control must never leave a floating hint behind.
                        if viewport.contains(target), let focus = layout.focus, layout.card.height >= 110 {
                            let p = MARCPalette(dark: scheme == .dark)
                            let colour = (MARCAccentColor(rawValue: accent) ?? .defaultColor).color(dark: scheme == .dark)
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(colour.opacity(0.75), lineWidth: 1)
                                    .frame(width: focus.width + 4, height: focus.height + 4)
                                    .position(x: focus.midX, y: focus.midY)
                                    .allowsHitTesting(false).accessibilityHidden(true)
                                pointer(focus: focus, card: layout.card, colour: colour)
                                VStack(alignment: .leading, spacing: 6) {
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(hint.title).font(.subheadline.weight(.semibold))
                                                .accessibilityAddTraits(.isHeader)
                                            Text(hint.message).font(.footnote).foregroundStyle(p.muted)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }.frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    HStack {
                                        Spacer()
                                        Button("Got it") {
                                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                                                UserDefaults.standard.set(true, forKey: hint.preferenceKey)
                                                revision += 1
                                            }
                                        }
                                        .font(.footnote.weight(.semibold)).tint(colour)
                                        .frame(minWidth: 60, minHeight: 44)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 2)
                                .frame(width: layout.card.width, height: layout.card.height)
                                .foregroundStyle(p.text)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
                                .overlay(RoundedRectangle(cornerRadius: 17).stroke(colour.opacity(0.65), lineWidth: 1))
                                .shadow(color: .black.opacity(0.13), radius: 12, y: 5)
                                .position(x: layout.card.midX, y: layout.card.midY)
                                .accessibilityElement(children: .contain)
                                .transition(.opacity)
                                .id(hint.rawValue)
                                .onAppear {
                                    guard announced.insert(hint.rawValue).inserted else { return }
                                    UISelectionFeedbackGenerator().selectionChanged()
                                }
                            }
                        }
                    }
                }
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: visible)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: revision)
    }

    private func pointer(focus: CGRect, card: CGRect, colour: Color) -> some View {
        let above = card.maxY < focus.minY
        let x = min(max(focus.midX, card.minX + 18), card.maxX - 18)
        let start = CGPoint(x: x, y: above ? card.maxY : card.minY)
        let end = CGPoint(x: focus.midX, y: above ? focus.minY - 4 : focus.maxY + 4)
        return Path { path in
            path.move(to: start)
            path.addQuadCurve(to: end, control: CGPoint(x: start.x, y: (start.y + end.y) / 2))
        }
        .stroke(colour.opacity(0.8), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

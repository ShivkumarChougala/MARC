import SwiftUI
import UIKit

private struct MARCGuideEnvironmentKey: EnvironmentKey {
    static let defaultValue: MARCGuidedTour? = nil
}
extension EnvironmentValues {
    var marcGuidedTour: MARCGuidedTour? {
        get { self[MARCGuideEnvironmentKey.self] }
        set { self[MARCGuideEnvironmentKey.self] = newValue }
    }
}
// Shared presentation barriers still suppress contextual learning hints.
extension View {
    func marcGuidePresentationBarrier() -> some View { modifier(MARCGuidePresentationBarrier()) }
}
private struct MARCGuidePresentationBarrier: ViewModifier {
    @Environment(\.marcGuidedTour) private var tour
    @State private var id = UUID()
    func body(content: Content) -> some View {
        content.onAppear { tour?.setPresentation(id, visible: true) }
            .onDisappear { tour?.setPresentation(id, visible: false) }
    }
}

// Setup guidance shares the existing screen's anchor coordinates. Only the
// caption accepts touches: the focus decoration never intercepts real controls.
private struct MARCSetupAnchors: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func marcSetupTarget(_ id: String, enabled: Bool = true) -> some View {
        // Append this target without replacing anchors from nested fields/rows.
        // Manual form and nearby-panel protection must preserve Host/device targets.
        transformAnchorPreference(key: MARCSetupAnchors.self, value: .bounds) { targets, anchor in
            if enabled { targets[id] = anchor }
        }
    }
    func marcSetupCoach(target: String?, title: String, message: String, enabled: Bool,
                        next: @escaping () -> Void, skip: @escaping () -> Void,
                        back: (() -> Void)? = nil) -> some View {
        modifier(MARCSetupCoach(target: target, title: title, message: message,
                                enabled: enabled, next: next, skip: skip, back: back))
    }
}

private struct MARCSetupCoach: ViewModifier {
    let target: String?
    let title: String
    let message: String
    let enabled: Bool
    let next: () -> Void
    let skip: () -> Void
    let back: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicType
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue
    @State private var measuredHeight: CGFloat = 146
    @State private var keyboardVisible = false

    private var step: Int { target == "add" ? 1 : ["login", "connect"].contains(target ?? "") ? 3 : 2 }

    func body(content: Content) -> some View {
        content.overlayPreferenceValue(MARCSetupAnchors.self) { anchors in
            if enabled && scenePhase == .active && !keyboardVisible,
               let target, let anchor = anchors[target] {
                GeometryReader { geometry in
                    let rect = geometry[anchor]
                    let avoid = ["method", "scan", "device"].contains(target) ? anchors["nearbyPanel"].map { geometry[$0] } : nil
                    let protected = ["method", "manualForm", "login", "test", "connect", "nearbyPanel"]
                        .filter { $0 != target }.compactMap { anchors[$0].map { geometry[$0] } }
                    if let caption = MARCGuidePlacement.setupCaption(size: geometry.size,
                        target: rect, avoid: avoid, preferredHeight: measuredHeight,
                        accessibility: dynamicType.isAccessibilitySize, protected: protected) {
                        let p = MARCPalette(dark: scheme == .dark)
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(p.accent.opacity(0.8), lineWidth: 1)
                                .frame(width: rect.width + 6, height: rect.height + 6)
                                .position(x: rect.midX, y: rect.midY)
                                .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: rect)
                                .accessibilityHidden(true).allowsHitTesting(false)
                            // Route through the outer margin so the guide never crosses form controls.
                            let edge = min(geometry.size.width - 6, max(rect.maxX, caption.maxX) + 8)
                            let start = CGPoint(x: rect.maxX + 3, y: rect.midY)
                            let end = CGPoint(x: caption.maxX - 8, y: caption.minY + 10)
                            Path { path in
                                path.move(to: start)
                                path.addCurve(to: CGPoint(x: edge, y: start.y + 10),
                                    control1: CGPoint(x: edge, y: start.y), control2: CGPoint(x: edge, y: start.y))
                                path.addLine(to: CGPoint(x: edge, y: end.y - 8))
                                path.addQuadCurve(to: end, control: CGPoint(x: edge, y: end.y))
                            }.stroke(p.accent.opacity(0.55), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                                .accessibilityHidden(true).allowsHitTesting(false)
                            Circle().fill(p.accent).frame(width: 5, height: 5)
                                .position(start).accessibilityHidden(true).allowsHitTesting(false)
                            MARCSetupCaption(step: step, title: title, message: message,
                                next: next, skip: skip, back: back)
                            .foregroundStyle(p.text)
                            .frame(width: caption.width)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(p.background.opacity(0.97))
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { value in
                                if abs(value - measuredHeight) > 0.5 { measuredHeight = value }
                            }
                            .position(x: caption.midX, y: caption.midY)
                            .animation(reduceMotion ? nil : .smooth(duration: 0.42), value: caption)
                            .accessibilityElement(children: .contain)
                            .onAppear { announce() }
                            .onChange(of: target) { _, _ in announce() }
                        }
                    }
                }
            }
        }
        .onChange(of: dynamicType) { _, _ in measuredHeight = 146 }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
    }

    private func announce() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: "Step \(step) of 3. \(title). \(message)")
    }
}

private struct MARCSetupCaption: View {
    let step: Int
    let title: String
    let message: String
    let next: () -> Void
    let skip: () -> Void
    let back: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { index in
                    Capsule().fill(index == step ? p.accent : p.muted.opacity(0.3))
                        .frame(width: 16, height: 3)
                }
            }.accessibilityElement(children: .ignore).accessibilityLabel("Step \(step) of 3")
            Text(title).font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
            Text(message).font(.caption).foregroundStyle(p.muted)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { secondaryActions(p); Spacer(minLength: 8); nextAction(p) }
                VStack(alignment: .leading, spacing: 4) { secondaryActions(p); nextAction(p) }
            }
        }.padding(.horizontal, 8).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func secondaryActions(_ p: MARCPalette) -> some View {
        HStack(spacing: 12) {
            if let back {
                Button("Back", action: back).frame(minWidth: 44, minHeight: 44)
            }
            Button("Skip") {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.45)
                skip()
            }.frame(minWidth: 44, minHeight: 44).accessibilityLabel("Skip setup tour")
        }.font(.caption).foregroundStyle(p.muted).buttonStyle(.plain)
    }
    private func nextAction(_ p: MARCPalette) -> some View {
        Button(action: next) {
            Label("Next", systemImage: "arrow.right").font(.caption.weight(.semibold))
                .padding(.horizontal, 14).frame(minHeight: 44)
                .foregroundStyle(p.text).background(p.accent.opacity(0.16), in: Capsule())
                .overlay(Capsule().stroke(p.accent.opacity(0.6), lineWidth: 0.75))
        }.buttonStyle(.plain).accessibilityHint("Continue setup guidance")
    }
}

// Optional troubleshooting is read-only and never advances or resets setup.
enum MARCSetupHelpTopic: String, Identifiable {
    case remoteLogin, username, address
    var id: String { rawValue }
    var title: String {
        switch self {
        case .remoteLogin: return "Mac setup"
        case .username: return "Mac username"
        case .address: return "Mac address"
        }
    }
}

struct MARCSetupHelpSheet: View {
    let topic: MARCSetupHelpTopic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch topic {
                    case .remoteLogin:
                        Text("On your Mac: System Settings → General → Sharing → Remote Login.")
                        Text("Turn it on and allow your Mac account.")
                        Text("Keep your Mac awake and both devices on the same trusted network. Then tap Refresh in MARC.")
                            .foregroundStyle(p.muted)
                        DisclosureGroup("Still not showing?") {
                            Text("Allow MARC’s Local Network access in iPhone Settings, or enter your Mac’s address manually.")
                                .foregroundStyle(p.muted).padding(.top, 8)
                        }.tint(p.accent)
                    case .username:
                        Text("On your Mac, open Terminal and run:")
                        Text("whoami").font(.body.monospaced()).textSelection(.enabled)
                        Text("Use the result as Username in MARC.")
                        Text("Remote Login must allow this account. Use its Mac password or an authorized SSH key.")
                            .foregroundStyle(p.muted)
                    case .address:
                        Text("On your Mac: System Settings → General → Sharing → Remote Login.")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Example").font(.caption).foregroundStyle(p.muted)
                            Text("ssh marc@MARC-Mac.local")
                                .font(.subheadline.monospaced()).textSelection(.enabled)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("In MARC, enter:")
                            LabeledContent("Host", value: "MARC-Mac.local")
                            LabeledContent("Username", value: "marc")
                        }
                        Text("Use the values shown on your own Mac.")
                            .font(.footnote).foregroundStyle(p.muted)
                        DisclosureGroup("Using an IP address?") {
                            Text("Find it in System Settings → Network → your connection → Details. Enter only the IP in Host.")
                                .foregroundStyle(p.muted).padding(.top, 8)
                        }.tint(p.accent)

                    }
                }
                .font(.subheadline).foregroundStyle(p.text)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }
            .marcCanvas()
            .navigationTitle(topic.title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.tint(p.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// Compact label/value rows; accessibility text sizes can stack without truncating labels.
struct MARCSetupTextField: View {
    let title: String
    let hint: String
    @Binding var text: String
    var help: (() -> Void)? = nil
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var dynamicType

    private var rowLabel: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return HStack(spacing: 0) {
            Text(title).font(.subheadline).foregroundStyle(p.text).fixedSize()
            if let help {
                Button(action: help) {
                    Image(systemName: "questionmark.circle")
                        .font(.subheadline).foregroundStyle(p.muted)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Help with \(title.lowercased())")
            }
        }
    }
    private var input: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return TextField(hint, text: $text)
            .font(.subheadline).foregroundStyle(p.text)
            .multilineTextAlignment(.trailing)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityLabel(title)
    }
    var body: some View {
        Group {
            if dynamicType.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) { rowLabel; input }
            } else {
                HStack(spacing: 8) { rowLabel; input }
            }
        }
        .frame(minHeight: 44)
    }
}

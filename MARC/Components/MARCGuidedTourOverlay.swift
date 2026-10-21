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
        anchorPreference(key: MARCSetupAnchors.self, value: .bounds) { enabled ? [id: $0] : [:] }
    }
    func marcSetupCoach(target: String?, title: String, message: String, enabled: Bool,
                        next: @escaping () -> Void, skip: @escaping () -> Void) -> some View {
        modifier(MARCSetupCoach(target: target, title: title, message: message,
                                enabled: enabled, next: next, skip: skip))
    }
}

/// Four short corners keep the underlying control legible without a scrim.
private struct MARCSetupCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(12, min(rect.width, rect.height) / 3)
        var path = Path()
        for (x, y, dx, dy) in [
            (rect.minX, rect.minY, CGFloat(1), CGFloat(1)),
            (rect.maxX, rect.minY, CGFloat(-1), CGFloat(1)),
            (rect.minX, rect.maxY, CGFloat(1), CGFloat(-1)),
            (rect.maxX, rect.maxY, CGFloat(-1), CGFloat(-1))
        ] {
            path.move(to: CGPoint(x: x, y: y + length * dy))
            path.addLine(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + length * dx, y: y))
        }
        return path
    }
}

private struct MARCSetupCoach: ViewModifier {
    let target: String?
    let title: String
    let message: String
    let enabled: Bool
    let next: () -> Void
    let skip: () -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicType
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue
    @State private var measuredHeight: CGFloat = 88
    @State private var keyboardVisible = false

    private var step: Int { target == "add" ? 1 : ["login", "connect"].contains(target ?? "") ? 3 : 2 }

    func body(content: Content) -> some View {
        content.overlayPreferenceValue(MARCSetupAnchors.self) { anchors in
            if enabled && scenePhase == .active && !keyboardVisible,
               let target, let anchor = anchors[target] {
                GeometryReader { geometry in
                    let rect = geometry[anchor]
                    let avoid = ["method", "scan", "device"].contains(target) ? anchors["nearbyPanel"].map { geometry[$0] } : nil
                    if let caption = MARCGuidePlacement.setupCaption(size: geometry.size,
                        target: rect, avoid: avoid, preferredHeight: measuredHeight,
                        accessibility: dynamicType.isAccessibilitySize) {
                        let p = MARCPalette(dark: scheme == .dark)
                        ZStack(alignment: .topLeading) {
                            MARCSetupCorners()
                                .stroke(p.accent.opacity(0.7), style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round))
                                .frame(width: rect.width + 8, height: rect.height + 8)
                                .position(x: rect.midX, y: rect.midY)
                                .animation(reduceMotion ? nil : .smooth(duration: 0.42), value: rect)
                                .accessibilityHidden(true)
                                .allowsHitTesting(false)
                            MARCSetupCaption(step: step, title: title, message: message,
                                inline: caption.width >= 340 && !dynamicType.isAccessibilitySize,
                                next: next, skip: skip)
                            .foregroundStyle(p.text)
                            .frame(width: caption.width)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(p.raised, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
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
        .onChange(of: dynamicType) { _, _ in measuredHeight = 88 }
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
    let inline: Bool
    let next: () -> Void
    let skip: () -> Void
    @Environment(\.colorScheme) private var scheme

    private var description: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return HStack(alignment: .top, spacing: 8) {
            Text("\(step)").font(.caption.weight(.medium)).monospacedDigit()
                .foregroundStyle(p.accent).frame(width: 24, height: 24)
                .background(p.accent.opacity(0.1), in: Circle())
                .accessibilityLabel("Step \(step) of 3")
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption.weight(.medium))
                Text(message).font(.caption).foregroundStyle(p.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    private var actions: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return HStack(spacing: 8) {
            Button("Skip") {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.45)
                skip()
            }
            .foregroundStyle(p.muted).frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Skip setup tour")
            Button(action: next) {
                Label("Next", systemImage: "arrow.right").fixedSize()
                    .frame(minWidth: 54, minHeight: 44)
            }
            .foregroundStyle(p.accent)
            .accessibilityHint("Continue setup guidance")
        }
        .font(.caption).buttonStyle(.plain)
    }
    var body: some View {
        Group {
            if inline {
                HStack(spacing: 8) { description; actions }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    description
                    HStack { Spacer(minLength: 0); actions }
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
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

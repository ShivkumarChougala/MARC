import SwiftUI
import UIKit

/// Offered after a verified connection; choosing Later never opens the gallery.
struct MARCExploreInvitationScreen: View {
    let explore: () -> Void
    let later: () -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var dynamicType
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 24, weight: .light)).foregroundStyle(p.accent)
                    .accessibilityHidden(true)
                Text("Your Mac, within reach.").font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("Take a quick look at what you can do with MARC.")
                    .font(.subheadline).foregroundStyle(p.muted)
                    .fixedSize(horizontal: false, vertical: true)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 20) { exploreButton(p); laterButton(p) }
                    VStack(alignment: .leading, spacing: 4) { exploreButton(p); laterButton(p) }
                }.padding(.top, 2)
            }.padding(24).frame(maxWidth: 520, alignment: .leading).frame(maxWidth: .infinity)
        }
        .foregroundStyle(p.text).background(p.background.ignoresSafeArea())
        .presentationDetents(dynamicType.isAccessibilitySize ? [.large] : [.height(250)])
        .presentationDragIndicator(.visible)
    }
    private func exploreButton(_ p: MARCPalette) -> some View {
        Button(action: explore) {
            Label("Explore MARC", systemImage: "arrow.right")
                .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
        }.buttonStyle(.plain).foregroundStyle(p.accent)
    }
    private func laterButton(_ p: MARCPalette) -> some View {
        Button("Not now", action: later).font(.subheadline)
            .frame(minWidth: 60, minHeight: 44).buttonStyle(.plain).foregroundStyle(p.muted)
    }
}

/// A self-contained gallery of real screenshots; never creates SSH, file or AI clients.
struct MARCFeatureGuideScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue
    @State private var selection = 0
    private var pageCount: Int { MARCPreviewTopic.allCases.count }
    private var isLastPage: Bool { selection == pageCount - 1 }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(spacing: 0) {
            HStack {
                Text("What’s inside MARC").font(.subheadline.weight(.medium)).foregroundStyle(p.muted)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .medium))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.accessibilityLabel("Close What’s inside MARC")
            }.padding(.horizontal, 20)
            TabView(selection: $selection) {
                ForEach(MARCPreviewTopic.allCases) { topic in
                    MARCFeaturePreviewPage(topic: topic).tag(topic.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityLabel("MARC feature previews")
            VStack(spacing: 6) {
                HStack(spacing: 7) {
                    ForEach(MARCPreviewTopic.allCases) { topic in
                        Button { move(to: topic.rawValue) } label: {
                            Capsule().fill(selection == topic.rawValue ? p.accent : p.border)
                                .frame(width: selection == topic.rawValue ? 18 : 6, height: 6)
                                .frame(minWidth: 30, minHeight: 44).contentShape(Rectangle())
                        }
                        .accessibilityLabel("\(topic.name), \(topic.rawValue + 1) of \(pageCount)")
                        .accessibilityAddTraits(selection == topic.rawValue ? .isSelected : [])
                    }
                }
                HStack {
                    Button("Previous") { move(to: selection - 1) }
                        .disabled(selection == 0).opacity(selection == 0 ? 0.35 : 1)
                        .frame(minWidth: 80, minHeight: 44)
                    Spacer(minLength: 4)
                    Text("\(selection + 1) / \(pageCount)").font(.caption).monospacedDigit()
                        .foregroundStyle(p.muted).accessibilityLabel("Page \(selection + 1) of \(pageCount)")
                    Spacer(minLength: 4)
                    Button(isLastPage ? "Done" : "Next →") {
                        if isLastPage { dismiss() } else { move(to: selection + 1) }
                    }.frame(minWidth: 80, minHeight: 44)
                }.font(.subheadline.weight(.medium))
            }.padding(.horizontal, 20).padding(.bottom, 8)
        }
        .buttonStyle(.plain).foregroundStyle(p.text).tint(p.accent)
        .background(p.background.ignoresSafeArea())
        .onChange(of: selection) { _, value in
            UISelectionFeedbackGenerator().selectionChanged()
            if UIAccessibility.isVoiceOverRunning, let topic = MARCPreviewTopic(rawValue: value) {
                UIAccessibility.post(notification: .announcement,
                    argument: "\(topic.name), page \(value + 1) of \(pageCount). \(topic.headline). \(topic.explanation)")
            }
        }
    }

    private func move(to index: Int) {
        guard MARCPreviewTopic(rawValue: index) != nil else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { selection = index }
    }
}

private enum MARCPreviewTopic: Int, CaseIterable, Identifiable {
    case status, system, statistics, processes, terminal, files, controls
    var id: Int { rawValue }
    var name: String {
        switch self {
        case .status: return "Status"
        case .system: return "System"
        case .statistics: return "Statistics"
        case .processes: return "Processes"
        case .files: return "Files"
        case .controls: return "Controls"
        case .terminal: return "Terminal & AI"
        }
    }
    var headline: String {
        switch self {
        case .status: return "Your Mac, at a glance."
        case .system: return "A closer look at usage."
        case .statistics: return "See the bigger picture."
        case .processes: return "Find what’s keeping it busy."
        case .files: return "Your files, closer."
        case .controls: return "A little more control."
        case .terminal: return "A terminal, within reach."
        }
    }
    var explanation: String {
        switch self {
        case .status: return "See usage, battery and storage in one place."
        case .system: return "Explore CPU cores, memory and storage."
        case .statistics: return "Follow CPU, memory, network and disk usage over time."
        case .processes: return "Sort by CPU or memory. Review an app before ending it."
        case .files: return "Browse, preview, upload and download over SSH."
        case .controls: return "Adjust supported controls and launch your Mac’s apps."
        case .terminal: return "Use the shell. Ask AI, then review commands before Run."
        }
    }
    var assetName: String {
        switch self {
        case .status: return "MARCGuideStatus"
        case .system: return "MARCGuideSystem"
        case .statistics: return "MARCGuideStatistics"
        case .processes: return "MARCGuideProcesses"
        case .files: return "MARCGuideFiles"
        case .controls: return "MARCGuideControls"
        case .terminal: return "MARCGuideTerminal"
        }
    }
    var summary: String {
        "Screenshot of MARC’s \(name) screen. \(explanation)"
    }

}

private struct MARCFeaturePreviewPage: View {
    let topic: MARCPreviewTopic
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        GeometryReader { geometry in
            let phoneHeight = min(570, max(300, geometry.size.height - 130))
            ScrollView {
                VStack(spacing: 12) {
                    Text(topic.headline).font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                    Text(topic.explanation).font(.subheadline)
                        .foregroundStyle(MARCPalette(dark: scheme == .dark).muted)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    MARCPhoneScreenshotFrame(image: Image(topic.assetName),
                        accessibilityDescription: topic.summary)
                        .frame(width: max(1, min(geometry.size.width - 56, phoneHeight * MARCPhoneScreenshotFrame.displayAspectRatio)))
                        .padding(.top, 8)
                    Text("Swipe to explore")
                        .font(.caption).foregroundStyle(MARCPalette(dark: scheme == .dark).muted)
                }
                .frame(maxWidth: 520).padding(.horizontal, 20).padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }.scrollIndicators(.hidden)
        }
    }
}


/// A decorative Pro-style frame around an unmodified, full-resolution screenshot.
/// Hardware colours are independent of MARC's interface palette.
private struct MARCPhoneScreenshotFrame: View {
    let image: Image
    let accessibilityDescription: String

    private static let screenWidth: CGFloat = 306
    private static let screenHeight: CGFloat = screenWidth * 2048.0 / 946.0
    static let displayAspectRatio: CGFloat = 328 / (screenHeight + 14)
    private var shellHeight: CGFloat { Self.screenHeight + 14 }
    private var metal: LinearGradient {
        LinearGradient(colors: [Color(white: 0.68), Color(white: 0.27), Color(white: 0.56), Color(white: 0.22)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 42).fill(metal)
                RoundedRectangle(cornerRadius: 40).fill(Color.black).padding(2)
                image.resizable().interpolation(.high)
                    .frame(width: Self.screenWidth, height: Self.screenHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 35))
                    .overlay(alignment: .top) {
                        // No recreated clock, dock, home indicator or UI labels.
                        Capsule().fill(Color.black).frame(width: 82, height: 23).padding(.top, 12)
                            .accessibilityHidden(true)
                    }
                RoundedRectangle(cornerRadius: 41).stroke(Color.white.opacity(0.30), lineWidth: 0.8).padding(0.8)
            }
            .frame(width: 320, height: shellHeight)
            .overlay(alignment: .topLeading) {
                VStack(spacing: 18) {
                    sideButton(height: 18)
                    sideButton(height: 38)
                    sideButton(height: 38)
                }.offset(x: -3, y: 80)
            }
            .overlay(alignment: .topTrailing) {
                sideButton(height: 64).offset(x: 3, y: 141)
            }
            .padding(.horizontal, 4)
            .frame(width: 328, height: shellHeight)
            .scaleEffect(geometry.size.width / 328, anchor: .topLeading)
            .allowsHitTesting(false)
        }
        .aspectRatio(328 / shellHeight, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
    private func sideButton(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5).fill(metal).frame(width: 3, height: height)
    }
}

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
            Label("Show me around", systemImage: "arrow.right")
                .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
        }.buttonStyle(.plain).foregroundStyle(p.accent)
    }
    private func laterButton(_ p: MARCPalette) -> some View {
        Button("Explore on my own", action: later).font(.subheadline)
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
                    MARCFeaturePreviewPage(topic: topic, isActive: selection == topic.rawValue)
                        .tag(topic.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityLabel("MARC feature previews")
            VStack(spacing: 0) {
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
        case .status: return "See system usage, battery, storage, services and top processes in one place."
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

    // Anchors refer to the original screenshots, not live controls.
    var notes: [MARCPreviewNote] {
        switch self {
        case .status:
            return [
                .init(title: "System", summary: "CPU & memory", detail: "Check CPU and memory usage, load and swap, plus current network and disk activity. Tap Details for a closer look.", x: 0.04, y: 0.30),
                .init(title: "Power & storage", summary: "Battery & SSD", detail: "See your Mac’s battery level and the percentage of SSD space used beside its name.", x: 0.96, y: 0.15),
                .init(title: "Services & Docker", summary: "Apps & containers", detail: "Switch between services and Docker containers. Open All services or All containers to see the full list and available controls.", x: 0.04, y: 0.60),
                .init(title: "Top processes", summary: "See what’s running", detail: "See process names, PIDs, CPU and memory usage. Tap View all to open Processes and explore the full list.", x: 0.96, y: 0.79)
            ]
        case .system:
            return [
                .init(title: "Each core", summary: "CPU activity", detail: "See activity across your Mac’s CPU cores, along with uptime and load.", x: 0.19, y: 0.27),
                .init(title: "Memory", summary: "RAM & swap", detail: "Check available memory and swap to understand how your Mac is using RAM.", x: 0.80, y: 0.52),
                .init(title: "Network", summary: "Data in and out", detail: "See current download and upload rates, your Mac’s network address and cumulative transfer totals.", x: 0.22, y: 0.66),
                .init(title: "Storage", summary: "Space & disk activity", detail: "Check used and available space, along with current disk reads and writes.", x: 0.80, y: 0.85)
            ]
        case .statistics:
            return [
                .init(title: "Time range", summary: "Usage history", detail: "Switch time ranges to explore the history collected by MARC.", x: 0.23, y: 0.18),
                .init(title: "Spot patterns", summary: "Usage trends", detail: "Compare CPU, load, memory, network and disk activity over time.", x: 0.76, y: 0.51)
            ]
        case .processes:
            return [
                .init(title: "Find an app", summary: "Search processes", detail: "Search the process list to find an app or background task on your Mac.", x: 0.23, y: 0.14),
                .init(title: "Busy apps", summary: "CPU & memory", detail: "Sort the list to find busy processes. Review the selected process before ending it.", x: 0.82, y: 0.24)
            ]
        case .terminal:
            return [
                .init(title: "Ask in words", summary: "AI suggestions", detail: "Describe what you want to do. Your configured AI model can suggest a shell command.", x: 0.24, y: 0.47),
                .init(title: "You decide", summary: "Review, then Run", detail: "Read the suggested command before choosing Run. Generating a suggestion does not run it.", x: 0.80, y: 0.54),
                .init(title: "Add session", summary: "Another shell", detail: "Use + to open another terminal session on this Mac. Use the session selector to switch between sessions.", x: 0.92, y: 0.39)
            ]
        case .files:
            return [
                .init(title: "Your folders", summary: "Browse & preview", detail: "Open folders and preview supported files on your Mac over SSH.", x: 0.20, y: 0.26),
                .init(title: "File actions", summary: "More options", detail: "Use a file’s menu to find actions such as download, rename, move and permissions.", x: 0.89, y: 0.34),
                .init(title: "Upload", summary: "iPhone to Mac", detail: "Choose Upload to select a file or photo from your iPhone and send it to the current folder on your Mac.", x: 0.78, y: 0.14),
                .init(title: "Back", summary: "One folder up", detail: "Use Back to open the parent folder. The Home button returns to your Mac account’s home folder.", x: 0.88, y: 0.19)
            ]
        case .controls:
            return [
                .init(title: "Adjust", summary: "Sound & display", detail: "Adjust supported audio and display settings on your connected Mac.", x: 0.24, y: 0.36),
                .init(title: "Quick Launch", summary: "Open Mac apps", detail: "Choose a saved app to launch it on your Mac. Edit Quick Launch to pick your favourites.", x: 0.77, y: 0.85),
                .init(title: "Now Playing", summary: "Playback controls", detail: "See what’s playing and use the supported play, pause and skip controls on your Mac.", x: 0.78, y: 0.70)
            ]
        }
    }

}

private struct MARCPreviewNote {
    let title: String
    let summary: String
    let detail: String
    let x: CGFloat
    let y: CGFloat
}

private struct MARCFeaturePreviewPage: View {
    let topic: MARCPreviewTopic
    let isActive: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var dynamicType
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var revealed = false
    @State private var expandedNote: Int?
    @ScaledMetric(relativeTo: .caption2) private var noteGutter: CGFloat = 58

    private var p: MARCPalette { MARCPalette(dark: scheme == .dark) }

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, min(520, geometry.size.width - 16))
            let gutter = min(64, max(58, noteGutter))
            // Ordinary text sizes keep the side labels. Only accessibility text
            // or insufficient room for both measured gutters uses the vertical layout.
            let besidePhone = !dynamicType.isAccessibilitySize && width >= 2 * gutter + 140
            let phoneHeight = min(540, max(240, geometry.size.height - 126))
            ScrollView {
                VStack(spacing: 12) {
                    Text(topic.headline).font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                        .fixedSize(horizontal: false, vertical: true).padding(.horizontal, 8)
                    if !besidePhone {
                        Text(topic.explanation).font(.subheadline)
                            .foregroundStyle(p.muted)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                    }
                    if besidePhone {
                        annotatedPhone(width: width, maxHeight: phoneHeight, gutter: gutter)
                    } else {
                        phone.frame(width: max(1, min(width - 32,
                            phoneHeight * MARCPhoneScreenshotFrame.displayAspectRatio)))
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(topic.notes.enumerated()), id: \.offset) { index, note in
                                noteButton(note, index: index, besidePhone: false)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12)
                    }
                    if let index = expandedNote, topic.notes.indices.contains(index) {
                        Text(topic.notes[index].detail).font(.subheadline).foregroundStyle(p.muted)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 12).transition(.opacity)
                    }
                    Text("Tap a label to learn more")
                        .font(.caption).foregroundStyle(p.muted).multilineTextAlignment(.center)
                }
                // A fixed top inset keeps the headline near the header. Centering
                // a short page in the entire viewport created the oversized top gap.
                .frame(width: width).padding(.top, 20).padding(.bottom, 12)
                .frame(maxWidth: .infinity)
            }.scrollIndicators(.hidden)
        }
        // TabView preloads neighbouring pages. Only reveal the selected, active page.
        .task(id: isActive && scenePhase == .active) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { revealed = false; expandedNote = nil }
            guard isActive, scenePhase == .active else { return }
            do { try await Task.sleep(for: .milliseconds(160)) } catch { return }
            guard !Task.isCancelled else { return }
            revealed = true
        }
    }

    private var phone: some View {
        MARCPhoneScreenshotFrame(image: Image(topic.assetName), accessibilityDescription: topic.summary)
    }

    private func annotatedPhone(width: CGFloat, maxHeight: CGFloat, gutter: CGFloat) -> some View {
        MARCPreviewAnnotationLayout(notes: topic.notes, gutter: gutter, maxPhoneHeight: maxHeight) {
            phone.anchorPreference(key: MARCPreviewLabelAnchors.self, value: .bounds) { [-1: $0] }
            ForEach(Array(topic.notes.enumerated()), id: \.offset) { index, note in
                noteButton(note, index: index, besidePhone: true)
                    .anchorPreference(key: MARCPreviewLabelAnchors.self, value: .bounds) { [index: $0] }
            }
        }
        .frame(width: width)
        .overlayPreferenceValue(MARCPreviewLabelAnchors.self) { anchors in
            GeometryReader { reader in
                if let phoneAnchor = anchors[-1] {
                    let phoneRect = reader[phoneAnchor]
                    ForEach(Array(topic.notes.enumerated()), id: \.offset) { index, note in
                        if let labelAnchor = anchors[index] {
                            let label = reader[labelAnchor]
                            let start = CGPoint(x: note.x < 0.5 ? label.maxX + 4 : label.minX - 4,
                                                y: label.midY)
                            let end = CGPoint(x: phoneRect.minX + phoneRect.width * (11 + 306 * note.x) / 328,
                                              y: phoneRect.minY + phoneRect.height * note.y)
                            MARCPreviewLeader(start: start, end: end)
                                .trim(from: 0, to: reduceMotion ? 1 : (revealed ? 1 : 0))
                                .stroke(p.accent.opacity(0.75), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                                .opacity(reduceMotion && !revealed ? 0 : 1)
                                .animation(.easeOut(duration: reduceMotion ? 0.16 : 0.35)
                                    .delay(reduceMotion ? 0 : Double(index) * 0.10), value: revealed)
                            Circle().fill(p.accent).frame(width: 4, height: 4)
                                .position(end).opacity(revealed ? 1 : 0)
                                .animation(.easeOut(duration: 0.16).delay(reduceMotion ? 0 : 0.25), value: revealed)
                        }
                    }
                }
            }.accessibilityHidden(true).allowsHitTesting(false)
        }
        .padding(.top, 8)
    }

    private func noteButton(_ note: MARCPreviewNote, index: Int, besidePhone: Bool) -> some View {
        return Button {
            guard isActive, scenePhase == .active else { return }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.65)
            withAnimation(.easeInOut(duration: reduceMotion ? 0.12 : 0.20)) {
                expandedNote = expandedNote == index ? nil : index
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title).font(besidePhone ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(expandedNote == index ? p.accent : p.text)
                Text(note.summary).font(besidePhone ? .caption2 : .caption).foregroundStyle(p.muted)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 44,
                   alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(note.title). \(note.summary)")
        .accessibilityValue(expandedNote == index ? note.detail : "")
        .accessibilityHint(expandedNote == index ? "Double tap to collapse explanation" : "Double tap for explanation")
        .opacity(revealed ? 1 : 0)
        .offset(y: reduceMotion || revealed ? 0 : 4)
        .animation(.easeOut(duration: reduceMotion ? 0.16 : 0.28)
            .delay(reduceMotion ? 0 : 0.12 + Double(index) * 0.10), value: revealed)
        .allowsHitTesting(revealed && isActive && scenePhase == .active)
        .accessibilityHidden(!revealed)
    }
}

private struct MARCPreviewLabelAnchors: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

/// Ordered labels keep their natural text height and at least one clear gap.
private enum MARCPreviewLabelPlacement {
    static func centers(targets: [CGFloat], heights: [CGFloat], height: CGFloat,
                        gap: CGFloat = 12, padding: CGFloat = 8) -> [CGFloat] {
        precondition(targets.count == heights.count)
        guard !heights.isEmpty else { return [] }
        var tops = [CGFloat](repeating: 0, count: heights.count)
        var cursor = padding
        for index in heights.indices {
            tops[index] = max(cursor, min(targets[index] - heights[index] / 2,
                                          height - padding - heights[index]))
            cursor = tops[index] + heights[index] + gap
        }
        cursor = height - padding
        for index in heights.indices.reversed() {
            tops[index] = min(tops[index], cursor - heights[index])
            cursor = tops[index] - gap
        }
        return heights.indices.map { tops[$0] + heights[$0] / 2 }
    }
}

/// Measure captions before placement. Extra labels never squeeze the phone;
/// if text needs more height the existing page ScrollView can accommodate it.
private struct MARCPreviewAnnotationLayout: Layout {
    let notes: [MARCPreviewNote]
    let gutter: CGFloat
    let maxPhoneHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(width: proposal.width ?? 374, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = arrangement(width: bounds.width, subviews: subviews)
        for index in subviews.indices {
            let rect = layout.frames[index]
            subviews[index].place(at: CGPoint(x: bounds.minX + rect.minX, y: bounds.minY + rect.minY),
                                 anchor: .topLeading,
                                 proposal: ProposedViewSize(width: rect.width, height: rect.height))
        }
    }

    private func arrangement(width: CGFloat, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let phoneWidth = max(1, min(width - 2 * gutter - 16,
                                   maxPhoneHeight * MARCPhoneScreenshotFrame.displayAspectRatio))
        let phoneHeight = phoneWidth / MARCPhoneScreenshotFrame.displayAspectRatio
        let heights = notes.indices.map {
            subviews[$0 + 1].sizeThatFits(ProposedViewSize(width: gutter, height: nil)).height
        }
        var height = phoneHeight
        for onLeft in [true, false] {
            let column = notes.indices.filter { (notes[$0].x < 0.5) == onLeft }
            let required = column.reduce(CGFloat.zero) { $0 + heights[$1] }
                + CGFloat(max(0, column.count - 1)) * 12 + 16
            height = max(height, required)
        }
        let phoneRect = CGRect(x: (width - phoneWidth) / 2, y: (height - phoneHeight) / 2,
                               width: phoneWidth, height: phoneHeight)
        var frames = [CGRect](repeating: .zero, count: notes.count + 1)
        frames[0] = phoneRect
        for onLeft in [true, false] {
            let ordered = notes.indices.filter { (notes[$0].x < 0.5) == onLeft }
                .sorted { notes[$0].y < notes[$1].y }
            let centers = MARCPreviewLabelPlacement.centers(
                targets: ordered.map { phoneRect.minY + phoneHeight * notes[$0].y },
                heights: ordered.map { heights[$0] }, height: height)
            for (position, index) in ordered.enumerated() {
                frames[index + 1] = CGRect(x: onLeft ? 0 : width - gutter,
                    y: centers[position] - heights[index] / 2, width: gutter, height: heights[index])
            }
        }
        return (CGSize(width: width, height: height), frames)
    }
}

private struct MARCPreviewLeader: Shape {
    let start: CGPoint
    let end: CGPoint
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
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

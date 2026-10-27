import SwiftUI

/// Native text and controls surround decorative artwork. Remote Login is enabled on the Mac.
struct MARCPrepareMacScreen: View {
    let tour: MARCGuidedTour
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicType
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue
    @AccessibilityFocusState private var titleFocused: Bool
    private var preparing: Bool { tour.stage != .welcome }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("MARC").font(.caption.weight(.semibold)).tracking(4)
                            .foregroundStyle(p.muted).accessibilityHidden(true)
                        Spacer()
                        Button("Skip") { tour.skip() }
                            .font(.subheadline).foregroundStyle(p.muted)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    Spacer(minLength: 24)
                    illustration(palette: p)
                        .padding(.bottom, preparing ? 24 : 32)
                    VStack(alignment: .leading, spacing: 14) {
                        Text(preparing ? "Enable Remote Login." : "Your Mac,\nwithin reach.")
                            .font(preparing ? .title.weight(.semibold) : .largeTitle.weight(.semibold))
                            .tracking(preparing ? -0.6 : -1)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($titleFocused)
                        if preparing {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("System Settings › General")
                                Text("Sharing › Remote Login")
                            }
                            .font(.subheadline).foregroundStyle(p.muted)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("On your Mac, open System Settings, then General, then Sharing, then Remote Login")
                            Text("Turn it on and allow access for your Mac account.")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("A secure connection to your Mac.")
                                .font(.body).foregroundStyle(p.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 28)
                    if preparing {
                        Label("Same trusted network. Keep your Mac awake.", systemImage: "wifi")
                            .font(.footnote).foregroundStyle(p.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 18)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 20) {
                            if preparing { backAction; Spacer(minLength: 12) }
                            primaryAction
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            primaryAction
                            if preparing { backAction }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, dynamicType.isAccessibilitySize ? 24 : 32)
                .padding(.top, 12)
                .frame(maxWidth: 480)
                .frame(minHeight: geometry.size.height, alignment: .topLeading)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(p.text).tint(p.accent)
        .background(p.background.ignoresSafeArea())
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: preparing)
        .interactiveDismissDisabled()
        .onAppear { titleFocused = true }
        .onChange(of: preparing) { _, _ in titleFocused = true }
    }

    @ViewBuilder private func illustration(palette p: MARCPalette) -> some View {
        if preparing {
            VStack(spacing: 10) {
                Text("On your Mac").font(.caption).foregroundStyle(p.muted)
                MARCSetupSharingWindow(palette: p)
                    .aspectRatio(1.22, contentMode: .fit)
            }
            .accessibilityHidden(true).allowsHitTesting(false)
        } else {
            MARCSetupConnectionCanvas(palette: p)
                .aspectRatio(1.3, contentMode: .fit)
                .accessibilityHidden(true).allowsHitTesting(false)
        }
    }

    private var primaryAction: some View {
        Button { tour.next() } label: {
            HStack(spacing: 10) {
                Text(preparing ? "My Mac is ready" : "Let’s connect")
                Image(systemName: "arrow.right").accessibilityHidden(true)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(Capsule())
            .overlay(Capsule().stroke(MARCPalette(dark: scheme == .dark).accent.opacity(0.8), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundStyle(MARCPalette(dark: scheme == .dark).text)
    }

    private var backAction: some View {
        Button { tour.back() } label: {
            Label("Back", systemImage: "arrow.left")
                .font(.subheadline).frame(minWidth: 44, minHeight: 44)
        }.buttonStyle(.plain).foregroundStyle(MARCPalette(dark: scheme == .dark).muted)
    }
}

private struct MARCSetupConnectionCanvas: View {
    let palette: MARCPalette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lineVisible = false
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            // Use each bundled image's aspect ratio and visible base, including
            // its transparent margins, so the physical devices share a baseline.
            let macWidth = (w * 0.73 * displayScale).rounded() / displayScale
            let macHeight = macWidth * 1024 / 1536
            let phoneWidth = (w * 0.212 * displayScale).rounded() / displayScale
            let phoneHeight = phoneWidth * 1774 / 887
            let baseY = (h * 0.78 * displayScale).rounded() / displayScale
            let macX = macWidth / 2
            let macY = baseY - macHeight * (977.0 / 1024.0 - 0.5)
            let phoneX = w * 0.89
            let phoneY = baseY - phoneHeight * (1673.0 / 1774.0 - 0.5) + h * 0.035
            let start = CGPoint(x: macWidth * 0.892,
                y: macY - macHeight / 2 + macHeight * 0.27)
            let end = CGPoint(x: phoneX - phoneWidth / 2 + phoneWidth * 48 / 887,
                y: phoneY - phoneHeight / 2 + phoneHeight * 0.25)
            ZStack(alignment: .topLeading) {
                macBook
                    .frame(width: macWidth, height: macHeight)
                    .position(x: macX, y: macY)
                phone
                    .frame(width: phoneWidth, height: phoneHeight)
                    .position(x: phoneX, y: phoneY)
                Path { path in
                    path.move(to: start)
                    let gap = end.x - start.x
                    path.addCurve(to: end,
                        control1: CGPoint(x: start.x + gap * 0.45, y: start.y),
                        control2: CGPoint(x: end.x - gap * 0.45, y: end.y))
                }
                .trim(from: 0, to: lineVisible || reduceMotion ? 1 : 0)
                .stroke(palette.accent.opacity(0.65), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                Circle().fill(palette.accent.opacity(0.85)).frame(width: 2.5, height: 2.5)
                    .position(start)
                Circle().fill(palette.accent.opacity(0.85)).frame(width: 2.5, height: 2.5)
                    .position(end)
            }
        }
        .task {
            guard !reduceMotion else { lineVisible = true; return }
            withAnimation(.easeOut(duration: 0.6)) { lineVisible = true }
        }
    }

    // Keep original captures as separate high-resolution layers: generated
    // device frames never need to redraw the website's or app's typography.
    private var macBook: some View {
        Image("MARCSetupMacBook")
            .resizable().interpolation(.high).scaledToFit()
            .overlay {
                GeometryReader { geometry in
                    let screenWidth = geometry.size.width * 1153 / 1536
                    let screenHeight = geometry.size.height * 645 / 1024
                    Image("MARCSetupWebsiteCapture")
                        .resizable().interpolation(.high).scaledToFill()
                        .frame(width: screenWidth, height: screenHeight, alignment: .top)
                        .clipped()
                        .position(x: geometry.size.width * (191 + 1153.0 / 2) / 1536,
                                  y: geometry.size.height * (145 + 645.0 / 2) / 1024)
                }.allowsHitTesting(false)
            }
    }

    private var phone: some View {
        Image("MARCSetupStatus")
            .resizable().interpolation(.high).scaledToFit()
            .overlay {
                GeometryReader { geometry in
                    let screenWidth = geometry.size.width * 702 / 887
                    let screenHeight = geometry.size.height * 1518 / 1774
                    Image("MARCSetupStatusCapture")
                        .resizable().interpolation(.high).scaledToFill()
                        .frame(width: screenWidth, height: screenHeight)
                        .clipShape(RoundedRectangle(cornerRadius: screenWidth * 0.09))
                        .overlay(alignment: .top) {
                            Capsule().fill(.black)
                                .frame(width: screenWidth * 0.28, height: screenHeight * 0.026)
                                .padding(.top, screenHeight * 0.012)
                        }
                        .position(x: geometry.size.width * (97 + 702.0 / 2) / 887,
                                  y: geometry.size.height * (120 + 1518.0 / 2) / 1774)
                }.allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.16), radius: 7, y: 4)
    }

}

/// A noninteractive, theme-aware illustration of the Mac's Sharing settings.
/// Its off indicators intentionally never respond to a tap on the iPhone.
private struct MARCSetupSharingWindow: View {
    let palette: MARCPalette

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 340
            window
                .frame(width: 340, height: 278)
                .scaleEffect(scale, anchor: .topLeading)
        }
    }

    private var window: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Circle().fill(Color.red.opacity(0.8))
                    Circle().fill(Color.yellow.opacity(0.8))
                    Circle().fill(Color.green.opacity(0.8))
                }.frame(width: 32, height: 8).padding(.bottom, 10)
                Label("Search", systemImage: "magnifyingglass")
                    .font(.system(size: 9)).foregroundStyle(palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(5)
                    .background(palette.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
                sidebarRow("General", symbol: "gearshape", selected: true)
                sidebarRow("Appearance", symbol: "circle.lefthalf.filled")
                sidebarRow("Control Centre", symbol: "switch.2")
                sidebarRow("Desktop & Dock", symbol: "menubar.dock.rectangle")
                sidebarRow("Displays", symbol: "display")
                sidebarRow("Wallpaper", symbol: "photo")
                sidebarRow("Notifications", symbol: "bell.badge")
                sidebarRow("Sound", symbol: "speaker.wave.2")
                sidebarRow("Focus", symbol: "moon")
                Spacer(minLength: 0)
            }
            .padding(10).frame(width: 116)
            .background(palette.raised.opacity(0.65))
            Rectangle().fill(palette.border).frame(width: 0.5)
            VStack(alignment: .leading, spacing: 12) {
                Label("Sharing", systemImage: "chevron.left")
                    .font(.system(size: 11, weight: .medium)).padding(.bottom, 10)
                sharingRow("Screen Sharing", symbol: "display", focus: false)
                sharingRow("File Sharing", symbol: "folder.fill", focus: false)
                sharingRow("Remote Login", symbol: "terminal", focus: true)
                Spacer(minLength: 0)
            }.padding(12).frame(maxWidth: .infinity)
        }
        .foregroundStyle(palette.text)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(palette.border, lineWidth: 0.8))
    }

    private func sidebarRow(_ title: String, symbol: String, selected: Bool = false) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 8.5))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4).padding(.vertical, 3)
            .background(selected ? palette.muted.opacity(0.22) : .clear, in: RoundedRectangle(cornerRadius: 4))
    }

    private func sharingRow(_ title: String, symbol: String, focus: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 12)).frame(width: 16)
            Text(title).font(.system(size: 8.5)).lineLimit(1)
            Spacer(minLength: 4)
            Capsule().fill(palette.muted.opacity(0.25)).frame(width: 22, height: 13)
                .overlay(alignment: .leading) {
                    Circle().fill(palette.muted).frame(width: 9, height: 9).padding(2)
                }
            Image(systemName: "info.circle").font(.system(size: 9)).foregroundStyle(palette.muted)
        }
        .padding(.horizontal, 7).frame(height: 38)
        .background(palette.raised.opacity(0.4), in: RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(focus ? palette.accent.opacity(0.8) : palette.border.opacity(0.6), lineWidth: 0.8))
    }
}

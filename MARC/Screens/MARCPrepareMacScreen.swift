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
            // Preserve the uploaded screenshot's aspect ratio inside a 3-point bezel.
            // Snap frame edges to physical pixels and avoid rotating/resampling the text.
            let phoneWidth = (w * 0.27 * displayScale).rounded() / displayScale
            let phoneHeight = (((phoneWidth - 6) * 2048 / 946 + 6) * displayScale).rounded() / displayScale
            let phoneX = ((w * 0.83 - phoneWidth / 2) * displayScale).rounded() / displayScale + phoneWidth / 2
            let phoneY = ((h * 0.64 - phoneHeight / 2) * displayScale).rounded() / displayScale + phoneHeight / 2
            let phoneTop = phoneY - phoneHeight / 2
            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: w * 0.64, y: h * 0.25))
                    path.addCurve(to: CGPoint(x: phoneX, y: phoneTop),
                                  control1: CGPoint(x: w * 0.77, y: h * 0.24),
                                  control2: CGPoint(x: w * 0.85, y: h * 0.26))
                }
                .trim(from: 0, to: lineVisible || reduceMotion ? 1 : 0)
                .stroke(palette.accent.opacity(0.8), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                Image("MARCSetupMacBook")
                    .resizable().scaledToFit()
                    .frame(width: w * 0.76, height: h * 0.7)
                    .position(x: w * 0.38, y: h * 0.43)
                phone
                    .frame(width: phoneWidth, height: phoneHeight)
                    .position(x: phoneX, y: phoneY)
                Circle().fill(palette.accent).frame(width: 4, height: 4)
                    .position(x: w * 0.64, y: h * 0.25)
                Circle().fill(palette.accent).frame(width: 4, height: 4)
                    .position(x: phoneX, y: phoneTop)
            }
        }
        .task {
            guard !reduceMotion else { lineVisible = true; return }
            withAnimation(.easeOut(duration: 0.6)) { lineVisible = true }
        }
    }

    private var phone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color.black)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.9), lineWidth: 1))
            Image("MARCSetupStatus")
                .resizable().interpolation(.high).antialiased(true).scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .padding(3)
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

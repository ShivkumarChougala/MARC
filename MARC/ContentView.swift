import SwiftUI
import UIKit
import Citadel
struct ContentView: View {
    @State private var store = ServerStore()
    @State private var terminalWorkspace = MARCTerminalWorkspace()
    @State private var remoteFiles = MARCRemoteFiles()
    @AppStorage("marc.appearance") private var appearance = "system"
    @State private var tab = 0
    @State private var terminalReturnTab = 0
    @State private var workspaceReturnTab = 0
    @State private var initialConnectionCheck = true
    @State private var terminalKeyboardVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 1:
                    NavigationStack {
                        ProcessesScreen(monitor: store.monitor, onClose: closeWorkspace)
                    }
                case 2:
                        MARCKeyboardContainer {
                            TerminalScreen(
                                monitor: store.monitor,
                                workspace: terminalWorkspace,
                                navigate: { destination in
                                    UIApplication.shared.sendAction(
                                        #selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil
                                    )
                                    tab = destination < 0 ? terminalReturnTab : destination
                                }
                            )
                            .environment(\.colorScheme, scheme)
                        }
                        .background(p.background.ignoresSafeArea(.container, edges: .top))
                case 3:
                    NavigationStack {
                        FilesScreen(monitor: store.monitor, files: remoteFiles, onShowTerminal: { path in
                            guard terminalWorkspace.stageDirectory(path) else { return }
                            terminalReturnTab = 3
                            tab = 2
                        }, onClose: closeWorkspace)
                    }
                case 4: NavigationStack { SettingsScreen(store: store) }
                default: NavigationStack { HomeScreen(store: store, openSettings: { tab = 4 }) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if tab != 1 && tab != 2 && tab != 3 {
            HStack(spacing: 2) {
                navItem("Status", symbol: "gauge.with.needle", index: 0, palette: p)
                navItem("Processes", symbol: "slider.horizontal.3", index: 1, palette: p)
                navItem("Terminal", symbol: "terminal", index: 2, palette: p)
                navItem("Files", symbol: "folder", index: 3, palette: p)
                navItem("Settings", symbol: "slider.horizontal.2.square", index: 4, palette: p)
            }.padding(5).background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(p.border.opacity(0.7), lineWidth: 1))
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                .padding(.horizontal, 12).padding(.bottom, 10).padding(.top, 6)
                .background {
                    Rectangle().fill(.ultraThinMaterial)
                        .mask(LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .ignoresSafeArea(.container, edges: .bottom)
                }

            }
        }
        .ignoresSafeArea(
            tab == 2 ? .keyboard : [],
            edges: .bottom
        )
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillChangeFrameNotification
        )) { notification in
            guard let frame = notification.userInfo?[
                UIResponder.keyboardFrameEndUserInfoKey
            ] as? CGRect else { return }
            terminalKeyboardVisible =
                frame.height > 0 &&
                frame.minY < UIScreen.main.bounds.maxY - 1
        }
        .marcCanvas()
        .overlay {
            if !store.servers.isEmpty &&
                ((initialConnectionCheck && store.monitor.error == nil) ||
                 store.monitor.connecting ||
                 (store.monitor.connected &&
                  store.monitor.snapshot == nil &&
                  store.monitor.error == nil)) {
                MARCConnectionLoadingView(
                    serverName: store.monitor.server?.name ?? "your Mac",
                    cancel: {
                        initialConnectionCheck = false
                        store.monitor.cancelConnection()
                    }
                )
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                await store.reconnectRememberedServer()
                guard !Task.isCancelled else { return }
                initialConnectionCheck = false
                do {
                    try await Task.sleep(for: .seconds(15))
                } catch {
                    return
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                terminalWorkspace.pause()
                remoteFiles.stop()
                store.monitor.cancelConnection(reconnectAutomatically: store.monitor.automaticReconnectEnabled)
            }
        }
        .onDisappear {
            terminalWorkspace.pause()
            remoteFiles.stop()
            store.monitor.cancelConnection(reconnectAutomatically: store.monitor.automaticReconnectEnabled)
        }
        .onChange(of: store.monitor.connected) { _, connected in
            if !connected { terminalWorkspace.pause(); remoteFiles.stop() }
        }
        .onChange(of: store.monitor.server?.id) { _, id in
            terminalWorkspace.clearIfDifferent(id)
            remoteFiles.stop()
        }
        .preferredColorScheme(appearance == "system" ? nil : (appearance == "dark" ? .dark : .light))
    }
    private func closeWorkspace() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
        tab = workspaceReturnTab
    }

    private func navItem(_ title: String, symbol: String, index: Int, palette: MARCPalette) -> some View {
        Button {
            if index == 2 && tab != 2 { terminalReturnTab = tab }
            if index == 1 || index == 3 { workspaceReturnTab = tab }
            tab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 23, weight: .regular))
                Text(title).lineLimit(1).minimumScaleFactor(0.75).font(.system(size: 10, weight: tab == index ? .semibold : .medium))
            }.frame(maxWidth: .infinity).frame(minHeight: 58)
                .foregroundStyle(tab == index ? palette.accent : (scheme == .dark ? Color(marcHex: 0xd9d9df) : palette.muted))
                .background(tab == index ? palette.raised.opacity(0.55) : .clear, in: Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(tab == index ? .isSelected : [])
    }
}



private struct MARCConnectionLoadingView: View {
    let serverName: String
    let cancel: () -> Void

    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        GeometryReader { geometry in
            let logoWidth = min(geometry.size.width * 0.78, 340)
            ZStack {
                p.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    Image("MARCLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: logoWidth,
                            height: logoWidth
                        )
                        .frame(height: logoWidth * 0.32)
                        .clipped()
                        .modifier(
                            MARCLoadingLogoAppearance(dark: scheme == .dark)
                        )
                        .accessibilityLabel("MARC")

                    TimelineView(.periodic(from: .now, by: 0.5)) { context in
                        let tick = Int(
                            context.date.timeIntervalSinceReferenceDate * 2
                        )
                        VStack(spacing: 18) {
                            HStack(spacing: 0) {
                                Text(">")
                                Text("_")
                                    .opacity(
                                        reduceMotion || tick % 2 == 0 ? 1 : 0
                                    )
                            }
                            .font(.system(
                                size: 20,
                                weight: .medium,
                                design: .monospaced
                            ))
                            .foregroundStyle(p.accent)
                            .accessibilityHidden(true)

                            HStack(spacing: 0) {
                                Text("Connecting")
                                Text(reduceMotion
                                     ? "…"
                                     : String(repeating: ".", count: tick % 4))
                                    .frame(width: 18, alignment: .leading)
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(p.text)
                            .accessibilityLabel("Connecting to \(serverName)")
                        }
                    }
                    .padding(.top, 22)

                    Text(serverName)
                        .font(.system(size: 12))
                        .foregroundStyle(p.muted)
                        .lineLimit(1)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    Spacer()

                    Button("Cancel", action: cancel)
                        .font(.system(size: 13))
                        .foregroundStyle(p.muted)
                        .padding(.horizontal, 24)
                        .frame(minHeight: 44)
                        .padding(.bottom, 20)
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
            }
        }
    }
}


private struct MARCLoadingLogoAppearance: ViewModifier {
    let dark: Bool

    func body(content: Content) -> some View {
        Group {
            if dark {
                content
            } else {
                content.colorInvert()
            }
        }
        .mask {
            content
                .saturation(0)
                .contrast(10)
                .luminanceToAlpha()
        }
    }
}

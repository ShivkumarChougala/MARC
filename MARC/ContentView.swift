import SwiftUI
import UIKit

struct ContentView: View {
    let store: ServerStore
    let terminalWorkspace: MARCTerminalWorkspace
    @State private var remoteFiles = MARCRemoteFiles()
    @AppStorage("marc.appearance") private var appearance = "system"
    @Binding var tab: Int
    @State private var processSorting = "CPU"
    @State private var terminalReturnTab = 0
    @State private var initialConnectionCheck = true
    @State private var keyboardVisible = false
    @State private var terminating: MARCProcessTarget?
    @AppStorage("marc.onboarding.version") private var onboardingVersion = 0
    @State private var guidedTour = MARCGuidedTour()
    @State private var addingFromSetup = false
    @State private var setupConnectedProfile: UUID?
    @State private var setupConnectedSession: UUID?
    @State private var setupSuccessName: String?
    @State private var setupSuccessSession: UUID?
    @AppStorage("marc.explore.audience") private var exploreAudience = ""
    private enum ExplorePresentation: String, Identifiable {
        case invitation, gallery
        var id: String { rawValue }
    }
    @State private var explorePresentation: ExplorePresentation?
    @State private var exploreInvitation = MARCExploreInvitation()
    @State private var openGalleryAfterInvite = false
    @State private var exploreBarrier = UUID()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue
    private var needsIntroduction: Bool {
        MARCOnboardingPolicy.needsIntroduction(
            completedVersion: onboardingVersion, hasSavedServers: !store.servers.isEmpty,
            profileReadFailed: store.storageError != nil)
    }
    private var reconnectPermitted: Bool {
        scenePhase == .active && !needsIntroduction && guidedTour.flow != .setup
    }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        Group {
            switch tab {
            case 1:
                workspace {
                    ProcessesScreen(monitor: store.monitor, terminating: $terminating,
                                    sorting: $processSorting)
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
                workspace {
                    FilesScreen(monitor: store.monitor, files: remoteFiles, onShowTerminal: { path in
                        guard terminalWorkspace.stageDirectory(path) else { return }
                        terminalReturnTab = 3
                        tab = 2
                    })
                }
            case 4: workspace {
                SettingsScreen(store: store, onAddedConnection: { connection in
                    offerExploration(connection: connection, replayingSetup: false)
                })
            }
            default: workspace {
                HomeScreen(store: store, openSettings: { tab = 4 }, openProcesses: { sorting in
                    processSorting = sorting
                    tab = 1
                })
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })?
                .windows.first(where: \.isKeyWindow) else { return }
            let local = window.convert(frame, from: window.screen.coordinateSpace)
            let overlap = window.bounds.intersection(local)
            keyboardVisible = !overlap.isNull && overlap.height > 0
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillHideNotification
        )) { _ in keyboardVisible = false }
        .marcCanvas()
        .environment(\.marcGuidedTour, guidedTour)
        .allowsHitTesting(terminating == nil)
        .accessibilityHidden(terminating != nil)
        .overlay {
            if guidedTour.flow != .setup && !needsIntroduction && !store.servers.isEmpty &&
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
        .overlay {
            if let target = terminating, tab == 1, store.monitor.connected,
               target.connection == store.monitor.processConnectionID {
                MARCProcessConfirmation(target: target, monitor: store.monitor) {
                    terminating = nil
                }
            }
        }
        .onChange(of: tab) { _, _ in
            terminating = nil
        }
        .onChange(of: store.monitor.processConnectionID) { _, _ in
            if let connection = exploreInvitation.connection, connection != store.monitor.processConnectionID {
                cancelExploreInvitation()
            }
            setupSuccessName = nil
            setupSuccessSession = nil
            terminating = nil
        }
        .onAppear(perform: prepareIntroduction)
        .fullScreenCover(isPresented: Binding(
            get: { guidedTour.active && (guidedTour.stage == .welcome || guidedTour.stage == .prepare) },
            set: { showing in
                if !showing && guidedTour.active && (guidedTour.stage == .welcome || guidedTour.stage == .prepare) {
                    guidedTour.skip()
                }
            }
        )) {
            MARCPrepareMacScreen(tour: guidedTour)
                .environment(\.marcGuidedTour, guidedTour)
                .preferredColorScheme(appearance == "system" ? nil : (appearance == "dark" ? .dark : .light))
        }
        .onChange(of: guidedTour.stage) { _, stage in
            if stage == .welcome { setupSuccessName = nil; setupSuccessSession = nil }
            if stage == .addServer { tab = 4 }
            if stage == .connect {
                setupConnectedProfile = nil
                setupConnectedSession = nil
                addingFromSetup = true
            }
        }
        .sheet(isPresented: $addingFromSetup, onDismiss: {
            if let id = setupConnectedProfile, store.monitor.connected,
               store.monitor.server?.id == id,
               setupConnectedSession == store.monitor.processConnectionID {
                // Only the still-active setup can publish its successful finish.
                if guidedTour.active && guidedTour.stage == .connect {
                    setupSuccessName = store.monitor.server?.name ?? "your Mac"
                    setupSuccessSession = store.monitor.processConnectionID
                    guidedTour.connectionSucceeded()
                    offerExploration(connection: store.monitor.processConnectionID, replayingSetup: true)
                    if scenePhase == .active {
                        UIAccessibility.post(notification: .announcement,
                            argument: "Connected to \(setupSuccessName ?? "your Mac")")
                    }
                }
            } else if guidedTour.active && guidedTour.stage == .connect {
                guidedTour.back()
            }
            setupConnectedProfile = nil
            setupConnectedSession = nil
        }) {
            AddServerScreen(store: store, onConnected: {
                if store.monitor.connected {
                    setupConnectedProfile = store.monitor.server?.id
                    setupConnectedSession = store.monitor.processConnectionID
                }
            })
            .environment(\.marcGuidedTour, guidedTour)
        }
        .sheet(item: $explorePresentation, onDismiss: {
            let open = openGalleryAfterInvite && exploreInvitation.valid(
                currentConnection: store.monitor.processConnectionID,
                connected: store.monitor.connected, active: scenePhase == .active)
            openGalleryAfterInvite = false
            exploreInvitation.cancel()
            if open { explorePresentation = .gallery }
            else { guidedTour.setPresentation(exploreBarrier, visible: false) }
        }) { presentation in
            Group {
                switch presentation {
                case .invitation:
                    MARCExploreInvitationScreen(explore: {
                        openGalleryAfterInvite = exploreInvitation.valid(
                            currentConnection: store.monitor.processConnectionID,
                            connected: store.monitor.connected, active: scenePhase == .active)
                        explorePresentation = nil
                    }, later: { explorePresentation = nil })
                    .onAppear(perform: markExploreInvitationPresented)
                case .gallery:
                    MARCFeatureGuideScreen()
                        .presentationDetents([.large]).presentationDragIndicator(.hidden)
                }
            }
            .environment(\.marcGuidedTour, guidedTour)
            .marcGuidePresentationBarrier()
            .preferredColorScheme(appearance == "system" ? nil : (appearance == "dark" ? .dark : .light))
        }
        .overlay(alignment: .top) {
            if let name = setupSuccessName, scenePhase == .active, tab == 0,
               store.monitor.connected, !guidedTour.active,
               setupSuccessSession == store.monitor.processConnectionID {
                Label {
                    Text("Connected to \(name)")
                } icon: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(p.accent)
                }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(p.text)
                    .lineLimit(2)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(p.raised, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(p.border, lineWidth: 0.75))
                    .padding(.horizontal, 24).padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
        .task(id: setupSuccessName) {
            guard setupSuccessName != nil else { return }
            do { try await Task.sleep(for: .seconds(3)) }
            catch { return }
            guard !Task.isCancelled else { return }
            setupSuccessName = nil
            setupSuccessSession = nil
        }
        .onChange(of: guidedTour.completionID) { _, _ in
            if guidedTour.completedFlow == .setup {
                onboardingVersion = max(onboardingVersion, MARCOnboardingPolicy.currentVersion)
                if guidedTour.finished { tab = 0 }
            }
        }
        .onChange(of: guidedTour.feedbackID) { _, _ in
            guard scenePhase == .active else { return }
            if guidedTour.feedback == .completion {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else { UISelectionFeedbackGenerator().selectionChanged() }
        }
        .onChange(of: keyboardVisible) { _, visible in guidedTour.keyboardVisible = visible }
        .task(id: reconnectPermitted) {
            guard reconnectPermitted else { return }
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
            if phase == .active && explorePresentation == .invitation { markExploreInvitationPresented() }
            if phase == .background {
                cancelExploreInvitation()
                setupSuccessName = nil
                setupSuccessSession = nil
                terminating = nil
                terminalWorkspace.pause()
                remoteFiles.stop()
                store.monitor.cancelConnection(reconnectAutomatically: store.monitor.automaticReconnectEnabled)
            }
        }
        .onDisappear {
            cancelExploreInvitation()
            guidedTour.setPresentation(exploreBarrier, visible: false)
            terminalWorkspace.pause()
            remoteFiles.stop()
            store.monitor.cancelConnection(reconnectAutomatically: store.monitor.automaticReconnectEnabled)
        }
        .onChange(of: store.monitor.connected) { _, connected in
            if !connected {
                cancelExploreInvitation()
                setupSuccessName = nil
                setupSuccessSession = nil
                terminating = nil; terminalWorkspace.pause(); remoteFiles.stop()
            }
        }
        .onChange(of: store.servers.map(\.id)) { _, ids in
            terminalWorkspace.discardIfRemoved(from: ids)
        }
        .onChange(of: store.monitor.server?.id) { _, id in
            terminating = nil
            terminalWorkspace.clearIfDifferent(id)
            remoteFiles.stop()
        }
        .preferredColorScheme(appearance == "system" ? nil : (appearance == "dark" ? .dark : .light))
    }

    private func prepareIntroduction() {
        if exploreInvitation.connection != nil && !exploreInvitation.valid(
            currentConnection: store.monitor.processConnectionID, connected: store.monitor.connected, active: true) {
            cancelExploreInvitation()
        }
        if explorePresentation != nil { guidedTour.setPresentation(exploreBarrier, visible: true) }
        exploreAudience = MARCExploreInvitation.audience(stored: exploreAudience,
            onboardingVersion: onboardingVersion, hasSavedServers: !store.servers.isEmpty,
            profileReadFailed: store.storageError != nil).rawValue
        onboardingVersion = MARCOnboardingPolicy.migratedVersion(
            onboardingVersion, hasSavedServers: !store.servers.isEmpty,
            profileReadFailed: store.storageError != nil)
        if needsIntroduction && !guidedTour.active {
            initialConnectionCheck = false
            tab = 4
            guidedTour.startSetup()
        }
    }

    private func offerExploration(connection: UUID, replayingSetup: Bool) {
        guard scenePhase == .active, !guidedTour.active, explorePresentation == nil,
              exploreInvitation.request(connection: connection,
                currentConnection: store.monitor.processConnectionID, connected: store.monitor.connected,
                audience: MARCExploreInvitation.Audience(rawValue: exploreAudience) ?? .existing,
                replayingSetup: replayingSetup) else { return }
        guidedTour.setPresentation(exploreBarrier, visible: true)
        tab = 0
        explorePresentation = .invitation
    }

    private func cancelExploreInvitation() {
        guard exploreInvitation.connection != nil || explorePresentation == .invitation || openGalleryAfterInvite else { return }
        openGalleryAfterInvite = false
        exploreInvitation.cancel()
        guidedTour.setPresentation(exploreBarrier, visible: false)
        explorePresentation = nil
    }

    private func markExploreInvitationPresented() {
        guard exploreInvitation.markPresented(currentConnection: store.monitor.processConnectionID,
            connected: store.monitor.connected, active: scenePhase == .active) else { return }
        exploreAudience = MARCExploreInvitation.Audience.handled.rawValue
        if !exploreInvitation.replayingSetup {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func workspace<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !keyboardVisible && tab != 1 && tab != 3 {
                        navigationDock(palette: MARCPalette(dark: scheme == .dark))
                    }
                }
                .overlay(alignment: .bottom) {
                    if !keyboardVisible && (tab == 1 || tab == 3) {
                        navigationDock(palette: MARCPalette(dark: scheme == .dark))
                    }
                }
        }
    }

    @ViewBuilder
    private func navigationDock(palette p: MARCPalette) -> some View {
        navigationItems(palette: p)
            .padding(4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(p.border.opacity(0.7), lineWidth: 1))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            .padding(.horizontal, 12)
            .padding(.top, 6)
    }

    private func navigationItems(palette p: MARCPalette) -> some View {
        HStack(spacing: 2) {
            navItem("Status", symbol: "gauge.with.needle", index: 0, palette: p)
            navItem("Processes", symbol: "slider.horizontal.3", index: 1, palette: p)
            navItem("Terminal", symbol: "terminal", index: 2, palette: p)
            navItem("Files", symbol: "folder", index: 3, palette: p)
            navItem("Settings", symbol: "slider.horizontal.2.square", index: 4, palette: p)
        }
    }

    private func navItem(_ title: String, symbol: String, index: Int, palette: MARCPalette) -> some View {
        Button {
            if index == 2 && tab != 2 { terminalReturnTab = tab }
            tab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 23, weight: .regular))
                Text(title).lineLimit(1).minimumScaleFactor(0.75).font(.system(size: 10, weight: tab == index ? .semibold : .medium))
            }.frame(maxWidth: .infinity).frame(minHeight: 50)
                .foregroundStyle(tab == index ? palette.accent : (scheme == .dark ? Color(marcHex: 0xd9d9df) : palette.muted))
                .background(tab == index ? palette.raised.opacity(0.55) : .clear, in: Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(tab == index ? .isSelected : [])
    }
}



private struct MARCConnectionLoadingView: View {
    let serverName: String
    let cancel: () -> Void

    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        GeometryReader { geometry in
            let mascotSize = min(geometry.size.width * 0.62, 240)
            ZStack {
                p.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    MARCLoadingMascot(size: mascotSize)
                        .offset(x: mascotSize * 0.13)
                        .overlay(alignment: .top) {
                            VStack(spacing: 6) {
                                MARCConnectingLabel()
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(p.text)
                                    .accessibilityLabel("Connecting to \(serverName)")
                                Text(serverName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(p.muted)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, mascotSize * 0.70)
                        }
                        .frame(height: mascotSize * 0.89, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    Spacer(minLength: 0)
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

private struct MARCConnectingLabel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.5,
                                paused: reduceMotion || scenePhase != .active)) { context in
            let count = Int(context.date.timeIntervalSinceReferenceDate * 2) % 3 + 1
            HStack(spacing: 0) {
                Text("Connecting")
                Text(reduceMotion ? "…" : String(repeating: ".", count: count))
                    .frame(width: 14, alignment: .leading)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Connecting")
    }
}

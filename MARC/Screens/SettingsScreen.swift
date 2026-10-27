import SwiftUI
struct SettingsScreen: View {
    let store: ServerStore
    var onAddedConnection: (UUID) -> Void = { _ in }
    @State private var addedConnection: UUID?
    @State private var customizingStatus = false
    @AppStorage("marc.status.order") private var statusOrder = "system,developer,processes"
    @AppStorage("marc.status.hidden") private var statusHidden = ""
    @State private var customizingSettings = false
    @State private var setupScroll = ScrollPosition(edge: .top)
    @Environment(\.marcGuidedTour) private var guidedTour
    @State private var showingFeatureGuide = false
    @AppStorage("marc.settings.order") private var settingsOrder = MARCSettingsSection.defaultOrder
    @AppStorage("marc.settings.hidden") private var settingsHidden = ""
    private var visibleSettingsSections: [MARCSettingsSection] {
        let hidden = Set(settingsHidden.split(separator: ",").map(String.init))
        return MARCSettingsSection.ordered(settingsOrder).filter {
            $0.alwaysVisible || !hidden.contains($0.rawValue)
        }
    }
    @AppStorage("marc.appearance") private var appearance = "system"
    @AppStorage("marc.refreshInterval") private var refreshInterval = 2
    @State private var removing: ServerProfile?
    @State private var adding = false
    @State private var editingServer: ServerProfile?
    @State private var testingServer: ServerProfile?
    @State private var connectingServer: ServerProfile?
    @State private var connectionFeedback: String?
    @State private var connectionTask: Task<Void, Never>?
    @State private var connectionRequest = UUID()
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Button {
                    if guidedTour?.active == true && guidedTour?.stage == .addServer {
                        guidedTour?.next()
                    } else { adding = true }
                } label: {
                    HStack(spacing: 12) {
                        MARCSettingsRowIcon(symbol: "plus")
                        Text("Add server").font(.system(size: 15)).foregroundStyle(p.text)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(p.muted)
                    }.padding(.horizontal, 16).frame(minHeight: 58)
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain).marcSetupTarget("add")
                if let error = store.storageError {
                    HStack(alignment: .top) {
                        Text(error).font(.footnote).foregroundStyle(.red)
                        Spacer(minLength: 8)
                        Button("Dismiss") { store.storageError = nil }.font(.footnote)
                    }
                }
                ForEach(visibleSettingsSections) { item in
                    settingsSection(item)
                }
                if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                    Text("MARC · Version \(version)")
                        .font(.footnote).foregroundStyle(p.muted)
                        .frame(maxWidth: .infinity).padding(.top, 2)
                }
            }.padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 16)
        }.scrollPosition($setupScroll).scrollClipDisabled().scrollIndicators(.hidden).marcCanvas()
            .onChange(of: guidedTour?.stage) { _, stage in
                if stage == .addServer { setupScroll.scrollTo(edge: .top) }
            }
            .sheet(isPresented: $showingFeatureGuide) {
                MARCFeatureGuideScreen()
                    .environment(\.colorScheme, scheme)
                    .marcGuidePresentationBarrier()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .marcSetupCoach(target: "add", title: "Add your Mac",
                message: "Tap Add server to begin.",
                enabled: guidedTour?.active == true && guidedTour?.stage == .addServer && guidedTour?.hasBlockingPresentation != true,
                next: { guidedTour?.next() }, skip: { guidedTour?.skip() },
                back: { guidedTour?.back() })
            .marcNavigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { customizingSettings = true } label: {
                        Label("Customize", systemImage: "square.grid.2x2")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(p.accent)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Customize Settings layout")
                }
                .marcToolbarBackgroundHidden()
            }
            .sheet(isPresented: $customizingStatus) {
                MARCStatusCustomizeSheet(order: $statusOrder, hidden: $statusHidden)
            }
            .sheet(isPresented: $customizingSettings) {
                MARCSettingsCustomizeSheet(order: $settingsOrder, hidden: $settingsHidden)
            }
            .sheet(isPresented: $adding, onDismiss: {
                let connection = addedConnection
                addedConnection = nil
                if let connection { onAddedConnection(connection) }
            }) {
                AddServerScreen(store: store, onConnected: {
                    if store.monitor.connected { addedConnection = store.monitor.processConnectionID }
                })
            }
            .onDisappear(perform: stopConnectionRequest)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { stopConnectionRequest() }
            }
            .onChange(of: store.monitor.connected) { _, connected in
                if connected { connectionFeedback = nil }
            }
            .sheet(item: $editingServer) { server in
                MARCEditServerScreen(store: store, server: server)
            }
            .sheet(item: $connectingServer) { server in SSHConnectScreen(server: server, monitor: store.monitor) }
            .sheet(item: $testingServer) { server in SSHTestScreen(server: server) }
            .sheet(item: $removing) { server in
                MARCRemoveServerSheet(server: server, store: store) {
                    let removed = store.remove(server)
                    if removed { removing = nil }
                    return removed
                }
            }
    }

    @ViewBuilder
    private func settingsSection(_ item: MARCSettingsSection) -> some View {
        let p = MARCPalette(dark: scheme == .dark)
        switch item {
        case .servers:
                if !store.servers.isEmpty {
                    MARCSettingsGroup(title: "Saved servers") {
                        ForEach(store.servers) { server in
                            HStack(spacing: 12) {
                                MARCSettingsRowIcon(symbol: "laptopcomputer")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(server.name).font(.system(size: 14, weight: .semibold))
                                    Text("\(server.username)@\(server.host):\(server.port)").font(.system(size: 11)).foregroundStyle(p.muted).lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                HStack(spacing: 6) {
                                    if store.selectedID == server.id && store.monitor.connecting {
                                        ProgressView().controlSize(.small)
                                    }
                                    Text(connectionLabel(server))
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(
                                            store.monitor.server?.id == server.id && store.monitor.connected
                                                ? Color(marcHex: 0x2dcc58)
                                                : p.muted
                                        )
                                }
                                Menu {
                                    Button("Edit server") { editingServer = server }
                                    if store.monitor.server?.id == server.id && store.monitor.connected {
                                        Button("Disconnect") { store.monitor.cancelConnection() }
                                    }
                                    Button("Test SSH") { store.selectedID = server.id; testingServer = server }
                                    Button("Remove server", role: .destructive) { removing = server }
                                } label: {
                                    Image(systemName: "ellipsis").font(.system(size: 20)).frame(width: 44, height: 44).foregroundStyle(p.muted)
                                }.accessibilityLabel("Actions for \(server.name)")
                            }
                            .padding(.horizontal, 14)
                            .frame(minHeight: 70)
                            .background(
                                store.selectedID == server.id
                                    ? p.raised.opacity(0.45) : Color.clear
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { selectAndConnect(server) }
                            if server.id != store.servers.last?.id { MARCSettingsDivider() }
                        }
                    }
                    if let connectionFeedback {
                        HStack(alignment: .top) {
                            Text(connectionFeedback).font(.footnote).foregroundStyle(p.muted)
                            Spacer(minLength: 8)
                            Button("Dismiss") { self.connectionFeedback = nil }.font(.footnote)
                        }
                        .padding(.horizontal, 14)
                    }
                }
        case .security:
                MARCSettingsGroup(title: "Security") {
                    MARCAppLockSetting()
                    MARCSettingsDivider()
                    NavigationLink {
                        MARCTerminalAISettings(monitor: store.monitor)
                    } label: {
                        MARCSettingsSupportRow(title: "Terminal & AI", icon: "terminal", external: false)
                    }.buttonStyle(.plain)
                    MARCSettingsDivider()
                    NavigationLink {
                        MARCKeychainScreen(store: store)
                    } label: {
                        MARCSettingsSupportRow(title: "Keychain", icon: "key", external: false)
                    }.buttonStyle(.plain)
                }
        case .general:
                MARCSettingsGroup(title: "General") {
                    HStack(spacing: 12) {
                        MARCSettingsRowIcon(symbol: "sun.max")
                        Text("Appearance").font(.system(size: 15))
                        Spacer()
                        Picker("Appearance", selection: $appearance) {
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                            Text("Auto").tag("system")
                        }.labelsHidden().pickerStyle(.menu).tint(p.muted).font(.system(size: 15))
                    }.padding(.horizontal, 14).frame(minHeight: 50)
                    MARCSettingsDivider()
                    MARCAccentPicker()
                    MARCSettingsDivider()
                    Button { customizingStatus = true } label: {
                        MARCSettingsSupportRow(title: "Customize Status", icon: "square.grid.2x2", external: false)
                    }.buttonStyle(.plain)
                    MARCSettingsDivider()
                    HStack(spacing: 12) {
                        MARCSettingsRowIcon(symbol: "arrow.clockwise")
                        Text("Refresh interval").font(.system(size: 15))
                        Spacer()
                        Picker("Refresh interval", selection: $refreshInterval) {
                            Text("1 second").tag(1)
                            Text("2 seconds").tag(2)
                            Text("5 seconds").tag(5)
                        }.labelsHidden().pickerStyle(.menu).tint(p.muted).font(.system(size: 15))
                    }.padding(.horizontal, 14).frame(minHeight: 50)
                }
        case .support:
                MARCSettingsGroup(title: "Support") {
                    Button { guidedTour?.startSetup() } label: {
                        MARCSettingsSupportRow(title: "Getting started", icon: "book", external: false)
                    }.buttonStyle(.plain)
                    MARCSettingsDivider()
                    Button {
                        showingFeatureGuide = true
                    } label: {
                        MARCSettingsSupportRow(title: "What’s inside MARC", icon: "square.grid.2x2", external: false)
                    }.buttonStyle(.plain).disabled(guidedTour?.active == true)
                    MARCSettingsDivider()
                    NavigationLink {
                        MARCHelpFeedbackScreen()
                    } label: {
                        MARCSettingsSupportRow(title: "Help & feedback", icon: "bubble.left", external: false)
                    }.buttonStyle(.plain)
                }
        case .contribute:
                MARCSettingsGroup(title: "Ways to Help") {
                    MARCSettingsSupportRow(title: "Rate MARC", icon: "star", detail: "Coming soon", enabled: false)
                        .accessibilityLabel("Rate MARC. Available after the App Store launch.")
                    MARCSettingsDivider()
                    ShareLink(item: URL(string: "https://getmarc.app/")!,
                              subject: Text("MARC — your Mac, within reach"),
                              message: Text("Check out MARC, an open-source iPhone app for monitoring and controlling your Mac over SSH.")) {
                        MARCSettingsSupportRow(title: "Share MARC", icon: "square.and.arrow.up", external: false)
                    }.buttonStyle(.plain)
                    MARCSettingsDivider()
                    Link(destination: URL(string: "https://github.com/ShivkumarChougala/MARC")!) {
                        MARCSettingsSupportRow(title: "Star on GitHub", icon: "chevron.left.forwardslash.chevron.right")
                    }.buttonStyle(.plain)
                    MARCSettingsDivider()
                    Link(destination: URL(string: "https://getmarc.app/support.html")!) {
                        MARCSettingsSupportRow(title: "Support MARC", icon: "heart")
                    }.buttonStyle(.plain)
                }
        case .legal:
                MARCSettingsGroup(title: "Legal") {
                    Link(destination: URL(string: "https://getmarc.app/privacy")!) {
                        MARCSettingsSupportRow(title: "Privacy Policy", icon: "doc.text")
                    }.buttonStyle(.plain)
                    MARCSettingsDivider()
                    Link(destination: URL(string: "https://getmarc.app/terms")!) {
                        MARCSettingsSupportRow(title: "Terms of Use", icon: "doc.text")
                    }.buttonStyle(.plain)
                    MARCSettingsDivider()
                    Link(destination: URL(string: "https://github.com/ShivkumarChougala/MARC/blob/main/LICENSE")!) {
                        MARCSettingsSupportRow(title: "License", icon: "chevron.left.forwardslash.chevron.right")
                    }.buttonStyle(.plain)
                }
        }
    }

    private func connectionLabel(_ server: ServerProfile) -> String {
        if store.selectedID == server.id && store.monitor.connecting {
            return "Connecting"
        }
        if store.monitor.server?.id == server.id && store.monitor.connected {
            return "Connected"
        }
        if store.selectedID == server.id && store.monitor.error != nil {
            return "Failed"
        }
        return "Offline"
    }

    private func selectAndConnect(_ server: ServerProfile) {
        guard !store.monitor.connecting else { return }
        connectionTask?.cancel()
        let request = UUID()
        connectionRequest = request
        connectionFeedback = nil

        if store.monitor.connected && store.monitor.server?.id == server.id {
            return
        }

        do {
            guard try MARCCredentials.readChecked(server.id) != nil else {
                store.selectedID = server.id
                connectingServer = server
                return
            }
        } catch {
            store.storageError = error.localizedDescription
            return
        }

        connectionTask = Task { @MainActor in
            defer {
                if connectionRequest == request { connectionTask = nil }
            }
            store.storageError = nil
            do {
                try await store.switchToSavedServer(server)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, connectionRequest == request,
                      store.monitor.automaticReconnectEnabled,
                      store.servers.contains(where: { $0.id == server.id }),
                      store.selectedID == server.id,
                      !(store.monitor.connected && store.monitor.server?.id == server.id) else { return }
                connectionFeedback = MARCConnectionIssue.message(error, login: nil)
            }
        }
    }

    private func stopConnectionRequest() {
        connectionRequest = UUID()
        connectionTask?.cancel()
        connectionTask = nil
        connectionFeedback = nil
    }
}


private struct MARCEditServerScreen: View {
    let store: ServerStore
    let server: ServerProfile

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var host = ""
    @State private var port = ""
    @State private var username = ""
    @State private var loginDraft = MARCLoginDraft()
    @State private var hostKey = ""
    @State private var trust = MARCHostTrust()
    @State private var loaded = false
    @State private var busy = false
    @State private var failure: String?
    @State private var requestTask: Task<Void, Never>?
    @State private var requestID = UUID()
    @Environment(\.scenePhase) private var scenePhase

    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (1...65535).contains(Int(port) ?? 0)
    }

    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue
    @State private var testMessage: String?

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    
                    dismiss()
                }
                .disabled(busy)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(p.raised, in: Capsule())

                Spacer(minLength: 8)
                Text("Edit Server")
                    .font(.system(size: 18, weight: .semibold))
                Spacer(minLength: 8)

                Button("Save", action: save)
                    .disabled(!valid || busy || !loaded)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(p.raised, in: Capsule())
            }
            .font(.system(size: 15))
            .tint(p.accent)
            .padding(16)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 0) {
                        inputRow("Name", hint: "Display Name", text: $name)
                        Divider().padding(.horizontal, 16)
                        inputRow("Host", hint: "IP or Domain", text: $host)
                        Divider().padding(.horizontal, 16)
                        inputRow("Port", hint: "22", text: $port)
                            .keyboardType(.numberPad)
                    }
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 22))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Authentication")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            inputRow("Username", hint: "Mac username", text: $username)
                            Divider().padding(.horizontal, 16)

                            MARCLoginFields(draft: $loginDraft)
                                .padding(16)
                        }
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 22))
                    }

                    Text("MARC remembers the fingerprint on first connection. Future connections are checked automatically; unexpected changes are blocked.")
                        .font(.system(size: 12)).foregroundStyle(p.muted)

                    Button(action: testConnection) {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if busy { ProgressView() }
                            else { Image(systemName: "arrow.right") }
                        }
                        .font(.system(size: 15))
                        .padding(16)
                        .frame(minHeight: 54)
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 22))
                    }
                    .buttonStyle(.plain)
                    .disabled(!valid || busy || !loaded)

                    if let testMessage {
                        Text(testMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 12)
                    }

                    Button(action: save) {
                        HStack {
                            Spacer()
                            if busy { ProgressView().tint(.white) }
                            Text(busy ? "Please wait…" : "Save changes")
                            Spacer()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(minHeight: 52)
                        .background(p.accent, in: RoundedRectangle(cornerRadius: 18))
                        .foregroundStyle(.white)
                    }
                    .disabled(!valid || busy || !loaded)

                    Text("Your saved login is loaded automatically. Changes are checked before saving.")
                        .font(.system(size: 11))
                        .foregroundStyle(p.muted)
                        .padding(.horizontal, 12)

                }
                .padding(16)
                .padding(.bottom, 24)
                .disabled(busy)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .marcCanvas()
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(busy)
        .onAppear {
            guard !loaded else { return }
            name = server.name
            host = server.host
            port = String(server.port)
            username = server.username
            do {
                let saved = try MARCCredentials.readChecked(server.id)
                hostKey = saved?.hostKey ?? ""
                loginDraft = MARCLoginDraft(saved: saved)
                loaded = true
            } catch { failure = error.localizedDescription }
        }
        .hostTrustPrompt(trust)
        .marcConnectionAlert($failure)
        .onDisappear { stopRequest(); loginDraft.clear() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { stopRequest() }
        }
    }

    private func inputRow(
        _ title: String, hint: String, text: Binding<String>
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
            TextField(hint, text: text)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)
        }
        .font(.system(size: 15))
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
    }

    private func existingKey(host: String, port: Int) -> String {
        guard HostKeyIdentity.endpoint(host: host, port: port) ==
                HostKeyIdentity.endpoint(host: server.host, port: server.port) else { return "" }
        return hostKey
    }

    private func testConnection() {
        guard valid, let number = Int(port), !busy else { return }
        let server = ServerProfile(
            id: self.server.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            host: host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: number,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            requiresHostKey: self.server.requiresHostKey
        )
        let remembered: MARCCredentials.Saved?
        do { remembered = try MARCCredentials.readChecked(server.id) }
        catch { failure = error.localizedDescription; return }
        let submittedLogin = loginDraft.credentials(fallback: remembered)
        let submittedKey = existingKey(host: server.host, port: server.port)
        busy = true
        failure = nil
        testMessage = nil

        let request = UUID()
        requestID = request
        requestTask = Task { @MainActor in
            defer { if requestID == request { busy = false; requestTask = nil } }
            do {
                try Task.checkCancellation()
                guard requestID == request else { throw CancellationError() }
                let verifiedKey = try await trust.keyForConnection(server: server, existingKey: submittedKey)
                try Task.checkCancellation()
                guard requestID == request else { throw CancellationError() }
                _ = try await SSHConnectionTest.run(
                    server: server,
                    login: submittedLogin,
                    publicHostKey: verifiedKey
                )
                try Task.checkCancellation()
                guard requestID == request else { return }
                testMessage = "Connection successful. Ready to save."
            } catch is CancellationError {
                if requestID == request { failure = nil }
            } catch {
                guard requestID == request, !Task.isCancelled else { return }
                failure = MARCConnectionIssue.message(error, login: submittedLogin)
            }
        }
    }

    private func save() {
        guard valid, let number = Int(port), !busy else { return }
        guard !store.monitor.connecting else {
            failure = "Wait for the current connection to finish."
            return
        }

        guard store.servers.contains(self.server) else {
            failure = "This saved server changed. Close and reopen Edit Server."
            return
        }
        let remembered: MARCCredentials.Saved?
        do { remembered = try MARCCredentials.readChecked(server.id) }
        catch { failure = error.localizedDescription; return }
        let chosenLogin = loginDraft.credentials(fallback: remembered)
        guard chosenLogin.hasLogin else {
            failure = "Enter a password or select a saved SSH key."
            return
        }

        var updated = server
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.host = host.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.port = number
        updated.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.requiresHostKey = true
        let key = existingKey(host: updated.host, port: updated.port)
        let endpoint = HostKeyIdentity.endpoint(host: updated.host, port: updated.port)
        guard !store.servers.contains(where: {
            $0.id != updated.id && $0.username == updated.username &&
            HostKeyIdentity.endpoint(host: $0.host, port: $0.port) == endpoint
        }) else {
            failure = "This Mac and username are already saved. Edit that saved login instead."
            return
        }
        let reconnect = store.monitor.connected && store.monitor.server?.id == server.id

        busy = true
        failure = nil
        let request = UUID()
        requestID = request
        requestTask = Task { @MainActor in
            defer { if requestID == request { busy = false; requestTask = nil } }
            do {
                try Task.checkCancellation()
                guard requestID == request else { throw CancellationError() }
                let verifiedKey = try await trust.keyForConnection(server: updated, existingKey: key)
                try Task.checkCancellation()
                guard requestID == request, store.servers.contains(self.server) else {
                    throw CancellationError()
                }
                _ = try SSHConnectionTest.hostKeyValidator(server: updated, publicHostKey: verifiedKey)
                if reconnect {
                    // Validate the edited connection before saving the profile.
                    try await store.monitor.connect(
                        server: updated,
                        login: chosenLogin,
                        hostKey: verifiedKey
                    )
                } else {
                    // Check the edited login before replacing its Keychain item.
                    _ = try await SSHConnectionTest.run(server: updated, login: chosenLogin, publicHostKey: verifiedKey)
                    try Task.checkCancellation()
                    guard requestID == request, store.servers.contains(self.server) else {
                        throw CancellationError()
                    }
                    try MARCCredentials.save(
                        server.id, login: chosenLogin, hostKey: verifiedKey
                    )
                }
                try Task.checkCancellation()
                guard requestID == request, store.servers.contains(self.server) else {
                    throw CancellationError()
                }
                store.update(updated)
                loginDraft.clear()
                dismiss()
            } catch is CancellationError {
                if requestID == request { failure = nil }
            } catch {
                guard requestID == request, !Task.isCancelled else { return }
                failure = MARCConnectionIssue.message(error, login: chosenLogin)
            }
        }
    }
    private func stopRequest() {
        requestID = UUID()
        requestTask?.cancel()
        requestTask = nil
        busy = false
        trust.cancel()
    }

}


private struct MARCRemoveServerSheet: View {
    let server: ServerProfile
    let store: ServerStore
    let remove: () -> Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 18) {
            Text("Remove server")
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: 5) {
                Text(server.name).fontWeight(.medium)
                Text("\(server.username)@\(server.host):\(server.port)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(p.muted)
            }
            Text("This removes the saved profile and login from MARC. The Mac and its files are unaffected.")
                .font(.system(size: 12))
                .foregroundStyle(p.muted)
            if let error = store.storageError {
                Text(error).font(.system(size: 12)).foregroundStyle(.red)
            }
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(p.raised, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(p.text)
                }
                Button {
                    if remove() { dismiss() }
                } label: {
                    Text("Remove")
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(
                            Color(marcHex: 0xd84350),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .foregroundStyle(.white)
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .marcCanvas()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

private enum MARCSettingsSection: String, CaseIterable, Identifiable {
    case servers, general, security, support, contribute, legal
    static let defaultOrder = "servers,general,security,support,contribute,legal"
    var id: String { rawValue }
    var alwaysVisible: Bool { self == .security || self == .legal }
    var title: String {
        switch self {
        case .servers: return "Saved servers"
        case .security: return "Security"
        case .general: return "General"
        case .support: return "Support"
        case .contribute: return "Ways to Help"
        case .legal: return "Legal"
        }
    }
    static func ordered(_ stored: String) -> [Self] {
        // Adopt the new default without overwriting a deliberately customized order.
        let legacyDefaults = ["servers,security,terminal,general,support", "servers,general,terminal,security,support",
                              "servers,general,terminal,security,support,contribute,legal"]
        let order = legacyDefaults.contains(stored) ? defaultOrder : stored
        var result: [Self] = []
        for raw in order.split(separator: ",") {
            if let item = Self(rawValue: String(raw)), !result.contains(item) {
                result.append(item)
            }
        }
        for item in allCases where !result.contains(item) { result.append(item) }
        return result
    }
}

private struct MARCSettingsCustomizeSheet: View {
    @Binding var order: String
    @Binding var hidden: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    private func shown(_ item: MARCSettingsSection) -> Binding<Bool> {
        Binding(get: {
            item.alwaysVisible || !hidden.split(separator: ",").contains(Substring(item.rawValue))
        }, set: { enabled in
            guard !item.alwaysVisible else { return }
            var values = Set(hidden.split(separator: ",").map(String.init))
            if enabled { values.remove(item.rawValue) }
            else { values.insert(item.rawValue) }
            hidden = values.sorted().joined(separator: ",")
        })
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        NavigationStack {
            List {
                Section {
                    ForEach(MARCSettingsSection.ordered(order)) { item in
                        Toggle(item.title, isOn: shown(item))
                            .tint(p.accent).disabled(item.alwaysVisible)
                    }.onMove { indices, destination in
                        var items = MARCSettingsSection.ordered(order)
                        items.move(fromOffsets: indices, toOffset: destination)
                        order = items.map(\.rawValue).joined(separator: ",")
                    }
                } header: { Text("Settings sections") }
                  footer: {
                    Text("Drag to reorder. Add server, Security and Legal stay available. Hiding a section does not change its settings.")
                }
                Section {
                    Button("Reset layout") {
                        order = MARCSettingsSection.defaultOrder
                        hidden = ""
                    }.foregroundStyle(p.accent)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                .marcToolbarBackgroundHidden()
            }.tint(p.accent)
        }
    }
}

/// Support destinations are opened only after the user chooses a row.
private struct MARCHelpFeedbackScreen: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            MARCSettingsGroup(title: "Get in touch") {
                supportLink("Email support", subtitle: "contact@getmarc.app", icon: "envelope",
                    destination: URL(string: "mailto:contact@getmarc.app?subject=MARC%20support")!)
                MARCSettingsDivider()
                supportLink("Report a bug", subtitle: "Open an issue on GitHub", icon: "ladybug",
                    destination: URL(string: "https://github.com/ShivkumarChougala/MARC/issues/new?title=Bug%20report")!)
                MARCSettingsDivider()
                supportLink("Request a feature", subtitle: "Share an idea on GitHub", icon: "lightbulb",
                    destination: URL(string: "https://github.com/ShivkumarChougala/MARC/issues/new?title=Feature%20request")!)
            }
            .padding(.horizontal, 16).padding(.top, 28).padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .marcCanvas()
        .marcNavigationTitle("Help & feedback")
    }

    private func supportLink(_ title: String, subtitle: String, icon: String, destination: URL) -> some View {
        let p = MARCPalette(dark: scheme == .dark)
        return Link(destination: destination) {
            HStack(spacing: 14) {
                MARCSettingsRowIcon(symbol: icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.body).foregroundStyle(p.text)
                    Text(subtitle).font(.footnote).foregroundStyle(p.muted)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13)).foregroundStyle(p.muted)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
        }.buttonStyle(.plain)
    }
}

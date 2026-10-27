import SwiftUI
import UIKit
struct AddServerScreen: View {
    private enum EntryMode: String, CaseIterable { case nearby = "Nearby Macs", manual = "Manual" }
    let store: ServerStore
    var onConnected: () -> Void = {}
    @Environment(\.marcGuidedTour) private var setupTour
    @State private var setupHints = MARCSetupHintProgress()
    @State private var setupHelp: MARCSetupHelpTopic?
    private var setupHint: String? {
        guard setupTour?.active == true, setupTour?.stage == .connect else { return nil }
        return setupHints.target(manual: mode == .manual, selected: selectedNearby != nil,
            hasHost: !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasDevices: !discovery.devices.isEmpty, ready: valid)
    }
    private var setupHintTitle: String {
        switch setupHint {
        case "method": return "Find your Mac"
        case "scan": return "Nearby Macs"
        case "device": return "Choose your Mac"
        case "address": return "Your Mac’s address"
        case "connect": return "Make the connection"
        default: return "Your Mac account"
        }
    }
    private var setupHintMessage: String {
        switch setupHint {
        case "method": return "Choose a nearby Mac, or use Manual if you know its address."
        case "scan": return discovery.isSearching ? "Keep your Mac awake while we look nearby." : "No Mac yet? Tap Refresh, or use Manual."
        case "device": return "Choose your Mac from the nearby results."
        case "address": return "Enter your Mac’s IP address or hostname. Tap ? if you need help."
        case "connect": return "Tap Connect when your login is ready."
        default: return "Use your Mac username and password, or choose SSH key."
        }
    }
    @State private var mode: EntryMode = .nearby
    @State private var selectedNearby: NearbyMac?
    @State private var existingNearby: NearbyMac?
    @State private var nearbyChoice: ServerProfile?
    @State private var anotherLogin: NearbyMac?
    @State private var existingServer: ServerProfile?
    @State private var usingSavedID: UUID?
    @State private var trustedEndpoints: Set<String> = []
    @Environment(\.scenePhase) private var scenePhase
    @State private var discovery = BonjourDiscoveryService()
    @State private var hasStartedScan = false
    @State private var trust = MARCHostTrust()
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var loginDraft = MARCLoginDraft()
    @State private var busy = false
    @State private var failure: String?
    @State private var pending: ServerProfile?
    @State private var requestTask: Task<Void, Never>?
    @State private var requestID = UUID()

    private var matchingLogin: ServerProfile? {
        guard let number = Int(port), (1...65535).contains(number) else {
            return nil
        }
        let endpoint = HostKeyIdentity.endpoint(
            host: host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: number
        )
        let user = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !user.isEmpty else { return nil }
        return store.servers.first {
            HostKeyIdentity.endpoint(host: $0.host, port: $0.port) == endpoint
                && $0.username == user
        }
    }

    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        loginDraft.hasLogin &&
        (1...65535).contains(Int(port) ?? 0)
    }


    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var dynamicType
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue
    @State private var testMessage: String?

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    if let pending, !store.remove(pending) {
                        failure = store.storageError
                        return
                    }
                    dismiss()
                }
                .disabled(busy).frame(minHeight: 44)
                Spacer(minLength: 8)
                if !dynamicType.isAccessibilitySize { Text("Add a Mac").font(.headline) }
                Spacer(minLength: 8)
                if !dynamicType.isAccessibilitySize { Text("Cancel").hidden().accessibilityHidden(true) }
            }
            .font(.subheadline).tint(p.accent)
            .padding(.horizontal, 20).padding(.vertical, 4)

            if dynamicType.isAccessibilitySize {
                Text("Add a Mac").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Connection method", selection: $mode) {
                        ForEach(EntryMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).marcSetupTarget("method")
                    .simultaneousGesture(TapGesture().onEnded { setupHints.review("method") })
                    if mode == .nearby { nearbyMacs }
                    if mode == .manual || selectedNearby != nil {
                    if mode == .manual {
                        VStack(spacing: 0) {
                            inputRow("Name", hint: "Display name", text: $name)
                            Divider().padding(.horizontal, 16)
                            inputRow("Host", hint: "IP or hostname", text: $host, help: .address)
                                .marcSetupTarget("address")
                            Divider().padding(.horizontal, 16)
                            inputRow("Port", hint: "22", text: $port)
                                .keyboardType(.numberPad)
                        }
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 14))
                        .marcSetupTarget("manualForm")
                    }

                    if let matchingLogin {
                        Text("Already saved as \(matchingLogin.username). Use the saved login below, or enter a different username to add another login.")
                            .font(.system(size: 12)).foregroundStyle(p.muted)
                    } else if let selectedNearby, !savedProfiles(for: selectedNearby).isEmpty {
                        Text("Adding another login for this Mac. Enter a different username; existing logins stay saved.")
                            .font(.system(size: 12)).foregroundStyle(p.muted)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                Text("Login").foregroundStyle(p.muted)
                                Spacer(minLength: 12)
                                MARCLoginMethodMenu(method: $loginDraft.method)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Login").foregroundStyle(p.muted)
                                MARCLoginMethodMenu(method: $loginDraft.method)
                            }
                        }
                        .font(.subheadline).padding(.horizontal, 4)
                        VStack(alignment: .leading, spacing: 0) {
                            MARCSetupTextField(title: "Username", hint: "Mac username", text: $username,
                                help: { setupHelp = .username })
                                .textContentType(.username)
                            Divider()
                            MARCLoginFields(draft: $loginDraft, quiet: true)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 4)
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .marcSetupTarget("login")

                    Button(action: testConnection) {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if busy { ProgressView() }
                            else { Image(systemName: "arrow.right") }
                        }
                        .font(.subheadline).foregroundStyle(p.muted)
                        .padding(.horizontal, 4).frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(!valid || busy)
                    .marcSetupTarget("test")

                    if let testMessage {
                        Text(testMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 12)
                    }


                    }
                }
                .padding(16)
                .padding(.bottom, 24)
                .disabled(busy)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if mode == .manual || selectedNearby != nil { connectionFooter }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .marcCanvas()
        .marcGuidePresentationBarrier()
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(busy || pending != nil)
        .onAppear {
            refreshNearbyTrust()
            if !hasStartedScan { hasStartedScan = true; discovery.start() }
        }
        .onChange(of: mode) { _, newMode in
            setupHints = MARCSetupHintProgress()
            if newMode == .nearby { setupHints.review("method") }
            if setupTour?.active == true && scenePhase == .active {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            discovery.stop()
            selectedNearby = nil
            name = ""; host = ""; port = "22"; loginDraft.clear()
            failure = nil; testMessage = nil
            if newMode == .nearby { discovery.start() }
        }
        .marcSetupCoach(target: setupHint, title: setupHintTitle, message: setupHintMessage,
            enabled: !busy && trust.request == nil && existingNearby == nil && existingServer == nil && failure == nil && setupHelp == nil,
            next: {
                if let setupHint {
                    setupHints.review(setupHint)
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }, skip: { setupTour?.skip() },
            back: setupHints.canGoBack ? { setupHints.back() } : nil)
        .sheet(item: $setupHelp) { topic in
            MARCSetupHelpSheet(topic: topic).marcGuidePresentationBarrier()
        }
        .hostTrustPrompt(trust)
        .marcConnectionAlert($failure)
        .onChange(of: failure) { old, message in
            guard setupTour?.active == true, setupTour?.stage == .connect,
                  scenePhase == .active, message != nil, message != old else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        .onChange(of: selectedNearby?.id) { _, _ in setupHints.restartLogin() }
        .onChange(of: trust.request?.id) { _, id in
            if id == nil { refreshNearbyTrust() }
        }
        .sheet(item: $existingNearby, onDismiss: {
            let chosen = nearbyChoice
            let device = anotherLogin
            nearbyChoice = nil; anotherLogin = nil
            if let chosen { openSaved(chosen) }
            else if let device { selectNearby(device) }
        }) { device in
            MARCSavedLoginsSheet(
                device: device, servers: savedProfiles(for: device),
                choose: { nearbyChoice = $0; existingNearby = nil },
                add: { anotherLogin = device; existingNearby = nil }
            )
        }
        .sheet(item: $existingServer, onDismiss: {
            if let id = usingSavedID, store.monitor.connected, store.monitor.server?.id == id {
                onConnected()
                dismiss()
            }
            usingSavedID = nil
        }) { server in
            SSHConnectScreen(server: server, monitor: store.monitor)
        }
        .onDisappear { stopRequest(); loginDraft.clear(); discovery.stop(clearResults: true) }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { discovery.stop(); stopRequest() }
        }
    }

    private var connectionFooter: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return Group {
            if dynamicType.isAccessibilitySize {
                VStack(alignment: .trailing, spacing: 4) {
                    connectAction
                    Label("Connect over SSH", systemImage: "lock")
                        .font(.caption).foregroundStyle(p.muted)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                HStack(spacing: 16) {
                    Label("Connect over SSH", systemImage: "lock")
                        .font(.caption).foregroundStyle(p.muted)
                    Spacer(minLength: 8)
                    connectAction
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(p.background)
        .overlay(alignment: .top) { Divider().padding(.horizontal, 20) }
    }

    private var connectAction: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return Button(action: saveAndConnect) {
            HStack(spacing: 8) {
                if busy { ProgressView().tint(.white) }
                Text(busy ? "Please wait…" : "Connect")
                if !busy { Image(systemName: "arrow.right") }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 20).frame(minHeight: 44)
            .background(p.accent, in: Capsule()).foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled((!valid && matchingLogin == nil) || busy)
        .opacity(!valid && matchingLogin == nil ? 0.45 : 1)
        .accessibilityHint(matchingLogin == nil ? "Save this Mac and connect using the entered login" : "Connect using the saved login")
        .marcSetupTarget("connect")
    }

    private var nearbyMacs: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedNearby == nil ? "Nearby Macs" : "Selected Mac").font(.subheadline.weight(.medium))
                Spacer()
                if selectedNearby != nil {
                    Button("Change Mac") {
                        selectedNearby = nil
                        name = ""; host = ""; port = "22"; loginDraft.clear()
                        failure = nil; testMessage = nil
                    }
                    .font(.system(size: 12)).tint(p.accent)
                    .frame(minHeight: 44)
                } else {
                    if discovery.isSearching { ProgressView().controlSize(.small) }
                    Button(discovery.isSearching ? "Stop" : "Refresh") {
                        if discovery.isSearching { discovery.stop() }
                        else { discovery.start() }
                    }
                    .font(.system(size: 12)).tint(p.accent)
                    .frame(minHeight: 44)
                }
            }
            .marcSetupTarget("scan")
            if selectedNearby == nil {
                Text("Choose a Mac to continue. Enable Remote Login on your Mac to make it discoverable. Other SSH devices may also appear.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
            }
            if let failure = discovery.failure {
                Text(failure).font(.system(size: 12)).foregroundStyle(p.muted)
            }
            if selectedNearby == nil && !discovery.isSearching && !discovery.devices.isEmpty {
                Text("Results from the last scan · Refresh to update")
                    .font(.system(size: 11)).foregroundStyle(p.muted)
            }
            if discovery.devices.isEmpty {
                Text(discovery.isSearching ? "Looking for nearby Macs…" : "No nearby Macs found.")
                    .font(.system(size: 13)).foregroundStyle(p.muted)
                if !discovery.isSearching && selectedNearby == nil {
                    Text("Can’t find your Mac?").font(.subheadline.weight(.medium))
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) { emptyScanActions }
                        VStack(alignment: .leading, spacing: 0) { emptyScanActions }
                    }
                    .font(.caption).tint(p.accent).buttonStyle(.borderless)
                }
            }
            ForEach(selectedNearby.map { [$0] } ?? discovery.devices) { device in
                let saved = !savedProfiles(for: device).isEmpty
                let trusted = trustedEndpoints.contains(HostKeyIdentity.endpoint(host: device.host, port: device.port))
                Button {
                    if setupTour?.active == true && scenePhase == .active {
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                    if saved { discovery.stop(); existingNearby = device }
                    else { selectNearby(device) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "laptopcomputer").foregroundStyle(p.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.name).font(.system(size: 14, weight: .medium))
                            if saved || trusted {
                                Text(saved ? "Saved" : "Trusted · add a login")
                                    .font(.system(size: 10, weight: .medium)).foregroundStyle(p.accent)
                            }
                            Text("\(device.host) · Port \(device.port)")
                                .font(.system(size: 11)).foregroundStyle(p.muted)
                        }
                        Spacer()
                        Image(systemName: selectedNearby?.id == device.id ? "checkmark.circle.fill" : "chevron.right").foregroundStyle(p.accent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(selectedNearby?.id == device.id)
                .marcSetupTarget("device", enabled: selectedNearby == nil && discovery.devices.first?.id == device.id)
                .accessibilityLabel("\(selectedNearby?.id == device.id ? "Selected" : "Choose") \(device.name), \(device.host), port \(device.port)")
            }
        }
        .padding(16)
        .background(p.surface, in: RoundedRectangle(cornerRadius: 22))
        .marcSetupTarget("nearbyPanel")
    }

    @ViewBuilder private var emptyScanActions: some View {
        Button("Check Mac setup") { setupHelp = .remoteLogin }.frame(minHeight: 44)
        Button("Enter address manually") { mode = .manual }.frame(minHeight: 44)
    }

    private func refreshNearbyTrust() {
        trustedEndpoints = Set((try? MARCHostTrustStore.entries())?.map(\.endpoint) ?? [])
    }

    private func savedProfiles(for device: NearbyMac) -> [ServerProfile] {
        let endpoint = HostKeyIdentity.endpoint(host: device.host, port: device.port)
        return store.servers.filter {
            HostKeyIdentity.endpoint(host: $0.host, port: $0.port) == endpoint
        }
    }

    private func selectNearby(_ device: NearbyMac) {
        existingNearby = nil
        selectedNearby = device
        name = device.name; host = device.host; port = String(device.port)
        username = ""
        loginDraft.clear()
        discovery.stop()
        failure = nil; testMessage = nil
    }

    private func openSaved(_ server: ServerProfile) {
        existingNearby = nil
        discovery.stop()
        loginDraft.clear()
        store.selectedID = server.id
        if store.monitor.connected && store.monitor.server?.id == server.id {
            onConnected()
            dismiss()
        } else {
            usingSavedID = server.id
            existingServer = server
        }
    }

    private func inputRow(
        _ title: String, hint: String, text: Binding<String>, help: MARCSetupHelpTopic? = nil
    ) -> some View {
        MARCSetupTextField(title: title, hint: hint, text: text,
            help: help.map { topic in { setupHelp = topic } })
            .padding(.horizontal, 16).padding(.vertical, 2)
    }

    private func testConnection() {
        guard valid, let number = Int(port), !busy else { return }
        let server = ServerProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            host: host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: number,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            requiresHostKey: true
        )
        let submittedLogin = loginDraft.credentials()
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
                let verifiedKey = try await trust.keyForConnection(server: server)
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

    private func saveAndConnect() {
        guard !busy, let number = Int(port),
              (1...65535).contains(number) else { return }
        let endpoint = HostKeyIdentity.endpoint(host: host.trimmingCharacters(in: .whitespacesAndNewlines), port: number)
        let user = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if let saved = store.servers.first(where: {
            HostKeyIdentity.endpoint(host: $0.host, port: $0.port) == endpoint && $0.username == user
        }) {
            openSaved(saved)
            return
        }
        guard valid else { return }
        let profile = ServerProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            host: host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: number,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            requiresHostKey: true
        )
        if let pending {
            guard store.remove(pending) else { failure = store.storageError; return }
            self.pending = nil
        }
        busy = true
        failure = nil
        let submittedLogin = loginDraft.credentials()

        let request = UUID()
        requestID = request
        requestTask = Task { @MainActor in
            defer { if requestID == request { busy = false; requestTask = nil } }
            do {
                try Task.checkCancellation()
                guard requestID == request else { throw CancellationError() }
                let verifiedKey = try await trust.keyForConnection(server: profile)
                try Task.checkCancellation()
                guard requestID == request else { throw CancellationError() }
                pending = profile
                try await store.monitor.connect(
                    server: profile,
                    login: submittedLogin,
                    hostKey: verifiedKey
                )
                store.add(profile)
                try Task.checkCancellation()
                guard requestID == request else { throw CancellationError() }
                pending = nil
                loginDraft.clear()
                onConnected()
                dismiss()
            } catch is CancellationError {
                if requestID == request { failure = nil }
                if pending?.id == profile.id, store.remove(profile) { pending = nil }
            } catch {
                guard requestID == request, !Task.isCancelled else { return }
                failure = MARCConnectionIssue.message(error, login: submittedLogin)
                if pending?.id == profile.id, store.remove(profile) { pending = nil }
            }
        }
    }
    private func stopRequest() {
        requestID = UUID()
        requestTask?.cancel()
        requestTask = nil
        busy = false
        trust.cancel()
        if let pending, store.remove(pending) { self.pending = nil }
    }

}

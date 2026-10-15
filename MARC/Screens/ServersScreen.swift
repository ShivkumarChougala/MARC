import SwiftUI
struct AddServerScreen: View {
    private enum EntryMode: String, CaseIterable { case nearby = "Nearby Macs", manual = "Manual" }
    let store: ServerStore
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
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
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
                .disabled(busy)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(p.raised, in: Capsule())

                Spacer(minLength: 8)
                Text("Add Server")
                    .font(.system(size: 18, weight: .semibold))
                Spacer(minLength: 8)

                Button(matchingLogin == nil ? "Add" : "Connect", action: saveAndConnect)
                    .disabled((!valid && matchingLogin == nil) || busy)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(p.raised, in: Capsule())
            }
            .font(.system(size: 15))
            .tint(p.accent)
            .padding(16)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Picker("Connection method", selection: $mode) {
                        ForEach(EntryMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    if mode == .nearby { nearbyMacs }
                    if mode == .manual || selectedNearby != nil {
                    VStack(spacing: 0) {
                        inputRow("Name", hint: "Display Name", text: $name)
                        Divider().padding(.horizontal, 16)
                        if mode == .manual {
                            inputRow("Host", hint: "IP or Domain", text: $host)
                            Divider().padding(.horizontal, 16)
                            inputRow("Port", hint: "22", text: $port)
                                .keyboardType(.numberPad)
                        } else {
                            Text("\(host):\(port)")
                                .font(.system(size: 12)).foregroundStyle(p.muted)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                        }
                    }
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 22))

                    if let matchingLogin {
                        Text("Already saved as \(matchingLogin.username). Use the saved login below, or enter a different username to add another login.")
                            .font(.system(size: 12)).foregroundStyle(p.muted)
                    } else if let selectedNearby, !savedProfiles(for: selectedNearby).isEmpty {
                        Text("Adding another login for this Mac. Enter a different username; existing logins stay saved.")
                            .font(.system(size: 12)).foregroundStyle(p.muted)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Login")
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
                    .disabled(!valid || busy)

                    if let testMessage {
                        Text(testMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 12)
                    }

                    Button(action: saveAndConnect) {
                        HStack {
                            Spacer()
                            if busy { ProgressView().tint(.white) }
                            Text(busy ? "Please wait…" : matchingLogin == nil ? "Save & connect" : "Use saved login")
                            Spacer()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(minHeight: 52)
                        .background(p.accent, in: RoundedRectangle(cornerRadius: 18))
                        .foregroundStyle(.white)
                    }
                    .disabled((!valid && matchingLogin == nil) || busy)

                    Text("Your login and this Mac’s fingerprint are stored securely on this iPhone.")
                        .font(.system(size: 11))
                        .foregroundStyle(p.muted)
                        .padding(.horizontal, 12)

                    }
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
        .interactiveDismissDisabled(busy || pending != nil)
        .onAppear {
            refreshNearbyTrust()
            if !hasStartedScan { hasStartedScan = true; discovery.start() }
        }
        .onChange(of: mode) { _, newMode in
            discovery.stop()
            selectedNearby = nil
            name = ""; host = ""; port = "22"; loginDraft.clear()
            failure = nil; testMessage = nil
            if newMode == .nearby { discovery.start() }
        }
        .hostTrustPrompt(trust)
        .marcConnectionAlert($failure)
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

    private var nearbyMacs: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nearby Macs").font(.system(size: 14, weight: .semibold))
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
            }
            ForEach(selectedNearby.map { [$0] } ?? discovery.devices) { device in
                let saved = !savedProfiles(for: device).isEmpty
                let trusted = trustedEndpoints.contains(HostKeyIdentity.endpoint(host: device.host, port: device.port))
                Button {
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
                            Text("\(device.host):\(device.port)")
                                .font(.system(size: 11)).foregroundStyle(p.muted)
                        }
                        Spacer()
                        Image(systemName: selectedNearby?.id == device.id ? "checkmark.circle.fill" : (saved ? "chevron.right" : "plus.circle")).foregroundStyle(p.accent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(selectedNearby?.id == device.id)
                .accessibilityLabel("\(selectedNearby?.id == device.id ? "Selected" : "Choose") \(device.name), \(device.host), port \(device.port)")
            }
        }
        .padding(16)
        .background(p.surface, in: RoundedRectangle(cornerRadius: 22))
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
            dismiss()
        } else {
            usingSavedID = server.id
            existingServer = server
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
                store.add(profile)
                try await store.monitor.connect(
                    server: profile,
                    login: submittedLogin,
                    hostKey: verifiedKey
                )
                try Task.checkCancellation()
                guard requestID == request else { throw CancellationError() }
                pending = nil
                loginDraft.clear()
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

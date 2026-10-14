import SwiftUI

struct MARCKeychainScreen: View {
    private enum Section: String, CaseIterable {
        case keys = "SSH Keys", fingerprints = "Mac Fingerprints"
    }
    @State private var section: Section = .keys
    let store: ServerStore
    @Environment(\.colorScheme) private var scheme
    @State private var entries: [Entry] = []
    @State private var failure: String?
    @State private var forgetting: Entry?

    private struct Login: Identifiable {
        let id: UUID
        let username: String
        let loginSummary: String
    }

    private struct Entry: Identifiable {
        let id: String
        var name: String
        var logins: [Login] = []
        var fingerprint: String?
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(spacing: 0) {
            Picker("Keychain section", selection: $section) {
                ForEach(Section.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.vertical, 12)
            ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if section == .keys {
                    MARCSSHKeysSection(servers: store.servers)
                } else {
                if let failure {
                    Text(failure).font(.system(size: 12)).foregroundStyle(.red)
                    Button("Try again", action: reload).tint(p.accent)
                }
                if entries.isEmpty && failure == nil {
                    Text("No Macs saved yet. Connect to a Mac to remember its fingerprint.")
                        .font(.system(size: 13)).foregroundStyle(p.muted)
                        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 18))
                }
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(entry.name).font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(p.text)
                        Text(entry.id).font(.system(size: 12)).foregroundStyle(p.muted)
                            .textSelection(.enabled)
                        ForEach(entry.logins) { login in
                            HStack(alignment: .top, spacing: 12) {
                                Text(login.username).textSelection(.enabled)
                                Spacer(minLength: 8)
                                Text(login.loginSummary)
                                    .multilineTextAlignment(.trailing)
                            }.font(.system(size: 12)).foregroundStyle(p.muted)
                        }
                        if entry.logins.isEmpty {
                            Text("No saved login").font(.system(size: 12)).foregroundStyle(p.muted)
                            Button("Forget Mac", role: .destructive) { forgetting = entry }
                                .font(.system(size: 13)).frame(minHeight: 44)
                        }
                        if let fingerprint = entry.fingerprint {
                            Divider()
                            DisclosureGroup("Fingerprint") {
                                Text(fingerprint)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(p.text).textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }.font(.system(size: 13)).tint(p.accent)
                        } else {
                            Text("The fingerprint is saved on first connection.")
                                .font(.system(size: 11)).foregroundStyle(p.muted)
                        }
                    }
                    .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 18))
                }
                }
            }.padding(16)
            }
        }
        .marcCanvas()
        .navigationTitle("Keychain")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
        .onChange(of: section) { _, _ in reload() }
        .onChange(of: store.servers) { _, _ in reload() }
        .alert("Forget this Mac?", isPresented: Binding(
            get: { forgetting != nil },
            set: { if !$0 { forgetting = nil } }
        )) {
            Button("Cancel", role: .cancel) { forgetting = nil }
            Button("Forget Mac", role: .destructive) {
                if let entry = forgetting { forget(entry) }
                forgetting = nil
            }
        } message: {
            Text("Remove the remembered fingerprint for \(forgetting?.id ?? "this Mac")? A future connection will remember a new fingerprint.")
        }
    }

    private func forget(_ entry: Entry) {
        guard !store.servers.contains(where: {
            HostKeyIdentity.endpoint(host: $0.host, port: $0.port) == entry.id
        }) else {
            failure = "Remove this Mac’s saved servers before forgetting its fingerprint."
            return
        }
        if let server = store.monitor.server,
           HostKeyIdentity.endpoint(host: server.host, port: server.port) == entry.id,
           store.monitor.connected || store.monitor.connecting {
            failure = "Wait for this Mac to disconnect, then try again."
            return
        }
        do {
            try MARCHostTrustStore.forget(endpoint: entry.id)
            reload()
        } catch { failure = error.localizedDescription }
    }

    private func reload() {
        failure = nil
        do { try MARCSSHKeyStore.migrate(store.servers) }
        catch { failure = error.localizedDescription }
        var result: [String: Entry] = [:]
        do {
            for host in try MARCHostTrustStore.entries() {
                result[host.endpoint] = Entry(
                    id: host.endpoint, name: host.endpoint,
                    fingerprint: try? HostKeyIdentity.fingerprint(publicKey: host.publicKey)
                )
            }
        } catch { failure = error.localizedDescription }
        for server in store.servers {
            let endpoint = HostKeyIdentity.endpoint(host: server.host, port: server.port)
            let saved = MARCCredentials.read(server.id)
            var entry = result[endpoint] ?? Entry(id: endpoint, name: server.name)
            if entry.logins.isEmpty { entry.name = server.name }
            entry.logins.append(Login(id: server.id, username: server.username,
                                      loginSummary: saved?.hasLogin == true ? (saved?.isKeyLogin == true ? MARCSSHKeyStore.loginName(saved) : "Password saved") : "No saved login"))
            if entry.fingerprint == nil, let key = saved?.hostKey {
                entry.fingerprint = try? HostKeyIdentity.fingerprint(publicKey: key)
            }
            result[endpoint] = entry
        }
        entries = result.values.sorted {
            let order = $0.name.localizedCaseInsensitiveCompare($1.name)
            return order == .orderedSame ? $0.id < $1.id : order == .orderedAscending
        }
    }
}

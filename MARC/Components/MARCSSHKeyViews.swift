import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct MARCSSHKeysSection: View {
    let servers: [ServerProfile]
    @State private var keys: [MARCSSHKeyStore.Info] = []
    @State private var importing = false
    @State private var editing: MARCSSHKeyStore.Info?
    @State private var removing: MARCSSHKeyStore.Info?
    @State private var removalAfterDismiss: MARCSSHKeyStore.Info?
    @State private var failure: String?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SSH Keys").font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("Add key") { importing = true }
                    .font(.system(size: 13)).tint(p.accent).frame(minHeight: 44)
            }
            if keys.isEmpty {
                Text("Import a key once, give it a name, then select it when adding a server.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
            }
            ForEach(keys) { key in
                HStack(spacing: 12) {
                    Button { editing = key } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(key.name).font(.system(size: 14, weight: .medium))
                                .foregroundStyle(p.text)
                            let count = try? MARCSSHKeyStore.users(key.id, servers: servers)
                            Text(count.map {
                                $0 == 0 ? "Ed25519 · ready to use"
                                    : "Ed25519 · used by \($0) login(s)"
                            } ?? "Usage unavailable")
                                .font(.system(size: 11)).foregroundStyle(p.muted)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain)

                    Button { UIPasteboard.general.string = key.publicKey } label: {
                        Image(systemName: "doc.on.doc").frame(width: 44, height: 44)
                    }
                    .tint(p.accent)
                    .accessibilityLabel("Copy public key for \(key.name)")
                }
            }
            if let failure {
                Text(failure).font(.system(size: 12)).foregroundStyle(p.muted)
            }
        }
        .padding(18).background(p.surface, in: RoundedRectangle(cornerRadius: 18))
        .onAppear(perform: reload)
        .onChange(of: servers) { _, _ in reload() }
        .sheet(isPresented: $importing, onDismiss: reload) {
            MARCSSHKeyImportSheet()
        }
        .sheet(item: $editing, onDismiss: {
            reload()
            removing = removalAfterDismiss
            removalAfterDismiss = nil
        }) { key in
            MARCSSHKeyNameSheet(
                key: key,
                used: (try? MARCSSHKeyStore.users(key.id, servers: servers)) != 0,
                remove: { removalAfterDismiss = key }
            )
        }
        .alert("Remove SSH key?", isPresented: Binding(
            get: { removing != nil },
            set: { if !$0 { removing = nil } }
        )) {
            Button("Cancel", role: .cancel) { removing = nil }
            Button("Remove", role: .destructive) {
                do {
                    if let key = removing {
                        try MARCSSHKeyStore.remove(key.id, servers: servers)
                    }
                    removing = nil
                    reload()
                } catch {
                    failure = error.localizedDescription
                    removing = nil
                }
            }
        } message: {
            Text("Remove this key from this iPhone’s Keychain? This does not remove its public key from any Mac.")
        }
    }

    private func reload() {
        do {
            try MARCSSHKeyStore.migrate(servers)
            keys = try MARCSSHKeyStore.entries()
            failure = nil
        } catch { failure = error.localizedDescription }
    }
}

struct MARCSSHKeyPicker: View {
    let selected: UUID?
    let choose: (MARCSSHKeyStore.Info) -> Void
    @State private var keys: [MARCSSHKeyStore.Info] = []
    @State private var failure: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Choose SSH key").font(.system(size: 20, weight: .semibold))
                    Spacer()
                    Button("Done") { dismiss() }.tint(p.accent).frame(minHeight: 44)
                }
                ForEach(keys) { key in
                    Button { choose(key) } label: {
                        HStack {
                            Text(key.name).font(.system(size: 15, weight: .medium))
                            Spacer()
                            if selected == key.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(p.accent)
                            }
                        }
                        .foregroundStyle(p.text).padding(16)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }
                Text(keys.isEmpty
                     ? "No SSH keys saved. Add one in Settings → Keychain first."
                     : "Manage these keys in Settings → Keychain.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
                if let failure {
                    Text(failure).font(.system(size: 12)).foregroundStyle(p.muted)
                }
            }.padding(20)
        }
        .marcCanvas().presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            do { keys = try MARCSSHKeyStore.entries() }
            catch { failure = error.localizedDescription }
        }
    }
}

private struct MARCSSHKeyImportSheet: View {
    @State private var name = ""
    @State private var privateKey = ""
    @State private var passphrase = ""
    @State private var importing = false
    @State private var failure: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Add SSH key").font(.system(size: 20, weight: .semibold))
                    Spacer()
                    Button("Cancel") { dismiss() }.tint(p.accent).frame(minHeight: 44)
                }
                TextField("Key name · e.g. Personal Mac", text: $name)
                    .padding(14)
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 12))
                Button(privateKey.isEmpty
                       ? "Import private key" : "Replace imported key") {
                    importing = true
                }.frame(minHeight: 44).tint(p.accent)
                if !privateKey.isEmpty {
                    Text("Private key loaded")
                        .font(.system(size: 12)).foregroundStyle(p.muted)
                }
                SecureField("Key passphrase · optional", text: $passphrase)
                    .padding(14)
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 12))
                Text("OpenSSH Ed25519 keys. The key and its passphrase stay in this iPhone’s Keychain. Only the public key can be copied.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
                Button("Save key") {
                    do {
                        _ = try MARCSSHKeyStore.add(
                            name: name, privateKey: privateKey,
                            passphrase: passphrase
                        )
                        dismiss()
                    } catch { failure = error.localizedDescription }
                }
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(.white)
                .background(p.accent, in: RoundedRectangle(cornerRadius: 14))
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || privateKey.isEmpty)
                if let failure {
                    Text(failure).font(.system(size: 12)).foregroundStyle(p.muted)
                }
            }.padding(20)
        }
        .marcCanvas().textInputAutocapitalization(.never).autocorrectionDisabled()
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.data, .plainText],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let url = try result.get().first else { return }
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let file = try FileHandle(forReadingFrom: url)
                defer { try? file.close() }
                guard let data = try file.read(upToCount: 32769),
                      data.count <= 32768,
                      let text = String(data: data, encoding: .utf8),
                      text.contains("-----BEGIN OPENSSH PRIVATE KEY-----") else {
                    failure = "Choose an OpenSSH Ed25519 private key smaller than 32 KB."
                    return
                }
                privateKey = text
                passphrase = ""
                failure = nil
            } catch {
                failure = "Couldn’t import the key. Choose it again from Files."
            }
        }
        .onDisappear { privateKey = ""; passphrase = "" }
    }
}

private struct MARCSSHKeyNameSheet: View {
    let key: MARCSSHKeyStore.Info
    let used: Bool
    let remove: () -> Void
    @State private var name = ""
    @State private var failure: String?
    @State private var wantsRemoval = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Edit key name").font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }.frame(minHeight: 44)
            }
            TextField("Key name", text: $name).textFieldStyle(.roundedBorder)
            Button("Save name") {
                do {
                    try MARCSSHKeyStore.rename(key.id, name: name)
                    dismiss()
                } catch { failure = error.localizedDescription }
            }.frame(minHeight: 44)
            Button("Remove key", role: .destructive) {
                wantsRemoval = true
                dismiss()
            }.disabled(used).frame(minHeight: 44)
            if used {
                Text("This key is used by a saved login. Change or remove that login before deleting the key.")
                    .font(.caption)
            }
            if let failure { Text(failure).font(.caption) }
            Spacer()
        }
        .padding(24).marcCanvas().presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear { name = key.name }
        .onDisappear { if wantsRemoval { remove() } }
    }
}

struct MARCSavedLoginsSheet: View {
    let device: NearbyMac
    let servers: [ServerProfile]
    let choose: (ServerProfile) -> Void
    let add: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(device.name).font(.system(size: 20, weight: .semibold))
                    Spacer()
                    Button("Done") { dismiss() }.tint(p.accent).frame(minHeight: 44)
                }
                Text("Choose a saved login")
                    .font(.system(size: 13)).foregroundStyle(p.muted)
                ForEach(servers) { server in
                    Button { choose(server) } label: {
                        HStack {
                            Text(server.username)
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(p.text).padding(16)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }
                Button("Add another login", action: add)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(.white)
                    .background(p.accent, in: RoundedRectangle(cornerRadius: 14))
                Text("Use another Mac username. Your existing connections stay saved.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
            }.padding(20)
        }
        .marcCanvas().presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

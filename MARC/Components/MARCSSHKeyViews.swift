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
    @State private var usage: [UUID: Int] = [:]
    @State private var notice: String?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved keys").font(.system(size: 14, weight: .semibold))
                Spacer()
                Button { importing = true } label: {
                    Label("Add key", systemImage: "plus").font(.system(size: 12, weight: .medium)).frame(minHeight: 44)
                }.tint(p.accent)
            }
            if keys.isEmpty {
                Text("Import a key once, give it a name, then select it when adding a server.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
            }
            ForEach(keys) { key in
                Divider()
                HStack(spacing: 12) {
                    Image(systemName: "key.horizontal").font(.system(size: 15)).foregroundStyle(p.accent)
                    Button { editing = key } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(key.name).font(.system(size: 14, weight: .medium))
                                .foregroundStyle(p.text)
                            let count = usage[key.id]
                            Text(count.map {
                                $0 == 0 ? "Ed25519 · ready to use"
                                    : "Ed25519 · used by \($0) login(s)"
                            } ?? "Usage unavailable")
                                .font(.system(size: 11)).foregroundStyle(p.muted)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain)

                    Menu {
                        Button("Rename", systemImage: "pencil") { editing = key }
                        Button("Copy public key", systemImage: "doc.on.doc") {
                            UIPasteboard.general.string = key.publicKey
                            notice = "Public key copied."
                        }
                        Button("Remove key", systemImage: "trash", role: .destructive) { removing = key }
                            .disabled(usage[key.id] != 0)
                    } label: {
                        Image(systemName: "ellipsis").foregroundStyle(p.muted).frame(width: 44, height: 44)
                    }.accessibilityLabel("Actions for SSH key \(key.name)")
                }
            }
            if let failure {
                Text(failure).font(.system(size: 12)).foregroundStyle(p.muted)
            }
            if let notice { Text(notice).font(.system(size: 12)).foregroundStyle(p.muted) }
        }
        .padding(14).background(p.surface, in: RoundedRectangle(cornerRadius: 16))
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
                used: usage[key.id] != 0,
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
                    notice = "SSH key removed."
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
            usage = Dictionary(uniqueKeysWithValues: try keys.map {
                ($0.id, try MARCSSHKeyStore.users($0.id, servers: servers))
            })
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
        NavigationStack {
            List {
                ForEach(keys) { key in
                    Button { choose(key) } label: {
                        HStack {
                            Image(systemName: "key.horizontal").foregroundStyle(p.accent)
                            Text(key.name).font(.system(size: 14, weight: .medium))
                            Spacer()
                            if selected == key.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(p.accent)
                            }
                        }
                        .foregroundStyle(p.text)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.plain)
                }
                Text(keys.isEmpty
                     ? "No SSH keys saved. Add one in Settings → Keychain first."
                     : "Manage these keys in Settings → Keychain.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
                if let failure {
                    Text(failure).font(.system(size: 12)).foregroundStyle(p.muted)
                }
            }
            .navigationTitle("Choose SSH Key").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .tint(p.accent).presentationDetents([.medium, .large])
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
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Personal Mac", text: $name).textInputAutocapitalization(.words)
                }
                Section("Private key") {
                    Button { importing = true } label: {
                        Label(privateKey.isEmpty ? "Import from Files" : "Replace imported key", systemImage: "doc.badge.plus")
                    }
                    if !privateKey.isEmpty {
                        Label("Private key loaded", systemImage: "checkmark.circle").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section("Passphrase") { SecureField("Optional", text: $passphrase) }
                Section {
                    Text("OpenSSH Ed25519 keys only. The private key and passphrase stay in this iPhone’s Keychain. You can copy only the public key.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let failure { Text(failure).font(.footnote).foregroundStyle(.red) }
            }
            .navigationTitle("Add SSH Key").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            _ = try MARCSSHKeyStore.add(name: name, privateKey: privateKey, passphrase: passphrase)
                            privateKey = ""; passphrase = ""; dismiss()
                        } catch { failure = error.localizedDescription }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || privateKey.isEmpty)
                }
            }
        }
        .tint(p.accent).textInputAutocapitalization(.never).autocorrectionDisabled()
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
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("Key name", text: $name) }
                Section {
                    Button("Remove key", role: .destructive) {
                        wantsRemoval = true
                        dismiss()
                    }.disabled(used)
                    if used {
                        Text("This key is used by a saved login. Change or remove that login before deleting the key.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if let failure { Text(failure).font(.footnote).foregroundStyle(.red) }
            }
            .navigationTitle("Rename SSH Key").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do { try MARCSSHKeyStore.rename(key.id, name: name); dismiss() }
                        catch { failure = error.localizedDescription }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .tint(MARCPalette(dark: scheme == .dark).accent)
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

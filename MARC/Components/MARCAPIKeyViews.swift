import SwiftUI

struct MARCAPIKeysSection: View {
    @AppStorage("marc.ai.endpoint") private var endpoint = ""
    @AppStorage("marc.ai.apiKeyID") private var selectedKey = ""
    @AppStorage("marc.ai.keysRevision") private var revision = ""
    @State private var keys: [MARCAPIKeyStore.Info] = []
    @State private var adding = false
    @State private var editing: MARCAPIKeyStore.Info?
    @State private var removing: MARCAPIKeyStore.Info?
    @State private var failure: String?
    @State private var notice: String?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved keys").font(.system(size: 14, weight: .semibold))
                Spacer()
                Button { adding = true } label: {
                    Label("Add key", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium)).frame(minHeight: 44)
                }.tint(p.accent)
            }
            if keys.isEmpty {
                Text("Add your provider’s API key, then select it in Terminal & AI.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
            }
            ForEach(keys) { key in
                Divider()
                HStack(spacing: 12) {
                    Image(systemName: "key.horizontal")
                        .font(.system(size: 15)).foregroundStyle(p.accent)
                    Button { editing = key } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(key.name).font(.system(size: 14, weight: .medium)).foregroundStyle(p.text)
                            Text(key.host)
                                .font(.system(size: 11)).foregroundStyle(p.muted).lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Menu {
                        Button("Rename", systemImage: "pencil") { editing = key }
                        Button("Remove key", systemImage: "trash", role: .destructive) { removing = key }
                    } label: {
                        Image(systemName: "ellipsis").frame(width: 44, height: 44).foregroundStyle(p.muted)
                    }.accessibilityLabel("Actions for API key \(key.name)")
                }
            }
            if let failure { Text(failure).font(.system(size: 12)).foregroundStyle(.red) }
            if let notice { Text(notice).font(.system(size: 12)).foregroundStyle(p.muted) }
        }
        .padding(14).background(p.surface, in: RoundedRectangle(cornerRadius: 16))
        .onAppear(perform: reload)
        .onChange(of: revision) { _, _ in reload() }
        .sheet(isPresented: $adding, onDismiss: reload) {
            MARCAPIKeyEditor(defaultEndpoint: endpoint)
        }
        .sheet(item: $editing, onDismiss: reload) { key in
            MARCAPIKeyEditor(key: key, defaultEndpoint: key.endpoint)
        }
        .alert("Remove API key?", isPresented: Binding(
            get: { removing != nil }, set: { if !$0 { removing = nil } }
        )) {
            Button("Cancel", role: .cancel) { removing = nil }
            Button("Remove", role: .destructive) {
                do {
                    if let key = removing { try MARCAPIKeyStore.remove(key.id) }
                    reload()
                    notice = "API key removed."
                } catch { failure = error.localizedDescription }
                removing = nil
            }
        } message: {
            Text("Remove \(removing?.name ?? "this key") from this iPhone? This does not revoke the key with its provider. Select another key before your next API request.")
        }
    }

    private func reload() {
        do {
            if let migrated = try MARCAPIKeyStore.migrateLegacy(endpoint: endpoint),
               selectedKey.isEmpty, migrated.endpoint == endpoint.trimmingCharacters(in: .whitespacesAndNewlines) {
                selectedKey = migrated.id.uuidString
            }
            keys = try MARCAPIKeyStore.entries()
            failure = nil
        } catch { failure = error.localizedDescription }
    }
}

struct MARCAPIKeyEditor: View {
    var key: MARCAPIKeyStore.Info? = nil
    let defaultEndpoint: String
    var onSaved: (UUID) -> Void = { _ in }
    @State private var name = ""
    @State private var endpoint = ""
    @State private var secret = ""
    @State private var failure: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("OpenAI Personal", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section("Chat completions endpoint") {
                    if key != nil {
                        Text(endpoint).font(.footnote).textSelection(.enabled)
                    } else {
                        TextField("https://…/v1/chat/completions", text: $endpoint)
                            .keyboardType(.URL)
                    }
                }
                if key == nil {
                    Section("API key") {
                        SecureField("Paste your API key", text: $secret)
                    }
                }
                Section {
                    Text("The secret stays in this iPhone’s Keychain. It can only be sent to this exact endpoint. To change the secret or endpoint, add a new key.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let failure { Text(failure).foregroundStyle(.red).font(.footnote) }
            }
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .navigationTitle(key == nil ? "Add API Key" : "Rename API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (key == nil && secret.isEmpty))
                }
            }
            .onAppear { name = key?.name ?? ""; endpoint = defaultEndpoint }
            .onDisappear { secret = "" }
        }
    }

    private func save() {
        do {
            let id: UUID
            if let key { try MARCAPIKeyStore.rename(key.id, name: name); id = key.id }
            else { id = try MARCAPIKeyStore.add(name: name, endpoint: endpoint, secret: secret) }
            secret = ""
            onSaved(id)
            dismiss()
        } catch { failure = error.localizedDescription }
    }
}

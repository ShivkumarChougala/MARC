import SwiftUI

struct MARCLoginDraft {
    enum Method: String, CaseIterable {
        case password = "Password", key = "SSH Key"
    }
    var method: Method = .password
    var password = ""
    var keyID: UUID?
    var privateKey = ""
    var passphrase = ""

    init(saved: MARCCredentials.Saved? = nil) {
        method = saved?.isKeyLogin == true ? .key : .password
        password = saved?.password ?? ""
        keyID = saved?.keyID
        privateKey = saved?.privateKey ?? ""
        passphrase = saved?.passphrase ?? ""
    }

    var hasLogin: Bool { credentials().hasLogin }

    func credentials(
        fallback: MARCCredentials.Saved? = nil
    ) -> MARCCredentials.Saved {
        if method == .key {
            if let keyID {
                return .init(password: "", hostKey: "", keyID: keyID)
            }
            return .init(password: "", hostKey: "",
                         privateKey: privateKey, passphrase: passphrase)
        }
        let value = password.isEmpty && fallback?.isKeyLogin == false
            ? fallback?.password : password
        return .init(password: value ?? "", hostKey: "")
    }

    mutating func clear() { self = MARCLoginDraft() }
}

struct MARCLoginFields: View {
    @Binding var draft: MARCLoginDraft
    var quiet = false
    @State private var showingPassword = false
    @FocusState private var passwordFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicType
    @State private var choosing = false
    @State private var keys: [MARCSSHKeyStore.Info] = []
    @State private var failure: String?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 14) {
            if !quiet {
            Picker("Login method", selection: $draft.method) {
                ForEach(MARCLoginDraft.Method.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }.pickerStyle(.segmented)
            }

            if draft.method == .password {
                if quiet {
                    Group {
                        if dynamicType.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 0) {
                                quietPasswordLabel
                                quietPasswordInput
                            }
                        } else {
                            HStack(spacing: 8) {
                                quietPasswordLabel
                                quietPasswordInput
                            }
                        }
                    }
                    .foregroundStyle(p.text).frame(minHeight: 44)
                } else {
                HStack(spacing: 12) {
                    Text("Password").foregroundStyle(p.text)
                    SecureField("Enter password", text: $draft.password)
                        .textContentType(.password)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(p.text)
                        .frame(maxWidth: .infinity)
                }
                .font(.system(size: 15)).frame(minHeight: 44)
                }
            } else {
                Button { choosing = true } label: {
                    HStack {
                        Text(keys.first(where: { $0.id == draft.keyID })?.name
                             ?? (draft.privateKey.isEmpty
                                 ? "Select saved key" : "Previously saved key"))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }.frame(minHeight: 44)
                }.buttonStyle(.plain).foregroundStyle(p.accent)

                Text("Import and name SSH keys in Settings → Keychain. Select a saved key here.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
            }

            if let failure {
                Text(failure).font(.system(size: 12)).foregroundStyle(p.muted)
            }
        }
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .onAppear(perform: reload)
        .onChange(of: draft.method) { _, _ in
            showingPassword = false
            reload()
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { showingPassword = false } }
        .onDisappear { showingPassword = false }
        .sheet(isPresented: $choosing, onDismiss: reload) {
            MARCSSHKeyPicker(selected: draft.keyID) { key in
                draft.keyID = key.id
                draft.privateKey = ""; draft.passphrase = ""
                choosing = false
            }
        }
    }

    private var quietPasswordLabel: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return HStack(spacing: 0) {
            Text("Password").font(.subheadline).fixedSize()
            Button {
                showingPassword.toggle()
                Task { @MainActor in
                    guard draft.method == .password else { return }
                    passwordFocused = true
                }
            } label: {
                Image(systemName: showingPassword ? "eye.slash" : "eye")
                    .font(.caption).frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain).foregroundStyle(p.muted)
            .accessibilityLabel(showingPassword ? "Hide password" : "Show password")
        }
    }

    private var quietPasswordInput: some View {
        Group {
            if showingPassword {
                TextField("Enter password", text: $draft.password)
            } else {
                SecureField("Enter password", text: $draft.password)
            }
        }
        .font(.subheadline).multilineTextAlignment(.trailing)
        .textContentType(.password).focused($passwordFocused)
        .privacySensitive().frame(maxWidth: .infinity, minHeight: 44)
        .accessibilityLabel("Password")
    }

    private func reload() {
        guard draft.method == .key else {
            keys = []; failure = nil
            return
        }
        do { keys = try MARCSSHKeyStore.entries(); failure = nil }
        catch { failure = error.localizedDescription }
    }
}

/// Add Server uses a quiet native menu; existing editors keep their segmented picker.
struct MARCLoginMethodMenu: View {
    @Binding var method: MARCLoginDraft.Method
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        Menu {
            Picker("Login method", selection: $method) {
                ForEach(MARCLoginDraft.Method.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(method.rawValue)
                Image(systemName: "chevron.down").font(.caption2.weight(.medium))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .tint(p.accent)
        .accessibilityLabel("Login method, \(method.rawValue)")
        .accessibilityHint("Choose Password or SSH Key")
    }
}

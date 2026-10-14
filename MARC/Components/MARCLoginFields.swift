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
    @State private var choosing = false
    @State private var keys: [MARCSSHKeyStore.Info] = []
    @State private var failure: String?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 14) {
            Picker("Login method", selection: $draft.method) {
                ForEach(MARCLoginDraft.Method.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }.pickerStyle(.segmented)

            if draft.method == .password {
                HStack(spacing: 12) {
                    Text("Password").foregroundStyle(p.text)
                    SecureField("Enter password", text: $draft.password)
                        .textContentType(.password)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(p.text)
                        .frame(maxWidth: .infinity)
                }
                .font(.system(size: 15)).frame(minHeight: 44)
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
        .sheet(isPresented: $choosing, onDismiss: reload) {
            MARCSSHKeyPicker(selected: draft.keyID) { key in
                draft.keyID = key.id
                draft.privateKey = ""; draft.passphrase = ""
                choosing = false
            }
        }
    }

    private func reload() {
        do { keys = try MARCSSHKeyStore.entries(); failure = nil }
        catch { failure = error.localizedDescription }
    }
}

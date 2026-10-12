import SwiftUI
struct AddServerScreen: View {
    let store: ServerStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var password = ""
    @State private var hostKey = ""
    @State private var busy = false
    @State private var failure: String?
    @State private var pending: ServerProfile?

    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        (1...65535).contains(Int(port) ?? 0)
    }


    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @State private var revealPassword = false
    @State private var testMessage: String?

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    if let pending { store.remove(pending) }
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

                Button("Save", action: saveAndConnect)
                    .disabled(!valid || busy)
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
                            inputRow("User", hint: "Mac username", text: $username)
                            Divider().padding(.horizontal, 16)

                            HStack(spacing: 10) {
                                Text("Password")
                                Button {
                                    revealPassword.toggle()
                                } label: {
                                    Image(systemName: revealPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(p.accent)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(
                                    revealPassword ? "Hide password" : "Show password"
                                )

                                Group {
                                    if revealPassword {
                                        TextField("Password", text: $password)
                                    } else {
                                        SecureField("Password", text: $password)
                                    }
                                }
                                .textContentType(.password)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity)
                            }
                            .font(.system(size: 15))
                            .padding(.horizontal, 16)
                            .frame(minHeight: 56)
                        }
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 22))
                    }

                    DisclosureGroup {
                        TextEditor(text: $hostKey)
                            .font(.system(size: 11, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .frame(height: 100)
                            .padding(.top, 8)
                    } label: {
                        HStack {
                            Text("Host key · optional")
                            Spacer()
                            Text(hostKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "None" : "Pinned")
                                .foregroundStyle(p.accent)
                        }
                        .font(.system(size: 15))
                    }
                    .tint(p.accent)
                    .padding(16)
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 22))

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
                            Text(busy ? "Please wait…" : "Save & connect")
                            Spacer()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(minHeight: 52)
                        .background(p.accent, in: RoundedRectangle(cornerRadius: 18))
                        .foregroundStyle(.white)
                    }
                    .disabled(!valid || busy)

                    Text("Connect once. Your password is remembered securely on this iPhone.")
                        .font(.system(size: 11))
                        .foregroundStyle(p.muted)
                        .padding(.horizontal, 12)

                    if let failure {
                        Text(failure)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
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
        .onDisappear { password = "" }
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
            username: username.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        let submittedPassword = password
        let submittedKey = hostKey
        busy = true
        failure = nil
        testMessage = nil

        Task { @MainActor in
            defer { busy = false }
            do {
                _ = try await SSHConnectionTest.run(
                    server: server,
                    password: submittedPassword,
                    publicHostKey: submittedKey
                )
                testMessage = "Connection successful. Ready to save."
            } catch {
                failure = error.localizedDescription
            }
        }
    }

    private func saveAndConnect() {
        guard valid, let number = Int(port), !busy else { return }
        let profile = ServerProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            host: host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: number,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        if let pending { store.remove(pending) }
        pending = profile
        store.add(profile)
        busy = true
        failure = nil
        let submittedPassword = password
        let submittedKey = hostKey

        Task { @MainActor in
            defer { busy = false }
            do {
                try await store.monitor.connect(
                    server: profile,
                    password: submittedPassword,
                    hostKey: submittedKey
                )
                pending = nil
                password = ""
                dismiss()
            } catch {
                failure = error.localizedDescription
                store.remove(profile)
                pending = nil
            }
        }
    }
}

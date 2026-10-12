import SwiftUI

struct SSHConnectScreen: View {
    let server: ServerProfile
    let monitor: SSHMonitor
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var publicHostKey = ""
    @State private var testing = false
    @State private var failure: String?
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Button("Close") { dismiss() }.disabled(testing)
                    Spacer()
                    Text("Connect").font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text("Close").hidden()
                }.font(.system(size: 13)).tint(p.accent)
                MARCSettingsGroup(title: "Server") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(server.name).font(.system(size: 15, weight: .semibold))
                        Text("\(server.username)@\(server.host):\(server.port)")
                            .font(.system(size: 12)).foregroundStyle(p.muted).textSelection(.enabled)
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                }
                MARCSettingsGroup(title: "Authentication") {
                    SecureField("Mac login password", text: $password)
                        .textContentType(.password).padding(16).disabled(testing)
                }
                Text("Connect once. Your password is saved in this iPhone’s Keychain for automatic reconnection.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
                MARCSettingsGroup(title: "Server host key · optional") {
                    TextEditor(text: $publicHostKey)
                        .font(.system(size: 11, design: .monospaced))
                        .scrollContentBackground(.hidden).frame(height: 100).padding(10)
                        .autocorrectionDisabled().textInputAutocapitalization(.never).disabled(testing)
                }
                Text("Leave blank to connect without host verification, or enter this server’s Ed25519 public host key.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
                Button {
                    startTest()
                } label: {
                    HStack(spacing: 10) {
                        if testing { ProgressView().tint(.white) }
                        Text(testing ? "Connecting…" : "Connect to Mac")
                    }.font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(p.accent, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white)
                }.disabled(testing || password.isEmpty)
                if let failure {
                    MARCCard(title: "Connection failed") {
                        Text(failure).font(.system(size: 12)).textSelection(.enabled)
                        Text("Check the password, server key, and that both devices are on the same Wi-Fi. Allow Local Network access if iOS asks.")
                            .font(.system(size: 12)).foregroundStyle(p.muted)
                    }
                }
            }.padding(16).padding(.top, 12)
        }.marcCanvas().interactiveDismissDisabled(testing)
            .onDisappear { password = "" }
    }

    private func startTest() {
        testing = true
        failure = nil
        let submittedPassword = password
        let submittedKey = publicHostKey
        password = ""
        Task { @MainActor in
            defer { testing = false }
            do {
                try await monitor.connect(server: server, password: submittedPassword, hostKey: submittedKey)
                dismiss()
            } catch {
                failure = String(describing: error)
            }
        }
    }
}

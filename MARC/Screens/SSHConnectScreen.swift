import SwiftUI

struct SSHConnectScreen: View {
    let server: ServerProfile
    let monitor: SSHMonitor
    @Environment(\.dismiss) private var dismiss
    @State private var loginDraft = MARCLoginDraft()
    @State private var publicHostKey = ""
    @State private var testing = false
    @State private var trust = MARCHostTrust()
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
                    MARCLoginFields(draft: $loginDraft).padding(16).disabled(testing)
                }
                Text("Your login is saved in this iPhone’s Keychain for automatic reconnection.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
                Text("MARC remembers this Mac’s fingerprint automatically and blocks unexpected changes.")
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
                }.disabled(testing || !loginDraft.hasLogin)
            }.padding(16).padding(.top, 12)
        }.marcCanvas().interactiveDismissDisabled(testing)
            .onAppear {
                let saved = MARCCredentials.read(server.id)
                publicHostKey = saved?.hostKey ?? ""
                loginDraft = MARCLoginDraft(saved: saved)
            }
            .hostTrustPrompt(trust)
        .marcConnectionAlert($failure)
            .onDisappear { loginDraft.clear(); trust.cancel() }
    }

    private func startTest() {
        testing = true
        failure = nil
        let submittedLogin = loginDraft.credentials()
        let submittedKey = publicHostKey
        Task { @MainActor in
            defer { testing = false }
            do {
                let verifiedKey = try await trust.keyForConnection(server: server, existingKey: submittedKey)
                try await monitor.connect(server: server, login: submittedLogin, hostKey: verifiedKey)
                dismiss()
            } catch is CancellationError {
                failure = nil
            } catch {
                failure = MARCConnectionIssue.message(error, login: submittedLogin)
            }
        }
    }
}

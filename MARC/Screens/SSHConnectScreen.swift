import SwiftUI
import UIKit

struct SSHConnectScreen: View {
    let server: ServerProfile
    let monitor: SSHMonitor
    @Environment(\.marcGuidedTour) private var setupTour
    @Environment(\.dismiss) private var dismiss
    @State private var loginDraft = MARCLoginDraft()
    @State private var publicHostKey = ""
    @State private var testing = false
    @State private var loaded = false
    @State private var requestTask: Task<Void, Never>?
    @State private var requestID = UUID()
    @Environment(\.scenePhase) private var scenePhase
    @State private var trust = MARCHostTrust()
    @State private var failure: String?
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue

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
                }.disabled(testing || !loaded || !loginDraft.hasLogin)
            }.padding(16).padding(.top, 12)
        }.marcCanvas().interactiveDismissDisabled(testing)
            .marcGuidePresentationBarrier()
            .onAppear {
                guard !loaded else { return }
                do {
                    let saved = try MARCCredentials.readChecked(server.id)
                    publicHostKey = saved?.hostKey ?? ""
                    loginDraft = MARCLoginDraft(saved: saved)
                    loaded = true
                } catch { failure = error.localizedDescription }
            }
            .hostTrustPrompt(trust)
        .marcConnectionAlert($failure)
            .onChange(of: failure) { old, message in
                guard setupTour?.active == true, setupTour?.stage == .connect,
                      scenePhase == .active, message != nil, message != old else { return }
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            .onDisappear { stopRequest(); loginDraft.clear() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { stopRequest() }
            }
    }

    private func startTest() {
        guard !testing, loaded, loginDraft.hasLogin, !monitor.connecting else { return }
        testing = true
        failure = nil
        let submittedLogin = loginDraft.credentials()
        let submittedKey = publicHostKey
        let request = UUID()
        requestID = request
        requestTask = Task { @MainActor in
            defer { if requestID == request { testing = false; requestTask = nil } }
            do {
                try Task.checkCancellation()
                guard requestID == request else { throw CancellationError() }
                let verifiedKey = try await trust.keyForConnection(server: server, existingKey: submittedKey)
                try Task.checkCancellation()
                guard requestID == request else { throw CancellationError() }
                try await monitor.connect(server: server, login: submittedLogin, hostKey: verifiedKey)
                try Task.checkCancellation()
                guard requestID == request else { return }
                dismiss()
            } catch is CancellationError {
                if requestID == request { failure = nil }
            } catch {
                guard requestID == request, !Task.isCancelled else { return }
                failure = MARCConnectionIssue.message(error, login: submittedLogin)
            }
        }
    }
    private func stopRequest() {
        requestID = UUID()
        requestTask?.cancel()
        requestTask = nil
        testing = false
        trust.cancel()
    }

}

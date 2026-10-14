import SwiftUI
import Network

struct SSHTestScreen: View {
    let server: ServerProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @State private var loginDraft = MARCLoginDraft()
    @State private var hostKey = ""
    @State private var trust = MARCHostTrust()
    @State private var busy = false
    @State private var latency: Double?
    @State private var output: String?
    @State private var failure: String?

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Test connection")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Button("Close") { dismiss() }.disabled(busy)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(server.name).fontWeight(.semibold)
                    Text("\(server.username)@\(server.host):\(server.port)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(p.muted)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(p.surface, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    run(authenticate: false)
                } label: {
                    HStack {
                        Text("Check reachability")
                        Spacer()
                        Image(systemName: "network")
                    }
                    .padding(16)
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(busy)

                if let latency {
                    Text(String(format: "SSH port reachable · %.0f ms", latency))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(marcHex: 0x2eae7d))
                }

                MARCLoginFields(draft: $loginDraft)
                    .padding(16).disabled(busy)
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    run(authenticate: true)
                } label: {
                    HStack(spacing: 8) {
                        Spacer()
                        if busy { ProgressView().tint(.white) }
                        Text(busy ? "Testing…" : "Test SSH login")
                        Spacer()
                    }
                    .frame(minHeight: 48)
                    .background(p.accent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                }
                .disabled(busy)

                if let output {
                    Text("SSH authentication successful")
                        .font(.system(size: 13, weight: .semibold))
                    Text(output)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }
                Text("Reachability measures a TCP connection to the SSH port, not ICMP ping.")
                    .font(.system(size: 10))
                    .foregroundStyle(p.muted)
            }
            .padding(20)
        }
        .marcCanvas()
        .interactiveDismissDisabled(busy)
        .onAppear {
            let saved = MARCCredentials.read(server.id)
            hostKey = saved?.hostKey ?? ""
            loginDraft = MARCLoginDraft(saved: saved)
        }
        .hostTrustPrompt(trust)
        .marcConnectionAlert($failure)
        .onDisappear { loginDraft.clear(); trust.cancel() }
    }

    private func run(authenticate: Bool) {
        guard !busy else { return }
        busy = true
        failure = nil
        latency = nil
        output = nil
        let saved = MARCCredentials.read(server.id)
        let submittedLogin = loginDraft.credentials(fallback: saved)
        let submittedKey = hostKey

        Task { @MainActor in
            defer { busy = false }
            do {
                latency = try await MARCPortProbe.check(
                    host: server.host, port: server.port
                )
                if authenticate {
                    guard submittedLogin.hasLogin else {
                        failure = "Server is reachable. Enter a password or select a saved SSH key to test login."
                        return
                    }
                    let verifiedKey = try await trust.keyForConnection(server: server, existingKey: submittedKey)
                    let result = try await SSHConnectionTest.run(
                        server: server,
                        login: submittedLogin,
                        publicHostKey: verifiedKey
                    )
                    output = result.output
                }
            } catch is CancellationError {
                failure = nil
            } catch {
                failure = MARCConnectionIssue.message(error, login: submittedLogin)
            }
        }
    }
}

@MainActor
private final class MARCPortProbe {
    private let connection: NWConnection
    private let continuation: CheckedContinuation<Double, Error>
    private let began = Date()
    private var finished = false

    private init(
        host: String, port: NWEndpoint.Port,
        continuation: CheckedContinuation<Double, Error>
    ) {
        connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .tcp)
        self.continuation = continuation
    }

    static func check(host: String, port: Int) async throws -> Double {
        guard let number = UInt16(exactly: port),
              let endpoint = NWEndpoint.Port(rawValue: number) else {
            throw NSError(domain: "MARC", code: 40, userInfo: [
                NSLocalizedDescriptionKey: "Invalid server port."
            ])
        }
        return try await withCheckedThrowingContinuation { continuation in
            let probe = MARCPortProbe(
                host: host, port: endpoint, continuation: continuation
            )
            probe.start()
        }
    }

    private func start() {
        connection.stateUpdateHandler = { [self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    finish(.success(Date().timeIntervalSince(began) * 1000))
                case .failed(let error):
                    finish(.failure(error))
                default:
                    break
                }
            }
        }
        connection.start(queue: .global(qos: .utility))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            finish(.failure(NSError(domain: "MARC", code: 41, userInfo: [
                NSLocalizedDescriptionKey: "SSH port did not respond within 5 seconds."
            ])))
        }
    }

    private func finish(_ result: Result<Double, Error>) {
        guard !finished else { return }
        finished = true
        connection.stateUpdateHandler = nil
        connection.cancel()
        continuation.resume(with: result)
    }
}

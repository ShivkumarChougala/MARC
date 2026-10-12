import SwiftUI
import Network

struct SSHTestScreen: View {
    let server: ServerProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @State private var password = ""
    @State private var hostKey = ""
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

                SecureField("Password · blank uses saved password", text: $password)
                    .textContentType(.password)
                    .font(.system(size: 12))
                    .padding(16)
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
                if let failure {
                    Text(failure)
                        .font(.system(size: 12))
                        .foregroundStyle(p.accent)
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
            hostKey = MARCCredentials.read(server.id)?.hostKey ?? ""
        }
        .onDisappear { password = "" }
    }

    private func run(authenticate: Bool) {
        guard !busy else { return }
        busy = true
        failure = nil
        latency = nil
        output = nil
        let saved = MARCCredentials.read(server.id)
        let submittedPassword = password.isEmpty ? (saved?.password ?? "") : password
        let submittedKey = hostKey

        Task { @MainActor in
            defer { busy = false }
            do {
                latency = try await MARCPortProbe.check(
                    host: server.host, port: server.port
                )
                if authenticate {
                    guard !submittedPassword.isEmpty else {
                        failure = "Server is reachable. Enter a password to test SSH login."
                        return
                    }
                    let result = try await SSHConnectionTest.run(
                        server: server,
                        password: submittedPassword,
                        publicHostKey: submittedKey
                    )
                    output = result.output
                }
            } catch {
                failure = error.localizedDescription
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

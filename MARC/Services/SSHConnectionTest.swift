import Foundation
import Citadel
import NIOSSH
import NIOCore

struct SSHTestResult: Sendable {
    let output: String
    let testedAt: Date
}

enum SSHTestError: LocalizedError {
    case invalidKey
    var errorDescription: String? { "Could not verify this Mac’s SSH host key. Check the Mac and try connecting again." }
}

/// One authenticated, read-only request. This deliberately does not retain a session or password.
enum SSHConnectionTest {
    static func run(server: ServerProfile, login: MARCCredentials.Saved, publicHostKey: String) async throws -> SSHTestResult {
        let verifiedHostKey = try await MARCHostTrust().keyForConnection(server: server, existingKey: publicHostKey)
        try Task.checkCancellation()
        let validator = try hostKeyValidator(server: server, publicHostKey: verifiedHostKey)
        let username = server.username
        let authentication = try MARCLogin.authentication(login, username: username)
        var settings = SSHClientSettings(
            host: server.host,
            port: server.port,
            authenticationMethod: authentication,
            hostKeyValidator: validator
        )
        settings.connectTimeout = .seconds(10)
        let client = try await SSHClient.connect(to: settings)
        do {
            let buffer = try await client.executeCommand(
                "/usr/bin/whoami; /bin/hostname; /usr/bin/uname -sm; /usr/bin/sw_vers -productVersion",
                maxResponseSize: 16384,
                mergeStreams: true
            )
            let output = String(decoding: buffer.readableBytesView, as: UTF8.self)
            try await client.close()
            return SSHTestResult(output: output, testedAt: Date())
        } catch {
            try? await client.close()
            throw error
        }
    }

    /// Discovery supplies an address, never proof of server identity.
    static func hostKeyValidator(server: ServerProfile, publicHostKey: String) throws -> SSHHostKeyValidator {
        let supplied = publicHostKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let stored = try MARCHostTrustStore.read(host: server.host, port: server.port)
        if let stored, !supplied.isEmpty {
            let suppliedKey = try NIOSSHPublicKey(openSSHPublicKey: supplied)
            guard String(openSSHPublicKey: suppliedKey) == stored else { throw HostTrustError.changed }
        }
        let key = stored ?? supplied
        guard !key.isEmpty else { throw SSHTestError.invalidKey }
        return .custom(MARCPinnedHostKeyDelegate(publicKey: try NIOSSHPublicKey(openSSHPublicKey: key)))
    }
}

/// Give every SSH transport a clear, fail-closed key-change error.
private final class MARCPinnedHostKeyDelegate: NIOSSHClientServerAuthenticationDelegate, Sendable {
    private let expected: String
    nonisolated init(publicKey: NIOSSHPublicKey) { expected = String(openSSHPublicKey: publicKey) }
    nonisolated func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        if String(openSSHPublicKey: hostKey) == expected {
            validationCompletePromise.succeed(())
        } else {
            validationCompletePromise.fail(HostTrustError.changed)
        }
    }
}

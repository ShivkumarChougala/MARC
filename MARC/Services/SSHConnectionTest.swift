import Foundation
import Citadel
import NIOSSH
import NIOCore
import CryptoKit

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
    static func run(server: ServerProfile, password: String, publicHostKey: String) async throws -> SSHTestResult {
        try await run(server: server, login: .init(password: password, hostKey: publicHostKey), publicHostKey: publicHostKey)
    }

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

    /// Decode the two length-prefixed fields in an OpenSSH Ed25519 public-key blob.
    static func parseEd25519(_ text: String) throws -> NIOSSHPublicKey {
        let fields = text.split(whereSeparator: { $0.isWhitespace })
        guard fields.count >= 2, fields[0] == "ssh-ed25519",
              let data = Data(base64Encoded: String(fields[1])) else { throw SSHTestError.invalidKey }
        let bytes = Array(data)
        var offset = 0
        func readField() throws -> [UInt8] {
            guard bytes.count - offset >= 4 else { throw SSHTestError.invalidKey }
            let count = bytes[offset..<(offset + 4)].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            offset += 4
            guard UInt64(count) <= UInt64(bytes.count - offset) else { throw SSHTestError.invalidKey }
            let end = offset + Int(count)
            let field = Array(bytes[offset..<end])
            offset = end
            return field
        }
        let algorithm = try readField()
        let rawKey = try readField()
        guard String(decoding: algorithm, as: UTF8.self) == "ssh-ed25519",
              rawKey.count == 32, offset == bytes.count else { throw SSHTestError.invalidKey }
        return try NIOSSHPublicKey(openSSHPublicKey: String(fields[0]) + " " + String(fields[1]))
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

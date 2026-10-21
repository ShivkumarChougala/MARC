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

/// Compatibility is checked only after the pinned SSH handshake and authentication.
/// Discovery names and SSH banners are not operating-system evidence.
enum MARCPlatformError: LocalizedError, Equatable {
    case unsupported, unverified

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "MARC only supports Macs running macOS. Connect to a Mac to continue."
        case .unverified:
            return "MARC couldn’t confirm that this device runs macOS. Check that you’re connecting to a Mac with Remote Login enabled, then try again."
        }
    }
}

enum MARCMacCompatibility {
    // Read-only, fixed commands. ProductName distinguishes macOS from other Darwin systems.
    static let command = """
    marc_kernel=$(/usr/bin/uname -s 2>/dev/null || /bin/uname -s 2>/dev/null) || exit 1
    if [ "$marc_kernel" != "Darwin" ]; then
        printf 'MARC_UNSUPPORTED_V1\\n'
    else
        marc_product=$(/usr/bin/sw_vers -productName 2>/dev/null) || exit 1
        case "$marc_product" in
            macOS|"Mac OS X") printf 'MARC_MACOS_V1\\n' ;;
            *) printf 'MARC_UNSUPPORTED_V1\\n' ;;
        esac
    fi
    """

    static func validate(_ output: String) throws {
        switch output.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "MARC_MACOS_V1": return
        case "MARC_UNSUPPORTED_V1": throw MARCPlatformError.unsupported
        default: throw MARCPlatformError.unverified
        }
    }

    static func requireMacOS(on client: SSHClient) async throws {
        try Task.checkCancellation()
        // Close a stalled probe's own transport; completion cancels this deadline.
        let deadline = Task {
            do { try await Task.sleep(nanoseconds: 10_000_000_000) }
            catch { return }
            try? await client.close()
        }
        defer { deadline.cancel() }
        do {
            let response = try await client.executeCommand(
                command, maxResponseSize: 1024, mergeStreams: true
            )
            try Task.checkCancellation()
            try validate(String(decoding: response.readableBytesView, as: UTF8.self))
        } catch {
            try Task.checkCancellation()
            if error is CancellationError || error is MARCPlatformError { throw error }
            // Non-POSIX shells and restricted accounts may reject the probe.
            // Do not label those replies as a verified Mac or a failed password.
            throw MARCPlatformError.unverified
        }
    }
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
            try await MARCMacCompatibility.requireMacOS(on: client)
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

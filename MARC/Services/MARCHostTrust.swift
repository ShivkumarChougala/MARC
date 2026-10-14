import Foundation
import Security
import Observation

struct HostTrustRequest: Identifiable {
    let id = UUID()
    let host: String
    let port: Int
    let publicKey: String
    let fingerprint: String
    var algorithm: String { String(publicKey.split(separator: " ").first ?? "") }
}

enum HostTrustError: LocalizedError {
    case changed
    case storage(OSStatus)
    nonisolated var errorDescription: String? {
        switch self {
        case .changed: return "This Mac’s SSH host key has changed. Connection blocked. Verify the change directly on the Mac before changing trust settings."
        case .storage(let status): return "Could not access trusted host keys in Keychain (\(status))."
        }
    }
}

struct MARCTrustedHostEntry: Identifiable {
    let endpoint: String
    let publicKey: String
    var id: String { endpoint }
}

/// Trust is scoped to host + port, independently of saved usernames/passwords.
enum MARCHostTrustStore {
    private static func query(host: String, port: Int) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "MARC.trustedSSHHosts.v1",
         kSecAttrAccount as String: HostKeyIdentity.endpoint(host: host, port: port)]
    }

    static func forget(endpoint: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "MARC.trustedSSHHosts.v1",
            kSecAttrAccount as String: endpoint
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw HostTrustError.storage(status)
        }
    }

    static func entries() throws -> [MARCTrustedHostEntry] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "MARC.trustedSSHHosts.v1",
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            throw HostTrustError.storage(status)
        }
        return try items.map { item in
            guard let endpoint = item[kSecAttrAccount as String] as? String,
                  let data = item[kSecValueData as String] as? Data,
                  let key = String(data: data, encoding: .utf8) else {
                throw HostTrustError.storage(errSecDecode)
            }
            return MARCTrustedHostEntry(endpoint: endpoint, publicKey: key)
        }.sorted { $0.endpoint.localizedStandardCompare($1.endpoint) == .orderedAscending }
    }

    static func read(host: String, port: Int) throws -> String? {
        var query = query(host: host, port: port)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8), !key.isEmpty else {
            throw HostTrustError.storage(status)
        }
        return key
    }

    static func remember(host: String, port: Int, publicKey: String) throws {
        if let existing = try read(host: host, port: port) {
            guard existing == publicKey else { throw HostTrustError.changed }
            return
        }
        var query = query(host: host, port: port)
        query[kSecValueData as String] = Data(publicKey.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        // Never overwrite an existing endpoint pin, even if another flow races us.
        if status == errSecDuplicateItem {
            guard try read(host: host, port: port) == publicKey else { throw HostTrustError.changed }
        } else if status != errSecSuccess { throw HostTrustError.storage(status) }
    }
}

@MainActor @Observable
final class MARCHostTrust {
    private(set) var request: HostTrustRequest?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var continuation: CheckedContinuation<String, Error>?

    func keyForConnection(server: ServerProfile, existingKey: String = "") async throws -> String {
        let token = UUID()
        generation = token
        try Task.checkCancellation()

        if let trusted = try MARCHostTrustStore.read(host: server.host, port: server.port) {
            return trusted
        }

        let existing = existingKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !existing.isEmpty {
            _ = try HostKeyIdentity.fingerprint(publicKey: existing)
            try MARCHostTrustStore.remember(
                host: server.host, port: server.port, publicKey: existing
            )
            return existing
        }

        let key = try await SSHHostKeyProbe.fetch(server: server)
        try Task.checkCancellation()
        guard generation == token else { throw CancellationError() }
        _ = try HostKeyIdentity.fingerprint(publicKey: key)

        // Trust on first use. The authenticated handshake must match this pin.
        try MARCHostTrustStore.remember(
            host: server.host, port: server.port, publicKey: key
        )
        return key
    }

    func approve() {
        guard let request else { return }
        do {
            try MARCHostTrustStore.remember(host: request.host, port: request.port, publicKey: request.publicKey)
            finish(.success(request.publicKey))
        } catch { finish(.failure(error)) }
    }

    func cancel() { generation = UUID(); finish(.failure(CancellationError())) }

    private func finish(_ result: Result<String, Error>) {
        let pending = continuation
        continuation = nil
        request = nil
        pending?.resume(with: result)
    }
}

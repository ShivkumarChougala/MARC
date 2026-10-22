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
    case approvalRequired
    case storage(OSStatus)
    nonisolated var errorDescription: String? {
        switch self {
        case .changed: return "This Mac’s SSH host key has changed. Connection blocked. Verify the change directly on the Mac before changing trust settings."
        case .approvalRequired: return "Confirm this Mac’s fingerprint in connection settings before reconnecting."
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

// Task cancellation can arrive off the main actor. Record it immediately so a
// queued approval cannot accept an already-cancelled connection request.
nonisolated private final class HostTrustCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        cancelled = true
    }
}

@MainActor @Observable
final class MARCHostTrust {
    private(set) var request: HostTrustRequest?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var continuation: CheckedContinuation<String, Error>?
    @ObservationIgnored private var cancellation: HostTrustCancellation?

    func keyForConnection(server: ServerProfile, existingKey: String = "", allowPrompt: Bool = true) async throws -> String {
        // Superseding a request must also resume its suspended caller.
        cancel()
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

        // Transport-only callers have no sheet owner. Never suspend an
        // automatic reconnect behind a prompt that cannot be presented.
        guard allowPrompt else { throw HostTrustError.approvalRequired }
        let key = try await SSHHostKeyProbe.fetch(server: server)
        try Task.checkCancellation()
        guard generation == token else { throw CancellationError() }
        let fingerprint = try HostKeyIdentity.fingerprint(publicKey: key)
        let cancelled = HostTrustCancellation()

        // The probe never authenticates. Suspend here until the visible trust
        // sheet is approved; only then may the caller start authentication.
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { pending in
                guard generation == token, !Task.isCancelled, !cancelled.isCancelled else {
                    pending.resume(throwing: CancellationError())
                    return
                }
                cancellation = cancelled
                continuation = pending
                request = HostTrustRequest(
                    host: server.host, port: server.port,
                    publicKey: key, fingerprint: fingerprint
                )
            }
        } onCancel: {
            cancelled.cancel()
            Task { @MainActor [weak self] in
                guard let self, self.generation == token else { return }
                self.cancel()
            }
        }
    }

    func approve(requestID: UUID) {
        guard let request, request.id == requestID else { return }
        guard cancellation?.isCancelled != true else { cancel(); return }
        do {
            try MARCHostTrustStore.remember(host: request.host, port: request.port, publicKey: request.publicKey)
            finish(.success(request.publicKey))
        } catch { finish(.failure(error)) }
    }

    func cancel(requestID: UUID? = nil) {
        if let requestID, request?.id != requestID { return }
        cancellation?.cancel()
        generation = UUID()
        finish(.failure(CancellationError()))
    }

    private func finish(_ result: Result<String, Error>) {
        let pending = continuation
        continuation = nil
        cancellation = nil
        request = nil
        pending?.resume(with: result)
    }
}

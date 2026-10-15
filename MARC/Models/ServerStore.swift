import Foundation
import Security
import Observation
@MainActor @Observable final class ServerStore {
    let monitor = SSHMonitor()
    private(set) var servers: [ServerProfile] = []
    var selectedID: UUID?
    var storageError: String?
    private let key = "marc.serverProfiles.v1"
    var selected: ServerProfile? { servers.first { $0.id == selectedID } }
    init() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do { servers = try JSONDecoder().decode([ServerProfile].self, from: data); selectedID = servers.first?.id }
        catch { storageError = "Saved server profiles could not be read." }
    }
    func add(_ profile: ServerProfile) {
        servers.append(profile); selectedID = profile.id; persist()
    }
    @discardableResult
    func remove(_ profile: ServerProfile) -> Bool {
        guard servers.contains(where: { $0.id == profile.id }) else { return true }
        do { try MARCCredentials.removeChecked(profile.id) }
        catch {
            storageError = error.localizedDescription
            return false
        }
        if UserDefaults.standard.string(forKey: "marc.autoServer") == profile.id.uuidString {
            UserDefaults.standard.removeObject(forKey: "marc.autoServer")
        }
        if monitor.server?.id == profile.id { monitor.cancelConnection() }
        servers.removeAll { $0.id == profile.id }
        if selectedID == profile.id { selectedID = servers.first?.id }
        persist()
        return true
    }
    func update(_ profile: ServerProfile) {
        guard let index = servers.firstIndex(where: { $0.id == profile.id }) else { return }
        servers[index] = profile
        persist()
    }

    private func persist() {
        do { UserDefaults.standard.set(try JSONEncoder().encode(servers), forKey: key); storageError = nil }
        catch { storageError = "Server profiles could not be saved." }
    }
}


enum MARCCredentials {
    struct Saved: Codable, Sendable {
        let password: String
        let hostKey: String
        let keyID: UUID?
        let privateKey: String?
        let passphrase: String?
        init(password: String, hostKey: String, privateKey: String? = nil, passphrase: String? = nil, keyID: UUID? = nil) {
            self.password = password; self.hostKey = hostKey
            self.privateKey = privateKey; self.passphrase = passphrase; self.keyID = keyID
        }
        var isKeyLogin: Bool { keyID != nil || privateKey != nil }
        var hasLogin: Bool { keyID != nil || (isKeyLogin ? !(privateKey?.isEmpty ?? true) : !password.isEmpty) }
    }

    private static let service = "MARC.savedSSH"

    private static func query(_ id: UUID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString
        ]
    }

    static func save(_ id: UUID, password: String, hostKey: String) throws {
        try save(id, login: Saved(password: password, hostKey: hostKey), hostKey: hostKey)
    }

    static func save(_ id: UUID, login: Saved, hostKey: String) throws {
        let data = try JSONEncoder().encode(Saved(
            password: login.isKeyLogin ? "" : login.password, hostKey: hostKey,
            privateKey: login.keyID == nil ? login.privateKey : nil,
            passphrase: login.keyID == nil && login.isKeyLogin ? login.passphrase : nil,
            keyID: login.keyID
        ))
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String:
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let existing = query(id)
        var status = SecItemUpdate(existing as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = existing
            attributes.forEach { item[$0.key] = $0.value }
            status = SecItemAdd(item as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            throw NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(status),
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not save the connection in Keychain (\(status))."
                ]
            )
        }
    }

    static func read(_ id: UUID) -> Saved? { try? readChecked(id) }

    static func readChecked(_ id: UUID) throws -> Saved? {
        var item = query(id)
        item[kSecReturnData as String] = true
        item[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(item as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw MARCKeyStoreError.storage(status)
        }
        do { return try JSONDecoder().decode(Saved.self, from: data) }
        catch { throw MARCKeyStoreError.storage(errSecDecode) }
    }

    static func remove(_ id: UUID) {
        try? removeChecked(id)
    }

    static func removeChecked(_ id: UUID) throws {
        let status = SecItemDelete(query(id) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw MARCKeyStoreError.storage(status)
        }
    }
}

extension ServerStore {
    func reconnectRememberedServer() async {
        guard !Task.isCancelled, monitor.automaticReconnectEnabled,
              monitor.connectionIssue?.canRetry != false,
              !monitor.connected, !monitor.connecting,
              let text = UserDefaults.standard.string(forKey: "marc.autoServer"),
              let id = UUID(uuidString: text),
              let server = servers.first(where: { $0.id == id }) else { return }

        do {
            guard let saved = try MARCCredentials.readChecked(id) else { return }
            try Task.checkCancellation()
            selectedID = id
            try await monitor.connect(
                server: server,
                login: saved,
                hostKey: saved.hostKey
            )
        } catch is CancellationError {
            return
        } catch {
            // Connection failures are presented by the monitor; also expose Keychain failures.
            if monitor.connectionIssue == nil { storageError = error.localizedDescription }
        }
    }
}


extension ServerStore {
    func switchToSavedServer(_ server: ServerProfile) async throws {
        try Task.checkCancellation()
        guard !monitor.connecting else { return }
        // A queued row action must use the current saved profile, not its old snapshot.
        guard let current = servers.first(where: { $0.id == server.id }) else { return }
        let server = current

        if monitor.connected && monitor.server?.id == server.id {
            selectedID = server.id
            return
        }

        guard let saved = try MARCCredentials.readChecked(server.id) else {
            throw NSError(domain: "MARC", code: 30, userInfo: [
                NSLocalizedDescriptionKey:
                    "Connect to this server once to save its login."
            ])
        }

        selectedID = server.id
        // SSHMonitor remembers the new target only after connection succeeds.
        try await monitor.connect(
            server: server,
            login: saved,
            hostKey: saved.hostKey
        )
    }
}

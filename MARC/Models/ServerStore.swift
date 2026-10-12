import Foundation
import Security
import Observation
struct ServerProfile: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var host: String
    var port: Int
    var username: String
}
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
    func remove(_ profile: ServerProfile) {
        MARCCredentials.remove(profile.id)
        if UserDefaults.standard.string(forKey: "marc.autoServer") == profile.id.uuidString {
            UserDefaults.standard.removeObject(forKey: "marc.autoServer")
        }
        if monitor.server?.id == profile.id { Task { await monitor.disconnect() } }
        servers.removeAll { $0.id == profile.id }
        if selectedID == profile.id { selectedID = servers.first?.id }
        persist()
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
    struct Saved: Codable {
        let password: String
        let hostKey: String
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
        let data = try JSONEncoder().encode(
            Saved(password: password, hostKey: hostKey)
        )
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

    static func read(_ id: UUID) -> Saved? {
        var item = query(id)
        item[kSecReturnData as String] = true
        item[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(item as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(Saved.self, from: data)
    }

    static func remove(_ id: UUID) {
        SecItemDelete(query(id) as CFDictionary)
    }
}

extension ServerStore {
    func reconnectRememberedServer() async {
        guard !monitor.connected, !monitor.connecting,
              let text = UserDefaults.standard.string(forKey: "marc.autoServer"),
              let id = UUID(uuidString: text),
              let server = servers.first(where: { $0.id == id }),
              let saved = MARCCredentials.read(id) else { return }

        selectedID = id
        do {
            try await monitor.connect(
                server: server,
                password: saved.password,
                hostKey: saved.hostKey
            )
        } catch {
            // The monitor presents the connection error.
        }
    }
}


extension ServerStore {
    func switchToSavedServer(_ server: ServerProfile) async throws {
        guard !monitor.connecting else { return }
        guard servers.contains(where: { $0.id == server.id }) else { return }

        if monitor.connected && monitor.server?.id == server.id {
            selectedID = server.id
            return
        }

        guard let saved = MARCCredentials.read(server.id) else {
            throw NSError(domain: "MARC", code: 30, userInfo: [
                NSLocalizedDescriptionKey:
                    "Connect to this server once to remember its password."
            ])
        }

        selectedID = server.id
        UserDefaults.standard.set(
            server.id.uuidString, forKey: "marc.autoServer"
        )
        try await monitor.connect(
            server: server,
            password: saved.password,
            hostKey: saved.hostKey
        )
    }
}

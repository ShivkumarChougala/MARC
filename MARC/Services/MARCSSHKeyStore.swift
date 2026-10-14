import Foundation
import Security

enum MARCKeyStoreError: LocalizedError {
    case missing, storage(OSStatus), duplicate(String), invalidName, inUse

    var errorDescription: String? {
        switch self {
        case .missing:
            return "This SSH key is unavailable. Select a saved key in Settings → Keychain."
        case .storage(let status):
            return "Could not access SSH keys in Keychain (\(status))."
        case .duplicate(let name):
            return "This key is already saved as \(name)."
        case .invalidName:
            return "Give this key a name, using up to 80 characters."
        case .inUse:
            return "This key is used by a saved login. Change or remove that login first."
        }
    }
}

@MainActor enum MARCSSHKeyStore {
    struct Record: Codable {
        let id: UUID
        var name: String
        let privateKey: String
        let passphrase: String
        let publicKey: String
    }

    struct Info: Identifiable {
        let id: UUID
        let name: String
        let publicKey: String
    }

    private static let service = "MARC.namedSSHKeys.v1"

    private static func query(_ id: UUID? = nil) -> [String: Any] {
        var q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if let id { q[kSecAttrAccount as String] = id.uuidString }
        return q
    }

    static func read(_ id: UUID) throws -> Record {
        var q = query(id)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { throw MARCKeyStoreError.missing }
        guard status == errSecSuccess, let data = result as? Data else {
            throw MARCKeyStoreError.storage(status)
        }
        do { return try JSONDecoder().decode(Record.self, from: data) }
        catch { throw MARCKeyStoreError.storage(errSecDecode) }
    }

    static func entries() throws -> [Info] {
        var q = query()
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitAll
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let rows = result as? [Data] else {
            throw MARCKeyStoreError.storage(status)
        }
        return try rows.map {
            guard let r = try? JSONDecoder().decode(Record.self, from: $0) else {
                throw MARCKeyStoreError.storage(errSecDecode)
            }
            return Info(id: r.id, name: r.name, publicKey: r.publicKey)
        }.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func save(_ r: Record) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: try JSONEncoder().encode(r),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        var status = SecItemUpdate(
            query(r.id) as CFDictionary, attributes as CFDictionary
        )
        if status == errSecItemNotFound {
            var q = query(r.id)
            attributes.forEach { q[$0.key] = $0.value }
            status = SecItemAdd(q as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            throw MARCKeyStoreError.storage(status)
        }
    }

    static func add(
        name: String, privateKey: String, passphrase: String
    ) throws -> UUID {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 80 else {
            throw MARCKeyStoreError.invalidName
        }
        let publicKey = try MARCLogin.publicKey(.init(
            password: "", hostKey: "",
            privateKey: privateKey, passphrase: passphrase
        ))
        if let duplicate = try entries().first(where: {
            $0.publicKey == publicKey
        }) {
            throw MARCKeyStoreError.duplicate(duplicate.name)
        }
        let id = UUID()
        try save(Record(id: id, name: name, privateKey: privateKey,
                        passphrase: passphrase, publicKey: publicKey))
        return id
    }

    static func rename(_ id: UUID, name: String) throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 80 else {
            throw MARCKeyStoreError.invalidName
        }
        var r = try read(id)
        r.name = name
        try save(r)
    }

    static func users(_ id: UUID, servers: [ServerProfile]) throws -> Int {
        var count = 0
        for server in servers {
            if try MARCCredentials.readChecked(server.id)?.keyID == id {
                count += 1
            }
        }
        return count
    }

    static func remove(_ id: UUID, servers: [ServerProfile]) throws {
        guard try users(id, servers: servers) == 0 else {
            throw MARCKeyStoreError.inUse
        }
        let status = SecItemDelete(query(id) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw MARCKeyStoreError.storage(status)
        }
    }

    static func migrate(_ servers: [ServerProfile]) throws {
        for server in servers {
            guard let saved = MARCCredentials.read(server.id),
                  saved.keyID == nil,
                  let privateKey = saved.privateKey,
                  !privateKey.isEmpty else { continue }

            let publicKey = try MARCLogin.publicKey(saved)
            let found = try entries().first { $0.publicKey == publicKey }
            let id: UUID
            if let found {
                id = found.id
            } else {
                id = try add(
                    name: String("\(server.name) · \(server.username)".prefix(80)),
                    privateKey: privateKey,
                    passphrase: saved.passphrase ?? ""
                )
            }

            // Store the reusable key before replacing the old login.
            try MARCCredentials.save(
                server.id,
                login: .init(password: "", hostKey: saved.hostKey, keyID: id),
                hostKey: saved.hostKey
            )
        }
    }

    static func loginName(_ saved: MARCCredentials.Saved?) -> String {
        if let id = saved?.keyID, let r = try? read(id) {
            return "Key · \(r.name)"
        }
        return "SSH key saved"
    }
}

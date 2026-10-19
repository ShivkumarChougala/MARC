import Foundation
import Security

enum MARCAPIKeyError: LocalizedError {
    case invalidName, invalidEndpoint, invalidSecret, duplicate, missing, destination, migrationConflict, storage(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidName: return "Enter a name using up to 80 characters."
        case .invalidEndpoint: return "Enter a valid HTTPS chat completions endpoint."
        case .invalidSecret: return "Enter an API key without spaces or control characters (up to 16 KB)."
        case .duplicate: return "An API key already uses this name. Choose another name."
        case .missing: return "This API key is unavailable. Select a saved key in Terminal & AI settings."
        case .destination: return "This key belongs to another endpoint. Select a matching key in Terminal & AI settings."
        case .migrationConflict: return "The previous API key differs from its saved copy. Both copies were preserved."
        case .storage(let status): return "Could not access API keys in Keychain (\(status))."
        }
    }
}

@MainActor enum MARCAPIKeyStore {
    struct Record: Codable {
        let id: UUID
        var name: String
        let endpoint: String
        let secret: String
    }

    struct Info: Identifiable {
        let id: UUID
        let name: String
        let endpoint: String
        var host: String { URL(string: endpoint)?.host ?? endpoint }
    }

    static let revisionKey = "marc.ai.keysRevision"
    private static let service = "MARC.namedAPIKeys.v1"
    private static let legacyID = UUID(uuidString: "8769682D-2807-4706-81D8-28512948AB21")!

    static func destination(_ text: String) throws -> String {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.utf8.count <= 2048, let url = URL(string: value),
              url.scheme?.lowercased() == "https", let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil, url.fragment == nil,
              !value.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.contains($0) || CharacterSet.controlCharacters.contains($0) }) else {
            throw MARCAPIKeyError.invalidEndpoint
        }
        return value
    }

    private static func query(_ id: UUID? = nil) -> [String: Any] {
        var result: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service]
        if let id { result[kSecAttrAccount as String] = id.uuidString }
        return result
    }

    private static func read(_ id: UUID) throws -> Record {
        var q = query(id)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { throw MARCAPIKeyError.missing }
        guard status == errSecSuccess, let data = result as? Data else {
            throw MARCAPIKeyError.storage(status)
        }
        guard let record = try? JSONDecoder().decode(Record.self, from: data), record.id == id else {
            throw MARCAPIKeyError.storage(errSecDecode)
        }
        return record
    }

    static func entries() throws -> [Info] {
        var q = query()
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitAll
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let rows = result as? [Data] else {
            throw MARCAPIKeyError.storage(status)
        }
        return try rows.map { data in
            guard let record = try? JSONDecoder().decode(Record.self, from: data) else {
                throw MARCAPIKeyError.storage(errSecDecode)
            }
            return Info(id: record.id, name: record.name, endpoint: record.endpoint)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func save(_ record: Record) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: try JSONEncoder().encode(record),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        var status = SecItemUpdate(query(record.id) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var q = query(record.id)
            attributes.forEach { q[$0.key] = $0.value }
            status = SecItemAdd(q as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw MARCAPIKeyError.storage(status) }
        changed()
    }

    private static func changed() {
        UserDefaults.standard.set(UUID().uuidString, forKey: revisionKey)
    }

    static func add(name: String, endpoint: String, secret: String) throws -> UUID {
        let name = try checkedName(name)
        let endpoint = try destination(endpoint)
        let secret = try checkedSecret(secret)
        let id = UUID()
        try save(Record(id: id, name: name, endpoint: endpoint, secret: secret))
        return id
    }

    private static func checkedSecret(_ text: String) throws -> String {
        let secret = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !secret.isEmpty, secret.utf8.count <= 16384,
              secret.unicodeScalars.allSatisfy({ $0.value >= 33 && $0.value <= 126 }) else {
            throw MARCAPIKeyError.invalidSecret
        }
        return secret
    }

    private static func checkedName(_ value: String, excluding id: UUID? = nil) throws -> String {
        let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 80,
              !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
            throw MARCAPIKeyError.invalidName
        }
        let duplicate = try entries().contains(where: { $0.id != id && $0.name.caseInsensitiveCompare(name) == .orderedSame })
        guard !duplicate else {
            throw MARCAPIKeyError.duplicate
        }
        return name
    }

    static func rename(_ id: UUID, name: String) throws {
        var record = try read(id)
        record.name = try checkedName(name, excluding: id)
        try save(record)
    }

    static func secret(selection: String, endpoint: String) throws -> String {
        // An explicit empty selection supports providers that do not require a key.
        guard !selection.isEmpty else {
            guard try MARCCredentials.readChecked(legacyID)?.password.isEmpty != false else {
                throw MARCAPIKeyError.missing
            }
            return ""
        }
        guard let id = UUID(uuidString: selection) else { throw MARCAPIKeyError.missing }
        let record = try read(id)
        guard record.endpoint == (try destination(endpoint)) else { throw MARCAPIKeyError.destination }
        return try checkedSecret(record.secret)
    }

    static func remove(_ id: UUID) throws {
        if id == legacyID { try MARCCredentials.removeChecked(legacyID) }
        let status = SecItemDelete(query(id) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw MARCAPIKeyError.storage(status)
        }
        if UserDefaults.standard.string(forKey: "marc.ai.apiKeyID") == id.uuidString {
            // Keep a missing selection rather than silently sending a keyless request.
            UserDefaults.standard.set("removed:\(id.uuidString)", forKey: "marc.ai.apiKeyID")
        }
        changed()
    }

    static func migrateLegacy(endpoint: String) throws -> Info? {
        guard let legacy = try MARCCredentials.readChecked(legacyID), !legacy.password.isEmpty else { return nil }
        let endpoint = try destination(endpoint)
        let record: Record
        do { record = try read(legacyID) }
        catch MARCAPIKeyError.missing {
            // A stable ID makes retrying a failed legacy deletion safe.
            let existing = try entries()
            var name = "Previous API key"
            var suffix = 2
            while existing.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                name = "Previous API key \(suffix)"; suffix += 1
            }
            record = Record(id: legacyID, name: name, endpoint: endpoint, secret: try checkedSecret(legacy.password))
            try save(record)
        }
        guard record.secret == (try checkedSecret(legacy.password)) else {
            throw MARCAPIKeyError.migrationConflict
        }
        // Only remove the old copy after the reusable record is stored successfully.
        try MARCCredentials.removeChecked(legacyID)
        return Info(id: record.id, name: record.name, endpoint: record.endpoint)
    }
}

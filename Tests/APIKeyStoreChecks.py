#!/usr/bin/env python3
"""Compile production API-key storage against isolated in-memory Security doubles.
No real Keychain, preferences or network access.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
production = (root / 'MARC/Services/MARCAPIKeyStore.swift').read_text()
production = production.replace('import Security', '').replace('UserDefaults.standard', 'FixtureDefaults.value')
settings = (root / 'MARC/Screens/MARCTerminalAI.swift').read_text()
selection_methods = settings[settings.index('    private func selectAPIKey('):settings.index('    private func loadAPIKeys(')].replace('private func ', 'func ')
selection_harness = '''
@MainActor final class SelectionHarness {
    var endpoint = ""
    var selectedAPIKey = ""
    var apiModel = ""
    var notice: String?
    var apiKeys: [MARCAPIKeyStore.Info] = []
''' + selection_methods + '\n}\n'

support = r'''
import Foundation
typealias OSStatus = Int32
typealias CFDictionary = [String: Any]
typealias CFTypeRef = AnyObject
let kSecClass = "class", kSecClassGenericPassword = "generic"
let kSecAttrService = "service", kSecAttrAccount = "account"
let kSecReturnData = "return", kSecMatchLimit = "limit"
let kSecMatchLimitOne = "one", kSecMatchLimitAll = "all"
let kSecValueData = "data", kSecAttrAccessible = "accessible"
let kSecAttrAccessibleWhenUnlockedThisDeviceOnly = "device-unlocked"
let errSecSuccess: OSStatus = 0, errSecItemNotFound: OSStatus = -25300
let errSecDecode: OSStatus = -26275, failure: OSStatus = -50
enum FixtureError: Error { case expected }
@MainActor enum FixtureDefaults {
    static let name = "MARC.APIKeyChecks.\(UUID().uuidString)"
    static let value = UserDefaults(suiteName: name)!
}
@MainActor enum MemoryKeychain {
    static var rows: [String: [String: Any]] = [:]
    static var readFails = false, writeFails = false, deleteFails = false
    static func address(_ q: CFDictionary) -> String {
        "\(q[kSecAttrService] as? String ?? "")/\(q[kSecAttrAccount] as? String ?? "")"
    }
}
@MainActor func SecItemCopyMatching(_ q: CFDictionary, _ result: inout CFTypeRef?) -> OSStatus {
    if MemoryKeychain.readFails { return failure }
    if q[kSecMatchLimit] as? String == kSecMatchLimitAll {
        let rows = MemoryKeychain.rows.values.filter {
            $0[kSecAttrService] as? String == q[kSecAttrService] as? String
        }.compactMap { $0[kSecValueData] as? Data }
        if rows.isEmpty { return errSecItemNotFound }
        result = rows as NSArray
    } else {
        guard let row = MemoryKeychain.rows[MemoryKeychain.address(q)],
              let data = row[kSecValueData] as? Data else { return errSecItemNotFound }
        result = data as NSData
    }
    return errSecSuccess
}
@MainActor func SecItemUpdate(_ q: CFDictionary, _ attributes: CFDictionary) -> OSStatus {
    if MemoryKeychain.writeFails { return failure }
    let address = MemoryKeychain.address(q)
    guard var row = MemoryKeychain.rows[address] else { return errSecItemNotFound }
    attributes.forEach { row[$0.key] = $0.value }; MemoryKeychain.rows[address] = row
    return errSecSuccess
}
@MainActor func SecItemAdd(_ q: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
    if MemoryKeychain.writeFails { return failure }
    MemoryKeychain.rows[MemoryKeychain.address(q)] = q
    return errSecSuccess
}
@MainActor func SecItemDelete(_ q: CFDictionary) -> OSStatus {
    if MemoryKeychain.deleteFails { return failure }
    return MemoryKeychain.rows.removeValue(forKey: MemoryKeychain.address(q)) == nil ? errSecItemNotFound : errSecSuccess
}
@MainActor enum MARCCredentials {
    struct Saved { let password: String }
    static var legacy: Saved?
    static var deleteFails = false, readFails = false
    static func readChecked(_ id: UUID) throws -> Saved? {
        if readFails { throw FixtureError.expected }; return legacy
    }
    static func removeChecked(_ id: UUID) throws {
        if deleteFails { throw FixtureError.expected }; legacy = nil
    }
}
'''

checks = r'''
@main struct APIKeyChecks {
    @MainActor static func rejects(_ operation: () throws -> Void) {
        do { try operation(); preconditionFailure("Expected rejection") } catch {}
    }
    @MainActor static func main() throws {
        defer { FixtureDefaults.value.removePersistentDomain(forName: FixtureDefaults.name) }
        let endpoint = "https://api.example.invalid/v1/chat/completions"
        precondition(try MARCAPIKeyStore.entries().isEmpty)
        precondition(try MARCAPIKeyStore.secret(selection: "", endpoint: endpoint) == "")
        let first = try MARCAPIKeyStore.add(name: " Personal ", endpoint: endpoint, secret: "fixture-key")
        let second = try MARCAPIKeyStore.add(name: "Work", endpoint: endpoint, secret: "other-key")
        let infos = try MARCAPIKeyStore.entries()
        precondition(infos.count == 2 && infos.first?.name == "Personal")
        precondition(try MARCAPIKeyStore.secret(selection: first.uuidString, endpoint: endpoint) == "fixture-key")
        for row in MemoryKeychain.rows.values {
            precondition(row[kSecAttrAccessible] as? String == kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        }
        rejects { _ = try MARCAPIKeyStore.secret(selection: first.uuidString, endpoint: endpoint + "/other") }
        rejects { _ = try MARCAPIKeyStore.secret(selection: first.uuidString, endpoint: "https://other.invalid") }
        rejects { _ = try MARCAPIKeyStore.secret(selection: "missing", endpoint: endpoint) }
        rejects { _ = try MARCAPIKeyStore.add(name: "personal", endpoint: endpoint, secret: "x") }
        rejects { _ = try MARCAPIKeyStore.add(name: "", endpoint: endpoint, secret: "x") }
        for bad in ["http://example.invalid", "https://user:pass@example.invalid", "https://example.invalid/#fragment", "https://example.invalid/a b"] {
            rejects { _ = try MARCAPIKeyStore.add(name: "Invalid", endpoint: bad, secret: "x") }
        }
        for bad in ["", "line\nbreak", "with space", String(repeating: "a", count: 16385)] {
            rejects { _ = try MARCAPIKeyStore.add(name: "Invalid", endpoint: endpoint, secret: bad) }
        }
        let revision = FixtureDefaults.value.string(forKey: MARCAPIKeyStore.revisionKey)
        try MARCAPIKeyStore.rename(first, name: "Renamed")
        precondition(FixtureDefaults.value.string(forKey: MARCAPIKeyStore.revisionKey) != revision)
        precondition(try MARCAPIKeyStore.secret(selection: first.uuidString, endpoint: endpoint) == "fixture-key")
        rejects { try MARCAPIKeyStore.rename(first, name: "Work") }
        MemoryKeychain.writeFails = true
        rejects { try MARCAPIKeyStore.rename(first, name: "Lost") }
        MemoryKeychain.writeFails = false
        precondition(try MARCAPIKeyStore.entries().contains { $0.name == "Renamed" })
        FixtureDefaults.value.set(first.uuidString, forKey: "marc.ai.apiKeyID")
        MemoryKeychain.deleteFails = true
        rejects { try MARCAPIKeyStore.remove(first) }
        precondition(FixtureDefaults.value.string(forKey: "marc.ai.apiKeyID") == first.uuidString)
        MemoryKeychain.deleteFails = false
        try MARCAPIKeyStore.remove(first)
        let removed = FixtureDefaults.value.string(forKey: "marc.ai.apiKeyID")!
        precondition(removed.hasPrefix("removed:"))
        rejects { _ = try MARCAPIKeyStore.secret(selection: removed, endpoint: endpoint) }
        precondition(try MARCAPIKeyStore.secret(selection: second.uuidString, endpoint: endpoint) == "other-key")
        MemoryKeychain.readFails = true
        rejects { _ = try MARCAPIKeyStore.entries() }
        MemoryKeychain.readFails = false
        MARCCredentials.legacy = .init(password: "legacy-key")
        rejects { _ = try MARCAPIKeyStore.secret(selection: "", endpoint: endpoint) }
        rejects { _ = try MARCAPIKeyStore.migrateLegacy(endpoint: "") }
        precondition(MARCCredentials.legacy != nil)
        MemoryKeychain.writeFails = true
        rejects { _ = try MARCAPIKeyStore.migrateLegacy(endpoint: endpoint) }
        MemoryKeychain.writeFails = false
        precondition(MARCCredentials.legacy != nil)
        MARCCredentials.deleteFails = true
        rejects { _ = try MARCAPIKeyStore.migrateLegacy(endpoint: endpoint) }
        let count = try MARCAPIKeyStore.entries().count
        precondition(MARCCredentials.legacy != nil)
        MARCCredentials.deleteFails = false
        let migrated = try MARCAPIKeyStore.migrateLegacy(endpoint: "https://changed.invalid/chat")!
        precondition(try MARCAPIKeyStore.entries().count == count)
        precondition(migrated.endpoint == endpoint && MARCCredentials.legacy == nil)
        precondition(try MARCAPIKeyStore.secret(selection: migrated.id.uuidString, endpoint: endpoint) == "legacy-key")
        precondition(try MARCAPIKeyStore.migrateLegacy(endpoint: endpoint) == nil)
        MARCCredentials.legacy = .init(password: "different-legacy-key")
        rejects { _ = try MARCAPIKeyStore.migrateLegacy(endpoint: endpoint) }
        precondition(MARCCredentials.legacy?.password == "different-legacy-key")
        precondition(try MARCAPIKeyStore.secret(selection: migrated.id.uuidString, endpoint: endpoint) == "legacy-key")
        precondition(!String(describing: FixtureDefaults.value.dictionaryRepresentation()).contains("legacy-key"))
        print("PASS: named API keys, endpoint binding, validation, rename/delete failures and safe legacy migration")
        let selection = SelectionHarness()
        let a = MARCAPIKeyStore.Info(id: UUID(), name: "First", endpoint: endpoint)
        let b = MARCAPIKeyStore.Info(id: UUID(), name: "Second", endpoint: endpoint)
        let c = MARCAPIKeyStore.Info(id: UUID(), name: "Other provider", endpoint: "https://other.invalid/chat")
        selection.apiKeys = [a, b, c]
        selection.apiModel = "previous-provider-model"
        selection.selectAPIKey(a)
        precondition(selection.endpoint == endpoint && selection.selectedAPIKey == a.id.uuidString && selection.apiModel.isEmpty)
        selection.validateAPISelection()
        precondition(selection.selectedAPIKey == a.id.uuidString)
        selection.apiModel = "current-model"
        selection.selectAPIKey(b)
        precondition(selection.apiModel == "current-model" && selection.selectedAPIKey == b.id.uuidString)
        selection.selectAPIKey(c)
        precondition(selection.endpoint == c.endpoint && selection.apiModel.isEmpty)
        selection.endpoint = "https://manual.invalid/chat"
        selection.validateAPISelection()
        precondition(selection.selectedAPIKey.isEmpty)
        print("PASS: key-first selection fills empty endpoints, survives UI validation and clears models only across endpoints")
    }
}
'''

def fixture_source():
    # precondition's autoclosure cannot throw: evaluate checks in a throwing helper.
    code = checks.replace('precondition(try ', 'verify(try ')
    code = code.replace('    @MainActor static func main()', '    static func verify(_ condition: Bool) { precondition(condition) }\n    @MainActor static func main()')
    return support + production + selection_harness + code

def main():
    compiler = shutil.which('swiftc')
    if not compiler:
        raise SystemExit('Swift is required. Run API key checks on your Mac.')
    with tempfile.TemporaryDirectory(prefix='marc-api-keys-') as folder:
        folder = Path(folder)
        source = folder / 'APIKeyChecks.swift'
        source.write_text(fixture_source())
        binary = folder / 'checks'
        subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(source), '-o', str(binary)], check=True)
        subprocess.run([str(binary)], check=True, timeout=30)

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Run actual saved-profile and screen action code with in-memory Keychain/SSH doubles."""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
store = (root / 'MARC/Models/ServerStore.swift').read_text()
settings = (root / 'MARC/Screens/SettingsScreen.swift').read_text()
add = (root / 'MARC/Screens/ServersScreen.swift').read_text()
connect = (root / 'MARC/Screens/SSHConnectScreen.swift').read_text()
test = (root / 'MARC/Screens/SSHTestScreen.swift').read_text()
draft = (root / 'MARC/Components/MARCLoginFields.swift').read_text()
identity = (root / 'MARC/Services/HostKeyIdentity.swift').read_text()
store_class = store[:store.index('enum MARCCredentials {')].replace('import Security\n', '').replace('import Observation\n', '').replace('@Observable ', '')
extensions = store[store.index('extension ServerStore {'):]
saved_type = store[store.index('    struct Saved:'):store.index('    private static let service')]
draft_type = draft[draft.index('struct MARCLoginDraft {'):draft.index('struct MARCLoginFields:')]
endpoint = identity[identity.index('    static func endpoint('):identity.index('    /// Accept')]
sections = settings[settings.index('private enum MARCSettingsSection:'):settings.index('private struct MARCSettingsCustomizeSheet:')]
edit = settings[settings.index('private struct MARCEditServerScreen:'):settings.index('private struct MARCRemoveServerSheet:')]
edit_valid = edit[edit.index('    private var valid:'):edit.index(r'    @Environment(\.colorScheme)')]
edit_methods = edit[edit.index('    private func existingKey('):edit.rfind('\n}')].replace('private func ', 'func ')
add_methods = add[add.index('    private func saveAndConnect('):add.rfind('\n}')].replace('private func ', 'func ')
connect_methods = connect[connect.index('    private func startTest('):connect.rfind('\n}')].replace('private func ', 'func ')
test_methods = test[test.index('    private func run(authenticate:'):test.index('\n}\n\n@MainActor')].replace('private func ', 'func ')

support = r'''
enum FixtureError: Error { case storage, authentication }
@MainActor enum MARCCredentials {
    __SAVED__
    static var items: [UUID: Saved] = [:]
    static var readFails = false
    static var deleteFails = false
    static var writes = 0
    static func readChecked(_ id: UUID) throws -> Saved? {
        if readFails { throw FixtureError.storage }; return items[id]
    }
    static func read(_ id: UUID) -> Saved? { try? readChecked(id) }
    static func removeChecked(_ id: UUID) throws {
        if deleteFails { throw FixtureError.storage }; items[id] = nil
    }
    static func save(_ id: UUID, login: Saved, hostKey: String) throws {
        writes += 1; items[id] = login
    }
}
enum HostKeyIdentity { __ENDPOINT__ }
struct MARCConnectionIssue {
    var canRetry = true
    static func message(_ error: Error, login: MARCCredentials.Saved?) -> String { "Fixture failure" }
}
@MainActor final class Gate {
    var entered = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; await withCheckedContinuation { continuation = $0 } }
    func open() { continuation?.resume(); continuation = nil }
}
@MainActor final class SSHMonitor {
    var server: ServerProfile?
    var connected = false
    var connecting = false
    var automaticReconnectEnabled = true
    var connectionIssue: MARCConnectionIssue?
    var calls = 0
    var cancellations = 0
    func connect(server: ServerProfile, login: MARCCredentials.Saved, hostKey: String) async throws {
        try Task.checkCancellation()
        calls += 1; self.server = server; connected = true
        try MARCCredentials.save(server.id, login: login, hostKey: hostKey)
    }
    func cancelConnection() { cancellations += 1; connected = false; server = nil }
}
@MainActor final class MARCHostTrust {
    var calls = 0
    var hook: (() async throws -> Void)?
    func keyForConnection(server: ServerProfile, existingKey: String = "") async throws -> String {
        calls += 1
        if let hook { try await hook() }
        return "fixture key"
    }
    func cancel() {}
}
@MainActor enum SSHConnectionTest {
    struct Result { let output = "Fixture output" }
    static var calls = 0
    static var hook: (() async throws -> Void)?
    static func run(server: ServerProfile, login: MARCCredentials.Saved, publicHostKey: String) async throws -> Result {
        calls += 1
        if let hook { try await hook() }
        return Result()
    }
    static func hostKeyValidator(server: ServerProfile, publicHostKey: String) throws -> String { publicHostKey }
}
@MainActor enum MARCPortProbe {
    static var calls = 0
    static var hook: (() async -> Void)?
    static func check(host: String, port: Int) async throws -> Double {
        calls += 1; if let hook { await hook() }; return 10
    }
}
@MainActor final class EditFixture {
    let store: ServerStore
    let server: ServerProfile
    var name: String
    var host: String
    var port: String
    var username: String
    var loginDraft = MARCLoginDraft()
    var hostKey = "fixture key"
    var loaded = true
    var busy = false
    var failure: String?
    var testMessage: String?
    var requestTask: Task<Void, Never>?
    var requestID = UUID()
    let trust = MARCHostTrust()
    var dismissed = false
    init(_ store: ServerStore, _ server: ServerProfile) {
        self.store = store; self.server = server
        name = server.name; host = server.host; port = String(server.port); username = server.username
        loginDraft.password = "fixture password"
    }
    func dismiss() { dismissed = true }
    __EDIT_VALID__
    __EDIT_METHODS__
}
@MainActor final class AddFixture {
    let store: ServerStore
    var name = "New Mac"
    var host = "new.invalid"
    var port = "22"
    var username = "fixture"
    var loginDraft = MARCLoginDraft()
    var pending: ServerProfile?
    var busy = false
    var valid = true
    var failure: String?
    var requestTask: Task<Void, Never>?
    var requestID = UUID()
    let trust = MARCHostTrust()
    var dismissed = false
    var openedID: UUID?
    init(_ store: ServerStore) { self.store = store; loginDraft.password = "fixture password" }
    func dismiss() { dismissed = true }
    func openSaved(_ server: ServerProfile) { openedID = server.id }
    __ADD_METHODS__
}
@MainActor final class ConnectFixture {
    let server: ServerProfile
    let monitor: SSHMonitor
    var loginDraft = MARCLoginDraft()
    var publicHostKey = "fixture key"
    var testing = false
    var loaded = true
    var failure: String?
    var requestTask: Task<Void, Never>?
    var requestID = UUID()
    let trust = MARCHostTrust()
    var dismissed = false
    init(_ monitor: SSHMonitor, _ server: ServerProfile) {
        self.monitor = monitor; self.server = server; loginDraft.password = "fixture password"
    }
    func dismiss() { dismissed = true }
    __CONNECT_METHODS__
}
@MainActor final class TestFixture {
    let server: ServerProfile
    var loginDraft = MARCLoginDraft()
    var hostKey = "fixture key"
    var busy = false
    var failure: String?
    var latency: Double?
    var output: String?
    var requestTask: Task<Void, Never>?
    var requestID = UUID()
    let trust = MARCHostTrust()
    init(_ server: ServerProfile) { self.server = server; loginDraft.password = "fixture password" }
    __TEST_METHODS__
}
'''
for token, value in {'__SAVED__': saved_type, '__ENDPOINT__': endpoint,
                     '__EDIT_VALID__': edit_valid, '__EDIT_METHODS__': edit_methods,
                     '__ADD_METHODS__': add_methods, '__CONNECT_METHODS__': connect_methods,
                     '__TEST_METHODS__': test_methods}.items():
    support = support.replace(token, value)

checks = r'''
@main struct SettingsChecks {
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<10000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Fixture did not reach its gate")
    }
    @MainActor static func main() async throws {
        let defaults = UserDefaults.standard
        let keys = ["marc.serverProfiles.v1", "marc.autoServer"]
        let originals = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, originals) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        keys.forEach { defaults.removeObject(forKey: $0) }
        let a = ServerProfile(name: "A", host: "a.invalid", port: 22, username: "alice")
        let b = ServerProfile(name: "B", host: "b.invalid", port: 22, username: "bob")
        let login = MARCCredentials.Saved(password: "fixture password", hostKey: "fixture key")
        let store = ServerStore(); store.add(a); store.add(b)
        MARCCredentials.items[a.id] = login; MARCCredentials.items[b.id] = login
        precondition(ServerStore().servers == [a, b], "Saved profiles must round-trip")
        defaults.set(Data("invalid profiles".utf8), forKey: keys[0])
        precondition(ServerStore().storageError != nil)
        store.update(a)
        precondition(MARCSettingsSection.ordered("general,general,unknown").map(\.rawValue) ==
                     ["general", "servers", "security", "terminal", "support"])

        store.monitor.server = a; store.monitor.connected = true; store.selectedID = b.id
        let editB = EditFixture(store, b); editB.name = "Renamed B"
        editB.save(); let editTask = editB.requestTask; await editTask?.value
        precondition(editB.dismissed && store.servers.last?.name == "Renamed B")
        precondition(store.monitor.server?.id == a.id && store.monitor.calls == 0,
                     "Selected offline profile must not replace another active Mac")

        let currentB = store.servers.last!
        let duplicate = EditFixture(store, currentB)
        duplicate.host = " A.INVALID. "; duplicate.username = "alice"
        duplicate.save()
        precondition(duplicate.failure != nil && duplicate.requestTask == nil)
        let staleEditor = EditFixture(store, b); staleEditor.save()
        precondition(staleEditor.failure != nil)

        let queued = EditFixture(store, currentB); queued.save()
        let queuedTask = queued.requestTask; queued.stopRequest(); await queuedTask?.value
        precondition(!queued.dismissed && queued.trust.calls == 0 && !queued.busy)

        let delayed = EditFixture(store, currentB); delayed.name = "Must not save"
        let gate = Gate(); SSHConnectionTest.hook = { await gate.wait() }
        delayed.save(); let delayedTask = delayed.requestTask
        await waitFor { gate.entered }
        let writes = MARCCredentials.writes
        delayed.stopRequest(); gate.open(); await delayedTask?.value
        precondition(!delayed.dismissed && MARCCredentials.writes == writes && store.servers.last == currentB)
        SSHConnectionTest.hook = nil

        MARCCredentials.readFails = true
        let unreadable = EditFixture(store, currentB); unreadable.save()
        precondition(unreadable.failure != nil && unreadable.requestTask == nil)
        do { try await store.switchToSavedServer(currentB); preconditionFailure("Expected Keychain error") }
        catch FixtureError.storage {}
        MARCCredentials.readFails = false

        MARCCredentials.deleteFails = true
        defaults.set(a.id.uuidString, forKey: "marc.autoServer")
        precondition(!store.remove(a) && store.servers.contains(a))
        precondition(store.monitor.connected && MARCCredentials.items[a.id] != nil && store.storageError != nil)
        precondition(defaults.string(forKey: "marc.autoServer") == a.id.uuidString)
        MARCCredentials.deleteFails = false
        precondition(store.remove(a) && !store.monitor.connected && MARCCredentials.items[a.id] == nil)
        precondition(defaults.string(forKey: "marc.autoServer") == nil && store.selectedID == b.id)

        var updatedB = currentB; updatedB.host = "updated.invalid"; store.update(updatedB)
        try await store.switchToSavedServer(b)
        precondition(store.monitor.server?.host == updatedB.host, "Queued switch must use current profile")
        let activeEdit = EditFixture(store, updatedB); activeEdit.name = "Active B"
        let activeCalls = store.monitor.calls
        activeEdit.save(); let activeTask = activeEdit.requestTask; await activeTask?.value
        precondition(activeEdit.dismissed && store.monitor.calls == activeCalls + 1)
        let before = store.monitor.calls
        let cancelled = Task { @MainActor in try await store.switchToSavedServer(updatedB) }
        cancelled.cancel(); _ = await cancelled.result
        precondition(store.monitor.calls == before)

        let add = AddFixture(store); add.saveAndConnect(); let addTask = add.requestTask
        add.stopRequest(); await addTask?.value
        precondition(add.trust.calls == 0 && store.servers.count == 1)
        let successfulAdd = AddFixture(store); successfulAdd.saveAndConnect()
        let successTask = successfulAdd.requestTask; await successTask?.value
        precondition(successfulAdd.dismissed && successfulAdd.pending == nil && store.servers.count == 2)

        let connect = ConnectFixture(store.monitor, updatedB); connect.startTest()
        let connectTask = connect.requestTask; connect.stopRequest(); await connectTask?.value
        precondition(connect.trust.calls == 0 && !connect.dismissed)
        let probeGate = Gate(); MARCPortProbe.hook = { await probeGate.wait() }
        let test = TestFixture(updatedB); test.run(authenticate: true)
        let testTask = test.requestTask; await waitFor { probeGate.entered }
        test.stopRequest(); probeGate.open(); await testTask?.value
        precondition(test.latency == nil && test.output == nil && test.trust.calls == 0)
        print("PASS: saved profiles, Settings order, edit targeting, duplicates, Keychain failures and screen task cancellation")
    }
}
'''
compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('Swift compiler required. Run this check on your Mac.')
with tempfile.TemporaryDirectory(prefix='marc-settings-checks-') as directory:
    path = Path(directory) / 'SettingsChecks.swift'
    profile = (root / 'MARC/Models/ServerProfile.swift').read_text()
    path.write_text('import Foundation\n' + profile + support + store_class + extensions + draft_type + sections + checks)
    binary = Path(directory) / 'settings-checks'
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(path), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True, timeout=30)

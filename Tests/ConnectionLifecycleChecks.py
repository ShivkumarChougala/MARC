#!/usr/bin/env python3
"""Run production lifecycle methods with deterministic in-memory SSH doubles.
No SSH transport, remote commands, or Keychain operations are used.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
monitor = (root / 'MARC/Services/SSHMonitor.swift').read_text()
store = (root / 'MARC/Models/ServerStore.swift').read_text()
# Use production bodies verbatim. Fail if the source boundaries change.
prefix = monitor[:monitor.index('    private func publish(')]
prefix = prefix.replace('import Citadel\n', '').replace('import NIOCore\n', '')
archive = monitor[monitor.index('private struct MARCArchivePoint:'):monitor.index('struct MARCProcess:')]
remove = store[store.index('    func remove('):store.index('    func update(')]
extensions = store[store.index('extension ServerStore {'):]

support = r'''
struct ServerProfile: Equatable {
    let id: UUID
    var name = "Fixture"
    var host = "test.invalid"
    var port = 22
    var username = "fixture"
}
enum FixtureError: Error, Equatable { case expected, blocked }
struct FixtureBytes { var readableBytesView: [UInt8] }
enum FixtureEvent { case stdout(FixtureBytes), stderr(FixtureBytes) }
struct SSHClientSettings {
    let host: String
    let port: Int
    let authenticationMethod: String
    let hostKeyValidator: String
    var connectTimeout: Duration = .seconds(10)
}
@MainActor final class Gate {
    var entered = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async {
        entered = true
        await withCheckedContinuation { continuation = $0 }
    }
    func open() { continuation?.resume(); continuation = nil }
}
@MainActor final class SSHClient {
    static var attempts = 0
    static var latest: SSHClient?
    static var connectHook: (() async throws -> Void)?
    static var closeHook: (() async -> Void)?
    static var readHook: (() async throws -> String)?
    private var continuation: AsyncThrowingStream<FixtureEvent, Error>.Continuation?
    static func connect(to settings: SSHClientSettings) async throws -> SSHClient {
        attempts += 1
        if let hook = connectHook { try await hook() }
        let client = SSHClient()
        latest = client
        return client
    }
    func emitFixture(_ line: String) {
        continuation?.yield(.stdout(FixtureBytes(readableBytesView: Array((line + "\n").utf8))))
    }
    func endFixture() { continuation?.finish() }
    func executeCommandStream(_ command: String) async throws -> AsyncThrowingStream<FixtureEvent, Error> {
        AsyncThrowingStream { continuation = $0 }
    }
    func executeCommand(_ command: String, maxResponseSize: Int, mergeStreams: Bool) async throws -> FixtureBytes {
        let result = try await Self.readHook?() ?? "[]"
        return FixtureBytes(readableBytesView: Array(result.utf8))
    }
    func close() async throws {
        if let hook = Self.closeHook { await hook() }
        continuation?.finish()
        continuation = nil
    }
}
@MainActor enum MARCCredentials {
    struct Saved { let password: String; let hostKey: String }
    static var saved: [UUID: Saved] = [:]
    static func read(_ id: UUID) -> Saved? { saved[id] }
    static func readChecked(_ id: UUID) throws -> Saved? { saved[id] }
    static func removeChecked(_ id: UUID) throws { saved[id] = nil }
    static func remove(_ id: UUID) { saved[id] = nil }
    static func save(_ id: UUID, login: Saved, hostKey: String) throws { saved[id] = login }
}
struct MARCHostTrust {
    func keyForConnection(server: ServerProfile, existingKey: String) async throws -> String { existingKey }
}
enum SSHConnectionTest {
    static func hostKeyValidator(server: ServerProfile, publicHostKey: String) throws -> String { publicHostKey }
}
enum MARCLogin {
    static func authentication(_ login: MARCCredentials.Saved, username: String) throws -> String { "fixture" }
}
struct MARCConnectionIssue {
    enum Kind: Equatable { case session, unknown, login }
    let kind: Kind
    let title: String
    let detail: String
    var message: String { title + detail }
    var canRetry: Bool { kind != .login }
    static func classify(_ error: Error, login: MARCCredentials.Saved) -> Self {
        let blocked = (error as? FixtureError) == .blocked
        return Self(kind: blocked ? .login : .unknown, title: "Fixture failure", detail: "")
    }
}
'''

end_monitor = r'''
    private static let command = "fixture collector"
    private func publish(_ next: MacSnapshot) { snapshot = next }
}
extension SSHMonitor {
    func collectorTokenFixture() -> UUID { generation }
    func expireCollectorFixture(token: UUID, hasSample: Bool = false) {
        if generation == token {
            collectorHealth.start(at: 0)
            if hasSample { _ = collectorHealth.received(at: 1, publishInterval: 2) }
        }
        checkCollectorHealth(token: token, at: 100)
    }
    func seedHistoryFixture() {
        archivedHistory = [SystemHistoryPoint(date: Date(), load: nil, cpu: 1, memory: 2,
            download: nil, upload: nil, read: nil, write: nil)]
        archiveError = "Old connection error"
        processTotalCount = 42
    }
}
@MainActor final class ServerStore {
    let monitor = SSHMonitor()
    var servers: [ServerProfile] = []
    var selectedID: UUID?
    var storageError: String?
    private func persist() {}
'''

checks = r'''
@main struct ConnectionChecks {
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<10000 {
            if condition() { return }
            await Task.yield()
        }
        preconditionFailure("Fixture gate was never reached")
    }
    @MainActor static func main() async throws {
        let defaults = UserDefaults.standard
        let original = defaults.object(forKey: "marc.autoServer")
        defer {
            if let original { defaults.set(original, forKey: "marc.autoServer") }
            else { defaults.removeObject(forKey: "marc.autoServer") }
        }
        let a = ServerProfile(id: UUID())
        let b = ServerProfile(id: UUID())
        let login = MARCCredentials.Saved(password: "fixture", hostKey: "fixture")
        let store = ServerStore()
        store.servers = [a, b]
        MARCCredentials.saved[a.id] = login
        MARCCredentials.saved[b.id] = login
        try await store.monitor.connect(server: a, login: login, hostKey: login.hostKey)
        precondition(store.monitor.connected && defaults.string(forKey: "marc.autoServer") == a.id.uuidString)

        store.monitor.cancelConnection()
        precondition(!store.monitor.connected && !store.monitor.connecting && !store.monitor.automaticReconnectEnabled)
        let before = SSHClient.attempts
        await store.reconnectRememberedServer()
        precondition(SSHClient.attempts == before, "Explicit disconnect must pause automatic reconnect")
        store.monitor.cancelConnection(reconnectAutomatically: store.monitor.automaticReconnectEnabled)
        await store.reconnectRememberedServer()
        precondition(SSHClient.attempts == before, "Backgrounding must preserve an explicit pause")

        try await store.switchToSavedServer(a)
        precondition(store.monitor.connected && store.monitor.automaticReconnectEnabled)
        store.monitor.cancelConnection(reconnectAutomatically: store.monitor.automaticReconnectEnabled)
        await store.reconnectRememberedServer()
        precondition(store.monitor.connected && SSHClient.attempts == before + 2)

        SSHClient.connectHook = { throw FixtureError.expected }
        do { try await store.switchToSavedServer(b); preconditionFailure("Expected connection failure") }
        catch FixtureError.expected {}
        SSHClient.connectHook = nil
        precondition(defaults.string(forKey: "marc.autoServer") == a.id.uuidString,
                     "A failed switch must preserve the last successful target")

        let gate = Gate()
        SSHClient.connectHook = { await gate.wait() }
        let pending = Task { try await store.switchToSavedServer(b) }
        await waitFor { gate.entered }
        precondition(store.monitor.server?.id == b.id && store.monitor.connecting)
        store.remove(b)
        precondition(!store.monitor.connecting && store.monitor.server == nil)
        gate.open()
        let result = await pending.result
        if case .success = result { preconditionFailure("Removed server connection must be rejected") }
        SSHClient.connectHook = nil
        precondition(MARCCredentials.read(b.id) == nil && !store.monitor.connected)

        try await store.switchToSavedServer(a)
        let closeGate = Gate()
        SSHClient.closeHook = { await closeGate.wait() }
        store.monitor.cancelConnection()
        await waitFor { closeGate.entered }
        SSHClient.closeHook = nil
        try await store.switchToSavedServer(a)
        closeGate.open()
        for _ in 0..<20 { await Task.yield() }
        precondition(store.monitor.connected, "Old transport cleanup must not disconnect the new session")

        store.monitor.seedHistoryFixture()
        store.monitor.cancelConnection()
        precondition(store.monitor.archivedHistory.isEmpty && store.monitor.archiveError == nil && store.monitor.processTotalCount == 0)

        // Both success and failure from an old same-server request must be ignored.
        for response in ["[]", "invalid JSON"] {
            try await store.switchToSavedServer(a)
            let readGate = Gate()
            SSHClient.readHook = { await readGate.wait(); return response }
            let oldRead = Task { await store.monitor.loadArchivedHistory(seconds: 900) }
            await waitFor { readGate.entered }
            store.monitor.cancelConnection()
            try await store.switchToSavedServer(a)
            store.monitor.seedHistoryFixture()
            readGate.open()
            await oldRead.value
            precondition(store.monitor.archivedHistory.count == 1 && store.monitor.archiveError == "Old connection error",
                         "Old archive results must not overwrite a new connection")
        }
        SSHClient.readHook = nil
        store.monitor.cancelConnection()

        try await store.switchToSavedServer(a)
        let oldToken = store.monitor.collectorTokenFixture()
        store.monitor.expireCollectorFixture(token: oldToken)
        precondition(!store.monitor.connected && !store.monitor.connecting)
        precondition(store.monitor.error?.contains("90 seconds") == true && store.monitor.connectionIssue?.canRetry == true)
        await store.reconnectRememberedServer()
        precondition(store.monitor.connected)
        store.monitor.expireCollectorFixture(token: oldToken)
        precondition(store.monitor.connected, "An old watchdog must not close the new connection")
        store.monitor.expireCollectorFixture(token: store.monitor.collectorTokenFixture(), hasSample: true)
        precondition(!store.monitor.connected && store.monitor.error?.contains("No valid readings") == true)

        try await store.switchToSavedServer(a)
        let sample = #"{"hostname":"Fixture","cpu":1,"memoryUsed":1,"memoryTotal":2,"diskUsed":1,"diskTotal":2,"diskAvailable":1,"sampledAt":100}"#
        SSHClient.latest?.emitFixture(sample)
        await waitFor { store.monitor.snapshot != nil }
        SSHClient.latest?.endFixture()
        await waitFor { !store.monitor.connected }
        precondition(store.monitor.snapshot != nil && store.monitor.error != nil,
                     "Collector EOF should preserve the last readings and end the live connection")

        try await store.switchToSavedServer(a)
        for _ in 0..<3 { SSHClient.latest?.emitFixture("invalid JSON") }
        await waitFor { !store.monitor.connected }
        precondition(store.monitor.error != nil)

        try await store.switchToSavedServer(a)
        store.servers.append(b)
        MARCCredentials.saved[b.id] = login
        SSHClient.connectHook = { throw FixtureError.blocked }
        do { try await store.switchToSavedServer(b); preconditionFailure("Expected failure") }
        catch FixtureError.blocked {}
        SSHClient.connectHook = nil
        let attempts = SSHClient.attempts
        await store.reconnectRememberedServer()
        precondition(SSHClient.attempts == attempts, "A nonretryable issue must require manual attention")
        try await store.switchToSavedServer(a)
        precondition(store.monitor.connected, "Manual retry must still work")
        SSHClient.readHook = nil
        store.monitor.cancelConnection()
        print("PASS: collector timeout, EOF, invalid output, retry eligibility and old watchdog checks")
        print("PASS: SSH lifecycle regression fixtures (manual stop, background resume, failed switch, removal, stale cleanup and archive results)")
    }
}
'''

compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('Swift compiler required. Run this check on your Mac.')
with tempfile.TemporaryDirectory(prefix='marc-connection-checks-') as directory:
    source = Path(directory) / 'ConnectionChecks.swift'
    health = (root / 'MARC/Services/MARCCollectorHealth.swift').read_text()
    source.write_text('import Foundation\nimport Observation\n' + support + health + prefix + end_monitor + remove + '\n}\n' + extensions + archive + checks)
    binary = Path(directory) / 'connection-checks'
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(source), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True, timeout=30)

#!/usr/bin/env python3
"""Exercise production trust-flow code with isolated probe/Keychain doubles.

The Swift harness runs on a Mac with Xcode command line tools. --source-only
checks integration here, without claiming that runtime checks passed.
"""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/MARCHostTrust.swift').read_text()
sheet = (root / 'MARC/Components/HostTrustSheet.swift').read_text()
probe = (root / 'MARC/Services/SSHHostKeyProbe.swift').read_text()
validator = (root / 'MARC/Services/SSHConnectionTest.swift').read_text()

# The visible approval owns one request; changing requests resets comparison UI.
assert 'approve: { trust.approve(requestID: request.id) }' in sheet
assert 'cancel: { trust.cancel(requestID: request.id) }' in sheet
assert '.id(request.id)' in sheet
assert 'serverAuthDelegate: ProbeHostKeyDelegate()' in probe
assert 'nextChallengePromise.succeed(nil)' in probe
assert 'validationCompletePromise.fail(HostKeyObserved(' in probe
assert 'validationCompletePromise.fail(HostTrustError.changed)' in validator
assert '.custom(MARCPinnedHostKeyDelegate(' in validator
for name in ('ServersScreen', 'SSHConnectScreen', 'SSHTestScreen', 'SettingsScreen'):
    assert '.hostTrustPrompt(trust)' in (root / f'MARC/Screens/{name}.swift').read_text()
print('PASS: visible trust-sheet integration, request ownership and fail-closed validator wiring', flush=True)

if '--source-only' in sys.argv:
    print('NOT RUN: Swift trust-flow runtime checks and iOS build (source-only mode)')
    raise SystemExit(0)
compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('NOT RUN: Swift is required for trust-flow runtime checks. Run on your Mac.')

request_type = source[source.index('struct HostTrustRequest:'):source.index('enum HostTrustError:')]
flow = source[source.index('private final class HostTrustCancellation:'):]
flow = flow.replace('@MainActor @Observable', '@MainActor').replace('@ObservationIgnored ', '')
profile = (root / 'MARC/Models/ServerProfile.swift').read_text()

support = r'''
enum FixtureError: Error { case storage, changed, malformed }
enum HostTrustError: Error { case approvalRequired }
@MainActor enum MARCHostTrustStore {
    static var keys: [String: String] = [:]
    static var failWrite = false
    static var writes = 0
    static func reset() { keys = [:]; failWrite = false; writes = 0 }
    static func endpoint(_ host: String, _ port: Int) -> String { "\(host):\(port)" }
    static func read(host: String, port: Int) throws -> String? { keys[endpoint(host, port)] }
    static func remember(host: String, port: Int, publicKey: String) throws {
        if failWrite { throw FixtureError.storage }
        let endpoint = endpoint(host, port)
        if let old = keys[endpoint], old != publicKey { throw FixtureError.changed }
        keys[endpoint] = publicKey
        writes += 1
    }
}
enum HostKeyIdentity {
    static func fingerprint(publicKey: String) throws -> String {
        guard publicKey.hasPrefix("ssh-ed25519 ") else { throw FixtureError.malformed }
        return "SHA256:fixture"
    }
}
@MainActor final class Gate {
    var entered = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; await withCheckedContinuation { continuation = $0 } }
    func open() { continuation?.resume(); continuation = nil }
}
@MainActor enum SSHHostKeyProbe {
    static var calls = 0
    static var hook: (() async throws -> String)?
    static func fetch(server: ServerProfile) async throws -> String {
        calls += 1
        if let hook { return try await hook() }
        return "ssh-ed25519 fixture"
    }
}
'''

checks = r'''
@main struct HostTrustChecks {
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<10000 {
            if condition() { return }
            await Task.yield()
        }
        preconditionFailure("Trust fixture did not reach the expected state")
    }
    @MainActor static func expectCancelled(_ task: Task<String, Error>) async {
        do { _ = try await task.value; preconditionFailure("Cancelled request returned a key") }
        catch { precondition(error is CancellationError) }
    }
    @MainActor static func main() async throws {
        let server = ServerProfile(name: "Fixture Mac", host: "mac.invalid", port: 22, username: "fixture")
        let other = ServerProfile(name: "Other Mac", host: "other.invalid", port: 22, username: "fixture")
        let key = "ssh-ed25519 fixture"
        MARCHostTrustStore.reset()
        let trust = MARCHostTrust()
        let initialProbes = SSHHostKeyProbe.calls
        do {
            _ = try await trust.keyForConnection(server: server, allowPrompt: false)
            preconditionFailure("Reconnect without a pin must fail instead of prompting")
        } catch { precondition(error is HostTrustError) }
        precondition(trust.request == nil && MARCHostTrustStore.writes == 0)
        precondition(SSHHostKeyProbe.calls == initialProbes)
        var authenticated = false
        let first = Task { @MainActor in
            let value = try await trust.keyForConnection(server: server)
            authenticated = true // models the caller proceeding to authentication
            return value
        }
        await waitFor { trust.request != nil }
        precondition(!authenticated && MARCHostTrustStore.writes == 0)
        let request = trust.request!
        precondition(request.host == server.host && request.port == server.port)
        precondition(request.publicKey == key && request.fingerprint == "SHA256:fixture")
        trust.approve(requestID: request.id)
        trust.approve(requestID: request.id) // duplicate approval must be harmless
        let approved = try await first.value
        precondition(approved == key && authenticated && trust.request == nil)
        precondition(MARCHostTrustStore.writes == 1)
        let probes = SSHHostKeyProbe.calls
        let saved = try await trust.keyForConnection(server: server)
        precondition(saved == key && SSHHostKeyProbe.calls == probes && trust.request == nil)

        MARCHostTrustStore.reset()
        let cancelled = Task { try await trust.keyForConnection(server: server) }
        await waitFor { trust.request != nil }
        let cancelledID = trust.request!.id
        trust.cancel(requestID: cancelledID)
        trust.approve(requestID: cancelledID)
        await expectCancelled(cancelled)
        precondition(MARCHostTrustStore.writes == 0 && trust.request == nil)

        let taskCancelled = Task { try await trust.keyForConnection(server: server) }
        await waitFor { trust.request != nil }
        let taskID = trust.request!.id
        taskCancelled.cancel()
        trust.approve(requestID: taskID) // even before actor cleanup gets to run
        await expectCancelled(taskCancelled)
        precondition(MARCHostTrustStore.writes == 0 && trust.request == nil)

        let older = Task { try await trust.keyForConnection(server: server) }
        await waitFor { trust.request != nil }
        let olderID = trust.request!.id
        let newer = Task { try await trust.keyForConnection(server: other) }
        await waitFor { trust.request?.host == other.host }
        await expectCancelled(older)
        older.cancel() // a delayed cancellation must not cancel the newer sheet
        trust.approve(requestID: olderID)
        trust.cancel(requestID: olderID)
        precondition(trust.request?.host == other.host && MARCHostTrustStore.writes == 0)
        trust.approve(requestID: trust.request!.id)
        _ = try await newer.value
        let absent = try MARCHostTrustStore.read(host: server.host, port: server.port)
        precondition(absent == nil)

        MARCHostTrustStore.reset()
        let failed = Task { try await trust.keyForConnection(server: server) }
        await waitFor { trust.request != nil }
        MARCHostTrustStore.failWrite = true
        trust.approve(requestID: trust.request!.id)
        do { _ = try await failed.value; preconditionFailure("Storage failure returned a key") }
        catch { precondition(error is FixtureError) }
        precondition(trust.request == nil && MARCHostTrustStore.writes == 0)

        MARCHostTrustStore.reset()
        let conflict = Task { try await trust.keyForConnection(server: server) }
        await waitFor { trust.request != nil }
        MARCHostTrustStore.keys["mac.invalid:22"] = "ssh-ed25519 different"
        trust.approve(requestID: trust.request!.id)
        do { _ = try await conflict.value; preconditionFailure("Conflicting pin overwritten") }
        catch { precondition(error is FixtureError) }
        precondition(MARCHostTrustStore.keys["mac.invalid:22"] == "ssh-ed25519 different")

        MARCHostTrustStore.reset()
        let gate = Gate()
        SSHHostKeyProbe.hook = { await gate.wait(); return key }
        let probing = Task { try await trust.keyForConnection(server: server) }
        await waitFor { gate.entered }
        probing.cancel()
        gate.open()
        await expectCancelled(probing)
        precondition(trust.request == nil && MARCHostTrustStore.writes == 0)
        SSHHostKeyProbe.hook = nil

        let legacy = try await trust.keyForConnection(server: server, existingKey: key)
        precondition(legacy == key && trust.request == nil)
        print("PASS: production trust flow: approval before authentication, saved pins, duplicate approval, cancellation, supersession, stale sheet actions, write failure, conflicting pins and legacy migration")
    }
}
'''

with tempfile.TemporaryDirectory(prefix='marc-host-trust-checks-') as directory:
    path = Path(directory)
    fixture = path / 'HostTrustChecks.swift'
    fixture.write_text(profile + '\n' + request_type + support + flow + checks)
    executable = path / 'host-trust-checks'
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(fixture), '-o', str(executable)], check=True)
    subprocess.run([str(executable)], check=True, timeout=30)

#!/usr/bin/env python3
"""Exercise the production platform probe and Swift gate without SSH or Keychain."""
from pathlib import Path
import argparse
import os
import re
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/SSHConnectionTest.swift').read_text()
platform = source[source.index('enum MARCPlatformError:'):source.index('/// One authenticated, read-only request.')]
command = re.search(r'static let command = """\n(.*?)\n    """', platform, re.S).group(1)
command = '\n'.join(line[4:] for line in command.splitlines()).replace('\\\\', '\\')
run = source[source.index('    static func run('):source.index('    /// Discovery supplies')]
# Read-only probe fixtures include non-macOS Darwin systems and restricted shells.
with tempfile.TemporaryDirectory(prefix='marc-platform-shell-') as directory:
    directory = Path(directory)
    uname = directory / 'uname'
    swvers = directory / 'sw_vers'
    uname.write_text('#!/bin/sh\n[ "$FIXTURE_KERNEL" != missing ] || exit 1\nprintf "%s\\n" "$FIXTURE_KERNEL"\n')
    swvers.write_text('#!/bin/sh\n[ "$FIXTURE_PRODUCT" != missing ] || exit 1\nprintf "%s\\n" "$FIXTURE_PRODUCT"\n')
    uname.chmod(0o700); swvers.chmod(0o700)
    fixture = command.replace('/usr/bin/uname', str(uname)).replace('/bin/uname', str(uname)).replace('/usr/bin/sw_vers', str(swvers))
    for kernel, product, expected in [
        ('Darwin', 'macOS', 'MARC_MACOS_V1'),
        ('Darwin', 'Mac OS X', 'MARC_MACOS_V1'),
        ('Linux', 'missing', 'MARC_UNSUPPORTED_V1'),
        ('FreeBSD', 'missing', 'MARC_UNSUPPORTED_V1'),
        ('Windows_NT', 'missing', 'MARC_UNSUPPORTED_V1'),
        ('Darwin', 'iPhone OS', 'MARC_UNSUPPORTED_V1'),
        ('Darwin', 'missing', None), ('missing', 'missing', None),
    ]:
        env = dict(os.environ, FIXTURE_KERNEL=kernel, FIXTURE_PRODUCT=product)
        result = subprocess.run(['/bin/sh', '-c', fixture], env=env, capture_output=True, text=True, timeout=3)
        if expected is None:
            assert result.returncode != 0 and not result.stdout.strip(), (kernel, product, result)
        else:
            assert result.returncode == 0 and result.stdout.strip() == expected, (kernel, product, result)

monitor = (root / 'MARC/Services/SSHMonitor.swift').read_text()
connect = monitor[monitor.index('    func connect(server: ServerProfile, login:'):monitor.index('    // Invalidate ownership')]
assert connect.index('hostKeyValidator') < connect.index('SSHClient.connect') < connect.index('requireMacOS') < connect.index('executeCommandStream') < connect.index('MARCCredentials.save') < connect.index('connected = true')
add = (root / 'MARC/Screens/ServersScreen.swift').read_text()
save = add[add.index('    private func saveAndConnect()'):add.index('    private func stopRequest()')]
assert save.index('store.monitor.connect') < save.index('store.add(profile)') < save.index('onConnected()')
issue = (root / 'MARC/Services/MARCConnectionIssue.swift').read_text()
assert 'if let platform = error as? MARCPlatformError' in issue
assert '[.network, .timeout, .session, .unknown].contains(kind)' in issue
assert run.index('requireMacOS') < run.index('/usr/bin/whoami')
print('PASS: production platform probe accepts macOS, rejects non-Mac systems and fails closed on missing commands; save/success order checked')

parser = argparse.ArgumentParser()
parser.add_argument('--source-only', action='store_true')
args = parser.parse_args()
if args.source_only:
    raise SystemExit(0)

support = r'''
struct FixtureBytes { let readableBytesView: [UInt8] }
enum FixtureError: Error { case command }
@MainActor final class SSHClient {
    static var output = "MARC_MACOS_V1\n"
    static var fails = false
    static var cancelDuringProbe = false
    static var closes = 0
    static var details = 0
    static var probes = 0
    static func connect(to settings: SSHClientSettings) async throws -> SSHClient { SSHClient() }
    func executeCommand(_ command: String, maxResponseSize: Int, mergeStreams: Bool) async throws -> FixtureBytes {
        if command == MARCMacCompatibility.command {
            precondition(maxResponseSize == 1024)
            Self.probes += 1
            if Self.cancelDuringProbe { withUnsafeCurrentTask { $0?.cancel() } }
            if Self.fails { throw FixtureError.command }
            return FixtureBytes(readableBytesView: Array(Self.output.utf8))
        }
        Self.details += 1
        return FixtureBytes(readableBytesView: Array("fixture Mac".utf8))
    }
    func close() async throws { Self.closes += 1 }
}
struct ServerProfile { let username = "fixture"; let host = "fixture.invalid"; let port = 22 }
enum MARCCredentials { struct Saved {} }
struct MARCHostTrust {
    func keyForConnection(server: ServerProfile, existingKey: String) async throws -> String { existingKey }
}
enum MARCLogin {
    static func authentication(_ login: MARCCredentials.Saved, username: String) throws -> String { "fixture" }
}
struct SSHClientSettings {
    let host: String; let port: Int; let authenticationMethod: String; let hostKeyValidator: String
    var connectTimeout = Duration.seconds(10)
}
struct SSHTestResult { let output: String; let testedAt: Date }
@MainActor enum SSHConnectionTest {
    static func hostKeyValidator(server: ServerProfile, publicHostKey: String) throws -> String { publicHostKey }
__RUN__
}
'''.replace('__RUN__', run)
checks = r'''
@main struct PlatformChecks {
    @MainActor static func main() async throws {
        let client = SSHClient()
        for output in ["MARC_MACOS_V1", "MARC_MACOS_V1\r\n", " \nMARC_MACOS_V1\n"] {
            SSHClient.output = output
            try await MARCMacCompatibility.requireMacOS(on: client)
        }
        for output in ["Linux", "Darwin", "", "macOS", "MARC_MACOS_V1\nextra", "MARC_UNSUPPORTED_V1"] {
            SSHClient.output = output
            do { try await MARCMacCompatibility.requireMacOS(on: client); preconditionFailure("Invalid reply accepted") }
            catch let error as MARCPlatformError {
                precondition(error == (output == "MARC_UNSUPPORTED_V1" ? .unsupported : .unverified))
            }
        }
        SSHClient.fails = true
        do { try await MARCMacCompatibility.requireMacOS(on: client); preconditionFailure("Failed command accepted") }
        catch MARCPlatformError.unverified {}
        SSHClient.fails = false
        let server = ServerProfile(), login = MARCCredentials.Saved()
        SSHClient.output = "MARC_UNSUPPORTED_V1"
        do { _ = try await SSHConnectionTest.run(server: server, login: login, publicHostKey: "fixture"); preconditionFailure("Linux test succeeded") }
        catch MARCPlatformError.unsupported {}
        precondition(SSHClient.closes == 1 && SSHClient.details == 0)
        SSHClient.output = "MARC_MACOS_V1"
        _ = try await SSHConnectionTest.run(server: server, login: login, publicHostKey: "fixture")
        precondition(SSHClient.closes == 2 && SSHClient.details == 1)
        let before = SSHClient.probes
        let cancelled = Task { @MainActor in try await MARCMacCompatibility.requireMacOS(on: client) }
        cancelled.cancel()
        do { try await cancelled.value; preconditionFailure("Cancelled request succeeded") } catch is CancellationError {}
        precondition(SSHClient.probes == before)
        SSHClient.cancelDuringProbe = true
        let midflight = Task { @MainActor in
            try await SSHConnectionTest.run(server: server, login: login, publicHostKey: "fixture")
        }
        do { _ = try await midflight.value; preconditionFailure("Cancelled probe reported success") } catch is CancellationError {}
        precondition(SSHClient.closes == 3 && SSHClient.details == 1)
        print("PASS: production macOS gate, invalid replies, command failure, test-client cleanup and queued/in-flight cancellation")
    }
}
'''
compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('Swift compiler required for remaining checks. Run on your Mac.')
with tempfile.TemporaryDirectory(prefix='marc-platform-swift-') as directory:
    path = Path(directory) / 'PlatformChecks.swift'
    path.write_text('import Foundation\n' + support + platform + checks)
    binary = Path(directory) / 'platform-checks'
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(path), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True, timeout=30)

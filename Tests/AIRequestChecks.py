#!/usr/bin/env python3
"""Compile actual AI request/history methods with deterministic in-memory transports.
No HTTP requests, SSH commands, Keychain access or model inference are performed.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
terminal = (root / 'MARC/Screens/MARCTerminalScreen.swift').read_text()
ai_source = (root / 'MARC/Screens/MARCTerminalAI.swift').read_text()
monitor = (root / 'MARC/Services/SSHMonitor.swift').read_text()
ai = ai_source[ai_source.index('struct MARCTerminalAI:'):ai_source.index('struct MARCTerminalAISettings:')]
properties = ai[ai.index('    private var configuration:'):ai.index('    private var modelLabel:')]
methods = ai[ai.index('    private func runCommand()'):ai.rfind('\n}')]
local_ai = terminal[terminal.index('extension MARCTerminalSession {\n    func localAI'):terminal.index('enum MARCAIError:')]
error_and_history = terminal[terminal.index('enum MARCAIError:'):terminal.index('extension MARCTerminalSession {\n    var aiConnectionID:')]
remember = terminal[terminal.index('    func rememberAI('):terminal.index('    func sendKeyboard(')]
models = monitor[monitor.index('extension SSHMonitor {\n    func marcInstalledAIModels'):monitor.index('// MARK: - MARC live Control Center')]

support = r'''
import Foundation

@MainActor final class Gate {
    var entered = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; await withCheckedContinuation { continuation = $0 } }
    func open() { continuation?.resume(); continuation = nil }
}
struct FixtureOutput { let readableBytesView: [UInt8] }
enum FixtureError: Error { case expected }
@MainActor final class SSHClient {
    static var calls = 0
    static var hook: (() async throws -> String)?
    func executeCommand(_ command: String, maxResponseSize: Int, mergeStreams: Bool) async throws -> FixtureOutput {
        Self.calls += 1
        let result = try await Self.hook?() ?? "{}"
        return FixtureOutput(readableBytesView: Array(result.utf8))
    }
}
@MainActor enum MARCCredentials {
    struct Saved { let password: String }
    static func read(_ id: UUID) -> Saved? { nil }
}
@MainActor final class FixtureView {
    @discardableResult func resignFirstResponder() -> Bool { true }
}
@MainActor final class MARCTerminalSession {
    var ready = true
    var aiServerID: UUID? = UUID()
    var token = UUID()
    var aiConnectionID: UUID { token }
    var client: SSHClient? = SSHClient()
    var view: FixtureView? = FixtureView()
    var aiHistory: [MARCAIHistoryRecord] = []
    var sent: [[UInt8]] = []
    func send(_ bytes: [UInt8]) { sent.append(bytes) }
'''
harness = r'''
@MainActor final class AIHarness {
    let session = MARCTerminalSession()
    var provider = "local"
    var localModel = "fixture"
    var apiModel = "fixture-api"
    var endpoint = "https://example.invalid/chat/completions"
    var localServer = ""
    var prompt = "fixture prompt"
    var command = ""
    var historyPrompt: String?
    var commandConnection: UUID?
    var commandConfiguration: [String]?
    var failure: String?
    var busy = false
    var requestTask: Task<Void, Never>?
    var requestID = UUID()
    var promptFocused = false
    let credentialID = UUID()
    init() { localServer = session.aiServerID!.uuidString }
    func start() { generate() }
    func cancel() { cancelRequest() }
    func run() { runCommand() }
    var canRun: Bool { insertable }
'''
monitor_support = r'''
@MainActor final class SSHMonitor {
    struct Server { let id = UUID() }
    var connected = true
    var client: SSHClient? = SSHClient()
    var server: Server? = Server()
    var generation = UUID()
}
'''
checks = r'''
@main struct AIRequestChecks {
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<4000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Fixture did not reach expected boundary")
    }
    @MainActor static func main() async throws {
        let queued = AIHarness()
        queued.start(); let queuedTask = queued.requestTask
        queued.start() // duplicate starts cannot replace a busy request
        queued.cancel(); await queuedTask?.value
        precondition(SSHClient.calls == 0 && !queued.busy && queued.failure == nil)

        let direct = Task { try await queued.session.localAI(body: Data()) }
        direct.cancel()
        if case .success = await direct.result { preconditionFailure("Cancelled local call dispatched") }
        precondition(SSHClient.calls == 0)

        let first = AIHarness()
        let oldGate = Gate()
        var call = 0
        SSHClient.hook = {
            call += 1
            if call == 1 { await oldGate.wait(); return #"{"message":{"content":"old-command"}}"# }
            return #"{"message":{"content":"pwd"}}"#
        }
        first.start(); let old = first.requestTask
        await waitFor { oldGate.entered }
        first.cancel(); first.prompt = "current prompt"; first.start()
        await first.requestTask?.value
        precondition(first.command == "pwd" && first.historyPrompt == "current prompt")
        precondition(first.requestTask == nil && !first.busy && first.session.sent.isEmpty)
        oldGate.open(); await old?.value
        precondition(first.command == "pwd" && first.failure == nil && !first.busy)

        let changed = AIHarness(); let changedGate = Gate()
        SSHClient.hook = { await changedGate.wait(); return #"{"message":{"content":"whoami"}}"# }
        changed.start(); let changedTask = changed.requestTask
        await waitFor { changedGate.entered }
        changed.localModel = "new-model"; changedGate.open(); await changedTask?.value
        precondition(changed.command.isEmpty && changed.failure == nil && !changed.busy)

        let switched = AIHarness(); let switchGate = Gate()
        SSHClient.hook = { await switchGate.wait(); throw FixtureError.expected }
        switched.start(); let switchTask = switched.requestTask
        await waitFor { switchGate.entered }
        switched.session.token = UUID(); switchGate.open(); await switchTask?.value
        precondition(switched.command.isEmpty && switched.failure == nil && !switched.busy)

        let history = AIHarness()
        history.historyPrompt = "old selected history prompt"
        history.prompt = "new question"
        SSHClient.hook = { #"{"message":{"content":"```sh\npwd\n```"}}"# }
        history.start(); await history.requestTask?.value
        precondition(history.command == "pwd" && history.historyPrompt == "new question")
        precondition(history.canRun && history.session.sent.isEmpty)
        history.run(); history.run()
        precondition(history.session.sent == [Array("pwd\r".utf8)])
        precondition(history.session.aiHistory.first?.prompt == "new question")
        for index in 0..<15 { history.session.rememberAI(prompt: "p\(index)", command: "c\(index)") }
        precondition(history.session.aiHistory.count == 12)
        history.session.rememberAI(prompt: "updated", command: "c14")
        precondition(history.session.aiHistory.count == 12 && history.session.aiHistory.first?.prompt == "updated")

        let staleRun = AIHarness()
        SSHClient.hook = { #"{"message":{"content":"pwd"}}"# }
        staleRun.start(); await staleRun.requestTask?.value
        staleRun.localModel = "other"
        precondition(!staleRun.canRun); staleRun.run()
        precondition(staleRun.session.sent.isEmpty)
        staleRun.localModel = "fixture"; staleRun.session.token = UUID()
        precondition(!staleRun.canRun); staleRun.run()
        precondition(staleRun.session.sent.isEmpty)

        let multiline = AIHarness()
        SSHClient.hook = { #"{"message":{"content":"pwd\nwhoami"}}"# }
        multiline.start(); await multiline.requestTask?.value
        precondition(!multiline.canRun); multiline.run()
        precondition(multiline.session.sent.isEmpty)
        SSHClient.hook = { #"{"message":{"content":""}}"# }
        multiline.start(); await multiline.requestTask?.value
        precondition(multiline.failure != nil && !multiline.busy && multiline.requestTask == nil)

        let invalidAPI = AIHarness()
        invalidAPI.provider = "api"; invalidAPI.endpoint = "http://example.invalid"
        let beforeInvalid = SSHClient.calls
        invalidAPI.start(); await invalidAPI.requestTask?.value
        precondition(invalidAPI.failure != nil && !invalidAPI.busy && SSHClient.calls == beforeInvalid)

        let modelMonitor = SSHMonitor(); let modelGate = Gate()
        SSHClient.hook = { await modelGate.wait(); return #"{"names":["old-model"]}"# }
        let discovery = Task { try await modelMonitor.marcInstalledAIModels() }
        await waitFor { modelGate.entered }
        modelMonitor.generation = UUID() // same Mac ID, new transport
        modelGate.open()
        if case .success = await discovery.result { preconditionFailure("Stale model discovery published") }
        let beforeCancelled = SSHClient.calls
        let cancelledDiscovery = Task { try await modelMonitor.marcInstalledAIModels() }
        cancelledDiscovery.cancel()
        if case .success = await cancelledDiscovery.result { preconditionFailure("Cancelled discovery dispatched") }
        precondition(SSHClient.calls == beforeCancelled)
        print("PASS: AI queued cancellation, duplicate starts, stale responses, settings, history and explicit Run checks")
        print("PASS: AI model discovery ignores previous connections and queued cancellation")
    }
}
'''

def fixture_source():
    return (support + remember + '\n}\n' + error_and_history + local_ai +
            harness + properties + methods + '\n}\n' + monitor_support + models + checks)

def main():
    compiler = shutil.which('swiftc')
    if not compiler:
        raise SystemExit('Swift is required. Run AI checks on your Mac.')
    with tempfile.TemporaryDirectory(prefix='marc-ai-checks-') as directory:
        directory = Path(directory)
        swift = directory / 'AIChecks.swift'
        swift.write_text(fixture_source())
        executable = directory / 'ai-checks'
        subprocess.run([compiler, '-swift-version', '5', '-parse-as-library',
                        str(swift), '-o', str(executable)], check=True)
        subprocess.run([str(executable)], check=True, timeout=30)

if __name__ == '__main__':
    main()

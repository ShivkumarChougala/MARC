#!/usr/bin/env python3
"""Exercise process identity checks with mocked ps/kill, then Swift task fixtures.
No real processes are signalled and no SSH/network requests are made.
"""
from pathlib import Path
import base64
import contextlib
import io
import json
import shutil
import signal
import subprocess
import sys
import tempfile
from unittest.mock import patch

root = Path(__file__).resolve().parents[1]
monitor = (root / 'MARC/Services/SSHMonitor.swift').read_text()
screen = (root / 'MARC/Screens/ProcessesScreen.swift').read_text()
types = monitor[monitor.index('struct MARCProcess:'):monitor.index('extension SSHMonitor {\n    var processConnectionID:')]
terminate = monitor[monitor.index('extension SSHMonitor {\n    var processConnectionID:'):monitor.index('struct MARCProcessResponse:')]
response_type = monitor[monitor.index('struct MARCProcessResponse:'):monitor.index('extension SSHMonitor {\n    func processUpdates(')]
stream = monitor[monitor.index('extension SSHMonitor {\n    func processUpdates('):monitor.index('extension SSHMonitor {\n    func marcInstalledAIModels(')]
rows = (root / 'MARC/Services/MARCProcessRows.swift').read_text()
sheet = screen[screen.index('private struct MARCTerminationSheet:'):]
sheet_methods = sheet[sheet.index('    @MainActor\n    private func stopTermination()'):sheet.rfind('\n}')]
remote_python = terminate[terminate.index('import subprocess, json, os, sys, base64, signal'):terminate.index('\nMARC_TERMINATE\n')]

def backend_checks():
    expected = dict(pid=321, user='fixture', started='Mon Oct 12 12:00:00 2026', name='fixture tool')
    def run(data, output='fixture Mon Oct 12 12:00:00 2026 /tmp/fixture tool\n', error=None):
        encoded = base64.b64encode(json.dumps(data).encode()).decode()
        with patch.object(sys, 'argv', ['fixture', encoded]), \
             patch('subprocess.run') as ps, patch('os.kill', side_effect=error) as kill, \
             contextlib.redirect_stdout(io.StringIO()):
            ps.return_value.stdout = output
            try:
                exec(compile(remote_python, 'production_termination', 'exec'), {})
                failure = None
            except RuntimeError as exception:
                failure = str(exception)
            return failure, kill.call_args_list
    failure, calls = run(expected)
    assert failure is None and len(calls) == 1 and calls[0].args == (321, signal.SIGTERM)
    for field, changed in [('user', 'other'), ('started', 'other'), ('name', 'other'), ('pid', 1)]:
        failure, calls = run(dict(expected, **{field: changed}))
        assert failure and not calls
    failure, calls = run(expected, output='')
    assert 'exited' in failure and not calls
    for error in [PermissionError(), ProcessLookupError()]:
        failure, calls = run(expected, error=error)
        assert failure and len(calls) == 1
    print('PASS: production process identity, protected PID, exited process and signal-error checks (mocked ps/kill)')

support = r'''
import Foundation
enum FixtureError: Error { case expected }
struct FixtureBytes { let readableBytesView: [UInt8] }
enum FixtureEvent { case stdout(FixtureBytes), stderr(FixtureBytes) }
@MainActor final class Gate {
    var entered = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; await withCheckedContinuation { continuation = $0 } }
    func open() { continuation?.resume(); continuation = nil }
}
@MainActor final class SSHClient {
    var commands: [String] = []
    var streams = 0
    var hook: (() async throws -> String)?
    var continuation: AsyncThrowingStream<FixtureEvent, Error>.Continuation?
    func executeCommand(_ command: String, maxResponseSize: Int, mergeStreams: Bool) async throws -> FixtureBytes {
        commands.append(command)
        let output = try await hook?() ?? "MARC_TERMINATE_OK"
        return FixtureBytes(readableBytesView: Array(output.utf8))
    }
    func executeCommandStream(_ command: String) async throws -> AsyncThrowingStream<FixtureEvent, Error> {
        streams += 1
        return AsyncThrowingStream { continuation = $0 }
    }
    func emit(_ total: Int) {
        let line = "{\"total\":\(total),\"processes\":[]}\n"
        continuation?.yield(.stdout(FixtureBytes(readableBytesView: Array(line.utf8))))
    }
}
@MainActor final class SSHMonitor {
    struct Server { let id = UUID() }
    var client: SSHClient? = SSHClient()
    var connected = true
    var server: Server? = Server()
    var generation = UUID()
    var processTotalCount = 0
}
@MainActor final class TerminationHarness {
    let process = MARCProcess(started: "start", pid: 321, user: "fixture", cpu: 0, memory: 0, name: "fixture")
    var terminate: () async throws -> Void = {}
    var busy = false
    var failure: String?
    var visible = true
    var requestID = UUID()
    var task: Task<Void, Never>?
    var dismissals = 0
    func dismiss() { dismissals += 1 }
    func confirm() { confirmTermination() }
    func leave() { stopTermination() }
'''
checks = r'''
@main struct ProcessChecks {
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<4000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Fixture did not reach expected boundary")
    }
    @MainActor static func main() async throws {
        var rows = (0..<60).map {
            MARCProcess(started: "start", pid: 100 + $0, user: "fixture", cpu: Double($0),
                        memory: Double($0), name: "z\($0)")
        }
        rows[59] = MARCProcess(started: "old", pid: 159, user: "uniqueuser", cpu: 999,
                               memory: 999, name: "AAAA")
        for sort in ["CPU", "Memory", "Name"] {
            let result = MARCProcessRows.visible(rows, query: "", sorting: sort)
            precondition(result.count == 50 && result.first?.pid == 159,
                         "Sort must inspect all rows before applying the top-50 limit")
        }
        precondition(MARCProcessRows.visible(rows, query: " UNIQUEUSER ", sorting: "CPU").map(\.pid) == [159])
        precondition(MARCProcessRows.visible(rows, query: "159", sorting: "CPU").map(\.pid) == [159])
        let frozen = MARCProcessRows.visible(rows, query: "", sorting: "CPU").map(\.id)
        rows[0] = MARCProcess(started: "start", pid: 100, user: "fixture", cpu: 5000, memory: 0, name: "z0")
        precondition(MARCProcessRows.visible(rows, query: "", sorting: "CPU", frozenOrder: frozen).map(\.id) == frozen)
        let oldID = rows[59].id
        rows[59] = MARCProcess(started: "new", pid: 159, user: "fixture", cpu: 1, memory: 1, name: "new")
        precondition(rows[59].id != oldID)
        let live = MARCProcessRows.visible(rows, query: "", sorting: "CPU", frozenOrder: frozen)
        precondition(!live.contains { $0.id == oldID } && live.count == 50)
        let deduped = MARCProcessRows.visible([rows[0], rows[0]], query: "", sorting: "CPU")
        precondition(deduped.count == 1)
        precondition(MARCProcessRows.memoryBytes(.infinity) == 0 && MARCProcessRows.memoryBytes(-1) == 0)
        precondition(MARCProcessRows.memoryBytes(Double.greatestFiniteMagnitude) == Int64.max)

        let monitor = SSHMonitor(); let firstClient = monitor.client!
        let queued = Task { try await monitor.processUpdates() }; queued.cancel()
        if case .success = await queued.result { preconditionFailure("Cancelled stream opened") }
        precondition(firstClient.streams == 0)
        let connection = monitor.processConnectionID
        let updates = try await monitor.processUpdates(expectedConnection: connection)
        let consumer = Task { for try await _ in updates {} }
        firstClient.emit(12)
        await waitFor { monitor.processTotalCount == 12 }
        let nextClient = SSHClient()
        monitor.client = nextClient; monitor.generation = UUID(); monitor.processTotalCount = 77
        firstClient.emit(999)
        if case .success = await consumer.result { preconditionFailure("Old stream survived reconnect") }
        await waitFor { firstClient.commands.contains { $0.contains("MARC_STOP_PROCESSES") } }
        precondition(monitor.processTotalCount == 77 && nextClient.commands.isEmpty)

        // Do not consume until a burst has been parsed. Historical snapshots
        // must not queue behind the newest state while the UI is delayed.
        let bufferedMonitor = SSHMonitor()
        let bufferedClient = bufferedMonitor.client!
        let bufferedUpdates = try await bufferedMonitor.processUpdates()
        for total in 1...500 { bufferedClient.emit(total) }
        await waitFor { bufferedMonitor.processTotalCount == 500 }
        bufferedClient.continuation?.finish()
        var bufferedTotals: [Int] = []
        for try await response in bufferedUpdates { bufferedTotals.append(response.total) }
        precondition(bufferedTotals == [500], "A delayed consumer must receive only the newest pending snapshot")
        await waitFor { bufferedClient.commands.contains { $0.contains("MARC_STOP_PROCESSES") } }

        let process = MARCProcess(started: "start", pid: 321, user: "fixture", cpu: 0, memory: 0, name: "fixture")
        do {
            try await monitor.terminateProcess(process, expectedConnection: connection)
            preconditionFailure("Wrong connection accepted")
        } catch is CancellationError {}
        let cancelled = Task { try await monitor.terminateProcess(process) }; cancelled.cancel()
        if case .success = await cancelled.result { preconditionFailure("Cancelled termination dispatched") }
        precondition(nextClient.commands.isEmpty)
        let gate = Gate()
        nextClient.hook = { await gate.wait(); return "MARC_TERMINATE_OK" }
        let terminating = Task { try await monitor.terminateProcess(process, expectedConnection: monitor.processConnectionID) }
        await waitFor { gate.entered }
        monitor.generation = UUID(); gate.open()
        if case .success = await terminating.result { preconditionFailure("Old termination result published") }

        let sheet = TerminationHarness(); var attempts = 0
        sheet.terminate = { attempts += 1 }
        sheet.confirm(); let queuedSheet = sheet.task; sheet.leave(); await queuedSheet?.value
        precondition(attempts == 0 && !sheet.busy && sheet.dismissals == 0)
        sheet.visible = true
        let sheetGate = Gate()
        sheet.terminate = { attempts += 1; await sheetGate.wait() }
        sheet.confirm(); sheet.confirm(); let activeSheet = sheet.task
        await waitFor { sheetGate.entered }
        precondition(attempts == 1)
        sheet.leave(); sheetGate.open(); await activeSheet?.value
        precondition(sheet.failure == nil && sheet.dismissals == 0 && sheet.task == nil)
        sheet.visible = true; sheet.terminate = { attempts += 1 }
        sheet.confirm(); await sheet.task?.value
        precondition(sheet.dismissals == 1 && sheet.task == nil && !sheet.busy)
        print("PASS: process top-50 sorting, search, frozen order, PID identity, deduplication and memory boundaries")
        print("PASS: process stream cleanup stays on its original client; stale/cancelled terminations and duplicate taps are blocked")
        print("PASS: slow process consumers retain one newest snapshot instead of a stale-update backlog")
    }
}
'''

def fixture_source():
    return ('import Foundation\n' + types + response_type + rows + support + sheet_methods +
            '\n}\n' + terminate + stream + checks)

def main():
    backend_checks()
    if '--backend-only' in sys.argv:
        return
    compiler = shutil.which('swiftc')
    if not compiler:
        raise SystemExit('Swift is required. Run process task checks on your Mac.')
    with tempfile.TemporaryDirectory(prefix='marc-process-checks-') as directory:
        directory = Path(directory)
        source = directory / 'ProcessChecks.swift'
        source.write_text(fixture_source())
        binary = directory / 'process-checks'
        subprocess.run([compiler, '-swift-version', '5', '-parse-as-library',
                        str(source), '-o', str(binary)], check=True)
        subprocess.run([str(binary)], check=True, timeout=30)

if __name__ == '__main__':
    main()

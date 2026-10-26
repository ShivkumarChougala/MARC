#!/usr/bin/env python3
"""Exercise production Status section migration and feed worker using mock streams."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
home = (root / 'MARC/Screens/HomeScreen.swift').read_text()
monitor = (root / 'MARC/Services/SSHMonitor.swift').read_text()
sections = home[home.index('private enum MARCStatusSection:'):home.index('struct MARCStatusCustomizeSheet:')]
view = home[home.index('private struct MARCOverviewProcesses:'):home.index('private struct MARCMacPickerSheet:')]
worker = view[view.index('    private func refreshProcesses()'):view.rfind('\n}')].replace('private func', 'func', 1)
properties = view[view.index('    private var active:'):view.index('    var body:')].replace('private var', 'var')
types = monitor[monitor.index('struct MARCProcess:'):monitor.index('extension SSHMonitor {\n    var processConnectionID:')]
response = monitor[monitor.index('struct MARCProcessResponse:'):monitor.index('extension SSHMonitor {\n    func processUpdates(')]
rows = (root / 'MARC/Services/MARCProcessRows.swift').read_text()
gauge_data = home[home.index('private struct MARCOverviewGaugeReading {'):home.index('private struct MARCOverviewSystemCard:')]


support = r'''
import Foundation
struct Transaction { var disablesAnimations = false }
@MainActor func withTransaction(_ transaction: Transaction, _ body: () -> Void) { body() }
enum ScenePhase: Equatable { case active, background }
enum FixtureError: Error { case expected }
@MainActor final class Gate {
    var entered = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; await withCheckedContinuation { self.continuation = $0 } }
    func open() { continuation?.resume(); continuation = nil }
}
@MainActor final class MockMonitor {
    var connected = true
    var processConnectionID = UUID()
    var calls = 0
    var gate: Gate?
    var throwAfterGate = false
    var continuation: AsyncThrowingStream<MARCProcessResponse, Error>.Continuation?
    func processUpdates(expectedConnection: UUID?) async throws -> AsyncThrowingStream<MARCProcessResponse, Error> {
        calls += 1
        if let gate { await gate.wait() }
        if throwAfterGate { throw FixtureError.expected }
        return AsyncThrowingStream(bufferingPolicy: .bufferingNewest(1)) { self.continuation = $0 }
    }
}
@MainActor final class FixtureFeed {
    let monitor = MockMonitor()
    var enabled = true
    var scenePhase = ScenePhase.active
    var rows: [MARCProcess] = []
    var processConnection: UUID?
    var failure: String?
    var received = false
'''
tests = r'''
@main struct StatusChecks {
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<10000 {
            if condition() { return }
            await Task.yield()
        }
        preconditionFailure("Fixture did not reach expected state")
    }
    @MainActor static func main() async {
        let percent = MARCOverviewGaugeReading(raw: 150, kind: .percentage)
        precondition(percent.value == 100 && percent.text == "100%" && percent.progress == 1)
        let load = MARCOverviewGaugeReading(raw: 1.2, kind: .load)
        precondition(load.value == 1.2 && load.text == "1.2" && load.unit == nil && load.progress == nil)
        let swap = MARCOverviewGaugeReading(raw: 1.5 * 1073741824, kind: .swap)
        precondition(swap.value == 1.5 && swap.text == "1.5" && swap.unit == "GB" && swap.progress == nil)
        let smallSwap = MARCOverviewGaugeReading(raw: 32 * 1048576, kind: .swap)
        precondition(smallSwap.value == 32 && smallSwap.unit == "MB")
        for kind in [MARCOverviewGaugeReading.Kind.percentage, .load, .swap] {
            for bad in [Double?.none, .some(-1), .some(.nan), .some(.infinity)] {
                let reading = MARCOverviewGaugeReading(raw: bad, kind: kind)
                precondition(reading.value == nil && reading.text == "—" && reading.progress == nil)
            }
            precondition(MARCOverviewGaugeReading(raw: 0, kind: kind).value == 0)
            precondition(!MARCOverviewGaugeReading(raw: Double.greatestFiniteMagnitude, kind: kind).text.isEmpty)
        }
        print("PASS: Status percent/load/swap readings preserve units, raw values and zero; reject unavailable/invalid data without fake progress arcs")
        let expected = ["system", "developer", "processes"]
        for legacy in ["", "system,statistics,powerStorage,alerts", "system,power,storage,alerts", "unknown,system,system,powerStorage,alerts"] {
            precondition(MARCStatusSection.ordered(legacy).map(\.rawValue) == expected)
        }
        precondition(MARCStatusSection.developerFirst("system,processes,developer").map(\.rawValue) == expected)
        let custom = "processes,alerts,powerStorage,system"
        precondition(MARCStatusSection.ordered(custom).map(\.rawValue).joined(separator: ",") == "processes,system,developer")
        precondition(MARCStatusSection.ordered(expected.joined(separator: ",")).map(\.rawValue) == expected)
        let cancelled = FixtureFeed()
        let queued = Task { await cancelled.refreshProcesses() }
        queued.cancel(); await queued.value
        precondition(cancelled.monitor.calls == 0)
        let hidden = FixtureFeed(); hidden.enabled = false
        await hidden.refreshProcesses(); precondition(hidden.monitor.calls == 0)
        let background = FixtureFeed(); background.scenePhase = .background
        await background.refreshProcesses(); precondition(background.monitor.calls == 0)

        let live = FixtureFeed()
        let running = Task { await live.refreshProcesses() }
        await waitFor { live.monitor.continuation != nil }
        func process(_ pid: Int, _ cpu: Double) -> MARCProcess {
            MARCProcess(started: "identity", pid: pid, user: "fixture", cpu: cpu, memory: 1024, name: "p\(pid)")
        }
        live.monitor.continuation?.yield(MARCProcessResponse(total: 5, processes: [
            process(5, 3), process(4, 9), process(3, 4), process(2, 7), process(1, .nan)]))
        await waitFor { live.received }
        precondition(live.current && live.rows.map(\.pid) == [4, 2, 3])
        live.monitor.processConnectionID = UUID()
        precondition(!live.current, "Old Mac readings must disappear before the replacement task starts")
        live.monitor.continuation?.yield(MARCProcessResponse(total: 1, processes: [process(9, 99)]))
        await running.value
        precondition(live.rows.map(\.pid) == [4, 2, 3], "Stale response must not replace readings")

        for cancel in [false, true] {
            let stale = FixtureFeed(); let gate = Gate(); stale.monitor.gate = gate
            stale.monitor.throwAfterGate = true
            let task = Task { await stale.refreshProcesses() }
            await waitFor { gate.entered }
            if cancel { task.cancel() } else { stale.monitor.processConnectionID = UUID() }
            gate.open(); await task.value
            precondition(stale.failure == nil, "Stale/cancelled failures must stay silent")
        }
        let stopped = FixtureFeed()
        let stoppedTask = Task { await stopped.refreshProcesses() }
        await waitFor { stopped.monitor.continuation != nil }
        stopped.monitor.continuation?.finish()
        await waitFor { stopped.failure != nil }
        stoppedTask.cancel(); await stoppedTask.value
        precondition(stopped.monitor.calls == 1, "Cancellation during retry must stop another dispatch")
        print("PASS: Status section migration, top-three ranking, queued cancellation, hidden/background suppression, stale responses/errors and retry cancellation")
    }
}
'''

def fixture_source():
    return support + properties + worker + '\n}\n' + types + response + rows + gauge_data + sections + tests

if __name__ == '__main__':
    if '--source-only' in sys.argv:
        assert 'UIBlurEffect' not in fixture_source()
        assert 'import Charts' not in home and 'MARCOverviewActivityRow' not in home
        assert 'MARCOverviewSavedTrend' not in home
        assert 'Needs attention' not in home and 'MARCStatusAlert' not in home
        assert 'if let error = store.monitor.error' in home
        assert 'Text("Name")' in home and 'Text("PID")' in home and 'Process ID' in home
        assert 'firstLabel: "Download"' in home and 'secondLabel: "Upload"' in home
        print('PASS: Status fixture extraction and requested alert/network presentation source checks')
        print('NOT RUN: native Swift Status fixture (source-only mode)')
    else:
        compiler = shutil.which('swiftc')
        if not compiler:
            raise SystemExit('Swift compiler required for Status overview checks')
        with tempfile.TemporaryDirectory(prefix='marc-status-checks-') as directory:
            source = Path(directory) / 'StatusChecks.swift'
            binary = Path(directory) / 'status-checks'
            source.write_text(fixture_source())
            subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(source), '-o', str(binary)], check=True)
            subprocess.run([str(binary)], check=True, timeout=30)

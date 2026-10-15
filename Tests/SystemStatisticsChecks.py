#!/usr/bin/env python3
"""Exercise production archive Python and Swift data/request code with local fixtures."""
from pathlib import Path
from unittest.mock import patch
import contextlib
import io
import json
import os
import time
import shutil
import sqlite3
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/SSHMonitor.swift').read_text()
archive = source[source.index('private struct MARCArchivePoint:'):source.index('struct MARCProcess:')]
backend = archive[archive.index('import sqlite3, pathlib'):archive.index('\nMARC_HISTORY')]

with tempfile.TemporaryDirectory(prefix='marc-statistics-db-') as directory:
    home = Path(directory)
    database = home / '.local/share/marc/history.sqlite'
    database.parent.mkdir(parents=True)
    def sample(counter, interface='en0'):
        return dict(cpu=30, memoryUsed=100, memoryTotal=1000, details={'load': 2},
                    interface=interface, received=counter, sent=counter,
                    diskReadBytes=counter, diskWriteBytes=counter)
    db = sqlite3.connect(database)
    db.execute('CREATE TABLE samples (ts REAL, payload TEXT)')
    fixtures = [(9990, sample(100)), (9995, sample(120)), (10000, sample(140)),
                (10010, sample(500))]
    db.executemany('INSERT INTO samples VALUES (?, ?)', [(t, json.dumps(s)) for t, s in fixtures])
    db.commit()
    def run():
        output = io.StringIO()
        with patch('pathlib.Path.home', return_value=home), patch('time.time', return_value=10000), \
             patch.object(sys, 'argv', ['fixture', '900']), contextlib.redirect_stdout(output):
            exec(compile(backend, '<production-history>', 'exec'), {})
        return json.loads(output.getvalue())
    rows = run()
    assert len(rows) == 3 and rows[-1]['date'] == 10000
    assert rows[0]['download'] is None and rows[1]['download'] == 4
    assert rows[-1]['memory'] == 10 and rows[-1]['load'] == 2
    db.execute('DELETE FROM samples')
    db.executemany('INSERT INTO samples VALUES (?, ?)', [
        (9990, json.dumps(sample(100))), (9995, json.dumps(sample(50, 'en1'))),
        (10000, json.dumps(sample(70, 'en1')))])
    db.commit()
    rows = run()
    assert rows[1]['download'] is None and rows[1]['read'] is None
    assert rows[2]['download'] == 4 and rows[2]['read'] == 4
    db.execute('DELETE FROM samples')
    db.commit()
    assert run() == []
    db.close()
print('PASS: saved-history time bounds, rates, interface/counter resets and empty database')
# Run the exact optional writer from the production collector without macOS calls.
writer_code = source[source.index('# MARC_HISTORY_WRITER_BEGIN'):source.index('# MARC_HISTORY_WRITER_END')]
def archive_for(home, now):
    output = io.StringIO()
    with patch('pathlib.Path.home', return_value=home), patch('time.time', return_value=now), \
         patch.object(sys, 'argv', ['fixture', '900']), contextlib.redirect_stdout(output):
        try:
            exec(compile(backend, '<production-history>', 'exec'), {})
        except SystemExit as error:
            assert error.code == 0
    return json.loads(output.getvalue())

with tempfile.TemporaryDirectory(prefix='marc-auto-history-') as directory:
    home = Path(directory)
    assert archive_for(home, 10000) == {'error': 'missing'}
    namespace = {'time': time, 'os': os}
    exec(compile(writer_code, '<production-history-writer>', 'exec'), namespace)
    writer = namespace['history_writer']
    payload = json.dumps(dict(cpu=30, memoryUsed=100, memoryTotal=1000,
        details={'load': 2}, interface='en0', received=100, sent=100))
    clock = [0]
    with patch('pathlib.Path.home', return_value=home), patch('time.monotonic', side_effect=lambda: clock[0]):
        writer.save(10000, payload)
        database = home / '.local/share/marc/history.sqlite'
        assert database.exists() and database.stat().st_mode & 0o777 == 0o600
        writer.save(10001, payload)
        assert writer.db.execute('SELECT COUNT(*) FROM marc_samples_v1').fetchone()[0] == 1
        clock[0] = 5
        writer.save(10005, payload)
        assert len(archive_for(home, 10005)) == 2
        writer.db.execute('CREATE TABLE samples (ts REAL, payload TEXT)')
        writer.db.executemany('INSERT INTO samples VALUES (?, ?)', [(1000, payload), (9995, payload), (10000, payload)])
        writer.db.execute('INSERT INTO marc_samples_v1 VALUES (?, ?)', (1000, payload))
        writer.db.commit()
        combined = archive_for(home, 10005)
        assert [row['date'] for row in combined] == [9995, 10000, 10005]
        writer.db.execute('INSERT INTO samples VALUES (?, ?)', (10010, payload))
        writer.db.commit()
        assert [row['date'] for row in archive_for(home, 10010)] == [9995, 10000, 10010]
        clock[0] = 65
        writer.save(10065, payload)
        assert writer.db.execute('SELECT MIN(ts) FROM marc_samples_v1').fetchone()[0] == 10000
        assert writer.db.execute('SELECT MIN(ts) FROM samples').fetchone()[0] == 1000
        writer.db.close()

with tempfile.TemporaryDirectory(prefix='marc-history-failure-') as directory:
    namespace = {'time': time, 'os': os}
    exec(compile(writer_code, '<production-history-writer>', 'exec'), namespace)
    writer = namespace['history_writer']
    with patch('pathlib.Path.home', return_value=Path(directory)), patch('time.monotonic', return_value=0), \
         patch('sqlite3.connect', side_effect=sqlite3.OperationalError('fixture locked')) as connect:
        writer.save(10000, '{}')
        writer.save(10001, '{}')
        assert writer.db is None and writer.retry_at == 60 and connect.call_count == 1
    assert archive_for(Path(directory), 10000) == {'error': 'schema'}
    (Path(directory) / '.local/share/marc/history.sqlite').write_text('not sqlite')
    assert archive_for(Path(directory), 10000) == {'error': 'unreadable'}
print('PASS: automatic history creation, cadence, permissions, legacy preservation, retention and isolated write failures')

if '--backend-only' in sys.argv:
    raise SystemExit(0)

types = source[source.index('struct SystemHistoryPoint:'):source.index('struct MacSnapshot:')]
helper = (root / 'MARC/Services/MARCStatisticsData.swift').read_text()
support = r'''
struct FixtureServer { let id = UUID() }
struct FixtureBuffer { let readableBytesView: [UInt8] }
@MainActor final class Gate {
    var entered = false
    var continuation: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; await withCheckedContinuation { continuation = $0 } }
    func open() { continuation?.resume(); continuation = nil }
}
@MainActor final class SSHClient {
    var calls = 0
    var hook: () async throws -> String = { "[]" }
    func executeCommand(_ command: String, maxResponseSize: Int, mergeStreams: Bool) async throws -> FixtureBuffer {
        calls += 1
        let result = try await hook()
        return FixtureBuffer(readableBytesView: Array(result.utf8))
    }
}
@MainActor final class SSHMonitor {
    var generation = UUID()
    var archiveRequest = UUID()
    var archivedHistory: [SystemHistoryPoint] = []
    var archivedHistorySeconds: Int?
    var archiveLoading = false
    var archiveError: String?
    var client: SSHClient? = SSHClient()
    var connected = true
    var server: FixtureServer? = FixtureServer()
}
'''
checks = r'''
@main struct StatisticsChecks {
    static func point(_ time: Double, cpu: Double = 30, network: Double? = nil) -> SystemHistoryPoint {
        SystemHistoryPoint(date: Date(timeIntervalSince1970: time), load: nil, cpu: cpu,
            memory: 10, download: network, upload: nil, read: nil, write: nil)
    }
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<10000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Fixture did not reach its gate")
    }
    @MainActor static func main() async {
        precondition(MARCStatisticsData.percent(.nan) == "—")
        precondition(MARCStatisticsData.percent(150) == "100%")
        precondition(MARCStatisticsData.byteCount(.infinity) == "—")
        precondition(MARCStatisticsData.byteCount(-1) == "—")
        precondition(!MARCStatisticsData.byteCount(Double.greatestFiniteMagnitude).isEmpty)
        precondition(MARCStatisticsData.uptime(.nan) == "—")
        precondition(MARCStatisticsData.uptime(90061) == "1d 1h")
        precondition(!MARCStatisticsData.uptime(Double.greatestFiniteMagnitude).isEmpty)
        let window = MARCStatisticsData.window([point(990), point(600), point(980), point(1010)],
            end: Date(timeIntervalSince1970: 1000), duration: 300)
        precondition(window.map { $0.date.timeIntervalSince1970 } == [980, 990])
        precondition(MARCStatisticsData.value(point(1, cpu: .infinity), metric: "CPU") == nil)
        precondition(MARCStatisticsData.value(point(1, network: 2048), metric: "Network") == 2)
        precondition(MARCStatisticsData.value(point(1), metric: "Server Load") == nil)

        let cpuPoint = point(1, cpu: 150)
        let cpuSeries = MARCStatisticsSeries(history: [point(0, cpu: .nan), cpuPoint], metric: "CPU")
        precondition(cpuSeries.ceiling == 100 && cpuSeries.primaryCount == 1)
        precondition(cpuSeries.samples[1].id == cpuPoint.id && cpuSeries.samples[1].primary == 100)
        precondition(cpuSeries.axisLabel(50) == "50%")
        let network = MARCStatisticsSeries(history: [point(1, network: 2_097_152)], metric: "Network")
        precondition(network.samples[0].primary == 2048 && network.rateUnit == "MB/s")
        precondition(network.axisLabel(1024) == "1.0" && network.primaryCount == 1)
        let smallNetwork = MARCStatisticsSeries(history: [point(1, network: 2048)], metric: "Network")
        precondition(smallNetwork.rateUnit == "KB/s" && smallNetwork.axisLabel(2) == "2.0")
        let secondaryOnly = SystemHistoryPoint(date: Date(), load: nil, cpu: 0, memory: 0,
            download: nil, upload: 4096, read: nil, write: nil)
        let upload = MARCStatisticsSeries(history: [secondaryOnly], metric: "Network")
        precondition(upload.hasSamples && upload.primaryCount == 0 && upload.secondaryCount == 1)
        let noLoad = MARCStatisticsSeries(history: [point(1)], metric: "Server Load")
        precondition(!noLoad.hasSamples && noLoad.ceiling == 1 && noLoad.axisLabel(1.42) == "1.42")
        let hugeLoad = SystemHistoryPoint(date: Date(), load: Double.greatestFiniteMagnitude,
            cpu: 0, memory: 0, download: nil, upload: nil, read: nil, write: nil)
        precondition(MARCStatisticsSeries(history: [hugeLoad], metric: "Server Load").ceiling.isFinite)
        precondition(!MARCStatisticsSeries(history: [], metric: "Disk").hasSamples)
        print("PASS: prepared chart scales, rate units, stable sample identity and independent series counts")

        let monitor = SSHMonitor()
        let client = monitor.client!
        monitor.archivedHistory = [point(990)]
        monitor.archivedHistorySeconds = 900
        let cancelled = Task { @MainActor in await monitor.loadArchivedHistory(seconds: 3600) }
        cancelled.cancel(); await cancelled.value
        precondition(client.calls == 0 && monitor.archivedHistorySeconds == 900)
        await monitor.loadArchivedHistory(seconds: 3600, expectedConnection: UUID())
        precondition(client.calls == 0 && monitor.archivedHistory.count == 1)

        let oldGate = Gate()
        client.hook = { await oldGate.wait(); return "[]" }
        let old = Task { @MainActor in await monitor.loadArchivedHistory(seconds: 1800) }
        await waitFor { oldGate.entered }
        precondition(monitor.archivedHistory.isEmpty && monitor.archiveLoading)
        precondition(monitor.archivedHistorySeconds == 1800)
        let newGate = Gate()
        client.hook = { await newGate.wait(); return "[]" }
        let newer = Task { @MainActor in await monitor.loadArchivedHistory(seconds: 3600) }
        await waitFor { newGate.entered }
        oldGate.open(); await old.value
        precondition(monitor.archiveLoading && monitor.archivedHistorySeconds == 3600,
                     "Old completion must not clear a new request's loading state")
        newGate.open(); await newer.value
        precondition(!monitor.archiveLoading && monitor.archiveError == nil && monitor.archivedHistory.isEmpty)

        let reconnectGate = Gate()
        client.hook = { await reconnectGate.wait(); return "invalid response" }
        let stale = Task { @MainActor in await monitor.loadArchivedHistory(seconds: 900) }
        await waitFor { reconnectGate.entered }
        monitor.generation = UUID(); monitor.archiveRequest = UUID()
        monitor.archivedHistory = [point(999)]; monitor.archiveLoading = true
        monitor.archiveError = "New session"
        reconnectGate.open(); await stale.value
        precondition(monitor.archiveLoading && monitor.archiveError == "New session" && monitor.archivedHistory.count == 1)
        client.hook = { "{\"error\":\"missing\"}" }
        await monitor.loadArchivedHistory(seconds: 900)
        precondition(monitor.archiveError?.contains("History is starting") == true && !monitor.archiveLoading)
        monitor.connected = false
        await monitor.loadArchivedHistory(seconds: 1800)
        precondition(!monitor.archiveLoading && monitor.archivedHistory.isEmpty && monitor.archiveError != nil)
        print("PASS: statistics numeric boundaries, chart windows, range switching, cancellation and reconnect ownership")
    }
}
'''
compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('Swift compiler required. Run this check on your Mac.')
with tempfile.TemporaryDirectory(prefix='marc-statistics-checks-') as directory:
    swift = Path(directory) / 'StatisticsChecks.swift'
    swift.write_text('import Foundation\n' + types + helper + support + archive + checks)
    binary = Path(directory) / 'statistics-checks'
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(swift), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True, timeout=30)

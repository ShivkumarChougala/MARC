import Foundation
import Observation
import Citadel
import NIOCore

struct SystemDetails: Decodable, Sendable {
    let coreUsage: [Double]?
    let cpuUser: Double?
    let cpuSystem: Double?
    let cores: Int?
    let tasks: Int?
    let uptime: Double?
    let load: Double?
    let swap: Double?
    let ip: String?
    let model: String?
    let osVersion: String?
    let architecture: String?
    let username: String?
    let batteryPercent: Double?
    let powerSource: String?
    let batteryState: String?
    let hasBattery: Bool?
    var batteryCondition: String? = nil
    var batteryMaximumCapacity: Double? = nil
    var batteryCycleCount: Int? = nil
}

struct SystemHistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let load: Double?
    let cpu: Double
    let memory: Double
    let download: Double?
    let upload: Double?
    let read: Double?
    let write: Double?
}

struct MacSnapshot: Decodable, Sendable {
    let hostname: String
    let cpu: Double
    let memoryUsed: Double
    let memoryTotal: Double
    let diskUsed: Double
    let diskTotal: Double
    let diskAvailable: Double
    let interface: String?
    let received: Double?
    let sent: Double?
    let diskReadBytes: Double?
    let diskWriteBytes: Double?
    let details: SystemDetails?
    let sampledAt: Double
    var memoryPercent: Double { memoryTotal > 0 ? memoryUsed / memoryTotal * 100 : 0 }
    var diskPercent: Double { diskUsed + diskAvailable > 0 ? diskUsed / (diskUsed + diskAvailable) * 100 : 0 }
}

@MainActor @Observable final class SSHMonitor {
    private(set) var server: ServerProfile?
    private(set) var history: [SystemHistoryPoint] = []
    private(set) var archivedHistory: [SystemHistoryPoint] = []
    private(set) var archiveError: String?
    private(set) var archivedHistorySeconds: Int?
    private(set) var archiveLoading = false
    var statisticsConnectionID: UUID { generation }
    @ObservationIgnored private var archiveRequest = UUID()

    private(set) var snapshot: MacSnapshot?
    private(set) var downloadRate: Double?
    private(set) var uploadRate: Double?
    private(set) var diskReadRate: Double?
    private(set) var diskWriteRate: Double?
    private(set) var processTotalCount = 0
    private(set) var connecting = false
    private(set) var connected = false
    private(set) var automaticReconnectEnabled = true
    private(set) var error: String?
    private(set) var connectionIssue: MARCConnectionIssue?
    private(set) var updatedAt: Date?
    @ObservationIgnored private var client: SSHClient?
    @ObservationIgnored private var polling: Task<Void, Never>?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var collectorWatchdog: Task<Void, Never>?
    @ObservationIgnored private var collectorHealth = MARCCollectorHealth()

    func connect(server: ServerProfile, password: String, hostKey: String) async throws {
        try await connect(server: server, login: .init(password: password, hostKey: hostKey), hostKey: hostKey)
    }

    func connect(server: ServerProfile, login: MARCCredentials.Saved, hostKey: String) async throws {
        automaticReconnectEnabled = true
        let previous = resetConnection()
        let token = generation
        self.server = server
        connecting = true
        error = nil
        defer { if generation == token { connecting = false } }
        let username = server.username
        do {
            if let previous { try? await previous.close() }
            try Task.checkCancellation()
            guard generation == token else { throw CancellationError() }
            let verifiedHostKey = try await MARCHostTrust().keyForConnection(server: server, existingKey: hostKey)
            try Task.checkCancellation()
            guard generation == token else { throw CancellationError() }
            let validator = try SSHConnectionTest.hostKeyValidator(server: server, publicHostKey: verifiedHostKey)
            let authentication = try MARCLogin.authentication(login, username: username)
            var settings = SSHClientSettings(host: server.host, port: server.port,
                authenticationMethod: authentication,
                hostKeyValidator: validator)
            settings.connectTimeout = .seconds(10)
            let opened = try await SSHClient.connect(to: settings)
            guard generation == token, !Task.isCancelled else { try? await opened.close(); throw CancellationError() }
            client = opened
            self.server = server
            startCollectorWatchdog(token: token)
            let stream = try await opened.executeCommandStream(Self.command)
            guard generation == token, !Task.isCancelled else {
                try? await opened.close()
                throw CancellationError()
            }
            try MARCCredentials.save(
                server.id, login: login, hostKey: verifiedHostKey
            )
            UserDefaults.standard.set(
                server.id.uuidString, forKey: "marc.autoServer"
            )
            connected = true
            polling = Task { @MainActor [weak self] in
                var pending = Data()
                var failures = 0
                do {
                    for try await event in stream {
                        guard !Task.isCancelled, let self,
                              self.generation == token else { return }
                        switch event {
                        case .stdout(let chunk):
                            pending.append(contentsOf: chunk.readableBytesView)
                            guard pending.count <= 65536 else {
                                throw NSError(domain: "MARC", code: 2,
                                    userInfo: [NSLocalizedDescriptionKey:
                                        "Collector output exceeded its limit."])
                            }
                            while let newline = pending.firstIndex(of: 10) {
                                let line = Data(pending[..<newline])
                                pending.removeSubrange(...newline)
                                if line.isEmpty { continue }

                                if let next = try? JSONDecoder().decode(
                                    MacSnapshot.self, from: line
                                ) {
                                    failures = 0
                                    self.error = nil
                                    self.connectionIssue = nil
                                    let choice = UserDefaults.standard.integer(
                                        forKey: "marc.refreshInterval"
                                    )
                                    let interval = Double(
                                        [1, 2, 5].contains(choice) ? choice : 2
                                    )
                                    if self.collectorHealth.received(
                                        at: ProcessInfo.processInfo.systemUptime,
                                        publishInterval: interval
                                    ) {
                                        self.publish(next)
                                    }
                                } else {
                                    failures += 1
                                    self.error = "Collector update delayed. Showing last readings."
                                    if failures >= 3 {
                                        throw NSError(domain: "MARC", code: 3,
                                            userInfo: [NSLocalizedDescriptionKey:
                                                "Collector failed repeatedly. Reconnect in Settings."])
                                    }
                                }
                            }
                        case .stderr(let chunk):
                            print("[MARC] Collector: " +
                                String(decoding: chunk.readableBytesView,
                                       as: UTF8.self).prefix(500))
                        }
                    }
                    guard let self, self.generation == token else { return }
                    self.finishCollector(token: token,
                        message: "The Mac stopped sending live readings. Reconnecting when available.")
                } catch {
                    guard let self, self.generation == token else { return }
                    self.finishCollector(token: token,
                        message: "Live updates stopped. Reconnecting when available.")
                }
            }
        } catch {
            if generation == token {
                let previous = resetConnection()
                if !(error is CancellationError) && !Task.isCancelled {
                    let issue = MARCConnectionIssue.classify(error, login: login)
                    self.connectionIssue = issue
                    self.error = issue.message
                }
                if let previous { try? await previous.close() }
            }
            throw error
        }
    }

    // Invalidate ownership synchronously; closing an old transport must never
    // reset a newer connection after a task has been scheduled.
    func cancelConnection(reconnectAutomatically: Bool = false) {
        automaticReconnectEnabled = reconnectAutomatically
        let previous = resetConnection()
        if let previous {
            Task { try? await previous.close() }
        }
    }

    private func startCollectorWatchdog(token: UUID) {
        collectorHealth.start(at: ProcessInfo.processInfo.systemUptime)
        collectorWatchdog?.cancel()
        collectorWatchdog = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(5)) }
                catch { return }
                guard !Task.isCancelled, let self,
                      self.generation == token else { return }
                self.checkCollectorHealth(token: token, at: ProcessInfo.processInfo.systemUptime)
            }
        }
    }

    private func checkCollectorHealth(token: UUID, at now: TimeInterval) {
        guard generation == token, let timeout = collectorHealth.timeout(at: now) else { return }
        finishCollector(token: token, message: timeout == .startup
            ? "The Mac did not start sending readings within 90 seconds. Reconnecting when available."
            : "No valid readings received for 90 seconds. Reconnecting when available.")
    }

    /// Retain the last readings for the existing stale-data label, invalidate all
    /// old callbacks, and close only this connection's captured transport.
    private func finishCollector(token: UUID, message: String) {
        guard generation == token else { return }
        generation = UUID()
        collectorWatchdog?.cancel()
        collectorWatchdog = nil
        collectorHealth.reset()
        polling?.cancel()
        polling = nil
        let previous = client
        client = nil
        connected = false
        connecting = false
        archiveRequest = UUID()
        archiveLoading = false
        error = message
        connectionIssue = MARCConnectionIssue(kind: .session,
            title: "Live monitoring interrupted", detail: message)
        if let previous { Task { try? await previous.close() } }
    }

    private func resetConnection() -> SSHClient? {
        generation = UUID()
        collectorWatchdog?.cancel()
        collectorWatchdog = nil
        collectorHealth.reset()
        polling?.cancel()
        polling = nil
        let previous = client
        client = nil
        connected = false
        connecting = false
        snapshot = nil
        archiveRequest = UUID()
        archivedHistory.removeAll(keepingCapacity: true)
        archiveError = nil
        archivedHistorySeconds = nil
        archiveLoading = false
        processTotalCount = 0
        history.removeAll(keepingCapacity: true)
        downloadRate = nil
        uploadRate = nil
        diskReadRate = nil
        diskWriteRate = nil
        updatedAt = nil
        server = nil
        error = nil
        connectionIssue = nil
        return previous
    }

    private func publish(_ next: MacSnapshot) {
        var newDownload: Double?
        var newUpload: Double?
        var newDiskRead: Double?
        var newDiskWrite: Double?
        if let previous = snapshot, previous.interface == next.interface {
            let elapsed = next.sampledAt - previous.sampledAt
            if elapsed > 0, let oldIn = previous.received, let oldOut = previous.sent,
               let newIn = next.received, let newOut = next.sent, newIn >= oldIn, newOut >= oldOut {
                newDownload = (newIn - oldIn) / elapsed
                newUpload = (newOut - oldOut) / elapsed
            }
        }
        if let previous = snapshot {
            let elapsed = next.sampledAt - previous.sampledAt
            if elapsed > 0, let oldRead = previous.diskReadBytes, let oldWrite = previous.diskWriteBytes,
               let newRead = next.diskReadBytes, let newWrite = next.diskWriteBytes,
               newRead >= oldRead, newWrite >= oldWrite {
                newDiskRead = (newRead - oldRead) / elapsed
                newDiskWrite = (newWrite - oldWrite) / elapsed
            }
        }
        downloadRate = newDownload
        uploadRate = newUpload
        diskReadRate = newDiskRead
        diskWriteRate = newDiskWrite
        history.append(SystemHistoryPoint(
            date: Date(timeIntervalSince1970: next.sampledAt),
            load: next.details?.load, cpu: next.cpu, memory: next.memoryPercent,
            download: newDownload, upload: newUpload,
            read: newDiskRead, write: newDiskWrite))
        history.removeAll {
            $0.date.timeIntervalSince1970 < next.sampledAt - 300
        }
        if history.count > 300 {
            history.removeFirst(history.count - 300)
        }
        snapshot = next
        updatedAt = Date()
    }

    private static var command: String {
        let requested = UserDefaults.standard.integer(
            forKey: "marc.powerRefreshSeconds"
        )
        let seconds = [5, 10, 30, 60].contains(requested) ? requested : 10
        return collectorCommand.replacingOccurrences(
            of: "__MARC_POWER_INTERVAL__", with: String(seconds)
        )
    }

    private static let collectorCommand = #"""
python3 -u - <<'MARC_COLLECTOR'
import json, subprocess, re, time, socket, plistlib, ctypes, sys, os, getpass

# MARC_HISTORY_WRITER_BEGIN
class MARCHistoryWriter:
    def __init__(self):
        self.db = None
        self.last_saved = None
        self.last_pruned = None
        self.retry_at = 0

    def save(self, timestamp, payload):
        now = time.monotonic()
        if now < self.retry_at or (self.last_saved is not None and now - self.last_saved < 5):
            return
        try:
            if self.db is None:
                import sqlite3
                from pathlib import Path
                folder = Path.home() / '.local/share/marc'
                folder.mkdir(mode=0o700, parents=True, exist_ok=True)
                path = folder / 'history.sqlite'
                if path.is_symlink():
                    raise OSError('History database must be a regular file.')
                try:
                    fd = os.open(str(path), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
                except FileExistsError:
                    pass
                else:
                    os.close(fd)
                self.db = sqlite3.connect(str(path), timeout=0.15)
                self.db.execute('CREATE TABLE IF NOT EXISTS marc_samples_v1 (ts REAL PRIMARY KEY, payload TEXT NOT NULL)')
                self.db.commit()
            self.db.execute('INSERT OR REPLACE INTO marc_samples_v1 (ts, payload) VALUES (?, ?)',
                            (timestamp, payload))
            if self.last_pruned is None or now - self.last_pruned >= 60:
                # Prune only MARC's live-session rows; keep any legacy collector table intact.
                self.db.execute('DELETE FROM marc_samples_v1 WHERE ts < ?', (timestamp - 7200,))
                self.last_pruned = now
            self.db.commit()
            self.last_saved = now
        except Exception:
            # Optional persistence must never turn a valid live reading into a collector failure.
            if self.db is not None:
                try:
                    self.db.close()
                except Exception:
                    pass
            self.db = None
            self.last_pruned = None
            self.retry_at = now + 60

history_writer = MARCHistoryWriter()
# MARC_HISTORY_WRITER_END

def run(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL, timeout=8)

if run('/usr/bin/uname', '-s').strip() != 'Darwin':
    raise RuntimeError('This collector currently supports macOS only.')
# CPU tick order: user, system, idle, nice.
lib = ctypes.CDLL('/usr/lib/libSystem.B.dylib')
lib.mach_host_self.restype = ctypes.c_uint
lib.host_statistics.argtypes = [
    ctypes.c_uint, ctypes.c_int,
    ctypes.POINTER(ctypes.c_uint), ctypes.POINTER(ctypes.c_uint)
]
lib.host_statistics.restype = ctypes.c_int
host = lib.mach_host_self()

# Per-core counters; release the allocation after every read.
lib.host_processor_info.argtypes = [
    ctypes.c_uint, ctypes.c_int,
    ctypes.POINTER(ctypes.c_uint),
    ctypes.POINTER(ctypes.POINTER(ctypes.c_uint)),
    ctypes.POINTER(ctypes.c_uint)
]
lib.host_processor_info.restype = ctypes.c_int
lib.vm_deallocate.argtypes = [
    ctypes.c_uint, ctypes.c_ulong, ctypes.c_ulong
]
lib.vm_deallocate.restype = ctypes.c_int
task_port = ctypes.c_uint.in_dll(lib, 'mach_task_self_').value

def core_ticks():
    processors = ctypes.c_uint()
    count = ctypes.c_uint()
    info = ctypes.POINTER(ctypes.c_uint)()
    result = lib.host_processor_info(
        host, 2, ctypes.byref(processors),
        ctypes.byref(info), ctypes.byref(count)
    )
    if result != 0:
        return []
    try:
        if count.value < processors.value * 4:
            return []
        return [
            [info[core * 4 + state] for state in range(4)]
            for core in range(processors.value)
        ]
    finally:
        if info:
            lib.vm_deallocate(
                task_port,
                ctypes.cast(info, ctypes.c_void_p).value,
                count.value * ctypes.sizeof(ctypes.c_uint)
            )

def cpu_ticks():
    ticks = (ctypes.c_uint * 4)()
    count = ctypes.c_uint(4)
    if lib.host_statistics(host, 3, ticks, ctypes.byref(count)) != 0:
        raise RuntimeError('Could not read CPU counters')
    return list(ticks)

hostname = socket.gethostname()
total = int(run('/usr/sbin/sysctl', '-n', 'hw.memsize').strip())
previous = cpu_ticks()
previous_cores = core_ticks()
disk_updated = None
disk_total = disk_used = disk_available = 0

cores = int(run('/usr/sbin/sysctl', '-n', 'hw.logicalcpu').strip())
boot_match = re.search(r'sec = (\d+)', run('/usr/sbin/sysctl', '-n', 'kern.boottime'))
boot = int(boot_match.group(1)) if boot_match else None
model = run('/usr/sbin/sysctl', '-n', 'hw.model').strip()
os_version = run('/usr/bin/sw_vers', '-productVersion').strip()
architecture = run('/usr/bin/uname', '-m').strip()
username = getpass.getuser()
slow_updated = 0
tasks, swap, local_ip = None, None, None
power_updated = 0
battery_percent, power_source, battery_state, has_battery = None, None, None, None

def parse_power(output):
    source = re.search(r"Now drawing from '([^']+)'", output)
    percentage = re.search(r'(\d+)%;\s*([^;\n]+)', output)
    source_name = source.group(1) if source else None
    if percentage:
        return (max(0, min(100, int(percentage.group(1)))),
                source_name, percentage.group(2).strip().lower(), True)
    if source:
        return (None, source_name, None, False)
    return (None, None, None, None)

# MARC_BATTERY_HEALTH_BEGIN
# Optional slow hardware information never blocks the live sampling loop.
import threading

def parse_battery_health(payload):
    entries = payload.get('SPPowerDataType', []) if isinstance(payload, dict) else []
    if not isinstance(entries, list):
        return {}
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        health = entry.get('sppower_battery_health_info')
        if not isinstance(health, dict):
            continue
        result = {}
        condition = health.get('sppower_battery_health')
        if isinstance(condition, str) and condition.strip():
            condition = condition.strip()
            result['batteryCondition'] = {
                'Good': 'Normal', 'Check Battery': 'Service recommended',
                'Poor': 'Service recommended'
            }.get(condition, condition[:80])
        cycles = health.get('sppower_battery_cycle_count')
        if type(cycles) is int and 0 <= cycles <= 100000:
            result['batteryCycleCount'] = cycles
        # Read the explicit percentage, never confuse mAh or current charge with health.
        capacity = health.get('sppower_battery_health_maximum_capacity')
        if isinstance(capacity, str):
            match = re.fullmatch(r'\s*(\d+(?:\.\d+)?)\s*%\s*', capacity)
            if match:
                value = float(match.group(1))
                if 0 <= value <= 100:
                    result['batteryMaximumCapacity'] = value
        return result
    return {}

class MARCBatteryHealth:
    def __init__(self):
        self.lock = threading.Lock()
        self.values = {}
        self.running = False
        self.next_read = 0

    def read(self, has_battery):
        if has_battery is not True:
            return {}
        now = time.monotonic()
        with self.lock:
            values = dict(self.values)
            if self.running or now < self.next_read:
                return values
            self.running = True
            self.next_read = now + 60
        try:
            threading.Thread(target=self._refresh, daemon=True).start()
        except Exception:
            with self.lock:
                self.running = False
        return values

    def _refresh(self):
        values = {}
        try:
            raw = subprocess.check_output(
                ['/usr/sbin/system_profiler', 'SPPowerDataType', '-json'],
                stderr=subprocess.DEVNULL, timeout=3)
            values = parse_battery_health(json.loads(raw))
        except Exception:
            pass
        finally:
            with self.lock:
                self.values = values
                self.running = False

battery_health = MARCBatteryHealth()
# MARC_BATTERY_HEALTH_END

# MARC_DISK_COUNTERS_BEGIN
def parse_disk_counters(raw):
    counters = []
    def walk(node):
        if isinstance(node, dict):
            stats = node.get('Statistics')
            if isinstance(stats, dict) and 'Bytes (Read)' in stats and 'Bytes (Write)' in stats:
                counters.append((int(stats['Bytes (Read)']), int(stats['Bytes (Write)'])))
            for key, value in node.items():
                if key != 'Statistics':
                    walk(value)
        elif isinstance(node, list):
            for item in node:
                walk(item)
    walk(plistlib.loads(raw))
    if not counters:
        return None, None
    return sum(item[0] for item in counters), sum(item[1] for item in counters)

def read_disk_counters():
    # Driver roots expose the counters; omit their unrelated child properties.
    # Keep fresh cumulative counters on every sample so existing rate math holds.
    command = ['/usr/sbin/ioreg', '-r', '-c', 'IOBlockStorageDriver']
    for depth in (['-d', '1'], []):
        try:
            raw = subprocess.check_output(command + depth + ['-a'],
                                          stderr=subprocess.DEVNULL, timeout=5)
            counters = parse_disk_counters(raw)
            if counters[0] is not None:
                return counters
        except (OSError, ValueError, TypeError, OverflowError, subprocess.SubprocessError,
                plistlib.InvalidFileException):
            return None, None
    return None, None
# MARC_DISK_COUNTERS_END

# MARC_NETWORK_COUNTERS_BEGIN
def read_network_counters():
    interface = None
    try:
        route = run('/sbin/route', '-n', 'get', 'default')
        match = re.search(r'interface:[ \t]*(\S+)', route)
        if not match:
            return None, None, None
        interface = match.group(1)
        lines = run('/usr/sbin/netstat', '-ibn').splitlines()
        if not lines:
            return interface, None, None
        headings = lines[0].split()
        incoming, outgoing = headings.index('Ibytes'), headings.index('Obytes')
        for line in lines[1:]:
            cols = line.split()
            if not cols or cols[0] != interface or not any(col.startswith('<Link#') for col in cols):
                continue
            # A missing link address shifts the byte columns one place left.
            offset = len(cols) - len(headings)
            if offset not in (-1, 0):
                continue
            positions = incoming + offset, outgoing + offset
            if not all(0 <= index < len(cols) for index in positions):
                continue
            received, sent = (int(cols[index]) for index in positions)
            if received >= 0 and sent >= 0:
                return interface, received, sent
    except (OSError, ValueError, subprocess.SubprocessError):
        pass
    # Missing network data must not discard otherwise valid system readings.
    return interface, None, None
# MARC_NETWORK_COUNTERS_END

# MARC_STORAGE_CAPACITY_BEGIN
def read_storage_capacity():
    try:
        lines = run('/bin/df', '-k', '/System/Volumes/Data').splitlines()
        if len(lines) < 2:
            return 0, 0, 0
        columns = lines[-1].split()
        total, used, available = (int(columns[index]) for index in (1, 2, 3))
        if not (0 < total <= (2 ** 63 - 1) // 1024 and
                0 <= used <= total and 0 <= available <= total):
            return 0, 0, 0
        return total * 1024, used * 1024, available * 1024
    except (OSError, ValueError, IndexError, subprocess.SubprocessError):
        return 0, 0, 0
# MARC_STORAGE_CAPACITY_END

while True:
    time.sleep(1)
    try:
        current_cores = core_ticks()
        core_usage = None
        if current_cores and len(current_cores) == len(previous_cores):
            core_usage = []
            for current_core, old_core in zip(current_cores, previous_cores):
                change = [
                    (new - old) & 0xffffffff
                    for new, old in zip(current_core, old_core)
                ]
                ticks = sum(change)
                core_usage.append(
                    100 * (ticks - change[2]) / ticks if ticks else 0
                )
        previous_cores = current_cores
        current = cpu_ticks()
        delta = [(new - old) & 0xffffffff for new, old in zip(current, previous)]
        previous = current
        all_ticks = sum(delta)
        cpu = 100 * (all_ticks - delta[2]) / all_ticks if all_ticks else 0
        vm = run('/usr/bin/vm_stat')
        page_match = re.search(r'page size of (\d+) bytes', vm)
        if not page_match:
            raise RuntimeError('Unable to parse memory page size.')
        page = int(page_match.group(1))
        pages = {k.strip(): int(v) for k, v in re.findall(r'^([^:\n]+):\s*(\d+)\.', vm, re.M)}
        # Resident usage estimate; includes wired, active and compressed memory.
        available = sum(pages.get(k, 0) for k in ('Pages free', 'Pages inactive', 'Pages speculative')) * page
        used = max(0, min(total, total - available))
        if disk_updated is None or time.monotonic() - disk_updated >= 5:
            disk_total, disk_used, disk_available = read_storage_capacity()
            # Bound retries after a failure too, independent of wall-clock jumps.
            disk_updated = time.monotonic()
        interface, received, sent = read_network_counters()
        disk_read, disk_write = read_disk_counters()
        if time.time() - slow_updated >= 5:
            try:
                tasks = len(run('/bin/ps', '-axo', 'pid=').splitlines())
                match = re.search(r'used = ([\d.]+)([MG])',
                    run('/usr/sbin/sysctl', '-n', 'vm.swapusage'))
                swap = float(match.group(1)) * (
                    1024 ** (2 if match.group(2) == 'M' else 3)
                ) if match else None
                local_ip = None
                if interface:
                    try:
                        local_ip = run('/usr/sbin/ipconfig',
                            'getifaddr', interface).strip() or None
                    except subprocess.SubprocessError:
                        pass
                slow_updated = time.time()
            except subprocess.SubprocessError:
                pass
        if time.time() - power_updated >= __MARC_POWER_INTERVAL__:
            try:
                battery_percent, power_source, battery_state, has_battery = parse_power(
                    run('/usr/bin/pmset', '-g', 'batt'))
            except (ValueError, subprocess.SubprocessError):
                battery_percent, power_source, battery_state, has_battery = None, None, None, None
            power_updated = time.time()
        details = dict(coreUsage=core_usage, 
            cpuUser=100 * (delta[0] + delta[3]) / all_ticks if all_ticks else 0,
            cpuSystem=100 * delta[1] / all_ticks if all_ticks else 0,
            cores=cores, tasks=tasks,
            uptime=time.time() - boot if boot else None,
            load=os.getloadavg()[0], swap=swap, ip=local_ip,
            model=model, osVersion=os_version,
            architecture=architecture, username=username,
            batteryPercent=battery_percent, powerSource=power_source,
            batteryState=battery_state, hasBattery=has_battery)
        details.update(battery_health.read(has_battery))
        sample = dict(hostname=hostname, cpu=cpu, memoryUsed=used,
            memoryTotal=total, diskUsed=disk_used, diskTotal=disk_total,
            diskAvailable=disk_available, interface=interface, received=received, sent=sent,
            diskReadBytes=disk_read, diskWriteBytes=disk_write, details=details, sampledAt=time.time())
        payload = json.dumps(sample)
        print(payload, flush=True)
        history_writer.save(sample['sampledAt'], payload)
    except BrokenPipeError:
        break
    except Exception as exc:
        print(json.dumps({'collectorError': str(exc)}), flush=True)
MARC_COLLECTOR
"""#
}


private struct MARCArchivePoint: Decodable {
    let date: Double
    let cpu: Double
    let memory: Double
    let load: Double?
    let download: Double?
    let upload: Double?
    let read: Double?
    let write: Double?
}

private struct MARCArchiveFailure: Decodable {
    let error: String
    var message: String {
        switch error {
        case "missing": return "History is starting on this Mac. Keep MARC connected, then try again shortly."
        case "schema": return "Saved history is not ready on this Mac. Reconnect to start collecting."
        default: return "This Mac’s saved history could not be read. Check access to its history database."
        }
    }
}

extension SSHMonitor {
    func loadArchivedHistory(seconds: Int, expectedConnection: UUID? = nil) async {
        guard !Task.isCancelled,
              expectedConnection == nil || expectedConnection == generation else { return }
        let connectionGeneration = generation
        let request = UUID()
        archiveRequest = request
        let duration = [900, 1800, 3600].contains(seconds) ? seconds : 3600
        if archivedHistorySeconds != duration {
            archivedHistory = []
            archiveError = nil
        }
        archivedHistorySeconds = duration
        archiveLoading = false
        guard let client, connected, let serverID = server?.id else {
            archivedHistory = []
            archiveError = "Connect to load saved history."
            return
        }
        archiveLoading = true
        defer {
            if generation == connectionGeneration, archiveRequest == request {
                archiveLoading = false
            }
        }
        let command = """
python3 - \(duration) <<'MARC_HISTORY'
import sqlite3, pathlib, json, time, sys
path = pathlib.Path.home() / '.local/share/marc/history.sqlite'
duration = int(sys.argv[1])
if not path.exists():
    print(json.dumps({'error': 'missing'}))
    sys.exit(0)
end = time.time()
start = end - duration
bucket = {900: 5, 1800: 5, 3600: 10}[duration]
try:
    db = sqlite3.connect(path.as_uri() + '?mode=ro', uri=True, timeout=0.25)
    tables = {row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    if not tables.intersection({'samples', 'marc_samples_v1'}):
        print(json.dumps({'error': 'schema'}))
        sys.exit(0)
    def read_table(name):
        # Names are selected only from the fixed internal table names above.
        return list(db.execute('SELECT ts, payload FROM ' + name +
                               ' WHERE ts >= ? AND ts <= ? ORDER BY ts', (start - 120, end)))
    live = read_table('marc_samples_v1') if 'marc_samples_v1' in tables else []
    legacy = read_table('samples') if 'samples' in tables else []
    # Preserve the existing collector's interval; use session samples outside it.
    if legacy:
        live = [row for row in live if row[0] < legacy[0][0] or row[0] > legacy[-1][0]]
    rows = sorted(legacy + live, key=lambda row: row[0])
    db.close()
except sqlite3.Error:
    print(json.dumps({'error': 'unreadable'}))
    sys.exit(0)
groups = {}
previous = None

def rate(current, old, field, dt):
    a, b = current.get(field), old.get(field)
    if a is None or b is None or a < b:
        return None
    return (a - b) / dt

for timestamp, payload in rows:
    sample = json.loads(payload)
    values = dict(
        cpu=sample['cpu'],
        memory=sample['memoryUsed'] / sample['memoryTotal'] * 100,
        load=(sample.get('details') or {}).get('load'),
        download=None, upload=None, read=None, write=None
    )
    if previous:
        old_time, old = previous
        dt = timestamp - old_time
        if 0 < dt <= 120:
            if old.get('interface') == sample.get('interface'):
                values['download'] = rate(sample, old, 'received', dt)
                values['upload'] = rate(sample, old, 'sent', dt)
            values['read'] = rate(sample, old, 'diskReadBytes', dt)
            values['write'] = rate(sample, old, 'diskWriteBytes', dt)
    previous = (timestamp, sample)
    if timestamp < start:
        continue
    key = int(timestamp // bucket) * bucket
    group = groups.setdefault(key, {'date': [], **{k: [] for k in values}})
    group['date'].append(timestamp)
    for field, value in values.items():
        if value is not None:
            group[field].append(value)

result = []
for key in sorted(groups):
    group = groups[key]
    result.append({
        field: sum(values) / len(values) if values else None
        for field, values in group.items()
    })
print(json.dumps(result))
MARC_HISTORY
"""
        do {
            let buffer = try await client.executeCommand(
                command, maxResponseSize: 524288, mergeStreams: true
            )
            let data = Data(buffer.readableBytesView)
            if let failure = try? JSONDecoder().decode(MARCArchiveFailure.self, from: data) {
                guard !Task.isCancelled, generation == connectionGeneration,
                      archiveRequest == request, server?.id == serverID else { return }
                archivedHistory = []
                archiveError = failure.message
                return
            }
            let rows = try JSONDecoder().decode([MARCArchivePoint].self, from: data)
            guard !Task.isCancelled, generation == connectionGeneration,
                  archiveRequest == request, server?.id == serverID else { return }
            archivedHistory = rows.map {
                SystemHistoryPoint(
                    date: Date(timeIntervalSince1970: $0.date),
                    load: $0.load, cpu: $0.cpu, memory: $0.memory,
                    download: $0.download, upload: $0.upload,
                    read: $0.read, write: $0.write
                )
            }
            archiveError = nil
        } catch {
            guard !Task.isCancelled, generation == connectionGeneration,
                  archiveRequest == request else { return }
            archivedHistory = []
            archiveError = "Saved history could not be loaded."
        }
    }
}


struct MARCProcess: Codable, Identifiable, Equatable, Sendable {
    let started: String?
    let pid: Int
    let user: String
    let cpu: Double
    let memory: Double
    let name: String
    var id: String { "\(pid):\(started ?? "")" }
}

extension SSHMonitor {
    var processConnectionID: UUID { generation }

    func terminateProcess(_ process: MARCProcess, expectedConnection: UUID? = nil) async throws {
        try Task.checkCancellation()
        if let expectedConnection, expectedConnection != generation { throw CancellationError() }
        guard let client, connected, process.pid > 1,
              process.started != nil else {
            throw NSError(domain: "MARC", code: 11, userInfo: [
                NSLocalizedDescriptionKey: "This process cannot be terminated."
            ])
        }
        let encoded = try JSONEncoder().encode(process).base64EncodedString()
        let connection = generation
        let command = """
python3 - \(encoded) <<'MARC_TERMINATE'
import subprocess, json, os, sys, base64, signal
expected = json.loads(base64.b64decode(sys.argv[1]))
pid = int(expected['pid'])
if pid <= 1:
    raise RuntimeError('Protected process.')
environment = dict(os.environ, LC_ALL='C')
result = subprocess.run(
    ['/bin/ps', '-p', str(pid), '-o', 'user=,lstart=,comm='],
    text=True, capture_output=True, timeout=5, env=environment
)
fields = result.stdout.strip().split(None, 6)
if len(fields) != 7:
    raise RuntimeError('Process has already exited.')
started = ' '.join(fields[1:6])
name = os.path.basename(fields[6])
if (fields[0] != expected['user'] or
    started != expected['started'] or name != expected['name']):
    raise RuntimeError('Process identity changed. Refresh and try again.')
try:
    os.kill(pid, signal.SIGTERM)
except PermissionError:
    raise RuntimeError('macOS denied permission to terminate this process.')
except ProcessLookupError:
    raise RuntimeError('Process has already exited.')
print('MARC_TERMINATE_OK')
MARC_TERMINATE
"""
        let buffer = try await client.executeCommand(
            command, maxResponseSize: 8192, mergeStreams: true
        )
        try Task.checkCancellation()
        guard connected, generation == connection else { throw CancellationError() }
        let output = String(decoding: buffer.readableBytesView, as: UTF8.self)
        guard output.trimmingCharacters(in: .whitespacesAndNewlines) == "MARC_TERMINATE_OK" else {
            throw NSError(domain: "MARC", code: 12, userInfo: [
                NSLocalizedDescriptionKey:
                    output.components(separatedBy: "\n").filter {
                        !$0.trimmingCharacters(in: .whitespaces).isEmpty
                    }.last ?? "Termination request failed."
            ])
        }
    }
}

struct MARCProcessResponse: Decodable, Sendable {
    let total: Int
    let processes: [MARCProcess]
}


extension SSHMonitor {
    func processUpdates(expectedConnection: UUID? = nil) async throws -> AsyncThrowingStream<MARCProcessResponse, Error> {
        try Task.checkCancellation()
        if let expectedConnection, expectedConnection != generation { throw CancellationError() }
        guard let client, connected, let serverID = server?.id else {
            throw NSError(domain: "MARC", code: 20, userInfo: [
                NSLocalizedDescriptionKey: "Connect to a Mac to view processes."
            ])
        }
        let token = UUID().uuidString
        let connection = generation
        let command = """
python3 -u - \(token) <<'MARC_PROCESS_STREAM'
import subprocess, json, os, datetime, time, pathlib, sys
folder = pathlib.Path.home() / '.local/share/marc'
folder.mkdir(parents=True, exist_ok=True)
flag = folder / ('process-stream-' + sys.argv[1])
flag.touch()
environment = dict(os.environ, LC_ALL='C')
previous = {}
previous_time = None

def cpu_seconds(text):
    days = 0
    if '-' in text:
        day, text = text.split('-', 1)
        days = int(day)
    parts = [float(item) for item in text.split(':')]
    value = 0
    for item in parts:
        value = value * 60 + item
    return days * 86400 + value

try:
    while flag.exists():
        cycle = time.monotonic()
        output = subprocess.check_output(
            ['/bin/ps', '-axo', 'pid=,user=,rss=,lstart=,time=,comm='],
            text=True, timeout=8, env=environment
        )
        now = time.monotonic()
        elapsed = now - previous_time if previous_time is not None else None
        current = {}
        rows = []

        for line in output.splitlines():
            fields = line.strip().split(None, 9)
            if len(fields) != 10:
                continue
            try:
                pid = int(fields[0])
                user = fields[1]
                memory = int(fields[2]) * 1024
                started = ' '.join(fields[3:8])
                total_cpu = cpu_seconds(fields[8])
                name = os.path.basename(fields[9]) or fields[9]
                started_at = datetime.datetime.strptime(
                    started, '%a %b %d %H:%M:%S %Y'
                ).timestamp()
                identity = (pid, started)
                current[identity] = total_cpu
                old = previous.get(identity)
                cpu = 0.0
                if elapsed and old is not None and total_cpu >= old:
                    cpu = (total_cpu - old) / elapsed * 100
                elif elapsed and started_at >= time.time() - elapsed:
                    cpu = total_cpu / elapsed * 100

                rows.append((started_at, dict(
                    pid=pid, user=user, memory=memory,
                    started=started, name=name, cpu=round(cpu, 1)
                )))
            except (ValueError, OverflowError):
                continue

        rows.sort(key=lambda item: (item[0], item[1]['pid']), reverse=True)
        if previous_time is not None and flag.exists():
            print(json.dumps(dict(
                total=len(rows),
                processes=[item[1] for item in rows]
            )), flush=True)

        previous = current
        previous_time = now
        time.sleep(max(0, 1 - (time.monotonic() - cycle)))
except BrokenPipeError:
    pass
finally:
    flag.unlink(missing_ok=True)
MARC_PROCESS_STREAM
"""
        let remote = try await client.executeCommandStream(command)
        guard !Task.isCancelled, connected, generation == connection else {
            // Cleanup must not inherit cancellation from the abandoned opener.
            Task { @MainActor in await Self.stopProcessStream(token, using: client) }
            throw CancellationError()
        }

        return AsyncThrowingStream { continuation in
            let reader = Task { @MainActor [weak self] in
                var pending = Data()
                do {
                    for try await event in remote {
                        guard !Task.isCancelled, let self,
                              self.connected, self.server?.id == serverID,
                              self.generation == connection else {
                            throw CancellationError()
                        }
                        switch event {
                        case .stdout(let chunk):
                            pending.append(contentsOf: chunk.readableBytesView)
                            guard pending.count <= 4194304 else {
                                throw NSError(domain: "MARC", code: 21, userInfo: [
                                    NSLocalizedDescriptionKey: "Process output exceeded its limit."
                                ])
                            }
                            while let newline = pending.firstIndex(of: 10) {
                                let line = Data(pending[..<newline])
                                pending.removeSubrange(...newline)
                                if line.isEmpty { continue }
                                let response = try JSONDecoder().decode(
                                    MARCProcessResponse.self, from: line
                                )
                                self.processTotalCount = response.total
                                continuation.yield(response)
                            }
                        case .stderr:
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                reader.cancel()
                Task { @MainActor in
                    await Self.stopProcessStream(token, using: client)
                }
            }
        }
    }

    private static func stopProcessStream(_ token: String, using client: SSHClient) async {
        let command = """
python3 - <<'MARC_STOP_PROCESSES'
import pathlib
(pathlib.Path.home() / '.local/share/marc/process-stream-\(token)').unlink(missing_ok=True)
MARC_STOP_PROCESSES
"""
        _ = try? await client.executeCommand(
            command, maxResponseSize: 1024, mergeStreams: true
        )
    }
}

extension SSHMonitor {
    func marcInstalledAIModels() async throws -> [String] {
        try Task.checkCancellation()
        guard connected, let client else {
            throw MARCAIError.message("Connect a Mac first.")
        }
        let serverID = server?.id
        let connection = generation
        let command = """
        python3 - <<'MARC_MODELS'
        import json, urllib.request
        try:
            with urllib.request.urlopen(
                'http://127.0.0.1:11434/api/tags', timeout=10
            ) as response:
                data = response.read(262145)
            if len(data) > 262144:
                raise ValueError('Response too large')
            result = json.loads(data)
            names = sorted(set(
                model['name'] for model in result.get('models', [])
                if isinstance(model.get('name'), str)
            ))
            print(json.dumps({'names': names}))
        except Exception:
            print(json.dumps({'error':
                'Could not read models. Make sure Ollama is running on this Mac, then refresh.'}))
        MARC_MODELS
        """
        let output = try await client.executeCommand(
            command, maxResponseSize: 262144, mergeStreams: false
        )
        try Task.checkCancellation()
        guard connected, server?.id == serverID, generation == connection else {
            throw CancellationError()
        }
        let data = Data(output.readableBytesView)
        guard let result = try JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any] else {
            throw MARCAIError.message("Invalid model list.")
        }
        if let error = result["error"] as? String {
            throw MARCAIError.message(error)
        }
        guard let names = result["names"] as? [String] else {
            throw MARCAIError.message("Invalid model list.")
        }
        return names
    }
}

// MARK: - MARC live Control Center
struct MARCControlDisplay: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
    let resolution: String
    let supported: Bool
    let brightness: Int?
}
struct MARCControlOutput: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
}
struct MARCControlState: Decodable, Sendable {
    var volume: Int?
    var muted: Bool?
    var audioError: String?
    var wifiEnabled: Bool?
    var wifiInterface: String?
    var wifiName: String?
    var wifiError: String?
    var bluetoothEnabled: Bool?
    var bluetoothWritable: Bool
    var bluetoothError: String?
    var wirelessIncluded: Bool
    var actionError: String?
    var displays: [MARCControlDisplay]?
    var selectedDisplayID: Int?
    var displayName: String?
    var brightness: Int?
    var brightnessError: String?
    var outputs: [MARCControlOutput]?
    var audioOutputID: Int?
    var audioOutputName: String?
    var audioOutputError: String?
    var mediaPlayers: [String]?
    var mediaHelperInstalled: Bool?
    var mediaInstallCommand: String?
    var mediaSetupMessage: String?
    var nowPlaying: MARCNowPlaying?
    var mediaError: String?
    var screenLocked: Bool?
}
struct MARCNowPlaying: Decodable, Sendable {
    let title: String
    let artist: String?
    let source: String
    let playing: Bool?
    let prohibitsSkip: Bool
}

enum MARCControlAction: String, Encodable, Sendable {
    case read, volume, mute, wifi, bluetooth, output, brightness
    case lock, displaySleep, displayWake, playPause, previousTrack, nextTrack
}
private struct MARCControlRequest: Encodable {
    let action: MARCControlAction
    let value: Int?
    let includeWireless: Bool
    let displayID: Int?
}

extension SSHMonitor {
    var controlConnectionID: UUID { generation }

    func marcControlRequest(_ action: MARCControlAction = .read,
                            value: Int? = nil, includeWireless: Bool = true, displayID: Int? = nil,
                            expectedConnection: UUID? = nil) async throws -> MARCControlState {
        try Task.checkCancellation()
        if let expectedConnection, expectedConnection != generation { throw CancellationError() }
        guard connected, let client else {
            throw MARCAIError.message("Connect to a Mac in Settings first.")
        }
        let connectionGeneration = generation
        let request = MARCControlRequest(action: action, value: value, includeWireless: includeWireless, displayID: displayID)
        let encoded = try JSONEncoder().encode(request).base64EncodedString()
        let command = "python3 - " + encoded + " <<'MARC_CONTROLS'\n" + Self.marcControlPython + "\nMARC_CONTROLS\n"
        let response = try await client.executeCommand(command, maxResponseSize: 65536, mergeStreams: false)
        try Task.checkCancellation()
        guard connected, generation == connectionGeneration else { throw CancellationError() }
        return try JSONDecoder().decode(MARCControlState.self, from: Data(response.readableBytesView))
    }

    private static let marcControlPython = #"""
import base64, json, os, re, shutil, subprocess, sys, time
import ctypes as C, math

class AudioAddress(C.Structure):
    _fields_ = [('selector', C.c_uint32), ('scope', C.c_uint32), ('element', C.c_uint32)]

def fourcc(text): return int.from_bytes(text.encode('ascii'), 'big')

class MacAudio:
    def __init__(self):
        self.audio = C.CDLL('/System/Library/Frameworks/CoreAudio.framework/CoreAudio')
        self.cf = C.CDLL('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
        ptr = C.POINTER(AudioAddress)
        self.audio.AudioObjectGetPropertyDataSize.argtypes = [C.c_uint32,ptr,C.c_uint32,C.c_void_p,C.POINTER(C.c_uint32)]
        self.audio.AudioObjectGetPropertyDataSize.restype = C.c_int32
        self.audio.AudioObjectGetPropertyData.argtypes = [C.c_uint32,ptr,C.c_uint32,C.c_void_p,C.POINTER(C.c_uint32),C.c_void_p]
        self.audio.AudioObjectGetPropertyData.restype = C.c_int32
        self.audio.AudioObjectSetPropertyData.argtypes = [C.c_uint32,ptr,C.c_uint32,C.c_void_p,C.c_uint32,C.c_void_p]
        self.audio.AudioObjectSetPropertyData.restype = C.c_int32
        self.audio.AudioObjectIsPropertySettable.argtypes = [C.c_uint32,ptr,C.POINTER(C.c_ubyte)]
        self.audio.AudioObjectIsPropertySettable.restype = C.c_int32
        self.cf.CFStringGetLength.argtypes = [C.c_void_p]
        self.cf.CFStringGetLength.restype = C.c_long
        self.cf.CFStringGetMaximumSizeForEncoding.argtypes = [C.c_long,C.c_uint32]
        self.cf.CFStringGetMaximumSizeForEncoding.restype = C.c_long
        self.cf.CFStringGetCString.argtypes = [C.c_void_p,C.c_void_p,C.c_long,C.c_uint32]
        self.cf.CFStringGetCString.restype = C.c_ubyte
        self.cf.CFRelease.argtypes = [C.c_void_p]
        self.cf.CFRelease.restype = None
    def address(self, selector, scope='glob'): return AudioAddress(fourcc(selector),fourcc(scope),0)
    def size(self, obj, address):
        size=C.c_uint32()
        if self.audio.AudioObjectGetPropertyDataSize(obj,C.byref(address),0,None,C.byref(size)):
            raise RuntimeError('Audio property unavailable.')
        return size.value
    def read(self, obj, address, target):
        size=C.c_uint32(C.sizeof(target))
        if self.audio.AudioObjectGetPropertyData(obj,C.byref(address),0,None,C.byref(size),C.byref(target)):
            raise RuntimeError('Audio property unavailable.')
        return target
    def string(self, obj, selector):
        value=self.read(obj,self.address(selector),C.c_void_p())
        if not value.value: return ''
        try:
            length=self.cf.CFStringGetLength(value)
            size=self.cf.CFStringGetMaximumSizeForEncoding(length,0x08000100)+1
            if not 1 <= size <= 65536: return ''
            buffer=C.create_string_buffer(size)
            if not self.cf.CFStringGetCString(value,buffer,size,0x08000100): return ''
            return buffer.value.decode('utf-8',errors='replace')
        finally: self.cf.CFRelease(value)
    def current(self): return self.read(1,self.address('dOut'),C.c_uint32()).value
    def outputs(self):
        address=self.address('dev#')
        size=self.size(1,address)
        if size > 16384 or size%4: raise RuntimeError('Audio device list unavailable.')
        ids=(C.c_uint32*(size//4))()
        self.read(1,address,ids)
        rows=[]
        for obj in ids:
            try:
                if self.size(obj,self.address('stm#','outp')) == 0: continue
                alive=self.read(obj,self.address('livn'),C.c_uint32()).value
                if not alive: continue
                name=self.string(obj,'lnam')
                if name: rows.append(dict(id=int(obj),name=name))
            except Exception: continue
        return sorted(rows,key=lambda row: (row['name'].lower(),row['id']))
    def select(self, value):
        if value not in [row['id'] for row in self.outputs()]:
            raise RuntimeError('That audio output is no longer available. Refresh and choose again.')
        address=self.address('dOut')
        writable=C.c_ubyte()
        if self.audio.AudioObjectIsPropertySettable(1,C.byref(address),C.byref(writable)) or not writable.value:
            raise RuntimeError('macOS does not allow this audio-output change.')
        data=C.c_uint32(value)
        if self.audio.AudioObjectSetPropertyData(1,C.byref(address),0,None,C.sizeof(data),C.byref(data)):
            raise RuntimeError('macOS rejected the audio-output change.')

class MacBrightness:
    @staticmethod
    def online():
        cg=C.CDLL('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
        cg.CGGetOnlineDisplayList.argtypes=[C.c_uint32,C.POINTER(C.c_uint32),C.POINTER(C.c_uint32)]
        cg.CGGetOnlineDisplayList.restype=C.c_int32
        cg.CGDisplayIsBuiltin.argtypes=[C.c_uint32];cg.CGDisplayIsBuiltin.restype=C.c_uint32
        cg.CGDisplayPixelsWide.argtypes=[C.c_uint32];cg.CGDisplayPixelsWide.restype=C.c_size_t
        cg.CGDisplayPixelsHigh.argtypes=[C.c_uint32];cg.CGDisplayPixelsHigh.restype=C.c_size_t
        displays=(C.c_uint32*16)();count=C.c_uint32()
        if cg.CGGetOnlineDisplayList(16,displays,C.byref(count)):
            raise RuntimeError('Display information unavailable.')
        rows=[]
        for i in range(min(count.value,16)):
            display=int(displays[i]);builtin=bool(cg.CGDisplayIsBuiltin(display))
            width=int(cg.CGDisplayPixelsWide(display));height=int(cg.CGDisplayPixelsHigh(display))
            name='Built-in display' if builtin else 'External display ' + str(i+1)
            rows.append(dict(id=display,name=name,resolution=str(width)+' × '+str(height),supported=False,brightness=None))
        return rows
    @classmethod
    def displays(cls):
        rows=cls.online()
        for row in rows:
            try:
                controller=cls(row['id'])
                row['brightness']=controller.read()
                row['supported']=True
            except Exception: pass
        return rows
    def __init__(self, selected=None):
        rows=self.online()
        if not rows: raise RuntimeError('No active displays.')
        ids=[row['id'] for row in rows]
        if selected is not None and (isinstance(selected,bool) or not isinstance(selected,int) or selected not in ids):
            raise RuntimeError('This display disconnected. Choose another display.')
        self.display=selected if selected is not None else next((row['id'] for row in rows if row['name']=='Built-in display'),ids[0])
        self.ds=C.CDLL('/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices')
        self.ds.DisplayServicesCanChangeBrightness.argtypes=[C.c_uint32]
        self.ds.DisplayServicesCanChangeBrightness.restype=C.c_bool
        self.ds.DisplayServicesGetBrightness.argtypes=[C.c_uint32,C.POINTER(C.c_float)]
        self.ds.DisplayServicesGetBrightness.restype=C.c_int32
        self.ds.DisplayServicesSetBrightness.argtypes=[C.c_uint32,C.c_float]
        self.ds.DisplayServicesSetBrightness.restype=C.c_int32
        if not self.ds.DisplayServicesCanChangeBrightness(self.display):
            raise RuntimeError('This display does not expose brightness control.')
    def read(self):
        value=C.c_float()
        if self.ds.DisplayServicesGetBrightness(self.display,C.byref(value)):
            raise RuntimeError('Brightness is unavailable for this display.')
        if not math.isfinite(value.value) or not 0 <= value.value <= 1:
            raise RuntimeError('Display reported an invalid brightness.')
        return round(value.value*100)
    def set(self, percent):
        if not 0 <= percent <= 100: raise RuntimeError('Brightness must be between 0 and 100.')
        if self.ds.DisplayServicesSetBrightness(self.display,C.c_float(percent/100)):
            raise RuntimeError('macOS rejected the brightness change.')


request = json.loads(base64.b64decode(sys.argv[1]))
result = dict(volume=None, muted=None, audioError=None,
              wifiEnabled=None, wifiInterface=None, wifiName=None, wifiError=None,
              bluetoothEnabled=None, bluetoothWritable=False, bluetoothError=None,
              wirelessIncluded=bool(request.get('includeWireless')), actionError=None,
              displays=[], selectedDisplayID=None, displayName=None, brightness=None, brightnessError=None, outputs=[], audioOutputID=None,
              audioOutputName=None, audioOutputError=None, mediaPlayers=[])

def run(*args, timeout=8):
    completed = subprocess.run(args, text=True, capture_output=True,
                               timeout=timeout, env=dict(os.environ, LC_ALL='C'))
    if completed.returncode:
        message = (completed.stderr or completed.stdout).strip()
        raise RuntimeError(message.splitlines()[-1][:240] if message else 'macOS rejected the request.')
    return completed.stdout.strip()

def wifi_interface(output):
    for block in re.split(r'\n\s*\n', output):
        port = re.search(r'Hardware Port:\s*(.+)', block)
        device = re.search(r'Device:\s*(en\d+)\b', block)
        if port and device and port.group(1).strip().lower() in ('wi-fi', 'wifi', 'airport'):
            return device.group(1)
    return None

def parse_wifi_power(output):
    match = re.search(r':\s*(On|Off)\s*$', output, re.I)
    return match.group(1).lower() == 'on' if match else None

def parse_bluetooth_report(data):
    controllers = data.get('SPBluetoothDataType', [])
    for controller in controllers:
        properties = controller.get('controller_properties', {})
        state = properties.get('controller_state')
        if isinstance(state, str):
            state = state.lower()
            if state in ('on', 'enabled', 'attrib_on', 'spbluetooth_on'): return True
            if state in ('off', 'disabled', 'attrib_off', 'spbluetooth_off'): return False
    return None

def find_blueutil():
    for path in ('/opt/homebrew/bin/blueutil', '/usr/local/bin/blueutil', shutil.which('blueutil')):
        if path and os.path.isfile(path) and os.access(path, os.X_OK): return path
    return None

def read_audio():
    script = ('set s to get volume settings\n'
              'return ((output volume of s) as text) & "|" & ((output muted of s) as text)')
    output = run('/usr/bin/osascript', '-e', script)
    parts = output.split('|')
    if len(parts) != 2: raise RuntimeError('Could not read Mac audio settings.')
    try:
        volume = int(parts[0])
    except ValueError:
        raise RuntimeError('This audio output does not expose adjustable volume.')
    if not 0 <= volume <= 100 or parts[1].lower() not in ('true', 'false'):
        raise RuntimeError('This output does not expose adjustable volume.')
    result['volume'], result['muted'] = volume, parts[1].lower() == 'true'


# Detect only this SSH user's already-open players.
# Polling never launches a music application.
for player in ('Music', 'Spotify'):
    try:
        process = subprocess.run(
            ('/usr/bin/pgrep', '-u', str(os.getuid()), '-x', player),
            capture_output=True, timeout=2
        )
        if process.returncode == 0:
            result['mediaPlayers'].append(player)
    except (OSError, subprocess.TimeoutExpired):
        pass


def find_executable(name):
    for path in ('/opt/homebrew/bin/' + name, '/usr/local/bin/' + name, shutil.which(name)):
        if path and os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    return None

media_tool = find_executable('media-control')
brew_tool = find_executable('brew')
result['mediaHelperInstalled'] = media_tool is not None
result['mediaInstallCommand'] = ("'" + brew_tool.replace("'", "'\"'\"'") + "' install media-control") if brew_tool else None
result['mediaSetupMessage'] = (
    'Copy the command and paste it into MARC Terminal. Then return and tap Check again.'
    if brew_tool else
    'Homebrew is needed first. Set it up on your Mac, then return here.'
)
result['nowPlaying'] = None
result['mediaError'] = None
result['screenLocked'] = None

def read_now_playing():
    result['nowPlaying'] = None
    if not media_tool:
        return
    try:
        # Keep artwork on the Mac: only small selected fields enter the SSH response.
        data = json.loads(run(media_tool, 'get', timeout=3))
        if data is None:
            return
        if not isinstance(data, dict):
            raise ValueError('Invalid media response')
        title = data.get('title')
        bundle = data.get('parentApplicationBundleIdentifier') or data.get('bundleIdentifier')
        if not isinstance(title, str) or not title.strip() or not isinstance(bundle, str):
            return
        names = {'com.apple.Safari': 'Safari', 'com.google.Chrome': 'Chrome',
                 'com.brave.Browser': 'Brave', 'org.mozilla.firefox': 'Firefox',
                 'com.microsoft.edgemac': 'Edge', 'com.apple.Music': 'Music',
                 'com.spotify.client': 'Spotify'}
        playing = data.get('playing')
        result['nowPlaying'] = dict(
            title=title[:300],
            artist=data.get('artist')[:200] if isinstance(data.get('artist'), str) else None,
            source=names.get(bundle, bundle[:160]),
            playing=playing if isinstance(playing, bool) else None,
            prohibitsSkip=data.get('prohibitsSkip') is True
        )
    except Exception:
        result['mediaError'] = 'Now Playing could not be read. Check that media is open on the Mac, then tap Check again.'

def control_active_media(action):
    read_now_playing()
    if not media_tool or not result['nowPlaying']:
        raise RuntimeError('No active media session. Start playback on the Mac and try again.')
    if action != 'playPause' and result['nowPlaying']['prohibitsSkip']:
        raise RuntimeError('This media session does not allow skipping tracks.')
    if action == 'playPause':
        command = 'toggle-play-pause'
    else:
        # Only use a command advertised by the installed version's help.
        help_result = subprocess.run((media_tool,), text=True, capture_output=True, timeout=3)
        help_text = help_result.stdout + '\n' + help_result.stderr
        options = ('next-track', 'next') if action == 'nextTrack' else ('previous-track', 'previous', 'prev')
        command = next((item for item in options if re.search(
            r'(?<![\w-])' + re.escape(item) + r'(?![\w-])', help_text)), None)
        if not command:
            raise RuntimeError('This helper version does not advertise a track-skip command. Update media-control on your Mac.')
    run(media_tool, command, timeout=4)
    time.sleep(0.15)

def session_locked():
    try:
        cg = C.CDLL('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
        cf = C.CDLL('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
        cg.CGSessionCopyCurrentDictionary.argtypes = []
        cg.CGSessionCopyCurrentDictionary.restype = C.c_void_p
        cf.CFStringCreateWithCString.argtypes = [C.c_void_p, C.c_char_p, C.c_uint32]
        cf.CFStringCreateWithCString.restype = C.c_void_p
        cf.CFDictionaryGetValue.argtypes = [C.c_void_p, C.c_void_p]
        cf.CFDictionaryGetValue.restype = C.c_void_p
        cf.CFBooleanGetValue.argtypes = [C.c_void_p]
        cf.CFBooleanGetValue.restype = C.c_ubyte
        cf.CFRelease.argtypes = [C.c_void_p]
        cf.CFRelease.restype = None
        session = cg.CGSessionCopyCurrentDictionary()
        if not session:
            return None
        key = cf.CFStringCreateWithCString(None, b'CGSSessionScreenIsLocked', 0x08000100)
        try:
            if not key:
                return None
            value = cf.CFDictionaryGetValue(session, key)
            return bool(cf.CFBooleanGetValue(value)) if value else None
        finally:
            if key:
                cf.CFRelease(key)
            cf.CFRelease(session)
    except Exception:
        return None

def lock_session():
    if os.stat('/dev/console').st_uid != os.getuid():
        raise RuntimeError('Connect as the Mac user who is currently signed in to lock their screen.')
    if session_locked() is True:
        return
    # Invoke on the Mac, in a child process. Never activate Terminal or type keys.
    code = (
        'import ctypes as c; '
        'lib=c.CDLL("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"); '
        'f=lib.SACLockScreenImmediate; f.argtypes=[]; f.restype=None; f()'
    )
    try:
        run(sys.executable, '-c', code, timeout=4)
    except Exception:
        raise RuntimeError('This Mac does not support the direct screen-lock request.')
    for _ in range(15):
        if session_locked() is True:
            return
        time.sleep(0.15)
    raise RuntimeError('Lock was requested, but macOS did not confirm it. Check the Mac before relying on it being locked.')

read_now_playing()

action = request.get('action')
value = request.get('value')
blueutil = find_blueutil()
audio_controller = None
brightness_controller = None
try:
    if action not in ('read', 'volume', 'mute', 'wifi', 'bluetooth', 'output', 'brightness',
                       'lock', 'displaySleep', 'displayWake', 'playPause', 'previousTrack', 'nextTrack'):
        raise RuntimeError('Unsupported control request.')
    if action != 'read':
        if isinstance(value, bool) or not isinstance(value, int):
            raise RuntimeError('Invalid control value.')

        if action == 'lock':
            lock_session()
        elif action == 'displaySleep':
            run('/usr/bin/pmset', 'displaysleepnow')
        elif action == 'displayWake':
            run('/usr/bin/caffeinate', '-u', '-t', '1', timeout=3)
        elif action in ('playPause', 'previousTrack', 'nextTrack'):
            if value == 2:
                control_active_media(action)
            else:
                if value not in (0, 1):
                    raise RuntimeError('Choose Music or Spotify.')
                player = 'Spotify' if value else 'Music'
                if player not in result['mediaPlayers']:
                    raise RuntimeError('Open ' + player + ' on your Mac, then refresh controls.')
                command = {
                    'playPause': 'playpause',
                    'previousTrack': 'previous track',
                    'nextTrack': 'next track'
                }[action]
                # Fixed app and command names; no user-supplied script text.
                # Recheck so an app closing during the request is not relaunched.
                script = (
                    'if application "' + player + '" is running then\n'
                    'tell application "' + player + '" to ' + command + '\n'
                    'else\nerror "Player closed"\nend if'
                )
                try:
                    run('/usr/bin/osascript', '-e', script)
                except Exception:
                    raise RuntimeError(
                        'Playback was not confirmed. Check that ' + player +
                        ' is open and allows Automation on your Mac.'
                    )
        elif action == 'volume':
            if not 0 <= value <= 100: raise RuntimeError('Volume must be between 0 and 100.')
            run('/usr/bin/osascript', '-e', 'set volume output volume ' + str(value))
        elif action == 'mute':
            if value not in (0, 1): raise RuntimeError('Invalid mute value.')
            run('/usr/bin/osascript', '-e', 'set volume output muted ' + ('true' if value else 'false'))
        elif action == 'wifi':
            if value not in (0, 1): raise RuntimeError('Invalid Wi-Fi value.')
            interface = wifi_interface(run('/usr/sbin/networksetup', '-listallhardwareports'))
            if not interface: raise RuntimeError('No Wi-Fi interface was detected.')
            run('/usr/sbin/networksetup', '-setairportpower', interface, 'on' if value else 'off')
        elif action == 'output':
            if not 0 < value <= 0xffffffff: raise RuntimeError('Invalid audio output.')
            audio_controller = MacAudio()
            audio_controller.select(value)
            time.sleep(0.15)
        elif action == 'brightness':
            if not 0 <= value <= 100: raise RuntimeError('Brightness must be between 0 and 100.')
            brightness_controller = MacBrightness(request.get('displayID'))
            brightness_controller.set(value)
        elif action == 'bluetooth':
            if value not in (0, 1): raise RuntimeError('Invalid Bluetooth value.')
            if not blueutil: raise RuntimeError('Bluetooth switching requires blueutil on this Mac.')
            run(blueutil, '--power', str(value))
except Exception as exc:
    result['actionError'] = ('This control is unavailable on this Mac.'
                             if isinstance(exc, (OSError, AttributeError)) else str(exc)[:240])

try:
    read_audio()
except Exception as exc:
    result['audioError'] = str(exc)[:240]

try:
    audio_controller = audio_controller or MacAudio()
    result['outputs'] = audio_controller.outputs()
    result['audioOutputID'] = audio_controller.current()
    result['audioOutputName'] = next((row['name'] for row in result['outputs']
                                    if row['id'] == result['audioOutputID']), None)
except Exception:
    result['audioOutputError'] = 'Audio output information is unavailable.'
try:
    result['displays'] = MacBrightness.displays()
    selected = request.get('displayID')
    if selected is not None and not any(row['id'] == selected for row in result['displays']):
        raise RuntimeError('This display disconnected. Choose another display.')
    brightness_controller = brightness_controller or MacBrightness(selected)
    result['selectedDisplayID'] = brightness_controller.display
    result['displayName'] = next((row['name'] for row in result['displays'] if row['id'] == brightness_controller.display), 'Display')
    result['brightness'] = brightness_controller.read()
except Exception as exc:
    result['brightnessError'] = (str(exc)[:160] if isinstance(exc, RuntimeError)
                                 else 'Brightness control is unavailable for this display.')

if result['wirelessIncluded']:
    try:
        interface = wifi_interface(run('/usr/sbin/networksetup', '-listallhardwareports'))
        result['wifiInterface'] = interface
        if not interface: raise RuntimeError('No Wi-Fi interface was detected.')
        result['wifiEnabled'] = parse_wifi_power(run('/usr/sbin/networksetup', '-getairportpower', interface))
        if result['wifiEnabled'] is None: raise RuntimeError('macOS did not report Wi-Fi power state.')
        if result['wifiEnabled']:
            output = run('/usr/sbin/networksetup', '-getairportnetwork', interface)
            match = re.search(r'^Current Wi-Fi Network:\s*(.+)$', output, re.M)
            if match and match.group(1).strip() not in ('<redacted>', '<hidden>', '(null)'):
                result['wifiName'] = match.group(1).strip()
    except Exception as exc:
        result['wifiError'] = str(exc)[:240]
    try:
        result['bluetoothWritable'] = blueutil is not None
        if blueutil:
            power = run(blueutil, '--power')
            if power not in ('0', '1'): raise RuntimeError('Bluetooth power state unavailable.')
            result['bluetoothEnabled'] = power == '1'
        else:
            report = run('/usr/sbin/system_profiler', 'SPBluetoothDataType', '-json', timeout=12)
            result['bluetoothEnabled'] = parse_bluetooth_report(json.loads(report))
            if result['bluetoothEnabled'] is None:
                raise RuntimeError('macOS did not report Bluetooth power state.')
    except Exception as exc:
        result['bluetoothError'] = str(exc)[:240]

if not result['actionError']:
    if action == 'volume' and (result['volume'] is None or abs(result['volume'] - value) > 2):
        result['actionError'] = 'The Mac did not confirm this volume. Its output may have fixed volume.'
    elif action == 'mute' and result['muted'] != bool(value):
        result['actionError'] = 'The Mac did not confirm the mute change.'
    elif action == 'wifi' and result['wifiEnabled'] != bool(value):
        result['actionError'] = 'The Mac did not confirm the Wi-Fi change.'
    elif action == 'bluetooth' and result['bluetoothEnabled'] != bool(value):
        result['actionError'] = 'The Mac did not confirm the Bluetooth change.'
    elif action == 'output' and result['audioOutputID'] != value:
        result['actionError'] = 'The Mac did not confirm the audio-output change.'
    elif action == 'brightness' and (result['brightness'] is None or abs(result['brightness'] - value) > 2):
        result['actionError'] = 'The Mac did not confirm this brightness. Refresh and try again.'
if action in ('playPause', 'previousTrack', 'nextTrack'):
    read_now_playing()
result['screenLocked'] = session_locked()
print(json.dumps(result))
"""#
}



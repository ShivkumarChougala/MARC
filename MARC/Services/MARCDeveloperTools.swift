import Foundation

struct MARCListeningIdentity: Codable, Hashable, Sendable {
    let pid: Int
    let uid: Int
    let started: String
    let executable: String
}

struct MARCListeningService: Codable, Identifiable, Hashable, Sendable {
    let pid: Int
    let name: String
    let address: String
    let port: Int
    var identity: MARCListeningIdentity? = nil
    var stoppable: Bool? = nil
    var canStop: Bool { stoppable == true && identity != nil }
    var endpoint: String { (address.contains(":") ? "[\(address)]" : address) + ":\(port)" }
    var id: String { "\(pid)|\(name)|\(endpoint)|\(identity?.started ?? "")" }
    var previewID: String { "\(pid)|\(port)|\(identity?.started ?? "")" }
    var addressExplanation: String {
        if address == "127.0.0.1" || address == "::1" { return "Bound to loopback on your Mac." }
        if address == "*" || address == "0.0.0.0" || address == "::" { return "Listening on all local interfaces. Reachability depends on your network and firewall." }
        return "Listening on this address on your Mac."
    }
}

struct MARCDeveloperContainer: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let image: String
    let state: String
    let status: String
    var host: String? = nil
}

struct MARCDeveloperReply: Decodable, Sendable {
    var services: [MARCListeningService]?
    var containers: [MARCDeveloperContainer]?
    var managed: [MARCManagedService]?
    var portsMessage: String?
    var managedMessage: String?
    var message: String?
    var feedback: String?
    var truncated: Bool?
}

struct MARCDeveloperCachedRead {
    let reply: MARCDeveloperReply
    let receivedAt: Date
    let uptime: TimeInterval
}

struct MARCManagedService: Codable, Identifiable, Sendable {
    let name: String
    let state: String
    var id: String { name }
}

enum MARCDeveloperPreferences {
    static func tabKey(_ mac: UUID) -> String { "marc.developer.tab.\(mac.uuidString)" }
}

enum MARCDeveloperScript {
    // All target names are validated and passed as argv, never interpolated into a shell.
    static let python = #"""
import base64, json, os, re, selectors, signal, subprocess, sys, time

def clean(value, limit=256):
    return ''.join(c for c in str(value) if c.isprintable())[:limit]

def capture(argv, timeout=8, limit=262144, local_docker=False):
    environment = dict(os.environ, PAGER='cat', GIT_TERMINAL_PROMPT='0', NO_COLOR='1',
                       HOMEBREW_NO_AUTO_UPDATE='1', HOMEBREW_NO_ANALYTICS='1', LC_ALL='C')
    if local_docker:
        for key in ('DOCKER_CONTEXT', 'DOCKER_HOST', 'DOCKER_TLS_VERIFY', 'DOCKER_CERT_PATH'):
            environment.pop(key, None)
    proc = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, start_new_session=True, cwd=os.path.expanduser('~'),
                            env=environment)
    chunks = bytearray()
    selector = selectors.DefaultSelector()
    selector.register(proc.stdout, selectors.EVENT_READ)
    deadline = time.monotonic() + timeout
    try:
        while True:
            if time.monotonic() >= deadline:
                raise RuntimeError('The request timed out. Refresh to check its current state.')
            if not selector.select(min(0.1, max(0, deadline-time.monotonic()))):
                continue
            part = os.read(proc.stdout.fileno(), 8192)
            if not part:
                break
            chunks.extend(part)
            if len(chunks) > limit:
                raise RuntimeError('Too much data returned. Refresh and try again.')
        proc.wait(timeout=max(0.1, deadline-time.monotonic()))
        return proc.returncode, bytes(chunks).decode('utf-8', 'replace')
    finally:
        selector.close()
        # Also stop descendants retaining the output pipe after their parent exits.
        try: os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError: pass
        proc.stdout.close()
        proc.wait()

def process_table():
    code, output = capture(['/bin/ps', '-axo', 'pid=,uid=,ppid=,lstart=,comm='])
    if code != 0: raise RuntimeError('Could not check this process.')
    result = {}
    for line in output.splitlines():
        fields = line.strip().split(None, 8)
        if len(fields) != 9 or not all(x.isdigit() for x in fields[:3]): continue
        pid, uid, parent = map(int, fields[:3])
        result[pid] = dict(pid=pid, uid=uid, parent=parent,
                           started=' '.join(fields[3:8]), executable=fields[8])
    return result

def stoppable_process(row, table):
    if not row or row['pid'] <= 1 or row['uid'] != os.geteuid() or row['uid'] == 0: return False
    protected = {'launchd', 'kernel_task', 'loginwindow', 'WindowServer', 'ControlCenter',
                 'Dock', 'Finder', 'SystemUIServer', 'sshd', 'ssh', 'sshd-session', 'sshd-auth'}
    if os.path.basename(row['executable']) in protected: return False
    if row['executable'].startswith(('/System/', '/usr/libexec/', '/usr/sbin/', '/sbin/')): return False
    ancestor, seen = os.getpid(), set()
    while ancestor > 1 and ancestor not in seen:
        if row['pid'] == ancestor: return False
        seen.add(ancestor)
        ancestor = table.get(ancestor, {}).get('parent', 0)
    return True

def services():
    try: identities = process_table()
    except Exception: identities = {}
    code, output = capture(['/usr/sbin/lsof', '-nP', '-a', '-iTCP', '-sTCP:LISTEN', '-Fpcn'])
    if code == 1 and not output.strip():
        return {'services': []}
    if code != 0:
        raise RuntimeError('Listening ports could not be read for this SSH user.')
    result, seen, pid, name = [], set(), None, None
    for line in output.splitlines():
        if line.startswith('p'):
            pid, name = int(line[1:]) if line[1:].isdigit() else None, None
        elif line.startswith('c'):
            name = clean(line[1:])
        elif line.startswith('n') and pid and name:
            endpoint = line[1:]
            if ':' not in endpoint: continue
            address, port = endpoint.rsplit(':', 1)
            address = address.strip('[]')
            if not port.isdigit() or not 1 <= int(port) <= 65535: continue
            if not re.fullmatch(r'[A-Za-z0-9:.%_*\-]{1,128}', address): continue
            key = (pid, name, address, int(port))
            if key in seen: continue
            seen.add(key)
            identity = identities.get(pid)
            result.append(dict(pid=pid, name=name, address=address, port=int(port),
                identity={k: identity[k] for k in ('pid', 'uid', 'started', 'executable')} if identity else None,
                stoppable=stoppable_process(identity, identities)))
    result.sort(key=lambda row: (row['port'], row['name'], row['pid'], row['address']))
    return {'services': result[:256], 'truncated': len(result) > 256}

def stop_listener(request):
    try: identity = json.loads(request.get('identity', ''))
    except Exception: raise RuntimeError('Refresh the port list and try again.')
    keys = ('pid', 'uid', 'started', 'executable')
    if not isinstance(identity, dict) or not all(k in identity for k in keys):
        raise RuntimeError('Refresh the port list and try again.')
    table = process_table()
    row = table.get(identity['pid']) if type(identity['pid']) is int else None
    if not stoppable_process(row, table): raise RuntimeError('This process cannot be stopped from MARC.')
    if any(row[k] != identity[k] for k in keys): raise RuntimeError('Process changed. Refresh and try again.')
    # The selected address/port must still belong to the selected process.
    listeners = services()['services']
    if not any(r['identity'] == identity and r['address'] == request.get('expectedState') and
               str(r['port']) == request.get('target') for r in listeners):
        raise RuntimeError('Port changed. Refresh and try again.')
    latest_table = process_table()
    latest = latest_table.get(identity['pid'])
    if not stoppable_process(latest, latest_table) or any(latest[k] != identity[k] for k in keys):
        raise RuntimeError('Process changed. Refresh and try again.')
    try: os.kill(identity['pid'], signal.SIGTERM)
    except PermissionError: raise RuntimeError('macOS denied permission to stop this process.')
    except ProcessLookupError: raise RuntimeError('Process already stopped.')
    current = process_table().get(identity['pid'])
    stopped = not current or any(current[k] != identity[k] for k in keys)
    result = services()
    result['feedback'] = 'Stopped.' if stopped else 'Stop requested.'
    return result

def docker_connection():
    paths = ['/usr/local/bin/docker', '/opt/homebrew/bin/docker',
             '/Applications/Docker.app/Contents/Resources/bin/docker']
    binary = next((p for p in paths if os.path.isfile(p) and os.access(p, os.X_OK)), None)
    if not binary: raise RuntimeError('Docker is not installed on this Mac.')
    host = os.environ.get('DOCKER_HOST', '')
    if not host:
        code, output = capture([binary, 'context', 'inspect', '--format', '{{json .Endpoints.docker.Host}}'], limit=8192)
        if code != 0: raise RuntimeError('Open Docker on your Mac, then try again.')
        host = json.loads(output.strip())
    if not isinstance(host, str) or not host.startswith('unix:///') or len(host) > 1024:
        raise RuntimeError('Select a local Docker connection on your Mac.')
    return binary, host

def docker_rows(binary, host):
    code, output = capture([binary, '--host', host, 'ps', '-a', '--no-trunc', '--format', '{{json .}}'], local_docker=True)
    if code != 0: raise RuntimeError('Could not read containers. Check Docker on your Mac.')
    rows, seen = [], set()
    for line in output.splitlines():
        row = json.loads(line)
        identifier = row.get('ID', '')
        if not re.fullmatch('[0-9a-f]{64}', identifier): raise RuntimeError('Docker returned an invalid container.')
        if identifier in seen: continue
        seen.add(identifier)
        rows.append(dict(id=identifier, name=clean(row.get('Names', '')), image=clean(row.get('Image', '')),
                         state=clean(row.get('State', ''), 32), status=clean(row.get('Status', '')), host=host))
    rows.sort(key=lambda row: (row['state'] != 'running', row['name'], row['id']))
    return rows

def docker(request=None):
    binary, host = docker_connection()
    rows = docker_rows(binary, host)
    feedback = None
    if request:
        target, verb = request.get('target', ''), request.get('action')
        if not re.fullmatch('[0-9a-f]{64}', target): raise RuntimeError('Refresh the container list and try again.')
        if request.get('expectedHost') != host: raise RuntimeError('Docker connection changed. Refresh and try again.')
        current = next((row for row in rows if row['id'] == target), None)
        if not current or current['state'] != request.get('expectedState'):
            raise RuntimeError('Container state changed. Refresh and try again.')
        if verb == 'dockerStart' and current['state'] not in ('created', 'exited'):
            raise RuntimeError('This container cannot be started in its current state.')
        if verb == 'dockerStop' and current['state'] != 'running':
            raise RuntimeError('This container is not running.')
        if verb == 'dockerStart': args = ['start', target]
        elif verb == 'dockerStop': args = ['stop', '--timeout', '10', target]
        else: raise RuntimeError('Unsupported container action.')
        code, _ = capture([binary, '--host', host] + args, timeout=20, limit=16384, local_docker=True)
        if code != 0: raise RuntimeError('Could not change this container. Refresh to check its state.')
        rows = docker_rows(binary, host)
        current = next((row for row in rows if row['id'] == target), None)
        desired = 'running' if verb == 'dockerStart' else 'exited'
        feedback = ('Started.' if verb == 'dockerStart' else 'Stopped.') if current and current['state'] == desired else 'Request sent. Check the current state below.'
    return dict(containers=rows[:256], truncated=len(rows)>256, feedback=feedback)

def brew_binary():
    if os.geteuid() == 0: raise RuntimeError('Use your normal Mac account to manage services.')
    return next((p for p in ['/opt/homebrew/bin/brew', '/usr/local/bin/brew']
                 if os.path.isfile(p) and os.access(p, os.X_OK)), None)

def brew_rows(binary):
    if not binary: return []
    code, output = capture([binary, 'services', 'list', '--json'], timeout=12)
    if code != 0: raise RuntimeError('Could not read background services.')
    source = json.loads(output)
    if not isinstance(source, list): raise RuntimeError('Could not read background services.')
    rows, seen = [], set()
    for row in source:
        name = row.get('name', '')
        if not isinstance(name, str) or not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9@+_.-]{0,127}', name): continue
        if name in seen: continue
        seen.add(name)
        rows.append(dict(name=name, state=clean(row.get('status', 'unknown'), 32)))
    return sorted(rows, key=lambda row: (row['state'] != 'started', row['name']))

def managed_services(request=None):
    binary = brew_binary()
    if request and not binary: raise RuntimeError('Homebrew is not installed on this Mac.')
    rows = brew_rows(binary)
    feedback = None
    if request:
        target, verb = request.get('target', ''), request.get('action')
        if not isinstance(target, str) or not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9@+_.-]{0,127}', target):
            raise RuntimeError('Refresh the service list and try again.')
        current = next((row for row in rows if row['name'] == target), None)
        if not current or current['state'] != request.get('expectedState'):
            raise RuntimeError('Service state changed. Refresh and try again.')
        if verb == 'serviceStart' and current['state'] not in ('none', 'stopped'):
            raise RuntimeError('This service cannot be started in its current state.')
        if verb == 'serviceStop' and current['state'] != 'started':
            raise RuntimeError('This service is not running.')
        # Run does not change launch-at-login registration. Stop preserves registration.
        if verb == 'serviceStart': args = ['services', 'run', target]
        elif verb == 'serviceStop': args = ['services', 'stop', '--keep', '--max-wait=5', target]
        else: raise RuntimeError('Unsupported service action.')
        code, _ = capture([binary] + args, timeout=20, limit=16384)
        if code != 0: raise RuntimeError('Could not change this service. Refresh to check its state.')
        rows = brew_rows(binary)
        current = next((row for row in rows if row['name'] == target), None)
        done = current and (current['state'] == 'started' if verb == 'serviceStart' else current['state'] in ('none', 'stopped'))
        feedback = ('Started.' if verb == 'serviceStart' else 'Stopped.') if done else 'Request sent. Check the current state below.'
    return dict(managed=rows[:128], truncated=len(rows)>128, feedback=feedback)

def handle(request):
    if os.uname().sysname != 'Darwin': raise RuntimeError('Connect to a Mac first.')
    action = request.get('action')
    if action == 'services':
        try: result = services()
        except Exception: result = dict(services=[], portsMessage='Could not read listening ports.')
        try:
            managed = managed_services()
            managed['truncated'] = result.get('truncated', False) or managed.get('truncated', False)
            result.update(managed)
        except Exception: result['managedMessage'] = 'Background services are unavailable.'
        return result
    if action == 'docker': return docker()
    if action == 'portStop': return stop_listener(request)
    if action in ('dockerStart', 'dockerStop'): return docker(request)
    if action in ('serviceStart', 'serviceStop'): return managed_services(request)
    raise RuntimeError('Unsupported action.')

try:
    request = json.loads(base64.b64decode(sys.argv[1], validate=True))
    result = handle(request)
except Exception as error:
    result = {'message': clean(str(error), 240)}
print(json.dumps(result, ensure_ascii=True))
"""#
}

#!/usr/bin/env python3
"""Exercise production Developer Tools reads/actions with fixture CLI responses."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys
import tempfile
from unittest.mock import patch

root = Path(__file__).resolve().parents[1]
source = (root/'MARC/Services/MARCDeveloperTools.swift').read_text()
ui = (root/'MARC/Screens/MARCDeveloperToolsView.swift').read_text()
script = source.split('static let python = #"""\n',1)[1].split('\n"""#',1)[0]
ns = {}
exec(compile(script.split('\ntry:\n    request =',1)[0], '<production-developer-tools>', 'exec'), ns)
real_capture = ns['capture']

def failure(fn, expected):
    try: fn()
    except Exception as error: assert expected in str(error), str(error)
    else: raise AssertionError('Expected failure: '+expected)

def reply(code, output):
    ns['capture'] = lambda *args, **kwargs: (code, output)

with patch.object(os,'uname',return_value=type('Darwin',(),{'sysname':'Darwin'})()), patch.object(os,'geteuid',return_value=501):
    reply(0,'p42\ncnode\nf1\nn127.0.0.1:3000\nf2\nn127.0.0.1:3000\nn[::1]:3000\np43\ncpython\nn*:8000\nn*:99999\nninvalid:abc\npbad\ncstale\nn*:33\n')
    rows = ns['services']()['services']
    assert len(rows)==3 and rows[0]['pid']==42 and rows[1]['address']=='::1' and rows[-1]['port']==8000
    reply(1,''); assert ns['services']()=={'services':[]}
    reply(1,'lsof failure'); failure(ns['services'],'could not be read')
    reply(0,'p7\ncnode\n'+''.join(f'n127.0.0.1:{p}\n' for p in range(1,301)))
    assert ns['services']()['truncated'] and len(ns['services']()['services'])==256
    with patch.object(os.path,'isfile',return_value=False):
        failure(ns['docker'],'not installed')
        assert ns['managed_services']()['managed']==[]
    with patch.object(os.path,'isfile',return_value=True),patch.object(os,'access',return_value=True),patch.dict(os.environ,{},clear=True):
        state = {'docker':'exited','brew':'none','fail':False,'verify':True}
        mutations = []
        identifier='a'*64
        def capture(argv, **kwargs):
            if 'context' in argv: return 0,'"unix:///var/run/docker.sock"'
            if 'ps' in argv:
                return 0,json.dumps(dict(ID=identifier,Names='web',Image='web:latest',State=state['docker'],Status='current'))
            if 'list' in argv: return 0,json.dumps([dict(name='redis',status=state['brew']),dict(name='--all',status='started')])
            mutations.append(argv)
            if state['fail']: return 1,'failed'
            if state['verify']:
                if 'start' in argv: state['docker']='running'
                if 'stop' in argv and '--host' in argv: state['docker']='exited'
                if 'run' in argv: state['brew']='started'
                if 'stop' in argv and 'services' in argv: state['brew']='none'
            return 0,'ok'
        ns['capture']=capture
        assert ns['docker']()['containers'][0]['host']=='unix:///var/run/docker.sock'
        op=dict(action='dockerStart',target=identifier,expectedState='exited',expectedHost='unix:///var/run/docker.sock')
        assert ns['handle'](op)['feedback']=='Started.'
        assert mutations[-1][-2:]==['start',identifier]
        op.update(action='dockerStop',expectedState='running')
        assert ns['handle'](op)['feedback']=='Stopped.'
        assert mutations[-1][-4:]==['stop','--timeout','10',identifier]
        count=len(mutations)
        failure(lambda:ns['handle'](op),'state changed');assert len(mutations)==count
        failure(lambda:ns['handle'](dict(op,target='--all')),'Refresh')
        failure(lambda:ns['handle'](dict(op,target='b'*64)),'state changed')
        failure(lambda:ns['handle'](dict(op,expectedHost='unix:///other.sock')),'connection changed')
        assert len(mutations)==count
        state['docker']='paused';failure(lambda:ns['handle'](dict(op,expectedState='paused')),'not running')
        state['docker']='exited';state['fail']=True
        failure(lambda:ns['handle'](dict(op,action='dockerStart',expectedState='exited')),'Could not change')
        state['fail']=False;state['verify']=False
        assert ns['handle'](dict(op,action='dockerStart',expectedState='exited'))['feedback'].startswith('Request sent')
        state['verify']=True
        count=len(mutations)
        with patch.dict(os.environ,{'DOCKER_HOST':'tcp://remote:2375'}): failure(ns['docker'],'local Docker')
        assert len(mutations)==count
        assert [r['name'] for r in ns['managed_services']()['managed']]==['redis']
        brew=dict(action='serviceStart',target='redis',expectedState='none')
        assert ns['handle'](brew)['feedback']=='Started.'
        assert mutations[-1][-3:]==['services','run','redis']
        brew.update(action='serviceStop',expectedState='started')
        assert ns['handle'](brew)['feedback']=='Stopped.'
        assert mutations[-1][-5:]==['services','stop','--keep','--max-wait=5','redis']
        count=len(mutations)
        failure(lambda:ns['handle'](brew),'state changed')
        failure(lambda:ns['handle'](dict(brew,target='--all')),'Refresh')
        failure(lambda:ns['handle'](dict(brew,target='redis;rm')),'Refresh')
        failure(lambda:ns['handle'](dict(brew,target='not-installed')),'state changed')
        assert len(mutations)==count
        state['brew']='error';failure(lambda:ns['handle'](dict(brew,action='serviceStart',expectedState='error')),'cannot be started')
        state['brew']='none';state['fail']=True
        failure(lambda:ns['handle'](dict(brew,action='serviceStart',expectedState='none')),'Could not change')
        state['fail']=False;state['verify']=False
        assert ns['handle'](dict(brew,action='serviceStart',expectedState='none'))['feedback'].startswith('Request sent')
    failure(lambda:ns['handle']({'action':'command','command':'echo bad'}),'Unsupported')
    with patch.object(os,'geteuid',return_value=0): failure(ns['managed_services'],'normal Mac account')
with patch.object(os,'uname',return_value=type('Linux',(),{'sysname':'Linux'})()):
    failure(lambda:ns['handle']({'action':'dockerStart'}),'Connect to a Mac')
with patch.object(os,'geteuid',return_value=501),patch.object(os,'getpid',return_value=900):
    row=dict(pid=42,uid=501,parent=1,started='Mon Oct 26 12:00:00 2026',executable='/opt/homebrew/bin/node')
    table={42:row,900:dict(parent=800),800:dict(parent=1)}
    assert ns['stoppable_process'](row,table)
    assert not ns['stoppable_process'](dict(row,pid=800),table)
    assert not ns['stoppable_process'](dict(row,pid=1),table)
    assert not ns['stoppable_process'](dict(row,uid=0),table)
    assert not ns['stoppable_process'](dict(row,uid=502),table)
    assert not ns['stoppable_process'](dict(row,executable='/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter'),table)
    assert not ns['stoppable_process'](dict(row,executable='/usr/sbin/sshd'),table)
    identity={k:row[k] for k in ('pid','uid','started','executable')}
    req=dict(action='portStop',identity=json.dumps(identity),target='3000',expectedState='127.0.0.1')
    listener=dict(identity=identity,address='127.0.0.1',port=3000)
    original_capture=ns['capture']
    def identity_capture(argv, **kwargs):
        if argv[0]=='/bin/ps':
            return 0,'42 501 1 Mon Oct 26 12:00:00 2026 /opt/homebrew/bin/node\n43 501 1 Mon Oct 26 12:00:00 2026 /System/Library/CoreServices/ControlCenter\n'
        return 0,'p42\ncnode\nn127.0.0.1:3000\np43\ncControlCenter\nn*:5000\n'
    ns['capture']=identity_capture
    listed=ns['services']()['services']
    assert listed[0]['stoppable'] and listed[0]['identity']==identity
    assert not listed[1]['stoppable']
    ns['capture']=original_capture
    original_process,original_services=ns['process_table'],ns['services']
    ns['process_table']=lambda:table
    ns['services']=lambda:dict(services=[listener])
    try:
        with patch.object(os,'kill') as kill:
            assert ns['stop_listener'](req)['feedback']=='Stop requested.'
            kill.assert_called_once_with(42,ns['signal'].SIGTERM)
        with patch.object(os,'kill') as kill:
            failure(lambda:ns['stop_listener'](dict(req,identity=json.dumps(dict(identity,started='old')))),'Process changed')
            failure(lambda:ns['stop_listener'](dict(req,target='3001')),'Port changed')
            failure(lambda:ns['stop_listener'](dict(req,identity='broken')),'Refresh')
            kill.assert_not_called()
        with patch.object(os,'kill',side_effect=PermissionError): failure(lambda:ns['stop_listener'](req),'denied permission')
        calls=[]
        def table_after_stop():
            calls.append(1)
            return table if len(calls)<3 else {}
        ns['process_table']=table_after_stop
        with patch.object(os,'kill') as kill:
            assert ns['stop_listener'](req)['feedback']=='Stopped.'
            kill.assert_called_once()
    finally:
        ns['process_table'],ns['services']=original_process,original_services
print('PASS: port Stop protects macOS/SSH processes and other users; rejects changed identities/ports; sends SIGTERM only and reports confirmed versus requested stop')
assert real_capture([sys.executable,'-c','print("ok")'])[1].strip()=='ok'
assert real_capture([sys.executable,'-c','import sys;sys.exit(3)'])[0]==3
failure(lambda:real_capture([sys.executable,'-c','print("x"*10000)'],limit=100),'Too much data')
failure(lambda:real_capture([sys.executable,'-c','import time;time.sleep(2)'],timeout=0.1),'timed out')
failure(lambda:real_capture(['/bin/sh','-c','sleep 3 &'],timeout=0.1),'timed out')
with patch.dict(os.environ,{'DOCKER_CONTEXT':'remote','DOCKER_HOST':'tcp://remote'}):
    text=real_capture([sys.executable,'-c','import os;print(os.getenv("DOCKER_CONTEXT"));print(os.getenv("DOCKER_HOST"))'],local_docker=True)[1]
    assert text.strip()=='None\nNone'
print('PASS: production port parsing, IPv6/deduplication, limits, Docker/Homebrew Start/Stop, target/context/state guards, verified feedback, failures, output bounds and timeout cleanup')

models=source.split('enum MARCDeveloperScript {',1)[0]
feed=ui[ui.index('@MainActor @Observable private final class MARCDeveloperFeed'):ui.index('\nstruct MARCDeveloperToolsView:')]
feed=feed.replace('@MainActor @Observable private final class','@MainActor final class')
monitor_source = (root/'MARC/Services/SSHMonitor.swift').read_text()
cache_declaration = next(line for line in monitor_source.splitlines() if 'var developerReadCache:' in line)
assert '@ObservationIgnored' not in cache_declaration, 'Cache refreshes must invalidate the Status preview even when service rows are unchanged.'
backend = monitor_source.split('// Requests and actions stay bound',1)[1]
backend = backend[backend.index('extension SSHMonitor {'):]
fixture=models+'''
import Observation
final class ObservationFlag: @unchecked Sendable { var changed = false }
enum MARCAIError: Error { case message(String) }
enum MARCDeveloperScript { static let python = "fixture" }
struct FixtureBuffer { let readableBytesView: [UInt8] }
@MainActor final class FixtureClient {
    var calls = 0
    var blocked: CheckedContinuation<FixtureBuffer, Never>?
    func executeCommand(_ command: String, maxResponseSize: Int, mergeStreams: Bool) async throws -> FixtureBuffer {
        calls += 1
        return await withCheckedContinuation { blocked = $0 }
    }
    func finish() {
        let json = "{\\"services\\": [{\\"pid\\":42,\\"name\\":\\"node\\",\\"address\\":\\"::1\\",\\"port\\":3000}]}"
        blocked?.resume(returning: FixtureBuffer(readableBytesView: Array(json.utf8))); blocked = nil
    }
}
@MainActor @Observable final class SSHMonitor {
    var connected = true
    var generation = UUID()
    var statisticsConnectionID: UUID { get { generation } set { generation = newValue } }
    CACHE_DECLARATION
    var developerActionInFlight: UUID?
    var client: FixtureClient? = FixtureClient()
    var calls: Int { client!.calls }
    func finish() { client!.finish() }
}
'''+backend+feed+'''
@main struct Checks {
    @MainActor static func main() async throws {
        let ipv6 = MARCListeningService(pid: 42, name: "node", address: "::1", port: 3000)
        precondition(ipv6.endpoint == "[::1]:3000" && ipv6.addressExplanation.contains("loopback"))
        let queued = MARCDeveloperFeed(), qMonitor = SSHMonitor()
        let q = Task { await queued.poll(monitor: qMonitor, tab: "services", connection: qMonitor.statisticsConnectionID) }
        q.cancel(); await q.value; precondition(qMonitor.calls == 0)
        let stale = MARCDeveloperFeed(), monitor = SSHMonitor()
        let connection = monitor.statisticsConnectionID
        let work = Task { await stale.poll(monitor: monitor, tab: "services", connection: connection) }
        while monitor.calls == 0 { await Task.yield() }
        monitor.statisticsConnectionID = UUID(); monitor.finish(); await work.value
        precondition(stale.services.isEmpty)
        let cancelled = MARCDeveloperFeed(), cMonitor = SSHMonitor()
        let c = Task { await cancelled.poll(monitor: cMonitor, tab: "services", connection: cMonitor.statisticsConnectionID) }
        while cMonitor.calls == 0 { await Task.yield() }
        c.cancel(); cMonitor.finish(); await c.value; precondition(cancelled.services.isEmpty)
        let cacheMonitor = SSHMonitor()
        let read = Task { try? await cacheMonitor.marcDeveloperRequest(action: "services", expectedConnection: cacheMonitor.statisticsConnectionID) }
        while cacheMonitor.calls == 0 { await Task.yield() }
        cacheMonitor.finish(); _ = await read.value
        precondition(cacheMonitor.marcDeveloperCachedRead("services")?.reply.services?.count == 1)
        // Track the production cache getter, then publish identical rows again.
        // The timestamp/cache write must invalidate the preview independently of feed equality.
        let observation = ObservationFlag()
        withObservationTracking {
            _ = cacheMonitor.marcDeveloperCachedRead("services")
        } onChange: { observation.changed = true }
        let repeated = Task { try? await cacheMonitor.marcDeveloperRequest(action: "services", expectedConnection: cacheMonitor.statisticsConnectionID) }
        while cacheMonitor.calls < 2 { await Task.yield() }
        cacheMonitor.finish(); _ = await repeated.value
        precondition(observation.changed, "Identical service rows must still notify the preview of fresh data")
        precondition(cacheMonitor.marcDeveloperCachedRead("services")?.reply.services?.count == 1)
        let restored = MARCDeveloperFeed()
        let restore = Task { await restored.poll(monitor: cacheMonitor, tab: "services", connection: cacheMonitor.statisticsConnectionID) }
        while restored.connection == nil { await Task.yield() }
        precondition(!restored.loading && restored.services.count == 1 && cacheMonitor.calls == 2)
        restore.cancel(); await restore.value
        cacheMonitor.statisticsConnectionID = UUID()
        precondition(cacheMonitor.marcDeveloperCachedRead("services") == nil)
        let actions = SSHMonitor()
        do {
            _ = try await actions.marcDeveloperRequest(action: "dockerStop", expectedConnection: UUID())
            preconditionFailure("Wrong connection must fail before dispatch")
        } catch {}
        precondition(actions.calls == 0)
        let task = Task { try? await actions.marcDeveloperRequest(action: "dockerStop", expectedConnection: actions.statisticsConnectionID) }
        while actions.calls == 0 { await Task.yield() }
        do {
            _ = try await actions.marcDeveloperRequest(action: "dockerStop", expectedConnection: actions.statisticsConnectionID)
            preconditionFailure("Duplicate mutation must be blocked")
        } catch {}
        precondition(actions.calls == 1)
        task.cancel(); actions.finish(); _ = await task.value
        precondition(actions.developerActionInFlight == nil)
        print("PASS: production Developer Tools request/feed cancellation, stale connection rejection, mutation slot ownership and endpoint formatting")
    }
}
'''
fixture = fixture.replace('    CACHE_DECLARATION', cache_declaration)
print('PASS: production Developer cache is observable; native fixture tracks identical-result refresh invalidation')
assert 'case services, docker\n' in ui and 'Copy endpoint' not in ui and 'MARCSavedCommand' not in source
assert 'List {' not in ui and 'Search process or port' in ui and 'Stop process' in ui
if '--source-only' in sys.argv: print('NOT RUN: native Swift Developer Tools checks (source-only mode)')
else:
    compiler=shutil.which('swiftc')
    if not compiler: raise SystemExit('Swift compiler required for native Developer Tools checks.')
    with tempfile.TemporaryDirectory(prefix='marc-developer-checks-') as td:
        path=Path(td)/'DeveloperChecks.swift';path.write_text(fixture)
        binary=Path(td)/'checks'
        subprocess.run([compiler,'-swift-version','5','-parse-as-library',str(path),'-o',str(binary)],check=True)
        subprocess.run([str(binary)],check=True)

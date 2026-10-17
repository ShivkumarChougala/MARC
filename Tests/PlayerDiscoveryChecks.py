#!/usr/bin/env python3
"""Run production player-discovery routing with mocked pgrep processes."""
import ast
from pathlib import Path
import subprocess
from types import SimpleNamespace
from unittest.mock import Mock

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/MARCControlScript.swift').read_text()
python = source.split('    static let python = #"""\n', 1)[1].split('\n"""#', 1)[0]
node = next(node for node in ast.parse(python).body if isinstance(node, (ast.For, ast.If))
    and any(isinstance(child, ast.For) and isinstance(child.target, ast.Name)
            and child.target.id == 'player' for child in ast.walk(node)))
code = compile(ast.fix_missing_locations(ast.Module(body=[node], type_ignores=[])), '<production-player-discovery>', 'exec')

def check(helper, action='read', value=None, failures=False):
    process = Mock(side_effect=[subprocess.TimeoutExpired('pgrep', 2), SimpleNamespace(returncode=0)]
                   if failures else [SimpleNamespace(returncode=0), SimpleNamespace(returncode=1)])
    ns = dict(media_tool='/fixture/media-control' if helper else None,
        request=dict(action=action, value=value), result=dict(mediaPlayers=[]),
        os=SimpleNamespace(getuid=lambda: 501),
        subprocess=SimpleNamespace(run=process, TimeoutExpired=subprocess.TimeoutExpired))
    exec(code, ns)
    for call in process.call_args_list:
        assert call.args[0][:4] == ('/usr/bin/pgrep', '-u', '501', '-x')
        assert call.kwargs == dict(capture_output=True, timeout=2)
    return ns['result']['mediaPlayers'], process.call_count

for action, value in [('read', None), ('volume', 45), ('brightness', 30), ('launchApp', 0),
                      ('playPause', 2), ('nextTrack', 2), ('previousTrack', 2)]:
    players, calls = check(True, action, value)
    assert calls == 0 and players == [], 'Unused native player polling ran: ' + action
for action in ('playPause', 'nextTrack', 'previousTrack'):
    for value in (0, 1):
        players, calls = check(True, action, value)
        assert calls == 2 and players == ['Music']
for action, value in [('read', None), ('playPause', 0), ('launchApp', 0)]:
    players, calls = check(False, action, value)
    assert calls == 2 and players == ['Music']
players, calls = check(False, failures=True)
assert calls == 2 and players == ['Spotify']
players, calls = check(True, 'playPause', True)
assert calls == 0 and players == []
print('PASS: helper-backed refreshes skip native player processes; legacy targeting, user scope and timeout isolation preserved')

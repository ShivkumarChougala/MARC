#!/usr/bin/env python3
"""Exercise real media preflight/dispatch/feedback using mocked helper responses."""
import ast
import json
from pathlib import Path
import re
import subprocess
from types import SimpleNamespace
from unittest.mock import Mock

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/MARCControlScript.swift').read_text()
python = source.split('    static let python = #"""\n', 1)[1].split('\n"""#', 1)[0]
tree = ast.parse(python)
functions = [node for node in tree.body if isinstance(node, ast.FunctionDef)
             and node.name in ('read_now_playing', 'control_active_media')]
function_code = compile(ast.fix_missing_locations(ast.Module(body=functions, type_ignores=[])), '<media-functions>', 'exec')
dispatch = next(node for node in tree.body if isinstance(node, ast.Try)
    and node.body and isinstance(node.body[0], ast.If) and isinstance(node.body[0].test, ast.Compare)
    and isinstance(node.body[0].test.left, ast.Name) and node.body[0].test.left.id == 'action')
dispatch_code = compile(ast.fix_missing_locations(ast.Module(body=[dispatch], type_ignores=[])), '<media-dispatch>', 'exec')
def phase(name):
    text = python.split('# MARC_MEDIA_' + name + '_BEGIN\n', 1)[1].split('# MARC_MEDIA_' + name + '_END', 1)[0]
    return compile(text, '<media-' + name.lower() + '>', 'exec')
before, after = phase('REQUEST'), phase('FEEDBACK')

def exercise(action, value=2, *, inactive=False, prohibited=False, helper=True,
             command_failure=False, help_text='next-track previous-track'):
    calls = []
    gets = []
    def run(*args, **kwargs):
        calls.append((args, kwargs))
        if len(args) > 1 and args[1] == 'get':
            gets.append(args)
            if inactive: return 'null'
            return json.dumps(dict(title='Before' if len(gets) == 1 else 'After',
                artist='Artist', bundleIdentifier='com.brave.Browser', playing=True,
                prohibitsSkip=prohibited))
        if command_failure: raise subprocess.TimeoutExpired(args[0], 4)
        # The media command must follow exactly one fresh helper read.
        if args[0] == '/fixture/media-control': assert len(gets) == 1
        return ''
    ns = dict(json=json, re=re, run=run, media_tool='/fixture/media-control' if helper else None,
        result=dict(nowPlaying=None, mediaError=None, actionError=None, mediaPlayers=['Music', 'Spotify']),
        request=dict(action=action, value=value),
        subprocess=SimpleNamespace(run=Mock(return_value=SimpleNamespace(stdout=help_text, stderr=''))),
        time=SimpleNamespace(sleep=Mock()))
    exec(function_code, ns)
    exec(before, ns)
    exec(dispatch_code, ns)
    exec(after, ns)
    return ns, calls, gets

for action, command in [('playPause', 'toggle-play-pause'), ('nextTrack', 'next-track'),
                        ('previousTrack', 'previous-track')]:
    ns, calls, gets = exercise(action)
    assert len(gets) == 2
    assert [args[1] for args, _ in calls] == ['get', command, 'get']
    assert ns['result']['nowPlaying']['title'] == 'After' and ns['result']['actionError'] is None
    assert all(kwargs['timeout'] in (3, 4) for _, kwargs in calls)
ns, _, gets = exercise('read', None)
assert len(gets) == 1 and ns['result']['actionError'] is None
for action in ('nextTrack', 'previousTrack'):
    ns, calls, gets = exercise(action, prohibited=True)
    assert len(gets) == 2 and all(args[1] == 'get' for args, _ in calls)
    assert 'does not allow skipping' in ns['result']['actionError']
for options in (dict(inactive=True), dict(helper=False)):
    ns, calls, gets = exercise('playPause', **options)
    assert all(args[1] == 'get' for args, _ in calls)
    assert 'No active media session' in ns['result']['actionError']
ns, calls, gets = exercise('nextTrack', help_text='unsupported')
assert len(gets) == 2 and all(args[1] == 'get' for args, _ in calls)
assert 'does not advertise' in ns['result']['actionError']
ns, _, gets = exercise('playPause', command_failure=True)
assert len(gets) == 2 and ns['result']['actionError'] is not None
for player in (0, 1):
    ns, calls, gets = exercise('playPause', player)
    assert len(gets) == 2 and any(args[0] == '/usr/bin/osascript' for args, _ in calls)
    assert ns['result']['actionError'] is None
ns, calls, gets = exercise('playPause', True)
assert ns['result']['actionError'] == 'Invalid control value.'
assert all(args[1] == 'get' for args, _ in calls)
print('PASS: media uses one fresh preflight and one feedback read; skip restrictions, missing sessions, failures and legacy players preserved')

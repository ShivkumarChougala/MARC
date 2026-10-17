#!/usr/bin/env python3
"""Exercise production discovery and app launching with local fixtures and mocked open."""
import ast
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
import time
from types import SimpleNamespace
from unittest.mock import Mock

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/MARCControlScript.swift').read_text()
python = source.split('    static let python = #"""\n', 1)[1].split('\n"""#', 1)[0]
compile(python, '<production-controls>', 'exec')
helper = python.split('# MARC_INSTALLED_APPS_BEGIN\n', 1)[1].split('# MARC_INSTALLED_APPS_END', 1)[0]
namespace = dict(os=os, re=re, time=time, json=json, subprocess=subprocess, run=Mock())
exec(compile(helper, '<installed-apps>', 'exec'), namespace)
with tempfile.TemporaryDirectory() as folder:
    folder = Path(folder)
    def app(relative, bundle, title):
        path = folder / relative / 'Contents'
        path.mkdir(parents=True)
        (path / 'Info.plist').write_bytes(plistlib.dumps(dict(CFBundleIdentifier=bundle, CFBundleName=title)))
    app('Zulu.app', 'dev.example.Zulu', 'Zulu')
    app('Tools/Alpha.app', 'dev.example.Alpha', 'Alpha\nEditor')
    app('Duplicate.app', 'dev.example.Zulu', 'Zulu duplicate')
    app('Bad.app', '--bad;command', 'Bad')
    app('Too/Deep/Hidden.app', 'dev.example.Hidden', 'Hidden')
    broken = folder / 'Broken.app/Contents'; broken.mkdir(parents=True)
    (broken / 'Info.plist').write_text('invalid plist')
    odd = folder / 'Odd.app/Contents'; odd.mkdir(parents=True)
    (odd / 'Info.plist').write_bytes(plistlib.dumps(['unexpected plist array']))
    apps = namespace['installed_apps']([str(folder), str(folder / 'missing')])
    assert len(apps) == 2 and {a['id'] for a in apps} == {'dev.example.Zulu', 'dev.example.Alpha'}
    assert apps[0]['title'] == 'AlphaEditor'
    assert namespace['installed_apps']([str(folder / 'missing')]) == []
    for i in range(230): app(f'App{i:03}.app', f'dev.test.App{i}', 'App ' + str(i))
    bounded = namespace['installed_apps']([str(folder)])
    assert len(bounded) <= 200 and len(json.dumps(bounded).encode()) <= 40000
namespace['os'] = SimpleNamespace(stat=lambda _: SimpleNamespace(st_uid=501), getuid=lambda: 501)
for bundle in ('com.apple.finder', 'com.microsoft.VSCode', 'org.mozilla.firefox'):
    namespace['run'] = Mock()
    namespace['launch_installed_app'](bundle)
    namespace['run'].assert_called_once_with('/usr/bin/open', '-b', bundle, timeout=4)
for bundle in (None, True, 1, '', '-b', 'foo bar', 'com.app\n', '$(touch x)', 'a' * 256):
    namespace['run'] = Mock()
    try: namespace['launch_installed_app'](bundle)
    except RuntimeError: pass
    else: raise AssertionError('Invalid identifier accepted: ' + repr(bundle))
    namespace['run'].assert_not_called()
namespace['os'].stat = lambda _: SimpleNamespace(st_uid=502)
try: namespace['launch_installed_app']('com.apple.finder')
except RuntimeError: pass
else: raise AssertionError('Wrong console user accepted')
namespace['run'].assert_not_called()
namespace['os'].stat = lambda _: SimpleNamespace(st_uid=501)
namespace['run'] = Mock(side_effect=subprocess.TimeoutExpired('open', 4))
try: namespace['launch_installed_app']('com.apple.finder')
except RuntimeError: pass
else: raise AssertionError('Timeout ignored')
dispatch = next(node for node in ast.parse(python).body if isinstance(node, ast.Try)
    and node.body and isinstance(node.body[0], ast.If) and isinstance(node.body[0].test, ast.Compare)
    and isinstance(node.body[0].test.left, ast.Name) and node.body[0].test.left.id == 'action')
code = compile(ast.fix_missing_locations(ast.Module(body=[dispatch], type_ignores=[])), '<dispatcher>', 'exec')
namespace.update(action='launchApp', value=0, request={'applicationID': 'com.apple.finder'}, result={}, run=Mock())
exec(code, namespace)
namespace['run'].assert_called_once_with('/usr/bin/open', '-b', 'com.apple.finder', timeout=4)
namespace.update(action='read', value=None, request={'applicationID': 'com.apple.finder'}, result={}, run=Mock())
exec(code, namespace)
namespace['run'].assert_not_called()
print('PASS: installed app discovery, deduplication, bounded output, identifier validation and signed-in launch routing')

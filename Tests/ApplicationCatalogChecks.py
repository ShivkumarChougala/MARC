#!/usr/bin/env python3
"""Run the production catalogue request with real app fixtures and blocked controls."""
import ast
import base64
import contextlib
import ctypes
import io
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
from unittest.mock import Mock, patch

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/MARCControlScript.swift').read_text()
python = source.split('    static let python = #"""\n', 1)[1].split('\n"""#', 1)[0]
compile(python, '<production-controls>', 'exec')
prefix = python.split('# MARC_APPLICATION_CATALOG_END', 1)[0]
branch = python.split('# MARC_APPLICATION_CATALOG_BEGIN\n', 1)[1].split('# MARC_APPLICATION_CATALOG_END', 1)[0]

def execute(code, namespace, request):
    encoded = base64.b64encode(json.dumps(request).encode()).decode()
    output = io.StringIO()
    with patch.object(sys, 'argv', ['controls', encoded]), contextlib.redirect_stdout(output):
        try:
            exec(compile(code, '<catalogue-request>', 'exec'), namespace)
        except SystemExit as stop:
            assert stop.code == 0
        else:
            raise AssertionError('Catalogue request did not exit before control reads')
    return json.loads(output.getvalue())

with tempfile.TemporaryDirectory() as folder:
    info = Path(folder) / 'Test.app/Contents/Info.plist'
    info.parent.mkdir(parents=True)
    info.write_bytes(plistlib.dumps({'CFBundleIdentifier': 'org.marc.Test', 'CFBundleName': 'Test App'}))
    original_scan, original_size = os.scandir, os.path.getsize
    def scan(path):
        if path == '/Applications':
            return original_scan(folder)
        raise FileNotFoundError(path)
    def size(path):
        if str(path).startswith(folder + os.sep):
            return original_size(path)
        raise FileNotFoundError(path)
    with patch.object(os, 'scandir', side_effect=scan), patch.object(os.path, 'getsize', side_effect=size), \
            patch.object(subprocess, 'run', side_effect=AssertionError('Unrelated command')) as commands, \
            patch.object(ctypes, 'CDLL', side_effect=AssertionError('Unrelated native framework')) as frameworks:
        result = execute(prefix, {}, dict(action='read', applicationsOnly=True, includeWireless=True))
        assert result['applications'] == [dict(id='org.marc.Test', title='Test App')]
        assert result['wirelessIncluded'] is False and result['bluetoothWritable'] is False
        assert result['volume'] is None and result['brightness'] is None
        commands.assert_not_called()
        frameworks.assert_not_called()

failed = Mock(side_effect=RuntimeError('enumeration failed'))
result = execute(branch, dict(request=dict(action='read', applicationsOnly=True),
    result={}, installed_apps=failed, json=json, sys=sys), {})
assert result['applicationsError'] == 'Installed apps could not be read. Try again.'
assert 'applications' not in result

# The early return is read-only and explicitly opt-in; action requests continue normally.
for request in (dict(action='read'), dict(action='launchApp', applicationsOnly=True),
                dict(action='read', applicationsOnly=1)):
    apps = Mock(side_effect=AssertionError('Unexpected catalogue request'))
    exec(compile(branch, '<catalogue-routing>', 'exec'),
         dict(request=request, result={}, installed_apps=apps, json=json, sys=sys))
    apps.assert_not_called()

screen = (root / 'MARC/Screens/ControlsScreen.swift').read_text()
assert 'includeApplications: true, applicationsOnly: true)' in screen
transport = (root / 'MARC/Services/SSHMonitor.swift').read_text()
assert 'let applicationsOnly: Bool' in transport
assert 'applicationsOnly: Bool = false' in transport
assert 'applicationsOnly: applicationsOnly)' in transport
print('PASS: app catalogue requests skip playback, audio, displays and wireless; failures and read-only routing')

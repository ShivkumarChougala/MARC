#!/usr/bin/env python3
"""Exercise production audio/wireless routing with simulated macOS failures."""
import ast
import ctypes
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
dispatch = next(node for node in tree.body if isinstance(node, ast.Try)
    and node.body and isinstance(node.body[0], ast.If)
    and isinstance(node.body[0].test, ast.Compare)
    and isinstance(node.body[0].test.left, ast.Name) and node.body[0].test.left.id == 'action')
code = compile('\n'.join(python.splitlines()[dispatch.lineno - 1:]).split('# MARC_MEDIA_FEEDBACK_BEGIN', 1)[0],
               '<control-dispatch-and-feedback>', 'exec')
helpers = [n for n in tree.body if isinstance(n, ast.FunctionDef)
           and n.name in ('wifi_interface', 'parse_wifi_power', 'parse_bluetooth_report', 'read_audio')]
helper_code = compile(ast.fix_missing_locations(ast.Module(body=helpers, type_ignores=[])), '<control-read-helpers>', 'exec')

def exercise(action='read', value=None, *, wireless=True, blueutil=True, fail=None,
             confirm=True, wifi_power='On', bluetooth_power='1', ports=True):
    calls = []
    def run(*args, **kwargs):
        calls.append((args, kwargs))
        if fail is not None and fail(args): raise subprocess.TimeoutExpired(args[0], 4)
        if args[0] == '/usr/bin/osascript': return '35|false'
        if '-listallhardwareports' in args:
            return 'Hardware Port: Wi-Fi\nDevice: en7\nEthernet Address: fixture' if ports else ''
        if '-getairportpower' in args: return 'Wi-Fi Power (en7): ' + wifi_power
        if '-getairportnetwork' in args: return 'Current Wi-Fi Network: Fixture LAN'
        if args[0] == '/fixture/blueutil': return bluetooth_power if len(args) == 2 else ''
        if args[0] == '/usr/sbin/system_profiler':
            return json.dumps({'SPBluetoothDataType': [{'controller_properties': {'controller_state': 'attrib_on'}}]})
        return ''
    audio = SimpleNamespace(outputs=Mock(return_value=[dict(id=10, name='Speakers'), dict(id=20, name='Headphones')]),
        current=Mock(return_value=value if action == 'output' and confirm else 10), select=Mock())
    brightness = SimpleNamespace(display=1, read=Mock(return_value=50))
    result = dict(actionError=None, volume=None, muted=None, wifiEnabled=None, bluetoothEnabled=None,
                  audioOutputID=None, brightness=None, wirelessIncluded=wireless)
    ns = dict(action=action, value=value, request={}, result=result, run=run, re=re, json=json,
              blueutil='/fixture/blueutil' if blueutil else None, audio_controller=None,
              brightness_controller=None, MacAudio=Mock(return_value=audio),
              MacBrightness=Mock(return_value=brightness), time=SimpleNamespace(sleep=Mock()))
    ns['MacBrightness'].displays.return_value = [dict(id=1, name='Display')]
    exec(helper_code, ns)
    exec(code, ns)
    return result, calls, audio

result, calls, audio = exercise('output', 20, wireless=False)
audio.select.assert_called_once_with(20)
assert result['audioOutputID'] == 20 and result['actionError'] is None
assert result['volume'] == 35 and result['brightness'] == 50
assert not any(args[0] in ('/usr/sbin/networksetup', '/fixture/blueutil') for args, _ in calls)
result, _, _ = exercise('output', 20, confirm=False)
assert 'did not confirm' in result['actionError'] and result['audioOutputID'] == 10
for value in (0, -1, 2**32, True):
    result, _, audio = exercise('output', value)
    audio.select.assert_not_called()
    assert result['actionError']

for action, value in (('wifi', 1), ('bluetooth', 1)):
    result, _, _ = exercise(action, value)
    assert result['actionError'] is None
    result, _, _ = exercise(action, value, fail=lambda args: '-setairportpower' in args or len(args) == 3 and args[0] == '/fixture/blueutil')
    assert result['actionError'] and result['volume'] == 35 and result['brightness'] == 50
    result, _, _ = exercise(action, True)
    assert result['actionError'] == 'Invalid control value.'
result, calls, _ = exercise('wifi', 1)
assert any(args == ('/usr/sbin/networksetup', '-setairportpower', 'en7', 'on') for args, _ in calls)
result, _, _ = exercise('wifi', 0)
assert 'did not confirm' in result['actionError']
result, _, _ = exercise('bluetooth', 0)
assert 'did not confirm' in result['actionError']
result, _, _ = exercise('wifi', 1, ports=False)
assert 'No Wi-Fi interface' in result['actionError'] and result['bluetoothEnabled'] is True
result, _, _ = exercise(wifi_power='unknown')
assert result['wifiError'] and result['bluetoothEnabled'] is True
result, _, _ = exercise(bluetooth_power='unknown')
assert result['bluetoothError'] and result['wifiEnabled'] is True
result, calls, _ = exercise(blueutil=False)
assert result['bluetoothEnabled'] is True and result['bluetoothWritable'] is False
assert next(options['timeout'] for args, options in calls if args[0] == '/usr/sbin/system_profiler') == 12
result, _, _ = exercise('bluetooth', 1, blueutil=False)
assert 'requires blueutil' in result['actionError']
result, _, _ = exercise(fail=lambda args: args[0] in ('/usr/sbin/networksetup', '/fixture/blueutil'))
assert result['wifiError'] and result['bluetoothError']
assert result['volume'] == 35 and result['brightness'] == 50

# Execute the real CoreAudio selection logic with mock property calls.
nodes = [n for n in tree.body if isinstance(n, ast.ClassDef) and n.name in ('AudioAddress', 'MacAudio')
         or isinstance(n, ast.FunctionDef) and n.name == 'fourcc']
ns = dict(C=ctypes)
exec(compile(ast.fix_missing_locations(ast.Module(body=nodes, type_ignores=[])), '<core-audio>', 'exec'), ns)
controller = object.__new__(ns['MacAudio'])
controller.outputs = Mock(return_value=[dict(id=20, name='Headphones')])
def settable(obj, address, writable): writable._obj.value = 1; return 0
controller.audio = SimpleNamespace(AudioObjectIsPropertySettable=Mock(side_effect=settable),
    AudioObjectSetPropertyData=Mock(return_value=0))
controller.select(20)
assert controller.audio.AudioObjectSetPropertyData.call_args.args[-1]._obj.value == 20
controller.outputs.return_value = []
controller.audio.AudioObjectSetPropertyData.reset_mock()
try: controller.select(20)
except RuntimeError as error: assert 'no longer available' in str(error)
else: raise AssertionError('Disconnected output accepted')
controller.audio.AudioObjectSetPropertyData.assert_not_called()
controller.outputs.return_value = [dict(id=20)]
controller.audio.AudioObjectIsPropertySettable.side_effect = None
controller.audio.AudioObjectIsPropertySettable.return_value = 1
try: controller.select(20)
except RuntimeError as error: assert 'does not allow' in str(error)
else: raise AssertionError('Non-writable output accepted')
controller.audio.AudioObjectIsPropertySettable.side_effect = settable
controller.audio.AudioObjectSetPropertyData.return_value = 1
try: controller.select(20)
except RuntimeError as error: assert 'rejected' in str(error)
else: raise AssertionError('Rejected output accepted')
print('PASS: audio output confirmation, disconnected/non-writable devices and invalid targets')
print('PASS: Wi-Fi/Bluetooth failure isolation, fallback, missing helpers and truthful action feedback')

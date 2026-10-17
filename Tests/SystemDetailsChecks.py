#!/usr/bin/env python3
"""Production battery parser/background worker, core boundaries and old payload compatibility."""
from pathlib import Path
from unittest.mock import patch
import json
import re
import shutil
import subprocess
import sys
import tempfile
import time

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/SSHMonitor.swift').read_text()
code = source[source.index('# MARC_BATTERY_HEALTH_BEGIN'):source.index('# MARC_BATTERY_HEALTH_END')]
namespace = dict(re=re, json=json, subprocess=subprocess, time=time)
exec(compile(code, '<production-battery>', 'exec'), namespace)
parse = namespace['parse_battery_health']
def payload(**fields):
    return {'SPPowerDataType': [{'sppower_battery_health_info': fields}]}
valid = payload(sppower_battery_cycle_count=286, sppower_battery_health='Good',
                sppower_battery_health_maximum_capacity='91%')
assert parse(valid) == dict(batteryCondition='Normal', batteryMaximumCapacity=91,
                            batteryCycleCount=286)
assert parse(payload(sppower_battery_health='Check Battery')) == {'batteryCondition': 'Service recommended'}
assert parse(payload(sppower_battery_cycle_count=0, sppower_battery_health_maximum_capacity='100%')) == dict(batteryCycleCount=0, batteryMaximumCapacity=100)
for invalid in [None, [], {}, {'SPPowerDataType': None}, {'SPPowerDataType': [None]},
                {'SPPowerDataType': [{'sppower_battery_health_info': []}]}]:
    assert parse(invalid) == {}
for invalid in [True, -1, '286', 100001, 2.5]:
    assert 'batteryCycleCount' not in parse(payload(sppower_battery_cycle_count=invalid))
for invalid in [None, 91, True, '101%', '-1%', 'inf%', 'NaN%', '4567 mAh', '91', '%']:
    assert 'batteryMaximumCapacity' not in parse(payload(sppower_battery_health_maximum_capacity=invalid))
# Capture scheduled work to exercise queued, completed and timed-out states deterministically.
pending = []
class QueuedThread:
    def __init__(self, target, daemon):
        assert daemon is True
        self.target = target
    def start(self):
        pending.append(self.target)
clock = [0]
health = namespace['MARCBatteryHealth']()
with patch('threading.Thread', QueuedThread), patch('time.monotonic', side_effect=lambda: clock[0]):
    assert health.read(False) == {} and health.read(None) == {} and not pending
    assert health.read(True) == {} and len(pending) == 1
    assert health.read(True) == {} and len(pending) == 1
    with patch('subprocess.check_output', return_value=json.dumps(valid).encode()) as command:
        pending.pop()()
        assert command.call_args.kwargs['timeout'] == 3
    assert health.read(True)['batteryCycleCount'] == 286 and not pending
    clock[0] = 59.9
    health.read(True)
    assert not pending
    clock[0] = 60
    health.read(True)
    assert len(pending) == 1
    with patch('subprocess.check_output', side_effect=subprocess.TimeoutExpired('fixture', 3)):
        pending.pop()()
    assert health.read(True) == {} and not pending
    clock[0] = 120
    health.read(True)
    with patch('subprocess.check_output', return_value=b'not json'):
        pending.pop()()
    assert health.read(True) == {}
    clock[0] = 180
    with patch('threading.Thread', side_effect=RuntimeError('unavailable')):
        assert health.read(True) == {} and health.running is False
print('PASS: battery health parsing, unsupported fields, background ownership, cadence and timeout recovery')
if '--python-only' in sys.argv:
    raise SystemExit(0)
compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('Swift compiler required. Run this check on your Mac.')
model = source[source.index('struct SystemDetails:'):source.index('struct SystemHistoryPoint:')]
helper = (root / 'MARC/Services/MARCSystemDetailsData.swift').read_text()
checks = '''
@main struct Checks {
    static func main() throws {
        precondition(MARCSystemDetailsData.coreLevel(69.99) == .normal)
        precondition(MARCSystemDetailsData.coreLevel(70) == .elevated)
        precondition(MARCSystemDetailsData.coreLevel(84.99) == .elevated)
        precondition(MARCSystemDetailsData.coreLevel(85) == .high)
        precondition(MARCSystemDetailsData.coreLevel(100) == .high)
        precondition(MARCSystemDetailsData.coreLevel(.nan) == .unavailable)
        precondition(MARCSystemDetailsData.coreLevel(.infinity) == .unavailable)
        precondition(MARCSystemDetailsData.batteryStatus(state: "discharging", source: "Battery Power") == "On battery")
        precondition(MARCSystemDetailsData.batteryStatus(state: "not charging", source: "AC Power") == "Not charging")
        precondition(MARCSystemDetailsData.batteryStatus(state: "charging", source: "AC Power") == "Charging")
        precondition(MARCSystemDetailsData.batteryStatus(state: nil, source: nil) == "Unavailable")
        let legacy = try JSONDecoder().decode(SystemDetails.self, from: Data("{}".utf8))
        precondition(legacy.batteryCondition == nil && legacy.batteryMaximumCapacity == nil && legacy.batteryCycleCount == nil)
        let current = try JSONDecoder().decode(SystemDetails.self, from: Data("{\\"batteryCondition\\":\\"Normal\\",\\"batteryMaximumCapacity\\":91,\\"batteryCycleCount\\":286}".utf8))
        precondition(current.batteryCondition == "Normal" && current.batteryMaximumCapacity == 91 && current.batteryCycleCount == 286)
        let oldUsersPayload = #"{"users":["bob","amy"],"username":"bob","batteryPercent":72}"#
        let oldUsers = try JSONDecoder().decode(SystemDetails.self, from: Data(oldUsersPayload.utf8))
        precondition(oldUsers.username == "bob" && oldUsers.batteryPercent == 72)
        print("PASS: per-core colour thresholds, battery status and older collector payloads with retired user lists")
    }
}
'''
with tempfile.TemporaryDirectory(prefix='marc-system-details-') as directory:
    swift = Path(directory) / 'SystemChecks.swift'
    binary = Path(directory) / 'system-checks'
    swift.write_text('import Foundation\n' + model + helper + checks)
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(swift), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)

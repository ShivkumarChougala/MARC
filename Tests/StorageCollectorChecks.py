#!/usr/bin/env python3
"""Production storage parsing and collector failure/recovery regression checks."""
import ast
import json
from pathlib import Path
import re
import subprocess
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'MARC/Services/SSHMonitor.swift').read_text()
block = source.split('# MARC_STORAGE_CAPACITY_BEGIN\n', 1)[1].split(
    '# MARC_STORAGE_CAPACITY_END', 1)[0]
namespace = dict(subprocess=subprocess)
exec(compile(block, '<production-storage-reader>', 'exec'), namespace)
read = namespace['read_storage_capacity']
header = 'Filesystem 1024-blocks Used Available Capacity Mounted on\n'


def output(total=1000, used=200, available=700):
    return header + '/dev/disk3s1 {} {} {} 20% /System/Volumes/Data\n'.format(total, used, available)


for total, used, available in ((1000, 200, 700), (1000, 0, 1000),
                              (1000, 1000, 0), (1000, 900, 200),
                              ((2 ** 63 - 1) // 1024, 0, 0)):
    namespace['run'] = lambda *_, text=output(total, used, available): text
    assert read() == (total * 1024, used * 1024, available * 1024)
for invalid in ('', '\n', header, header + 'truncated row\n',
                output('bad'), output(0), output(-1), output(100, -1, 1),
                output(100, 101, 0), output(100, 1, 101), output(100, 1, -1),
                output(2 ** 63), output('1e10')):
    namespace['run'] = lambda *_, text=invalid: text
    assert read() == (0, 0, 0)
for failure in (OSError('unavailable'), subprocess.TimeoutExpired('df', 8),
                subprocess.CalledProcessError(1, 'df')):
    def fail(*_):
        raise failure
    namespace['run'] = fail
    assert read() == (0, 0, 0)
print('PASS: storage capacity parsing, zero-free/full disks, invalid output and command failures')

# Run the actual production collector cycle with controlled dependencies. A
# failed capacity read must still produce and save CPU/memory/network/disk I/O.
collector = source.split("python3 -u - <<'MARC_COLLECTOR'\n", 1)[1].split('\nMARC_COLLECTOR', 1)[0]
collector = collector.replace('__MARC_POWER_INTERVAL__', '10')
tree = ast.parse(collector)
loop = next(node for node in tree.body if isinstance(node, ast.While))
cycle = next(node for node in loop.body if isinstance(node, ast.Try))
one_cycle = ast.While(test=ast.Constant(value=True), body=[cycle, ast.Break()], orelse=[])
cycle_code = compile(ast.fix_missing_locations(ast.Module(body=[one_cycle], type_ignores=[])),
                     '<production-collector-cycle>', 'exec')
clock, wall = [0], [100]
outputs, saved, calls = [], [], []
responses = [subprocess.TimeoutExpired('df', 8), output(), 'malformed', output(1000, 400, 500)]


def command(*args):
    if args[0] == '/usr/bin/vm_stat':
        return 'Mach Virtual Memory Statistics: (page size of 4096 bytes)\nPages free: 10.\n'
    assert args == ('/bin/df', '-k', '/System/Volumes/Data'), args
    calls.append(clock[0])
    result = responses.pop(0)
    if isinstance(result, Exception):
        clock[0] += 8  # Time spent waiting for the command timeout.
        raise result
    return result


state = dict(re=re, json=json, subprocess=subprocess, run=command,
             time=SimpleNamespace(time=lambda: wall[0], monotonic=lambda: clock[0]),
             os=SimpleNamespace(getloadavg=lambda: (1, 1, 1)),
             core_ticks=lambda: [(1, 2, 3, 4)], previous_cores=[(0, 0, 0, 0)],
             cpu_ticks=lambda: (1, 2, 3, 4), previous=(0, 0, 0, 0),
             total=1024 ** 3, disk_updated=None, disk_total=0, disk_used=0, disk_available=0,
             read_network_counters=lambda: ('en0', 1000, 2000), read_disk_counters=lambda: (100, 200),
             slow_updated=100, tasks=8, swap=0, local_ip=None, power_updated=100,
             battery_percent=None, power_source=None, battery_state=None, has_battery=False,
             cores=4, boot=1, model='fixture', os_version='fixture', architecture='arm64', username='fixture',
             battery_health=SimpleNamespace(read=lambda _: {}), hostname='fixture',
             history_writer=SimpleNamespace(save=lambda *args: saved.append(args)),
             print=lambda text, **_: outputs.append(json.loads(text)))
exec(compile(block, '<production-storage-reader>', 'exec'), state)
for index, now in enumerate((0, 12.9, 13, 17.9, 18, 22.9, 23)):
    clock[0] = now
    wall[0] = -1000 if index == 1 else 100  # Wall-clock jumps must not alter retries.
    exec(cycle_code, state)
assert calls == [0, 13, 18, 23] and not responses, calls
assert len(outputs) == len(saved) == 7
assert [sample['diskTotal'] for sample in outputs] == [0, 0, 1024000, 1024000, 0, 0, 1024000]
assert outputs[-1]['diskUsed'] == 409600 and outputs[-1]['diskAvailable'] == 512000
for sample in outputs:
    assert 'collectorError' not in sample
    assert isinstance(sample['cpu'], (int, float)) and sample['memoryUsed'] == 1024 ** 3 - 40960
    assert sample['received'] == 1000 and sample['sent'] == 2000
    assert sample['diskReadBytes'] == 100 and sample['diskWriteBytes'] == 200
print('PASS: storage failure isolation, recovery and five-second retry spacing after timeout despite clock jumps')

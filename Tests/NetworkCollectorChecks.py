#!/usr/bin/env python3
"""Exercise production network parsing and replay a collector cycle on failure."""
import ast
import json
from pathlib import Path
import re
import subprocess
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'MARC/Services/SSHMonitor.swift').read_text()
collector = source.split("python3 -u - <<'MARC_COLLECTOR'\n", 1)[1].split('\nMARC_COLLECTOR', 1)[0]
collector = collector.replace('__MARC_POWER_INTERVAL__', '10')
block = source.split('# MARC_NETWORK_COUNTERS_BEGIN\n', 1)[1].split(
    '# MARC_NETWORK_COUNTERS_END', 1)[0]
namespace = dict(re=re, subprocess=subprocess)
exec(compile(block, '<production-network-reader>', 'exec'), namespace)
read = namespace['read_network_counters']
header = 'Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes Coll\n'
route = 'route to: default\n interface: en0\n'
row = 'en0 1500 <Link#4> aa:bb:cc:dd:ee:ff 10 0 1024 20 0 2048 0\n'


def response(route_output=route, table=header + row):
    calls = []
    def run(*args):
        calls.append(args)
        output = route_output if args[0] == '/sbin/route' else table
        if isinstance(output, Exception):
            raise output
        return output
    namespace['run'] = run
    return calls


response()
assert read() == ('en0', 1024, 2048)
response(table=header + row.replace('aa:bb:cc:dd:ee:ff ', ''))
assert read() == ('en0', 1024, 2048)
response(table=header + row.replace('1024', '0').replace('2048', '0'))
assert read() == ('en0', 0, 0)
response(table=header + row.replace('en0', 'en1') + row)
assert read() == ('en0', 1024, 2048)
response(table=header + row.replace('<Link#4>', '192.168.1'))
assert read() == ('en0', None, None)  # Do not count address rows a second time.
for table in ('', '\n', header, 'Name Ipkts Opkts\n', header + 'en0 1500 <Link#4> 1 0 1234\n',
              header + row.replace('1024', 'bad'), header + row.replace('2048', '-2')):
    response(table=table)
    assert read() == ('en0', None, None)
for invalid_route in ('', 'interface: \n flags: UP\n', 'not a default route'):
    calls = response(route_output=invalid_route)
    assert read() == (None, None, None) and len(calls) == 1
for error in (OSError('unavailable'), subprocess.TimeoutExpired('fixture', 8),
              subprocess.CalledProcessError(1, 'fixture')):
    response(route_output=error)
    assert read() == (None, None, None)
    response(table=error)
    assert read() == ('en0', None, None)
response(route_output='interface: en1\n', table=header + row.replace('en0', 'en1'))
assert read() == ('en1', 1024, 2048)
response(table='')
assert read() == ('en0', None, None)
response(table=header + row.replace('1024', '1500'))
assert read() == ('en0', 1500, 2048)  # Recovery uses fresh counters, not cached totals.
print('PASS: network headers, empty output, link rows, zero counters, failures and interface changes')

# Execute the production loop's try/except body, rather than a copied sample
# builder. Avoid waiting or touching real commands, history or native libraries.
tree = ast.parse(collector)
loop = next(node for node in tree.body if isinstance(node, ast.While))
cycle = next(node for node in loop.body if isinstance(node, ast.Try))
one_cycle = ast.While(test=ast.Constant(value=True), body=[cycle, ast.Break()], orelse=[])
cycle_code = compile(ast.fix_missing_locations(ast.Module(body=[one_cycle], type_ignores=[])),
                     '<production-collector-cycle>', 'exec')

for network_result in ('', subprocess.TimeoutExpired('netstat', 8), header + row):
    outputs, saved = [], []
    def command(*args):
        if args[0] == '/usr/bin/vm_stat':
            return 'Mach Virtual Memory Statistics: (page size of 4096 bytes)\nPages free: 10.\nPages inactive: 20.\nPages speculative: 30.\n'
        if args[0] == '/sbin/route':
            return route
        if args[0] == '/usr/sbin/netstat':
            if isinstance(network_result, Exception):
                raise network_result
            return network_result
        raise AssertionError('Unexpected command in fixture: ' + str(args))
    state = dict(re=re, json=json, subprocess=subprocess, run=command,
                 time=SimpleNamespace(time=lambda: 100, monotonic=lambda: 100),
                 os=SimpleNamespace(getloadavg=lambda: (1, 1, 1)),
                 core_ticks=lambda: [(1, 2, 3, 4)], previous_cores=[(0, 0, 0, 0)],
                 cpu_ticks=lambda: (1, 2, 3, 4), previous=(0, 0, 0, 0),
                 total=1024 ** 3, disk_updated=100, disk_total=1000, disk_used=100, disk_available=900,
                 read_disk_counters=lambda: (100, 200), slow_updated=100,
                 tasks=8, swap=0, local_ip=None, power_updated=100,
                 battery_percent=None, power_source=None, battery_state=None, has_battery=False,
                 cores=4, boot=1, model='fixture', os_version='fixture', architecture='arm64', username='fixture',
                 battery_health=SimpleNamespace(read=lambda _: {}), hostname='fixture',
                 history_writer=SimpleNamespace(save=lambda *args: saved.append(args)),
                 print=lambda text, **_: outputs.append(json.loads(text)))
    exec(compile(block, '<production-network-reader>', 'exec'), state)
    exec(cycle_code, state)
    assert len(outputs) == len(saved) == 1
    sample = outputs[0]
    assert 'collectorError' not in sample and sample['cpu'] == 70
    assert sample['memoryUsed'] == 1024 ** 3 - 60 * 4096
    assert sample['diskReadBytes'] == 100 and sample['diskWriteBytes'] == 200
    assert sample['received'] == (1024 if isinstance(network_result, str) and network_result else None)
print('PASS: production collector still publishes CPU, memory and disk during empty/timed-out network reads')

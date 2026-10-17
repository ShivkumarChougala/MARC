#!/usr/bin/env python3
"""Exercise the production disk reader; optionally compare real Mac counters."""
import argparse
from pathlib import Path
import plistlib
import statistics
import subprocess
import sys
import time
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'MARC/Services/SSHMonitor.swift').read_text()
block = source.split('# MARC_DISK_COUNTERS_BEGIN\n', 1)[1].split(
    '# MARC_DISK_COUNTERS_END', 1)[0]
namespace = dict(plistlib=plistlib, subprocess=subprocess)
exec(compile(block, 'production-disk-reader', 'exec'), namespace)
parse = namespace['parse_disk_counters']
read = namespace['read_disk_counters']


def payload(read_bytes=0, write_bytes=0):
    return plistlib.dumps([{'Statistics': {
        'Bytes (Read)': read_bytes, 'Bytes (Write)': write_bytes}}])


def fixtures():
    assert parse(payload()) == (0, 0)  # Zero is valid, not unavailable.
    assert parse(plistlib.dumps([])) == (None, None)
    assert parse(plistlib.dumps([{'Statistics': {'Bytes (Read)': 42}}])) == (None, None)
    tree = [
        {'Statistics': {'Bytes (Read)': 100, 'Bytes (Write)': 200},
         'IORegistryEntryChildren': [{'Statistics': {
             'Bytes (Read)': 30, 'Bytes (Write)': 40}}]},
        {'Statistics': {'Bytes (Read)': 7, 'Bytes (Write)': 8}},
    ]
    assert parse(plistlib.dumps(tree)) == (137, 248)
    huge = 2 ** 60
    assert parse(payload(huge, huge + 1)) == (huge, huge + 1)
    with patch.object(subprocess, 'check_output', return_value=payload(100, 200)) as call:
        assert read() == (100, 200)
        assert call.call_count == 1
        assert call.call_args.args[0] == [
            '/usr/sbin/ioreg', '-r', '-c', 'IOBlockStorageDriver', '-d', '1', '-a']
        assert call.call_args.kwargs['timeout'] == 5
    # A driver exposing no root counters can still use the previous full-tree read.
    with patch.object(subprocess, 'check_output', side_effect=[
            plistlib.dumps([]), plistlib.dumps(tree)]) as call:
        assert read() == (137, 248)
        assert call.call_count == 2
        assert call.call_args.args[0] == [
            '/usr/sbin/ioreg', '-r', '-c', 'IOBlockStorageDriver', '-a']
    for failure in (OSError('missing'), subprocess.TimeoutExpired('ioreg', 5),
                    subprocess.CalledProcessError(1, 'ioreg')):
        with patch.object(subprocess, 'check_output', side_effect=failure) as call:
            assert read() == (None, None)
            assert call.call_count == 1  # Do not double a timeout with another command.
    for invalid in (b'not a plist', plistlib.dumps([{'Statistics': {
            'Bytes (Read)': 'bad', 'Bytes (Write)': 12}}])):
        with patch.object(subprocess, 'check_output', return_value=invalid):
            assert read() == (None, None)
    with patch.object(subprocess, 'check_output', side_effect=[
            payload(100, 200), payload(160, 240),
            subprocess.TimeoutExpired('ioreg', 5), payload(200, 300)]) as call:
        assert [read() for _ in range(4)] == [
            (100, 200), (160, 240), (None, None), (200, 300)]
        assert call.call_count == 4  # Every reading is fresh; failures do not reuse totals.
    print('PASS: disk counter totals, fresh reads, zero values, fallback and bounded failures')


def live_check():
    if sys.platform != 'darwin':
        raise SystemExit('The live disk comparison requires macOS.')
    timings = {'full': [], 'shallow': []}
    sizes = {'full': [], 'shallow': []}
    def capture(kind):
        command = ['/usr/sbin/ioreg', '-r', '-c', 'IOBlockStorageDriver']
        if kind == 'shallow':
            command += ['-d', '1']
        started = time.perf_counter()
        raw = subprocess.check_output(command + ['-a'],
                                      stderr=subprocess.DEVNULL, timeout=5)
        timings[kind].append(time.perf_counter() - started)
        sizes[kind].append(len(raw))
        return parse(raw)
    # The reads cannot be simultaneous. Bracket each proposed reading with the
    # original command, allowing real activity while detecting changed totals.
    for _ in range(5):
        before, candidate, after = capture('full'), capture('shallow'), capture('full')
        if any(value is None for pair in (before, candidate, after) for value in pair):
            raise SystemExit('Disk comparison unavailable: missing counters. No optimization verified.')
        if not all(low <= current <= high for low, current, high in zip(before, candidate, after)):
            raise SystemExit('Disk comparison differed. A drive may have changed or counters reset. '
                             'Retry once; if it persists, share this output.')
    print('PASS: five live disk comparisons match the original cumulative-counter bounds')
    for kind in ('full', 'shallow'):
        print('{}: median {:.2f} ms; average {:.0f} bytes per command'.format(
            kind, statistics.median(timings[kind]) * 1000, statistics.mean(sizes[kind])))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live', action='store_true', help='also compare real Mac disk counters')
    args = parser.parse_args()
    fixtures()
    if args.live:
        live_check()

#!/usr/bin/env python3
"""Exercise the production remote handler with small, deterministic budgets.
Swift UI/transport/space fixtures are separate and require a Mac.
"""
from pathlib import Path
import io
import os
import tempfile
from unittest.mock import patch

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/MARCFileOperations.swift').read_text()
handler = source.split('static let python = #"""', 1)[1].split('"""#', 1)[0]
namespace = {}
exec(compile(handler.split('\ntry:\n    request = json.loads', 1)[0], 'production-file-handler', 'exec'), namespace)
execute = namespace['execute']
count = 0

def check(condition, message):
    global count
    assert condition, message
    count += 1

def rejected(action, path, phrase):
    try:
        execute(dict(action=action, path=str(path)))
    except (ValueError, TimeoutError) as error:
        check(phrase in str(error), f'Expected {phrase}: {error}')
    else:
        raise AssertionError(f'{action} unexpectedly accepted')

with tempfile.TemporaryDirectory(prefix='marc-resource-checks-') as temporary:
    base = Path(temporary)
    directory = base / 'listing'; directory.mkdir()
    for name in ['a', 'b', '日本語.txt']:
        (directory / name).write_text('test')
    namespace['DIRECTORY_ENTRIES'] = 3
    rows = execute(dict(action='listDirectory', path=str(directory)))['rows']
    check(len(rows) == 3 and {r['name'] for r in rows} == {'a', 'b', '日本語.txt'}, 'exact entry boundary and Unicode')
    (directory / 'four').touch()
    rejected('listDirectory', directory, 'entry limit')
    namespace['DIRECTORY_ENTRIES'] = 5000
    namespace['DIRECTORY_BYTES'] = 1
    rejected('listDirectory', directory, 'metadata limit')
    namespace['DIRECTORY_BYTES'] = 2 * 1024 * 1024
    link = directory / 'link'; link.symlink_to(base / 'absent')
    check(any(r['name'] == 'link' and r['mode'] & 0o170000 == 0o120000
              for r in execute(dict(action='listDirectory', path=str(directory)))['rows']), 'listing does not follow symlinks')
    archive_input = base / 'input'; archive_input.mkdir()
    (archive_input / 'file').write_bytes(os.urandom(8192))
    namespace['ARCHIVE_INPUT_BYTES'] = 8192
    namespace['ARCHIVE_ENTRIES'] = 2
    # Directories consume headers but zero tar payload bytes.
    reply = execute(dict(action='archive', path=str(archive_input)))
    archive = Path(reply['archive'])
    check(archive.is_file() and archive.stat().st_mode & 0o777 == 0o600, 'successful archive private permissions')
    execute(dict(action='cleanupArchive', path=reply['archiveDirectory']))
    check(not archive.parent.exists(), 'successful cleanup')
    created = []
    original_mkdtemp = namespace['tempfile'].mkdtemp
    def tracked(*args, **kwargs):
        folder = original_mkdtemp(*args, **kwargs); created.append(Path(folder)); return folder
    with patch.object(namespace['tempfile'], 'mkdtemp', tracked):
        namespace['ARCHIVE_INPUT_BYTES'] = 8191
        rejected('archive', archive_input, 'input limit')
        namespace['ARCHIVE_INPUT_BYTES'] = 8192
        namespace['ARCHIVE_ENTRIES'] = 1
        rejected('archive', archive_input, 'item')
        namespace['ARCHIVE_ENTRIES'] = 10000
        namespace['ARCHIVE_OUTPUT_BYTES'] = 100
        rejected('archive', archive_input, 'output limit')
        namespace['ARCHIVE_OUTPUT_BYTES'] = 512 * 1024 * 1024
        class Space: free = 0
        with patch.object(namespace['shutil'], 'disk_usage', return_value=Space()):
            rejected('archive', archive_input, 'free space')
        check(all(not p.exists() for p in created), 'every rejected archive removes its temporary directory')
    deep = base / 'deep'; deep.mkdir()
    current = deep
    for _ in range(65):
        current = current / 'd'; current.mkdir()
    with patch.object(namespace['tempfile'], 'mkdtemp', tracked):
        rejected('archive', deep, 'depth limit')
        check(all(not p.exists() for p in created), 'depth rejection removes archive staging')
    # Writer exact boundary, zero-byte writes, and overflow before the underlying write.
    namespace['ARCHIVE_OUTPUT_BYTES'] = 3
    class Sink(io.BytesIO): name = str(base / 'budget.gz')
    sink = Sink(); writer = namespace['BudgetWriter'](sink)
    check(writer.write(b'abc') == 3 and writer.tell() == 3, 'writer exact byte boundary')
    check(writer.write(b'') == 0, 'zero-byte write')
    try: writer.write(b'd')
    except ValueError: pass
    else: raise AssertionError('writer overflow accepted')
    check(sink.getvalue() == b'abc', 'overflow rejected before bytes reach disk')
    # tarfile's recursive implementation must never be reached.
    check('recursive=False' in handler and 'os.scandir(current)' in handler, 'archive streams directory traversal')

print(f'PASS: {count} resource budget checks using the production remote handler')

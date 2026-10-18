#!/usr/bin/env python3
"""Exercise the exact embedded remote handler on isolated temporary fixtures."""
import base64
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tarfile
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/MARCFileOperations.swift').read_text()
handler = source.split('static let python = #"""', 1)[1].split('"""#', 1)[0]
compile(handler, 'remote_file_actions', 'exec')
count = 0

def check(value, message):
    global count
    if not value:
        raise AssertionError(message)
    count += 1

def request(action, path, **extras):
    body = dict(action=action, path=str(path), **extras)
    encoded = base64.b64encode(json.dumps(body).encode()).decode()
    result = subprocess.run([sys.executable, '-c', handler, encoded],
                            capture_output=True, text=True, timeout=30, check=True)
    return json.loads(result.stdout)

with tempfile.TemporaryDirectory(prefix='marc-action-checks-') as folder:
    base = Path(folder)
    file = base / "notes ' $(touch should-not-exist).txt"
    file.write_text('Hello 🌍\n')
    os.chmod(file, 0o640)
    details = request('info', file)['info']
    check(details['size'] == len(file.read_bytes()), 'metadata size')
    check(details['mode'] & 0o777 == 0o640, 'metadata mode')
    check(isinstance(details['owner'], str) and isinstance(details['accessed'], (float, int)), 'owner and accessed')
    check(details['editorSupported'] is True, 'UTF-8 text offers editor')
    check(isinstance(details['editorReason'], str), 'editor capability explains supported text')
    image = base / 'image.PNG'; image.write_bytes(b'not text editing content')
    check(request('info', image)['info']['editorSupported'] is False, 'image extension hides editor')
    pdf = base / 'document.pdf'; pdf.write_bytes(b'%PDF-1.7')
    check(request('info', pdf)['info']['editorSupported'] is False, 'ASCII PDF is not offered as editable text')
    extensionless = base / '.env'; extensionless.write_text('NAME=hello\n', encoding='utf-8')
    check(request('info', extensionless)['info']['editorSupported'] is True, 'extensionless configuration text detected')
    empty = base / 'empty'; empty.touch()
    check(request('info', empty)['info']['editorSupported'] is True, 'empty regular text can be edited')
    invalid_utf8 = base / 'bad.txt'; invalid_utf8.write_bytes(b'\xff\xfehello')
    check(request('info', invalid_utf8)['info']['editorSupported'] is False, 'invalid UTF-8 hides editor')
    late_binary = base / 'late.txt'; late_binary.write_bytes(b'x' * 8192 + b'\0')
    check(request('info', late_binary)['info']['editorSupported'] is False, 'inspection covers binary beyond an initial sample')
    control = base / 'control.txt'; control.write_bytes(b'hello\x01world')
    check(request('info', control)['info']['editorSupported'] is False, 'binary control characters hide editor')
    loaded = request('readText', file)
    check(loaded['text'] == 'Hello 🌍\n', 'UTF-8 text read')
    staged = base / '.marc-edit-input-fixture.part'
    staged.write_text('Updated text\n')
    saved = request('saveText', file, staged=str(staged), fingerprint=loaded['info']['fingerprint'])
    check('error' not in saved and file.read_text() == 'Updated text\n', 'staged text saved')
    check(stat.S_IMODE(file.stat().st_mode) == 0o640, 'mode preserved')
    check(file.stat().st_uid == details['uid'] and file.stat().st_gid == details['gid'], 'owner/group preserved')
    loaded = request('readText', file)
    file.write_text('Changed elsewhere\n')
    saved = request('saveText', file, staged=str(staged), fingerprint=loaded['info']['fingerprint'])
    check('error' in saved and file.read_text() == 'Changed elsewhere\n', 'conflict does not overwrite')
    check(not list(base.glob('.marc-edit-*')) or all(x == staged for x in base.glob('.marc-edit-*')), 'edit replacement temp cleaned')
    other = base / 'existing.txt'; other.write_text('existing')
    collision = request('rename', file, destination=str(other))
    check('error' in collision and other.read_text() == 'existing' and file.exists(), 'rename never overwrites')
    renamed = base / 'renamed.txt'
    check('error' not in request('rename', file, destination=str(renamed)), 'rename succeeds')
    check(renamed.read_text() == 'Changed elsewhere\n' and not file.exists(), 'renamed content')
    target_dir = base / 'target'; target_dir.mkdir()
    moved = target_dir / 'renamed.txt'
    check('error' not in request('rename', renamed, destination=str(moved)) and moved.exists(), 'move succeeds')
    mode = request('permissions', moved, mode=0o600)
    check(mode['info']['mode'] & 0o777 == 0o600, 'permissions applied')
    check('error' in request('permissions', moved, mode=0o10000), 'invalid permissions rejected')
    link = base / 'link'; link.symlink_to(moved)
    check(request('info', link)['info']['symlink'], 'symbolic-link metadata')
    check(request('info', link)['info']['editorSupported'] is False, 'symbolic link never offered for editing')
    check('error' in request('readText', link), 'text editor rejects symlink')
    check('error' in request('permissions', link, mode=0o777), 'permissions reject symlink')
    check('error' not in request('delete', link) and moved.exists(), 'deleting link preserves target')
    binary = base / 'binary'; binary.write_bytes(b'abc\0def')
    check('error' in request('readText', binary), 'binary text rejected')
    large = base / 'large'; large.write_bytes(b'x' * 1048577)
    check('error' in request('readText', large), '1 MB limit enforced')
    check(request('info', large)['info']['editorSupported'] is False, 'oversized text hides editor')
    maximum = base / 'maximum'; maximum.write_bytes(b'x' * 1048576)
    check(len(request('readText', maximum)['text']) == 1048576, '1 MB boundary accepted')
    check(request('info', maximum)['info']['editorSupported'] is True, 'editor capability accepts exact size boundary')
    check('error' in request('info', 'relative/path'), 'relative path rejected')
    check('error' in request('info', '/tmp/invalid\0path'), 'NUL path rejected')
    check('error' in request('delete', '/'), 'root delete rejected')
    check('error' in request('delete', Path.home()), 'home delete rejected')
    archive_source = base / 'folder'; archive_source.mkdir()
    (archive_source / 'one.txt').write_text('one')
    (archive_source / 'link').symlink_to(moved)
    archived = request('archive', archive_source)
    check('error' not in archived, 'folder archive created')
    with tarfile.open(archived['archive']) as tar:
        members = {x.name: x for x in tar.getmembers()}
        check(members['folder/link'].issym(), 'archive preserves symlink without following it')
        check(tar.extractfile('folder/one.txt').read() == b'one', 'archive file contents')
    check('error' in request('cleanupArchive', base), 'cleanup cannot delete arbitrary folder')
    check('error' not in request('cleanupArchive', archived['archiveDirectory']), 'archive cleanup')
    check(not Path(archived['archiveDirectory']).exists(), 'archive removed')
    fifo = archive_source / 'pipe'; os.mkfifo(fifo)
    check('error' in request('archive', archive_source), 'unsupported archive entries rejected')
    fifo.unlink()
    os.chmod(archive_source / 'one.txt', 0o640)
    check('error' not in request('permissions', archive_source, mode=0o700), 'folder permissions')
    check(stat.S_IMODE((archive_source / 'one.txt').stat().st_mode) == 0o640, 'permissions are nonrecursive')
    check('error' not in request('delete', archive_source) and not archive_source.exists(), 'folder deletion')

with tempfile.TemporaryDirectory(prefix='marc-replace-upload-checks-') as directory:
    base = Path(directory)
    target = base / 'existing.bin'
    staged = base / '.marc-upload-fixture.part'
    check(request('uploadTarget', target) == {}, 'missing upload target needs no replacement')
    target.write_bytes(b'original')
    target.chmod(0o640)
    expected = request('uploadTarget', target)['uploadFingerprint']
    staged.write_bytes(b'replacement')
    result = request('replaceUpload', target, staged=str(staged), fingerprint=expected, size=11)
    check('error' not in result and target.read_bytes() == b'replacement', 'confirmed replacement commits complete content')
    check(not staged.exists(), 'committed stage consumed')
    check(stat.S_IMODE(target.stat().st_mode) == 0o640, 'replacement preserves original permissions')
    staged.write_bytes(b'new')
    expected = request('uploadTarget', target)['uploadFingerprint']
    target.write_bytes(b'changed after confirmation')
    result = request('replaceUpload', target, staged=str(staged), fingerprint=expected, size=3)
    check('error' in result and target.read_bytes() == b'changed after confirmation', 'changed destination preserved')
    check(staged.exists(), 'failed replacement retains stage for caller cleanup')
    expected = request('uploadTarget', target)['uploadFingerprint']
    for size in (4, -1, True):
        check('error' in request('replaceUpload', target, staged=str(staged), fingerprint=expected, size=size), 'invalid staged size rejected')
    other = base / 'not-a-stage'; other.write_bytes(b'new')
    check('error' in request('replaceUpload', target, staged=str(other), fingerprint=expected, size=3), 'arbitrary staged name rejected')
    staged.unlink(); staged.symlink_to(other)
    check('error' in request('replaceUpload', target, staged=str(staged), fingerprint=expected, size=3), 'staged symbolic link rejected')
    link = base / 'link'; link.symlink_to(target)
    check('error' in request('uploadTarget', link), 'destination symbolic link rejected')
    folder = base / 'folder'; folder.mkdir()
    check('error' in request('uploadTarget', folder), 'destination folder rejected')
    check('error' in request('replaceUpload', link, staged=str(staged), fingerprint=expected, size=3), 'replacement through link rejected')
    check(target.read_bytes() == b'changed after confirmation', 'rejected replacements preserve destination bytes')
print('PASS: confirmed upload replacement, changed destinations, stage validation, links and preserved permissions')
print(f'PASS: {count} file-action checks (metadata, text conflicts, no-overwrite moves, permissions, links, archives, limits and deletion)')

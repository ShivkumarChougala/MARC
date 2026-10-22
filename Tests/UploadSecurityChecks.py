#!/usr/bin/env python3
"""Run exact embedded upload/edit handlers against isolated temporary files."""
from pathlib import Path
import base64
import json
import os
import stat
import subprocess
import sys
import tempfile
from unittest.mock import patch

root = Path(__file__).resolve().parents[1]
text = (root / 'MARC/Services/MARCFileOperations.swift').read_text()
handler = text.split('static let python = #"""', 1)[1].split('"""#', 1)[0]
remote = (root / 'MARC/Services/MARCRemoteFiles.swift').read_text()
assert remote.count('var attributes = SFTPFileAttributes()') == 2
assert remote.count('attributes.permissions = 0o600') == 2
assert remote.count('attributes: attributes') == 2
assert '.init(permissions:' not in remote
assert remote.count('["action": "prepareStage", "path": temporary]') == 2
upload = remote[remote.index('    func upload('):remote.index('    func download(')]
assert upload.index('"prepareStage"') < upload.index('try await file.write(')
edit = remote[remote.index('            if action == "saveText" {'):]
assert edit.index('"prepareStage"') < edit.index('try await file.write(')

def request(action, path, **extras):
    payload = base64.b64encode(json.dumps(dict(action=action, path=str(path), **extras)).encode()).decode()
    completed = subprocess.run([sys.executable, '-c', handler, payload], capture_output=True, text=True, timeout=15, check=True)
    return json.loads(completed.stdout)

count = 0
def check(condition, message):
    global count
    if not condition: raise AssertionError(message)
    count += 1

def set_attribute(path, name, value):
    if sys.platform == 'darwin':
        # macOS Python builds do not consistently expose os.setxattr/getxattr.
        # The system tool preserves arbitrary bytes through its hex interface.
        subprocess.run(['/usr/bin/xattr', '-wx', name, value.hex(), str(path)],
                       check=True, capture_output=True, timeout=10)
    else:
        os.setxattr(path, name, value)

def get_attribute(path, name):
    if sys.platform == 'darwin':
        output = subprocess.check_output(
            ['/usr/bin/xattr', '-px', name, str(path)], text=True, timeout=10)
        return bytes.fromhex(output)
    return os.getxattr(path, name)

def check_quarantine(original, actual, context):
    original_flags, original_provenance = original.split(b';', 1)
    flags, provenance = actual.split(b';', 1)
    required = int(original_flags, 16)
    check(int(flags, 16) & required == required, context + ' retains original quarantine flags')
    check(provenance == original_provenance, context + ' retains timestamp/agent/event provenance')

# Exercise the exact production merge, including the observed macOS rewrite.
namespace = {}
exec(handler[:handler.rindex('\ntry:\n    request =')], namespace)
source_quarantine = b'0081;00000000;MARCFixture;'
rewritten_quarantine = b'0281;6ad95a4b;;'
merged = namespace['merge_quarantine'](source_quarantine, rewritten_quarantine)
check(merged == b'0281;00000000;MARCFixture;', 'observed OS flags kept and original provenance restored')
check(namespace['merge_quarantine'](source_quarantine, None) == source_quarantine, 'missing copied attribute restored')
check(namespace['merge_quarantine'](source_quarantine, b'0004;other;agent;') == b'0085;00000000;MARCFixture;', 'source and destination flags combined')
for malformed in (b'', b'not-a-quarantine', b'xyz;time;agent;', b'123456789;time;agent;'):
    try:
        namespace['merge_quarantine'](malformed, rewritten_quarantine)
        raise AssertionError('Malformed quarantine silently accepted')
    except ValueError:
        count += 1

# Exercise the real descriptor wrappers with native-call doubles, including
# byte buffers and error propagation. These tests do not claim a macOS run.
ctypes = namespace['ctypes']
class NativeCall:
    def __init__(self, function): self.function = function
    def __call__(self, *args): return self.function(*args)

class NativeAttributes:
    def __init__(self):
        self.values = {11: rewritten_quarantine}
        self.fail_write = False
        self.rewrite_provenance = False
        self.fgetxattr = NativeCall(self.read)
        self.fsetxattr = NativeCall(self.write)
    def read(self, fd, name, buffer, size, position, options):
        assert name == b'com.apple.quarantine' and position == options == 0
        if fd not in self.values:
            ctypes.set_errno(93)
            return -1
        value = self.values[fd]
        if buffer is None: return len(value)
        assert len(value) <= size
        ctypes.memmove(buffer, value, len(value))
        return len(value)
    def write(self, fd, name, buffer, size, position, options):
        assert name == b'com.apple.quarantine' and position == options == 0
        if self.fail_write:
            ctypes.set_errno(13)
            return -1
        value = ctypes.string_at(buffer, size)
        self.values[fd] = rewritten_quarantine if self.rewrite_provenance else value
        return 0

native = NativeAttributes()
check(namespace['read_quarantine'](native, 99) is None, 'missing native attribute distinguished from errors')
namespace['restore_quarantine'](native, 11, source_quarantine)
check(native.values[11] == b'0281;00000000;MARCFixture;', 'descriptor API restores provenance without clearing added flags')
native.fail_write = True
try:
    namespace['restore_quarantine'](native, 11, source_quarantine)
    raise AssertionError('Native write failure ignored')
except OSError:
    count += 1
native.fail_write = False; native.rewrite_provenance = True
try:
    namespace['restore_quarantine'](native, 11, source_quarantine)
    raise AssertionError('Post-write provenance loss ignored')
except ValueError:
    count += 1

with tempfile.TemporaryDirectory(prefix='marc-upload-security-') as directory:
    base = Path(directory)
    staged = base / '.marc-upload-private.part'
    staged.touch(); staged.chmod(0o666)
    if sys.platform == 'darwin':
        subprocess.run(['/bin/chmod', '+a', 'everyone allow read', str(staged)], check=True)
        check('everyone allow read' in subprocess.check_output(['/bin/ls', '-le', str(staged)], text=True), 'ACL fixture installed')
    check(request('prepareStage', staged) == {}, 'empty stage secured')
    check(stat.S_IMODE(staged.stat().st_mode) == 0o600, 'stage restricted to owner')
    if sys.platform == 'darwin':
        check('everyone allow read' not in subprocess.check_output(['/bin/ls', '-le', str(staged)], text=True), 'inherited/access ACL removed before data')
    staged.write_bytes(b'not empty')
    check('error' in request('prepareStage', staged), 'nonempty stage rejected')
    other = base / 'ordinary.txt'; other.touch(); other.chmod(0o644)
    check('error' in request('prepareStage', other), 'arbitrary names rejected')
    staged.unlink(); staged.symlink_to(other)
    check('error' in request('prepareStage', staged), 'stage symlink rejected')
    staged.unlink(); os.link(other, staged)
    check('error' in request('prepareStage', staged), 'multiply linked stage rejected')
    check(stat.S_IMODE(other.stat().st_mode) != 0o600, 'rejected hardlink does not change other file permissions')
    staged.unlink()

    target = base / 'original.txt'
    target.write_bytes(b'original'); target.chmod(0o640)
    attribute = 'com.marc.security-test' if sys.platform == 'darwin' else 'user.marc-security-test'
    set_attribute(target, attribute, b'preserve-this')
    if sys.platform == 'darwin':
        subprocess.run(['/bin/chmod', '+a', 'everyone allow read', str(target)], check=True)
        set_attribute(target, 'com.apple.quarantine', b'0081;00000000;MARCFixture;')
        original_quarantine = get_attribute(target, 'com.apple.quarantine')
    expected = request('uploadTarget', target)['uploadFingerprint']
    staged.write_bytes(b'replacement')
    result = request('replaceUpload', target, staged=str(staged), fingerprint=expected, size=11)
    check(result == {} and target.read_bytes() == b'replacement', 'replacement keeps new content: ' + repr(result))
    check(get_attribute(target, attribute) == b'preserve-this', 'replacement preserves original extended attribute')
    check(stat.S_IMODE(target.stat().st_mode) == 0o640, 'replacement preserves original mode')
    if sys.platform == 'darwin':
        check('everyone allow read' in subprocess.check_output(['/bin/ls', '-le', str(target)], text=True), 'replacement preserves ACL')
        check_quarantine(original_quarantine, get_attribute(target, 'com.apple.quarantine'), 'replacement')
        original_quarantine = get_attribute(target, 'com.apple.quarantine')

    loaded = request('readText', target)
    edit = base / '.marc-edit-input-fixture.part'; edit.write_bytes(b'edited')
    result = request('saveText', target, staged=str(edit), fingerprint=loaded['info']['fingerprint'])
    check('error' not in result and target.read_bytes() == b'edited', 'text edit keeps edited content: ' + repr(result))
    check(get_attribute(target, attribute) == b'preserve-this', 'text edit preserves extended attribute')
    if sys.platform == 'darwin':
        check('everyone allow read' in subprocess.check_output(['/bin/ls', '-le', str(target)], text=True), 'text edit preserves original ACL')
        check_quarantine(original_quarantine, get_attribute(target, 'com.apple.quarantine'), 'text edit')

    # Inject metadata failure into the exact execute() implementation; never
    # allow a best-effort metadata copy to become a successful content replace.
    namespace = {}
    exec(handler[:handler.rindex('\ntry:\n    request =')], namespace)
    def refuse_metadata(*args): raise OSError('Fixture metadata failure')
    for action in ('replaceUpload', 'saveText'):
        before = target.read_bytes()
        expected = request('uploadTarget', target)['uploadFingerprint']
        staged.write_bytes(b'replacement')
        extras = {'staged': str(staged), 'size': 11} if action == 'replaceUpload' else {'staged': str(edit)}
        with patch.dict(namespace, {'preserve_metadata': refuse_metadata}):
            try:
                namespace['execute'](dict(action=action, path=str(target), fingerprint=expected, **extras))
                raise AssertionError('Metadata failure was ignored')
            except OSError as error:
                check('Fixture metadata failure' in str(error), 'metadata error surfaced')
        check(target.read_bytes() == before, 'metadata failure preserves original content')
    check(not [p for p in base.glob('.marc-edit-*') if p != edit], 'failed text-edit temporary file cleaned')

print(f'PASS: {count} upload security checks: private staging, links, metadata preservation and fail-closed replacement/edit')
if sys.platform == 'darwin':
    print('PASS: native macOS ACL removal/preservation and quarantine retention')
else:
    print('NOT RUN: native macOS ACL/quarantine checks (run this script on your Mac)')

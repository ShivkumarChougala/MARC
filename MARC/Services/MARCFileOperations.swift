import Foundation
@preconcurrency import Citadel
import NIOCore

struct MARCFileInfo: Decodable, Sendable {
    let path: String
    let size: UInt64
    let modified: Double
    let accessed: Double
    let mode: UInt32
    let owner: String
    let group: String
    let uid: UInt32
    let gid: UInt32
    let directory: Bool
    let symlink: Bool
    let fingerprint: [String]
    var editorSupported: Bool? = nil
    var editorReason: String? = nil

    var permissions: String { MARCFileFormatting.permissions(mode) }
    var octal: String { String(mode & 0o7777, radix: 8) }
}

struct MARCDirectoryRow: Decodable, Sendable {
    let name: String
    let size: UInt64
    let modified: Double
    let mode: UInt32
}

struct MARCFileReply: Decodable, Sendable {
    let error: String?
    let info: MARCFileInfo?
    let text: String?
    let archive: String?
    let archiveDirectory: String?
    var rows: [MARCDirectoryRow]? = nil
    var uploadFingerprint: [String]? = nil
}

enum MARCFileBridge {
    static func request(_ request: [String: Any], using ssh: SSHClient) async throws -> MARCFileReply {
        let payload = try JSONSerialization.data(withJSONObject: request).base64EncodedString()
        let command = "python3 - " + payload + " <<'MARC_FILE_ACTION'\n" + python + "\nMARC_FILE_ACTION\n"
        let output = try await ssh.executeCommand(command, maxResponseSize: 8388608, mergeStreams: false)
        let response = try JSONDecoder().decode(MARCFileReply.self, from: Data(output.readableBytesView))
        if let error = response.error { throw MARCAIError.message(error) }
        return response
    }

    // All paths/text are JSON data, never shell or Python source interpolation.
    static let python = #"""
import os, sys, json, base64, stat, pwd, grp, tempfile, shutil, tarfile, ctypes, signal, errno

# Fixed budgets, never raised by data supplied by the client.
DIRECTORY_ENTRIES = 5000
DIRECTORY_BYTES = 2 * 1024 * 1024
ARCHIVE_ENTRIES = 10000
ARCHIVE_INPUT_BYTES = 1024 * 1024 * 1024
ARCHIVE_OUTPUT_BYTES = 512 * 1024 * 1024
STORAGE_RESERVE = 256 * 1024 * 1024

class BudgetWriter:
    def __init__(self, file):
        self.file = file
        self.written = 0
    def write(self, data):
        if len(data) > ARCHIVE_OUTPUT_BYTES - self.written:
            raise ValueError('Folder archive exceeds the 512 MiB output limit.')
        if shutil.disk_usage(os.path.dirname(self.file.name)).free < len(data) + STORAGE_RESERVE:
            raise ValueError('Not enough free space on the Mac to prepare this folder.')
        result = self.file.write(data)
        self.written += result
        return result
    def tell(self): return self.written
    def flush(self): return self.file.flush()

def fingerprint(s):
    return [str(s.st_dev), str(s.st_ino), str(s.st_size), str(s.st_mtime_ns), str(s.st_ctime_ns)]

def editor_support(path, s):
    if not stat.S_ISREG(s.st_mode):
        return False, 'Text editing requires a regular file.'
    if s.st_size > 1048576:
        return False, 'Over the 1 MB text editing limit. Use Preview or Download.'
    binary_extensions = {
        '.png', '.jpg', '.jpeg', '.heic', '.heif', '.gif', '.webp', '.bmp', '.tif', '.tiff',
        '.ico', '.icns', '.pdf', '.mp4', '.mov', '.mkv', '.mp3', '.m4a', '.wav', '.flac',
        '.zip', '.gz', '.tar', '.7z', '.rar', '.dmg', '.pkg', '.sqlite', '.db',
        '.woff', '.woff2', '.ttf', '.otf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
        '.exe', '.dylib', '.so', '.o', '.a', '.class', '.jar', '.pyc'
    }
    if os.path.splitext(path)[1].lower() in binary_extensions:
        return False, 'Use Preview or Download for this file type.'
    try:
        # Bounded local inspection, in the existing metadata request. No extra
        # SSH round trip, and never follow a replacement symlink or block on FIFO.
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, 'rb') as file:
            current = os.fstat(file.fileno())
            if not stat.S_ISREG(current.st_mode) or fingerprint(current) != fingerprint(s):
                return False, 'This file changed. Reopen its details.'
            data = file.read(1048577)
            if len(data) > 1048576:
                return False, 'Over the 1 MB text editing limit. Use Preview or Download.'
            if any(byte < 32 and byte not in (9, 10, 12, 13) for byte in data):
                return False, 'This is not a supported text file. Use Preview or Download.'
            data.decode('utf-8')
            if fingerprint(os.fstat(file.fileno())) != fingerprint(s):
                return False, 'This file changed. Reopen its details.'
        return True, 'UTF-8 text files up to 1 MB'
    except UnicodeError:
        return False, 'This is not UTF-8 text. Use Preview or Download.'
    except OSError:
        return False, 'Text editing is unavailable. Try Preview or Download.'

def info(path):
    s = os.lstat(path)
    try: owner = pwd.getpwuid(s.st_uid).pw_name
    except KeyError: owner = str(s.st_uid)
    try: group = grp.getgrgid(s.st_gid).gr_name
    except KeyError: group = str(s.st_gid)
    supported, reason = editor_support(path, s)
    return dict(path=path, size=s.st_size, modified=s.st_mtime, accessed=s.st_atime,
                mode=s.st_mode, owner=owner, group=group, uid=s.st_uid, gid=s.st_gid,
                directory=stat.S_ISDIR(s.st_mode), symlink=stat.S_ISLNK(s.st_mode),
                fingerprint=fingerprint(s), editorSupported=supported, editorReason=reason)

def valid_path(value):
    if not isinstance(value, str) or not value.startswith('/') or '\0' in value:
        raise ValueError('Choose an absolute path.')
    return os.path.normpath(value)

def regular(path):
    s = os.lstat(path)
    if not stat.S_ISREG(s.st_mode):
        raise ValueError('Editing requires a regular file, not a link, folder or device.')
    if s.st_size > 1048576:
        raise ValueError('The text editor supports files up to 1 MB.')
    return s

def no_replace_rename(source, destination):
    # Atomic no-overwrite operations on macOS/Linux; no fallback that clobbers files.
    lib = ctypes.CDLL(None, use_errno=True)
    if sys.platform == 'darwin':
        f = lib.renamex_np
        f.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_uint]
        f.restype = ctypes.c_int
        code = f(os.fsencode(source), os.fsencode(destination), 4)  # RENAME_EXCL
    elif sys.platform.startswith('linux') and hasattr(lib, 'renameat2'):
        f = lib.renameat2
        f.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
        f.restype = ctypes.c_int
        code = f(-100, os.fsencode(source), -100, os.fsencode(destination), 1)
    else:
        raise ValueError('Safe rename is unavailable on this server.')
    if code:
        error = ctypes.get_errno()
        if error == 17: raise ValueError('An item already exists at that destination. Choose another name.')
        if error == 18: raise ValueError('Choose a destination on the same filesystem.')
        raise OSError(error, os.strerror(error))

def private_stage(fd):
    s = os.fstat(fd)
    if not stat.S_ISREG(s.st_mode) or s.st_nlink != 1 or s.st_uid != os.geteuid():
        raise ValueError('The temporary file is not privately owned. Nothing was uploaded.')
    os.fchmod(fd, 0o600)
    if sys.platform == 'darwin':
        # POSIX mode bits alone do not remove inherited macOS ACL grants.
        lib = ctypes.CDLL(None, use_errno=True)
        lib.acl_init.argtypes = [ctypes.c_int]
        lib.acl_init.restype = ctypes.c_void_p
        lib.acl_set_fd.argtypes = [ctypes.c_int, ctypes.c_void_p]
        lib.acl_set_fd.restype = ctypes.c_int
        lib.acl_free.argtypes = [ctypes.c_void_p]
        lib.acl_free.restype = ctypes.c_int
        acl = lib.acl_init(0)
        if not acl: raise OSError(ctypes.get_errno(), 'Could not prepare private upload permissions.')
        try:
            if lib.acl_set_fd(fd, acl):
                raise OSError(ctypes.get_errno(), 'Could not remove inherited temporary-file access.')
        finally:
            lib.acl_free(acl)
    elif sys.platform.startswith('linux') and 'system.posix_acl_access' in os.listxattr(fd):
        os.removexattr(fd, 'system.posix_acl_access')
    if stat.S_IMODE(os.fstat(fd).st_mode) != 0o600:
        raise ValueError('Could not confirm private temporary-file permissions.')

def quarantine_parts(value):
    flags, separator, provenance = value.partition(b';')
    if not separator or not 1 <= len(flags) <= 8 or any(c not in b'0123456789abcdefABCDEF' for c in flags):
        raise ValueError('Unrecognized quarantine metadata. Original file kept.')
    return int(flags, 16), provenance

def merge_quarantine(original, copied):
    # Retain every source AND destination flag, without interpreting undocumented
    # flag meanings. Preserve the source timestamp/agent/event data exactly.
    flags, provenance = quarantine_parts(original)
    copied_flags = quarantine_parts(copied)[0] if copied is not None else 0
    return format(flags | copied_flags, '04x').encode('ascii') + b';' + provenance

def read_quarantine(lib, fd):
    name = b'com.apple.quarantine'
    lib.fgetxattr.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_void_p,
                             ctypes.c_size_t, ctypes.c_uint32, ctypes.c_int]
    lib.fgetxattr.restype = ctypes.c_ssize_t
    size = lib.fgetxattr(fd, name, None, 0, 0, 0)
    if size < 0:
        error = ctypes.get_errno()
        if error == getattr(errno, 'ENOATTR', 93): return None
        raise OSError(error, 'Could not read quarantine metadata. Original file kept.')
    if not 0 < size <= 16384:
        raise ValueError('Unrecognized quarantine metadata size. Original file kept.')
    buffer = ctypes.create_string_buffer(size)
    actual = lib.fgetxattr(fd, name, buffer, size, 0, 0)
    if actual != size:
        raise OSError('Quarantine metadata changed during copying. Original file kept.')
    return buffer.raw[:actual]

def restore_quarantine(lib, fd, original):
    if original is None:
        # Keep any quarantine added by the OS; never remove it for an
        # originally unquarantined destination.
        return
    copied = read_quarantine(lib, fd)
    merged = merge_quarantine(original, copied)
    lib.fsetxattr.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_void_p,
                             ctypes.c_size_t, ctypes.c_uint32, ctypes.c_int]
    lib.fsetxattr.restype = ctypes.c_int
    data = ctypes.create_string_buffer(merged)
    if lib.fsetxattr(fd, b'com.apple.quarantine', data, len(merged), 0, 0):
        raise OSError(ctypes.get_errno(), 'Could not preserve quarantine provenance. Original file kept.')
    actual = read_quarantine(lib, fd)
    if actual is None:
        raise ValueError('Quarantine metadata was not retained. Original file kept.')
    actual_flags, actual_provenance = quarantine_parts(actual)
    required_flags, required_provenance = quarantine_parts(merged)
    if actual_flags & required_flags != required_flags or actual_provenance != required_provenance:
        raise ValueError('Could not verify quarantine provenance and flags. Original file kept.')

def preserve_metadata(source_fd, destination_fd):
    original = os.fstat(source_fd)
    staged = os.fstat(destination_fd)
    if (staged.st_uid, staged.st_gid) != (original.st_uid, original.st_gid):
        os.fchown(destination_fd, original.st_uid, original.st_gid)
    os.fchmod(destination_fd, stat.S_IMODE(original.st_mode))
    if sys.platform == 'darwin':
        # Public macOS copyfile API: ACL + extended attributes (including resource
        # forks/quarantine). Do not copy DATA or overwrite the new content/times.
        lib = ctypes.CDLL(None, use_errno=True)
        quarantine = read_quarantine(lib, source_fd)
        destination_quarantine = read_quarantine(lib, destination_fd)
        if quarantine is None:
            quarantine = destination_quarantine
        elif destination_quarantine is not None:
            quarantine = merge_quarantine(quarantine, destination_quarantine)
        lib.fcopyfile.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32]
        lib.fcopyfile.restype = ctypes.c_int
        if lib.fcopyfile(source_fd, destination_fd, None, (1 << 0) | (1 << 2)):
            raise OSError(ctypes.get_errno(), 'Could not preserve the original file metadata. Original kept.')
        # fcopyfile may synthesize a new quarantine timestamp/agent. Restore
        # source provenance using public descriptor APIs, retaining added flags.
        restore_quarantine(lib, destination_fd, quarantine)
    else:
        # Portable fixture path; production connections require macOS.
        for name in os.listxattr(source_fd):
            os.setxattr(destination_fd, name, os.getxattr(source_fd, name))

def execute(request):
    action = request.get('action')
    path = valid_path(request.get('path'))
    if action == 'cleanupArchive':
        root = os.path.realpath(tempfile.gettempdir())
        if (os.path.dirname(path) != root or not os.path.basename(path).startswith('marc-folder-')
                or os.path.islink(path)):
            raise ValueError('Invalid temporary archive location.')
        shutil.rmtree(path)
        return {}
    if action == 'listDirectory':
        rows = []
        budget = 0
        def expired_listing(signum, frame):
            raise TimeoutError('Folder listing timed out. Choose another folder.')
        previous = signal.signal(signal.SIGALRM, expired_listing)
        signal.alarm(20)
        try:
            with os.scandir(path) as items:
                for item in items:
                    if len(rows) >= DIRECTORY_ENTRIES:
                        raise ValueError('Folder exceeds the 5,000 entry limit. Choose a smaller subfolder.')
                    s = item.stat(follow_symlinks=False)
                    row = dict(name=item.name, size=max(0, s.st_size), modified=s.st_mtime, mode=s.st_mode)
                    budget += len(json.dumps(row).encode('utf-8')) + 2
                    if budget > DIRECTORY_BYTES:
                        raise ValueError('Folder listing exceeds the 2 MiB metadata limit.')
                    rows.append(row)
            return dict(rows=rows)
        finally:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, previous)
    if action == 'info': return dict(info=info(path))
    if action == 'prepareStage':
        name = os.path.basename(path)
        if not (name.startswith('.marc-upload-') or name.startswith('.marc-edit-input-')) or not name.endswith('.part'):
            raise ValueError('Invalid temporary upload location.')
        fd = os.open(path, os.O_RDWR | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, 'rb') as file:
            if os.fstat(file.fileno()).st_size != 0:
                raise ValueError('The temporary upload file is not empty.')
            private_stage(file.fileno())
            if fingerprint(os.lstat(path)) != fingerprint(os.fstat(file.fileno())):
                raise ValueError('The temporary upload file changed.')
        return {}
    if action == 'uploadTarget':
        try: s = os.lstat(path)
        except FileNotFoundError: return {}
        if not stat.S_ISREG(s.st_mode):
            raise ValueError('This name belongs to a folder, link or device. Choose another upload name.')
        return dict(uploadFingerprint=fingerprint(s))
    if action == 'replaceUpload':
        s = os.lstat(path)
        expected = request.get('fingerprint')
        if not stat.S_ISREG(s.st_mode) or expected != fingerprint(s):
            raise ValueError('The destination changed. Upload again to review the current file before replacing it.')
        staged = valid_path(request.get('staged'))
        size = request.get('size')
        if (os.path.dirname(staged) != os.path.dirname(path)
                or not os.path.basename(staged).startswith('.marc-upload-')
                or not os.path.basename(staged).endswith('.part') or staged == path):
            raise ValueError('Invalid staged upload location.')
        if isinstance(size, bool) or not isinstance(size, int) or size < 0:
            raise ValueError('Invalid upload size.')
        fd = os.open(staged, os.O_RDWR | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, 'rb') as file:
            stage = os.fstat(file.fileno())
            if not stat.S_ISREG(stage.st_mode) or stage.st_size != size or stage.st_nlink != 1 or stage.st_uid != os.geteuid():
                raise ValueError('Upload verification failed. The original file was not replaced.')
            original_fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
            with os.fdopen(original_fd, 'rb') as original:
                if fingerprint(os.fstat(original.fileno())) != expected:
                    raise ValueError('The destination changed. Original kept.')
                preserve_metadata(original.fileno(), file.fileno())
                if fingerprint(os.fstat(original.fileno())) != expected:
                    raise ValueError('The original metadata changed during upload. Original kept.')
            os.fsync(file.fileno())
            if fingerprint(os.lstat(staged)) != fingerprint(os.fstat(file.fileno())):
                raise ValueError('The staged upload changed. Try again.')
            if fingerprint(os.lstat(path)) != expected:
                raise ValueError('The destination changed during upload. Review it before replacing it.')
            os.replace(staged, path)
        return {}
    if action == 'readText':
        s = regular(path)
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
        with os.fdopen(fd, 'rb') as file:
            if fingerprint(os.fstat(file.fileno())) != fingerprint(s):
                raise ValueError('This file changed. Open it again.')
            data = file.read(1048577)
            if len(data) > 1048576 or b'\0' in data:
                raise ValueError('This is not a supported text file. Use preview or download.')
            text = data.decode('utf-8')
        current = info(path)
        if current['fingerprint'] != fingerprint(s):
            raise ValueError('This file changed. Open it again.')
        return dict(info=current, text=text)
    if action == 'saveText':
        s = regular(path)
        expected = request.get('fingerprint')
        if expected != fingerprint(s):
            raise ValueError('The remote file changed. Reopen it before saving; your edits were not written.')
        staged = valid_path(request.get('staged'))
        if (os.path.dirname(staged) != os.path.dirname(path)
                or not os.path.basename(staged).startswith('.marc-edit-input-')):
            raise ValueError('Invalid staged edit location.')
        regular(staged)
        fd = os.open(staged, os.O_RDONLY | os.O_NOFOLLOW)
        with os.fdopen(fd, 'rb') as file:
            data = file.read(1048577)
        if len(data) > 1048576 or b'\0' in data:
            raise ValueError('Save UTF-8 text up to 1 MB.')
        data.decode('utf-8')
        fd, temporary = tempfile.mkstemp(prefix='.marc-edit-', dir=os.path.dirname(path))
        try:
            with os.fdopen(fd, 'wb') as file:
                private_stage(file.fileno())
                file.write(data)
                file.flush()
                original_fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
                with os.fdopen(original_fd, 'rb') as original:
                    if fingerprint(os.fstat(original.fileno())) != expected:
                        raise ValueError('The remote file changed during save. Original kept.')
                    preserve_metadata(original.fileno(), file.fileno())
                    if fingerprint(os.fstat(original.fileno())) != expected:
                        raise ValueError('The remote metadata changed during save. Original kept.')
                os.fsync(file.fileno())
            if fingerprint(os.lstat(path)) != expected:
                raise ValueError('The remote file changed during save. Reopen it before saving.')
            os.replace(temporary, path)
        finally:
            if os.path.lexists(temporary): os.unlink(temporary)
        return dict(info=info(path))
    if action == 'rename':
        destination = valid_path(request.get('destination'))
        if path == destination: return dict(info=info(path))
        if path in ('/', os.path.expanduser('~')):
            raise ValueError('The filesystem root and home folder cannot be moved here.')
        no_replace_rename(path, destination)
        return dict(info=info(destination))
    if action == 'permissions':
        s = os.lstat(path)
        mode = request.get('mode')
        if stat.S_ISLNK(s.st_mode):
            raise ValueError('Permissions are not edited through symbolic links.')
        if isinstance(mode, bool) or not isinstance(mode, int) or not 0 <= mode <= 0o7777:
            raise ValueError('Choose a valid octal mode.')
        os.chmod(path, mode, follow_symlinks=False)
        return dict(info=info(path))
    if action == 'delete':
        if path in ('/', os.path.expanduser('~'), request.get('home')):
            raise ValueError('The filesystem root and home folder cannot be deleted here.')
        s = os.lstat(path)
        if stat.S_ISDIR(s.st_mode): shutil.rmtree(path)
        else: os.unlink(path)
        return {}
    if action == 'archive':
        if not stat.S_ISDIR(os.lstat(path).st_mode):
            raise ValueError('Choose a folder, not a symbolic link.')
        if path == '/': raise ValueError('Choose a folder rather than the filesystem root.')
        folder = tempfile.mkdtemp(prefix='marc-folder-')
        archive = os.path.join(folder, os.path.basename(path) + '.tar.gz')
        def expired(signum, frame):
            raise TimeoutError('Folder preparation timed out. Choose a smaller folder.')
        previous_handler = signal.signal(signal.SIGALRM, expired)
        signal.alarm(180)
        try:
            entries = 0
            input_bytes = 0
            def supported(item):
                nonlocal entries, input_bytes
                entries += 1
                input_bytes += item.size
                if entries > ARCHIVE_ENTRIES or input_bytes > ARCHIVE_INPUT_BYTES:
                    raise ValueError('Folder exceeds the 10,000 item or 1 GiB input limit.')
                if not (item.isfile() or item.isdir() or item.issym() or item.islnk()):
                    raise ValueError('This folder contains a device, socket or other unsupported item.')
                return item
            if shutil.disk_usage(folder).free < STORAGE_RESERVE:
                raise ValueError('Not enough free space on the Mac to prepare this folder.')
            with open(archive, 'xb') as raw:
                os.fchmod(raw.fileno(), 0o600)
                with tarfile.open(fileobj=BudgetWriter(raw), mode='w|gz', dereference=False) as output:
                    # tarfile.add(recursive=True) sorts an unbounded os.listdir.
                    # Walk incrementally instead; bound both breadth and depth.
                    def add_tree(current, name, depth=0):
                        if depth > 64:
                            raise ValueError('Folder exceeds the 64 level archive depth limit.')
                        output.add(current, arcname=name, recursive=False, filter=supported)
                        if stat.S_ISDIR(os.lstat(current).st_mode):
                            with os.scandir(current) as children:
                                for child in children:
                                    add_tree(child.path, name + '/' + child.name, depth + 1)
                    add_tree(path, os.path.basename(path))
            return dict(archive=archive, archiveDirectory=os.path.realpath(folder))
        except Exception:
            shutil.rmtree(folder, ignore_errors=True)
            raise
        finally:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, previous_handler)
    raise ValueError('Unsupported file action.')

try:
    request = json.loads(base64.b64decode(sys.argv[1], validate=True))
    result = execute(request)
except Exception as error:
    result = dict(error=str(error)[:500])
print(json.dumps(result))
"""#
}

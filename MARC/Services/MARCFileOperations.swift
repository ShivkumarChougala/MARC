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

struct MARCFileReply: Decodable, Sendable {
    let error: String?
    let info: MARCFileInfo?
    let text: String?
    let archive: String?
    let archiveDirectory: String?
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
import os, sys, json, base64, stat, pwd, grp, tempfile, shutil, tarfile, ctypes, signal

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
    if action == 'info': return dict(info=info(path))
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
            if not stat.S_ISREG(stage.st_mode) or stage.st_size != size:
                raise ValueError('Upload verification failed. The original file was not replaced.')
            if (stage.st_uid, stage.st_gid) != (s.st_uid, s.st_gid):
                os.fchown(file.fileno(), s.st_uid, s.st_gid)
            os.fchmod(file.fileno(), stat.S_IMODE(s.st_mode))
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
                file.write(data)
                file.flush()
                os.fsync(file.fileno())
            tmp = os.stat(temporary)
            if (tmp.st_uid, tmp.st_gid) != (s.st_uid, s.st_gid):
                os.chown(temporary, s.st_uid, s.st_gid)
            os.chmod(temporary, stat.S_IMODE(s.st_mode))
            if hasattr(os, 'listxattr'):
                for name in os.listxattr(path, follow_symlinks=False):
                    os.setxattr(temporary, name, os.getxattr(path, name, follow_symlinks=False), follow_symlinks=False)
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
            def supported(item):
                if not (item.isfile() or item.isdir() or item.issym() or item.islnk()):
                    raise ValueError('This folder contains a device, socket or other unsupported item.')
                return item
            with tarfile.open(archive, 'w:gz', dereference=False) as output:
                output.add(path, arcname=os.path.basename(path), filter=supported)
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

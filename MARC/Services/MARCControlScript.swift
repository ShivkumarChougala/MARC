// macOS Control Center script. Connection and response ownership stay in SSHMonitor.
enum MARCControlScript {
    static let python = #"""
import base64, json, os, re, shutil, subprocess, sys, time
import ctypes as C, math

class AudioAddress(C.Structure):
    _fields_ = [('selector', C.c_uint32), ('scope', C.c_uint32), ('element', C.c_uint32)]

def fourcc(text): return int.from_bytes(text.encode('ascii'), 'big')

class MacAudio:
    def __init__(self):
        self.audio = C.CDLL('/System/Library/Frameworks/CoreAudio.framework/CoreAudio')
        self.cf = C.CDLL('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
        ptr = C.POINTER(AudioAddress)
        self.audio.AudioObjectGetPropertyDataSize.argtypes = [C.c_uint32,ptr,C.c_uint32,C.c_void_p,C.POINTER(C.c_uint32)]
        self.audio.AudioObjectGetPropertyDataSize.restype = C.c_int32
        self.audio.AudioObjectGetPropertyData.argtypes = [C.c_uint32,ptr,C.c_uint32,C.c_void_p,C.POINTER(C.c_uint32),C.c_void_p]
        self.audio.AudioObjectGetPropertyData.restype = C.c_int32
        self.audio.AudioObjectSetPropertyData.argtypes = [C.c_uint32,ptr,C.c_uint32,C.c_void_p,C.c_uint32,C.c_void_p]
        self.audio.AudioObjectSetPropertyData.restype = C.c_int32
        self.audio.AudioObjectIsPropertySettable.argtypes = [C.c_uint32,ptr,C.POINTER(C.c_ubyte)]
        self.audio.AudioObjectIsPropertySettable.restype = C.c_int32
        self.cf.CFStringGetLength.argtypes = [C.c_void_p]
        self.cf.CFStringGetLength.restype = C.c_long
        self.cf.CFStringGetMaximumSizeForEncoding.argtypes = [C.c_long,C.c_uint32]
        self.cf.CFStringGetMaximumSizeForEncoding.restype = C.c_long
        self.cf.CFStringGetCString.argtypes = [C.c_void_p,C.c_void_p,C.c_long,C.c_uint32]
        self.cf.CFStringGetCString.restype = C.c_ubyte
        self.cf.CFRelease.argtypes = [C.c_void_p]
        self.cf.CFRelease.restype = None
    def address(self, selector, scope='glob'): return AudioAddress(fourcc(selector),fourcc(scope),0)
    def size(self, obj, address):
        size=C.c_uint32()
        if self.audio.AudioObjectGetPropertyDataSize(obj,C.byref(address),0,None,C.byref(size)):
            raise RuntimeError('Audio property unavailable.')
        return size.value
    def read(self, obj, address, target):
        size=C.c_uint32(C.sizeof(target))
        if self.audio.AudioObjectGetPropertyData(obj,C.byref(address),0,None,C.byref(size),C.byref(target)):
            raise RuntimeError('Audio property unavailable.')
        return target
    def string(self, obj, selector):
        value=self.read(obj,self.address(selector),C.c_void_p())
        if not value.value: return ''
        try:
            length=self.cf.CFStringGetLength(value)
            size=self.cf.CFStringGetMaximumSizeForEncoding(length,0x08000100)+1
            if not 1 <= size <= 65536: return ''
            buffer=C.create_string_buffer(size)
            if not self.cf.CFStringGetCString(value,buffer,size,0x08000100): return ''
            return buffer.value.decode('utf-8',errors='replace')
        finally: self.cf.CFRelease(value)
    def current(self): return self.read(1,self.address('dOut'),C.c_uint32()).value
    def outputs(self):
        address=self.address('dev#')
        size=self.size(1,address)
        if size > 16384 or size%4: raise RuntimeError('Audio device list unavailable.')
        ids=(C.c_uint32*(size//4))()
        self.read(1,address,ids)
        rows=[]
        for obj in ids:
            try:
                if self.size(obj,self.address('stm#','outp')) == 0: continue
                alive=self.read(obj,self.address('livn'),C.c_uint32()).value
                if not alive: continue
                name=self.string(obj,'lnam')
                if name: rows.append(dict(id=int(obj),name=name))
            except Exception: continue
        return sorted(rows,key=lambda row: (row['name'].lower(),row['id']))
    def select(self, value):
        if value not in [row['id'] for row in self.outputs()]:
            raise RuntimeError('That audio output is no longer available. Refresh and choose again.')
        address=self.address('dOut')
        writable=C.c_ubyte()
        if self.audio.AudioObjectIsPropertySettable(1,C.byref(address),C.byref(writable)) or not writable.value:
            raise RuntimeError('macOS does not allow this audio-output change.')
        data=C.c_uint32(value)
        if self.audio.AudioObjectSetPropertyData(1,C.byref(address),0,None,C.sizeof(data),C.byref(data)):
            raise RuntimeError('macOS rejected the audio-output change.')

class MacBrightness:
    @staticmethod
    def online():
        cg=C.CDLL('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
        cg.CGGetOnlineDisplayList.argtypes=[C.c_uint32,C.POINTER(C.c_uint32),C.POINTER(C.c_uint32)]
        cg.CGGetOnlineDisplayList.restype=C.c_int32
        cg.CGDisplayIsBuiltin.argtypes=[C.c_uint32];cg.CGDisplayIsBuiltin.restype=C.c_uint32
        cg.CGDisplayPixelsWide.argtypes=[C.c_uint32];cg.CGDisplayPixelsWide.restype=C.c_size_t
        cg.CGDisplayPixelsHigh.argtypes=[C.c_uint32];cg.CGDisplayPixelsHigh.restype=C.c_size_t
        displays=(C.c_uint32*16)();count=C.c_uint32()
        if cg.CGGetOnlineDisplayList(16,displays,C.byref(count)):
            raise RuntimeError('Display information unavailable.')
        rows=[]
        for i in range(min(count.value,16)):
            display=int(displays[i]);builtin=bool(cg.CGDisplayIsBuiltin(display))
            width=int(cg.CGDisplayPixelsWide(display));height=int(cg.CGDisplayPixelsHigh(display))
            name='Built-in display' if builtin else 'External display ' + str(i+1)
            rows.append(dict(id=display,name=name,resolution=str(width)+' × '+str(height),supported=False,brightness=None))
        return rows
    @classmethod
    def displays(cls):
        rows=cls.online()
        for row in rows:
            try:
                controller=cls(row['id'])
                row['brightness']=controller.read()
                row['supported']=True
            except Exception: pass
        return rows
    def __init__(self, selected=None):
        rows=self.online()
        if not rows: raise RuntimeError('No active displays.')
        ids=[row['id'] for row in rows]
        if selected is not None and (isinstance(selected,bool) or not isinstance(selected,int) or selected not in ids):
            raise RuntimeError('This display disconnected. Choose another display.')
        self.display=selected if selected is not None else next((row['id'] for row in rows if row['name']=='Built-in display'),ids[0])
        self.ds=C.CDLL('/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices')
        self.ds.DisplayServicesCanChangeBrightness.argtypes=[C.c_uint32]
        self.ds.DisplayServicesCanChangeBrightness.restype=C.c_bool
        self.ds.DisplayServicesGetBrightness.argtypes=[C.c_uint32,C.POINTER(C.c_float)]
        self.ds.DisplayServicesGetBrightness.restype=C.c_int32
        self.ds.DisplayServicesSetBrightness.argtypes=[C.c_uint32,C.c_float]
        self.ds.DisplayServicesSetBrightness.restype=C.c_int32
        if not self.ds.DisplayServicesCanChangeBrightness(self.display):
            raise RuntimeError('This display does not expose brightness control.')
    def read(self):
        value=C.c_float()
        if self.ds.DisplayServicesGetBrightness(self.display,C.byref(value)):
            raise RuntimeError('Brightness is unavailable for this display.')
        if not math.isfinite(value.value) or not 0 <= value.value <= 1:
            raise RuntimeError('Display reported an invalid brightness.')
        return round(value.value*100)
    def set(self, percent):
        if not 0 <= percent <= 100: raise RuntimeError('Brightness must be between 0 and 100.')
        if self.ds.DisplayServicesSetBrightness(self.display,C.c_float(percent/100)):
            raise RuntimeError('macOS rejected the brightness change.')


request = json.loads(base64.b64decode(sys.argv[1]))
result = dict(volume=None, muted=None, audioError=None,
              wifiEnabled=None, wifiInterface=None, wifiName=None, wifiError=None,
              bluetoothEnabled=None, bluetoothWritable=False, bluetoothError=None,
              wirelessIncluded=bool(request.get('includeWireless')), actionError=None,
              displays=[], selectedDisplayID=None, displayName=None, brightness=None, brightnessError=None, outputs=[], audioOutputID=None,
              audioOutputName=None, audioOutputError=None, mediaPlayers=[])

def run(*args, timeout=8):
    completed = subprocess.run(args, text=True, capture_output=True,
                               timeout=timeout, env=dict(os.environ, LC_ALL='C'))
    if completed.returncode:
        message = (completed.stderr or completed.stdout).strip()
        raise RuntimeError(message.splitlines()[-1][:240] if message else 'macOS rejected the request.')
    return completed.stdout.strip()

def wifi_interface(output):
    for block in re.split(r'\n\s*\n', output):
        port = re.search(r'Hardware Port:\s*(.+)', block)
        device = re.search(r'Device:\s*(en\d+)\b', block)
        if port and device and port.group(1).strip().lower() in ('wi-fi', 'wifi', 'airport'):
            return device.group(1)
    return None

def parse_wifi_power(output):
    match = re.search(r':\s*(On|Off)\s*$', output, re.I)
    return match.group(1).lower() == 'on' if match else None

def parse_bluetooth_report(data):
    controllers = data.get('SPBluetoothDataType', [])
    for controller in controllers:
        properties = controller.get('controller_properties', {})
        state = properties.get('controller_state')
        if isinstance(state, str):
            state = state.lower()
            if state in ('on', 'enabled', 'attrib_on', 'spbluetooth_on'): return True
            if state in ('off', 'disabled', 'attrib_off', 'spbluetooth_off'): return False
    return None

def find_blueutil():
    for path in ('/opt/homebrew/bin/blueutil', '/usr/local/bin/blueutil', shutil.which('blueutil')):
        if path and os.path.isfile(path) and os.access(path, os.X_OK): return path
    return None

def read_audio():
    script = ('set s to get volume settings\n'
              'return ((output volume of s) as text) & "|" & ((output muted of s) as text)')
    output = run('/usr/bin/osascript', '-e', script)
    parts = output.split('|')
    if len(parts) != 2: raise RuntimeError('Could not read Mac audio settings.')
    try:
        volume = int(parts[0])
    except ValueError:
        raise RuntimeError('This audio output does not expose adjustable volume.')
    if not 0 <= volume <= 100 or parts[1].lower() not in ('true', 'false'):
        raise RuntimeError('This output does not expose adjustable volume.')
    result['volume'], result['muted'] = volume, parts[1].lower() == 'true'


# Detect only this SSH user's already-open players.
# Polling never launches a music application.
for player in ('Music', 'Spotify'):
    try:
        process = subprocess.run(
            ('/usr/bin/pgrep', '-u', str(os.getuid()), '-x', player),
            capture_output=True, timeout=2
        )
        if process.returncode == 0:
            result['mediaPlayers'].append(player)
    except (OSError, subprocess.TimeoutExpired):
        pass


def find_executable(name):
    for path in ('/opt/homebrew/bin/' + name, '/usr/local/bin/' + name, shutil.which(name)):
        if path and os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    return None

media_tool = find_executable('media-control')
brew_tool = find_executable('brew')
result['mediaHelperInstalled'] = media_tool is not None
result['mediaInstallCommand'] = ("'" + brew_tool.replace("'", "'\"'\"'") + "' install media-control") if brew_tool else None
result['mediaSetupMessage'] = (
    'Copy the command and paste it into MARC Terminal. Then return and tap Check again.'
    if brew_tool else
    'Homebrew is needed first. Set it up on your Mac, then return here.'
)
result['nowPlaying'] = None
result['mediaError'] = None
result['screenLocked'] = None

def read_now_playing():
    result['nowPlaying'] = None
    result['mediaError'] = None
    if not media_tool:
        return
    try:
        # Keep artwork on the Mac: only small selected fields enter the SSH response.
        data = json.loads(run(media_tool, 'get', timeout=3))
        if data is None:
            return
        if not isinstance(data, dict):
            raise ValueError('Invalid media response')
        title = data.get('title')
        bundle = data.get('parentApplicationBundleIdentifier') or data.get('bundleIdentifier')
        if not isinstance(title, str) or not title.strip() or not isinstance(bundle, str):
            return
        names = {'com.apple.Safari': 'Safari', 'com.google.Chrome': 'Chrome',
                 'com.brave.Browser': 'Brave', 'org.mozilla.firefox': 'Firefox',
                 'com.microsoft.edgemac': 'Edge', 'com.apple.Music': 'Music',
                 'com.spotify.client': 'Spotify'}
        playing = data.get('playing')
        result['nowPlaying'] = dict(
            title=title[:300],
            artist=data.get('artist')[:200] if isinstance(data.get('artist'), str) else None,
            source=names.get(bundle, bundle[:160]),
            playing=playing if isinstance(playing, bool) else None,
            prohibitsSkip=data.get('prohibitsSkip') is True
        )
    except Exception:
        result['mediaError'] = 'Now Playing could not be read. Check that media is open on the Mac, then tap Check again.'

def control_active_media(action):
    read_now_playing()
    if not media_tool or not result['nowPlaying']:
        raise RuntimeError('No active media session. Start playback on the Mac and try again.')
    if action != 'playPause' and result['nowPlaying']['prohibitsSkip']:
        raise RuntimeError('This media session does not allow skipping tracks.')
    if action == 'playPause':
        command = 'toggle-play-pause'
    else:
        # Only use a command advertised by the installed version's help.
        help_result = subprocess.run((media_tool,), text=True, capture_output=True, timeout=3)
        help_text = help_result.stdout + '\n' + help_result.stderr
        options = ('next-track', 'next') if action == 'nextTrack' else ('previous-track', 'previous', 'prev')
        command = next((item for item in options if re.search(
            r'(?<![\w-])' + re.escape(item) + r'(?![\w-])', help_text)), None)
        if not command:
            raise RuntimeError('This helper version does not advertise a track-skip command. Update media-control on your Mac.')
    run(media_tool, command, timeout=4)
    time.sleep(0.15)

def session_locked():
    try:
        cg = C.CDLL('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
        cf = C.CDLL('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
        cg.CGSessionCopyCurrentDictionary.argtypes = []
        cg.CGSessionCopyCurrentDictionary.restype = C.c_void_p
        cf.CFStringCreateWithCString.argtypes = [C.c_void_p, C.c_char_p, C.c_uint32]
        cf.CFStringCreateWithCString.restype = C.c_void_p
        cf.CFDictionaryGetValue.argtypes = [C.c_void_p, C.c_void_p]
        cf.CFDictionaryGetValue.restype = C.c_void_p
        cf.CFBooleanGetValue.argtypes = [C.c_void_p]
        cf.CFBooleanGetValue.restype = C.c_ubyte
        cf.CFRelease.argtypes = [C.c_void_p]
        cf.CFRelease.restype = None
        session = cg.CGSessionCopyCurrentDictionary()
        if not session:
            return None
        key = cf.CFStringCreateWithCString(None, b'CGSSessionScreenIsLocked', 0x08000100)
        try:
            if not key:
                return None
            value = cf.CFDictionaryGetValue(session, key)
            return bool(cf.CFBooleanGetValue(value)) if value else None
        finally:
            if key:
                cf.CFRelease(key)
            cf.CFRelease(session)
    except Exception:
        return None

def lock_session():
    if os.stat('/dev/console').st_uid != os.getuid():
        raise RuntimeError('Connect as the Mac user who is currently signed in to lock their screen.')
    if session_locked() is True:
        return
    # Invoke on the Mac, in a child process. Never activate Terminal or type keys.
    code = (
        'import ctypes as c; '
        'lib=c.CDLL("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"); '
        'f=lib.SACLockScreenImmediate; f.argtypes=[]; f.restype=None; f()'
    )
    try:
        run(sys.executable, '-c', code, timeout=4)
    except Exception:
        raise RuntimeError('This Mac does not support the direct screen-lock request.')
    for _ in range(15):
        if session_locked() is True:
            return
        time.sleep(0.15)
    raise RuntimeError('Lock was requested, but macOS did not confirm it. Check the Mac before relying on it being locked.')

# MARC_QUICK_LAUNCH_BEGIN
def launch_app(value):
    apps = {0: 'com.apple.Safari', 1: 'com.apple.Terminal', 2: 'com.apple.Music'}
    if isinstance(value, bool) or not isinstance(value, int) or value not in apps:
        raise RuntimeError('Choose Safari, Terminal or Music.')
    if os.stat('/dev/console').st_uid != os.getuid():
        raise RuntimeError('Connect as the Mac user who is signed in to open apps.')
    try:
        run('/usr/bin/open', '-b', apps[value], timeout=4)
    except (OSError, subprocess.SubprocessError):
        raise RuntimeError('Could not confirm the app launch. Check your Mac and try again.') from None
# MARC_QUICK_LAUNCH_END

# MARC_INSTALLED_APPS_BEGIN
def installed_apps(roots=None):
    import plistlib
    roots = roots if roots is not None else (
        '/Applications', '/System/Applications', os.path.expanduser('~/Applications'),
        '/System/Library/CoreServices/Finder.app',
        '/System/Cryptexes/App/System/Applications')
    found = {}
    deadline = time.monotonic() + 3
    pending = [(path, 0) for path in roots]
    visited = 0
    while pending and visited < 4096 and time.monotonic() < deadline:
        path, depth = pending.pop(0)
        visited += 1
        if path.lower().endswith('.app'):
            try:
                info = os.path.join(path, 'Contents', 'Info.plist')
                if os.path.getsize(info) > 1048576: continue
                with open(info, 'rb') as stream: data = plistlib.load(stream)
                if not isinstance(data, dict): continue
                bundle = data.get('CFBundleIdentifier')
                if not isinstance(bundle, str) or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.-]{0,254}', bundle): continue
                title = data.get('CFBundleDisplayName') or data.get('CFBundleName') or os.path.basename(path)[:-4]
                if not isinstance(title, str): title = os.path.basename(path)[:-4]
                title = ''.join(c for c in title if c.isprintable()).strip()[:96] or bundle
                found.setdefault(bundle, dict(id=bundle, title=title))
            except Exception: pass
        elif depth < 2 and not os.path.islink(path):
            try:
                with os.scandir(path) as entries:
                    for entry in entries:
                        if entry.name.startswith('.'): continue
                        if entry.is_dir(follow_symlinks=True): pending.append((entry.path, depth + 1))
                        if len(pending) >= 4096: break
            except OSError: pass
    rows = []
    for app in sorted(found.values(), key=lambda app: (app['title'].casefold(), app['id'])):
        if len(rows) >= 200 or len(json.dumps(rows + [app]).encode()) > 40000: break
        rows.append(app)
    return rows

def launch_installed_app(bundle):
    if not isinstance(bundle, str) or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.-]{0,254}', bundle):
        raise RuntimeError('Choose an installed app from Quick Launch.')
    if os.stat('/dev/console').st_uid != os.getuid():
        raise RuntimeError('Connect as the Mac user who is signed in to open apps.')
    try:
        run('/usr/bin/open', '-b', bundle, timeout=4)
    except (OSError, subprocess.SubprocessError):
        raise RuntimeError('Could not open this app. It may have been moved or removed.') from None
# MARC_INSTALLED_APPS_END

# MARC_MEDIA_REQUEST_BEGIN
action = request.get('action')
value = request.get('value')
# Automatic media commands perform their own fresh preflight in control_active_media.
if action not in ('playPause', 'previousTrack', 'nextTrack') or value != 2:
    read_now_playing()
# MARC_MEDIA_REQUEST_END
blueutil = find_blueutil()
audio_controller = None
brightness_controller = None
try:
    if action not in ('read', 'volume', 'mute', 'wifi', 'bluetooth', 'output', 'brightness',
                       'lock', 'displaySleep', 'displayWake', 'playPause', 'previousTrack', 'nextTrack', 'launchApp'):
        raise RuntimeError('Unsupported control request.')
    if action != 'read':
        if isinstance(value, bool) or not isinstance(value, int):
            raise RuntimeError('Invalid control value.')

        if action == 'launchApp':
            if request.get('applicationID') is not None:
                launch_installed_app(request['applicationID'])
            else:
                launch_app(value)
        elif action == 'lock':
            lock_session()
        elif action == 'displaySleep':
            run('/usr/bin/pmset', 'displaysleepnow')
        elif action == 'displayWake':
            run('/usr/bin/caffeinate', '-u', '-t', '1', timeout=3)
        elif action in ('playPause', 'previousTrack', 'nextTrack'):
            if value == 2:
                control_active_media(action)
            else:
                if value not in (0, 1):
                    raise RuntimeError('Choose Music or Spotify.')
                player = 'Spotify' if value else 'Music'
                if player not in result['mediaPlayers']:
                    raise RuntimeError('Open ' + player + ' on your Mac, then refresh controls.')
                command = {
                    'playPause': 'playpause',
                    'previousTrack': 'previous track',
                    'nextTrack': 'next track'
                }[action]
                # Fixed app and command names; no user-supplied script text.
                # Recheck so an app closing during the request is not relaunched.
                script = (
                    'if application "' + player + '" is running then\n'
                    'tell application "' + player + '" to ' + command + '\n'
                    'else\nerror "Player closed"\nend if'
                )
                try:
                    run('/usr/bin/osascript', '-e', script)
                except Exception:
                    raise RuntimeError(
                        'Playback was not confirmed. Check that ' + player +
                        ' is open and allows Automation on your Mac.'
                    )
        elif action == 'volume':
            if not 0 <= value <= 100: raise RuntimeError('Volume must be between 0 and 100.')
            run('/usr/bin/osascript', '-e', 'set volume output volume ' + str(value))
        elif action == 'mute':
            if value not in (0, 1): raise RuntimeError('Invalid mute value.')
            run('/usr/bin/osascript', '-e', 'set volume output muted ' + ('true' if value else 'false'))
        elif action == 'wifi':
            if value not in (0, 1): raise RuntimeError('Invalid Wi-Fi value.')
            interface = wifi_interface(run('/usr/sbin/networksetup', '-listallhardwareports'))
            if not interface: raise RuntimeError('No Wi-Fi interface was detected.')
            run('/usr/sbin/networksetup', '-setairportpower', interface, 'on' if value else 'off')
        elif action == 'output':
            if not 0 < value <= 0xffffffff: raise RuntimeError('Invalid audio output.')
            audio_controller = MacAudio()
            audio_controller.select(value)
            time.sleep(0.15)
        elif action == 'brightness':
            if not 0 <= value <= 100: raise RuntimeError('Brightness must be between 0 and 100.')
            brightness_controller = MacBrightness(request.get('displayID'))
            brightness_controller.set(value)
        elif action == 'bluetooth':
            if value not in (0, 1): raise RuntimeError('Invalid Bluetooth value.')
            if not blueutil: raise RuntimeError('Bluetooth switching requires blueutil on this Mac.')
            run(blueutil, '--power', str(value))
except Exception as exc:
    result['actionError'] = ('This control is unavailable on this Mac.'
                             if isinstance(exc, (OSError, AttributeError)) else str(exc)[:240])

try:
    read_audio()
except Exception as exc:
    result['audioError'] = str(exc)[:240]

try:
    audio_controller = audio_controller or MacAudio()
    result['outputs'] = audio_controller.outputs()
    result['audioOutputID'] = audio_controller.current()
    result['audioOutputName'] = next((row['name'] for row in result['outputs']
                                    if row['id'] == result['audioOutputID']), None)
except Exception:
    result['audioOutputError'] = 'Audio output information is unavailable.'
try:
    result['displays'] = MacBrightness.displays()
    selected = request.get('displayID')
    if selected is not None and not any(row['id'] == selected for row in result['displays']):
        raise RuntimeError('This display disconnected. Choose another display.')
    brightness_controller = brightness_controller or MacBrightness(selected)
    result['selectedDisplayID'] = brightness_controller.display
    result['displayName'] = next((row['name'] for row in result['displays'] if row['id'] == brightness_controller.display), 'Display')
    result['brightness'] = brightness_controller.read()
except Exception as exc:
    result['brightnessError'] = (str(exc)[:160] if isinstance(exc, RuntimeError)
                                 else 'Brightness control is unavailable for this display.')

if result['wirelessIncluded']:
    try:
        interface = wifi_interface(run('/usr/sbin/networksetup', '-listallhardwareports'))
        result['wifiInterface'] = interface
        if not interface: raise RuntimeError('No Wi-Fi interface was detected.')
        result['wifiEnabled'] = parse_wifi_power(run('/usr/sbin/networksetup', '-getairportpower', interface))
        if result['wifiEnabled'] is None: raise RuntimeError('macOS did not report Wi-Fi power state.')
        if result['wifiEnabled']:
            output = run('/usr/sbin/networksetup', '-getairportnetwork', interface)
            match = re.search(r'^Current Wi-Fi Network:\s*(.+)$', output, re.M)
            if match and match.group(1).strip() not in ('<redacted>', '<hidden>', '(null)'):
                result['wifiName'] = match.group(1).strip()
    except Exception as exc:
        result['wifiError'] = str(exc)[:240]
    try:
        result['bluetoothWritable'] = blueutil is not None
        if blueutil:
            power = run(blueutil, '--power')
            if power not in ('0', '1'): raise RuntimeError('Bluetooth power state unavailable.')
            result['bluetoothEnabled'] = power == '1'
        else:
            report = run('/usr/sbin/system_profiler', 'SPBluetoothDataType', '-json', timeout=12)
            result['bluetoothEnabled'] = parse_bluetooth_report(json.loads(report))
            if result['bluetoothEnabled'] is None:
                raise RuntimeError('macOS did not report Bluetooth power state.')
    except Exception as exc:
        result['bluetoothError'] = str(exc)[:240]

if not result['actionError']:
    if action == 'volume' and (result['volume'] is None or abs(result['volume'] - value) > 2):
        result['actionError'] = 'The Mac did not confirm this volume. Its output may have fixed volume.'
    elif action == 'mute' and result['muted'] != bool(value):
        result['actionError'] = 'The Mac did not confirm the mute change.'
    elif action == 'wifi' and result['wifiEnabled'] != bool(value):
        result['actionError'] = 'The Mac did not confirm the Wi-Fi change.'
    elif action == 'bluetooth' and result['bluetoothEnabled'] != bool(value):
        result['actionError'] = 'The Mac did not confirm the Bluetooth change.'
    elif action == 'output' and result['audioOutputID'] != value:
        result['actionError'] = 'The Mac did not confirm the audio-output change.'
    elif action == 'brightness' and (result['brightness'] is None or abs(result['brightness'] - value) > 2):
        result['actionError'] = 'The Mac did not confirm this brightness. Refresh and try again.'
# MARC_MEDIA_FEEDBACK_BEGIN
if action in ('playPause', 'previousTrack', 'nextTrack'):
    read_now_playing()
# MARC_MEDIA_FEEDBACK_END
if action == 'lock':
    result['screenLocked'] = session_locked()
if request.get('includeApplications') is True:
    try:
        result['applications'] = installed_apps()
    except Exception:
        result['applicationsError'] = 'Installed apps could not be read. Try again.'
print(json.dumps(result))
"""#
}

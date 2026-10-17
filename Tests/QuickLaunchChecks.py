#!/usr/bin/env python3
"""Exercise production launch routing without opening apps or contacting a Mac."""
import ast
from pathlib import Path
import subprocess
from types import SimpleNamespace
from unittest.mock import Mock

source = (Path(__file__).resolve().parents[1] / 'MARC/Services/MARCControlScript.swift').read_text()
python = source.split('    static let python = #"""\n', 1)[1].split('\n"""#', 1)[0]
compile(python, '<production-controls>', 'exec')
helper = python.split('# MARC_QUICK_LAUNCH_BEGIN\n', 1)[1].split('# MARC_QUICK_LAUNCH_END', 1)[0]
namespace = dict(subprocess=subprocess,
                 os=SimpleNamespace(stat=lambda _: SimpleNamespace(st_uid=501), getuid=lambda: 501),
                 run=Mock())
exec(compile(helper, '<production-quick-launch>', 'exec'), namespace)
launch = namespace['launch_app']
for value, bundle in enumerate(('com.apple.Safari', 'com.apple.Terminal', 'com.apple.Music')):
    namespace['run'].reset_mock()
    launch(value)
    namespace['run'].assert_called_once_with('/usr/bin/open', '-b', bundle, timeout=4)
for value in (None, True, False, -1, 3, 99, 1.0, '0', 'com.apple.Safari', '; touch /tmp/nope'):
    namespace['run'].reset_mock()
    try:
        launch(value)
    except RuntimeError:
        pass
    else:
        raise AssertionError('Invalid app was accepted: ' + repr(value))
    namespace['run'].assert_not_called()
namespace['os'].stat = lambda _: SimpleNamespace(st_uid=502)
try:
    launch(0)
except RuntimeError:
    pass
else:
    raise AssertionError('Another console user was accepted')
namespace['run'].assert_not_called()
namespace['os'].stat = lambda _: SimpleNamespace(st_uid=501)
for failure in (OSError('missing'), subprocess.TimeoutExpired('open', 4),
                subprocess.CalledProcessError(1, 'open')):
    namespace['run'] = Mock(side_effect=failure)
    try:
        launch(1)
    except RuntimeError as error:
        assert str(error) == 'Could not confirm the app launch. Check your Mac and try again.'
    else:
        raise AssertionError('Launch failure was ignored')

# Execute the production dispatcher to prove reads do not launch anything and
# launch requests go through the same allowlist and value validation.
dispatch = next(node for node in ast.parse(python).body if isinstance(node, ast.Try)
                and node.body and isinstance(node.body[0], ast.If)
                and isinstance(node.body[0].test, ast.Compare)
                and isinstance(node.body[0].test.left, ast.Name)
                and node.body[0].test.left.id == 'action')
dispatch_code = compile(ast.fix_missing_locations(ast.Module(body=[dispatch], type_ignores=[])),
                        '<production-control-dispatch>', 'exec')
for action, value, should_launch in (('read', None, False), ('read', 0, False),
                                    ('launchApp', 0, True), ('launchApp', 2, True),
                                    ('launchApp', -1, False), ('launchApp', True, False),
                                    ('launchApp', 'Safari', False), ('open anything', 0, False)):
    namespace.update(action=action, value=value, request={}, result={'actionError': None}, run=Mock())
    exec(dispatch_code, namespace)
    assert namespace['run'].call_count == int(should_launch)
    if action == 'read' or should_launch:
        assert namespace['result']['actionError'] is None
    else:
        assert namespace['result']['actionError']
print('PASS: Quick Launch app allowlist, signed-in user, bounded failures and read-only refresh routing')

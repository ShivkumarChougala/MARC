#!/usr/bin/env python3
"""Exercise the production display controller against in-memory framework calls."""
import ast
import ctypes
import math
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Services/MARCControlScript.swift').read_text()
python = source.split('    static let python = #"""\n', 1)[1].split('\n"""#', 1)[0]
node = next(n for n in ast.parse(python).body if isinstance(n, ast.ClassDef) and n.name == 'MacBrightness')
active = [10, 20]
unsupported = set()
enumerations = []
values = {10: 0.4, 20: 0.7}
def online(capacity, displays, count):
    enumerations.append(tuple(active))
    count._obj.value = min(len(active), capacity)
    for index, display in enumerate(active[:capacity]): displays[index] = display
    return 0
def read(display, pointer):
    if display not in active: return 1
    pointer._obj.value = values[display]
    return 0
def write(display, percent):
    if display not in active: return 1
    values[display] = percent.value
    return 0
graphics = SimpleNamespace(CGGetOnlineDisplayList=Mock(side_effect=online),
    CGDisplayIsBuiltin=Mock(side_effect=lambda display: display == 10),
    CGDisplayPixelsWide=Mock(return_value=1920), CGDisplayPixelsHigh=Mock(return_value=1080))
services = SimpleNamespace(DisplayServicesCanChangeBrightness=Mock(side_effect=lambda display: display not in unsupported),
    DisplayServicesGetBrightness=Mock(side_effect=read), DisplayServicesSetBrightness=Mock(side_effect=write))
bindings = {name: getattr(ctypes, name) for name in ('c_uint32', 'c_size_t', 'c_int32', 'c_bool', 'c_float', 'POINTER', 'byref')}
bindings['CDLL'] = lambda path: graphics if 'CoreGraphics' in path else services
ns = dict(C=SimpleNamespace(**bindings), math=math)
exec(compile(ast.fix_missing_locations(ast.Module(body=[node], type_ignores=[])), '<production-display>', 'exec'), ns)
controller = ns['MacBrightness']
rows = controller.displays()
assert len(enumerations) == 1, 'One display-list read must enumerate only once'
assert [row['id'] for row in rows] == [10, 20]
assert [row['brightness'] for row in rows] == [40, 70] and all(row['supported'] for row in rows)
standalone = controller()
assert len(enumerations) == 2 and standalone.display == 10
standalone.set(55)
assert standalone.read() == 55
for percent in (0, 100):
    standalone.set(percent)
    assert standalone.read() == percent
external = controller(20)
assert external.display == 20 and external.read() == 70
unsupported.add(20)
rows = controller.displays()
assert rows[0]['supported'] and not rows[1]['supported'] and rows[1]['brightness'] is None
active[:] = [10]
try: controller(20)
except RuntimeError as error: assert 'disconnected' in str(error)
else: raise AssertionError('Disconnected display accepted')
values[10] = float('nan')
try: controller(10).read()
except RuntimeError: pass
else: raise AssertionError('Invalid brightness accepted')
for value in (-1, 101):
    try: standalone.set(value)
    except RuntimeError: pass
    else: raise AssertionError('Invalid brightness write accepted')
active.clear()
assert controller.displays() == []
try: standalone.set(50)
except RuntimeError as error: assert 'rejected' in str(error)
else: raise AssertionError('Write to a removed display was accepted')
try: controller()
except RuntimeError as error: assert 'No active displays' in str(error)
else: raise AssertionError('Missing display accepted')
print('PASS: one enumeration per display snapshot, fresh command targets, unsupported/disconnected displays and brightness boundaries')

#!/usr/bin/env python3
"""Read-only source and optional built-app artifact checks; no third-party packages."""
from pathlib import Path
import json
import re
import sys

root = Path(__file__).resolve().parents[1]
app = root / 'MARC'
transient_suffixes = ('.bak', '.orig', '.rej', '.patch', '.pyc', '~')
backup_pattern = re.compile(r'\.(?:bak|backup|orig|rej|patch)(?:$|[.-])', re.IGNORECASE)

def artifacts(directory):
    return sorted(str(p.relative_to(directory)) for p in directory.rglob('*')
                  if p.is_file() and (p.name.endswith(transient_suffixes) or backup_pattern.search(p.name) or '__pycache__' in p.parts))

failures = ['App source contains transient artifact: ' + rel for rel in artifacts(app)]
assets = app / 'Assets.xcassets'
populated_assets = set()
for contents in assets.rglob('Contents.json'):
    try:
        entries = json.loads(contents.read_text()).get('images', [])
        for entry in entries:
            filename = entry.get('filename')
            if filename:
                relative = Path(filename)
                if relative.is_absolute() or '..' in relative.parts or not (contents.parent / relative).is_file():
                    failures.append('Missing or unsafe image asset: ' + str(contents.parent.relative_to(root)) + '/' + filename)
                elif contents.parent.suffix == '.imageset':
                    populated_assets.add(contents.parent.stem)
    except (ValueError, TypeError, AttributeError) as error:
        failures.append('Invalid asset catalogue: ' + str(contents.relative_to(root)) + ': ' + str(error))
asset_names = {p.name.rsplit('.', 1)[0] for p in assets.rglob('*.imageset')}
for source in app.rglob('*.swift'):
    # Only literal asset images, not SF Symbols, dynamic names or platform images.
    for name in re.findall(r'\bImage\(\s*"([^"\\]+)"\s*\)', source.read_text()):
        if name not in asset_names:
            failures.append('Unknown image asset ' + name + ' in ' + str(source.relative_to(root)))
gallery = app / 'Screens/MARCFeatureGuideScreen.swift'
if gallery.is_file():
    # The gallery passes these static topic names to Image dynamically.
    names = re.search(r'var assetName:\s*String\s*\{(.*?)\n    \}', gallery.read_text(), re.DOTALL)
    if names:
        for name in re.findall(r'\breturn\s+"([^"\\]+)"', names.group(1)):
            if name not in populated_assets:
                failures.append('Missing or empty gallery image asset: ' + name)
if len(sys.argv) > 1:
    bundle = Path(sys.argv[1])
    if not bundle.is_dir():
        failures.append('Built app not found: ' + str(bundle))
    else:
        failures.extend('Built app contains transient artifact: ' + rel for rel in artifacts(bundle))
if failures:
    raise SystemExit('\n'.join(failures))
print('PASS: app source contains no backup/patch artifacts; literal image references and catalogue files resolve')
if len(sys.argv) > 1:
    print('PASS: built app contains no backup/patch artifacts')

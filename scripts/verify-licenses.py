#!/usr/bin/env python3
"""Verify pinned-package notice coverage, integrity and built-app packaging."""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
RESOURCE = ROOT / 'MARC/Resources/MARCOpenSourceNotices.json'

def verify(root=ROOT, built=None):
    resource = root / RESOURCE.relative_to(ROOT)
    data = json.loads(resource.read_text())
    pins = json.loads((root / 'MARC.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved').read_text())['pins']
    expected = {p['identity']: (p['location'], p['state']['revision'], p['state'].get('version')) for p in pins}
    from importlib.util import spec_from_file_location, module_from_spec
    spec = spec_from_file_location('marc_backport', root / 'scripts/verify-ssh-backport.py')
    backport = module_from_spec(spec)
    spec.loader.exec_module(backport)
    local_inventory = backport.verify(root)
    local = {p['identity']: p for p in local_inventory['packages']}
    remote = [p for p in data['packages'] if p.get('sourceKind') != 'vendored']
    if any(doc.get('localNotice') for p in remote for doc in p['documents']):
        raise ValueError('Remote package cannot substitute a local modification notice.')
    actual = {p['id']: (p['repository'], p['revision'], p['version']) for p in remote}
    if len(actual) != len(remote) or actual != expected:
        raise ValueError('Dependency pins changed or notices are missing. Review and regenerate notices before release.')
    vendored = [p for p in data['packages'] if p.get('sourceKind') == 'vendored']
    if {p['id'] for p in vendored} != set(local) or len(vendored) != len(local):
        raise ValueError('Vendored package notices are missing or duplicated.')
    if len({p['id'] for p in data['packages']}) != len(data['packages']):
        raise ValueError('Duplicate notice identity.')
    for package in vendored:
        source = local[package['id']]
        if (package['repository'], package['revision'], package['version'], package['localPath']) != (
                source['repository'], source['revision'], source['displayVersion'], source['path']):
            raise ValueError('Local notice provenance differs from vendored source.')
        additions = [d for d in package['documents'] if d.get('localNotice')]
        if len(additions) != 1:
            raise ValueError('Required local modification notice missing.')
        note = additions[0]
        expected_path = source['path'] + '/MARC_MODIFICATIONS.md'
        if note['sourceURL'] != expected_path or note['text'] != (root / expected_path).read_text():
            raise ValueError('Local modification notice differs from source.')
    license_text = (root / 'LICENSE').read_text()
    if data['marcLicense'] != license_text or 'Copyright (c) 2026 Shivkumar Chougala' not in license_text:
        raise ValueError('MARC license differs from its bundled copy.')
    if 'Permission is hereby granted, free of charge' not in license_text:
        raise ValueError('MARC MIT license text missing.')
    markdown = '# Third-party notices\n\n' + data['introduction'] + '\n\n' + data['acknowledgement'] + '\n\n'
    markdown += 'Remote notice texts identify their exact resolved revisions. Local snapshots identify their upstream base revisions and MARC modifications in `Vendor/DEPENDENCIES.json`. Embedded source notices are retained below along with root licenses and NOTICE files. Source comment wording is preserved; trailing whitespace is normalized in this Markdown copy. Bundled source notices remain verbatim.\n\n'
    for package in data['packages']:
        if not package['documents']:
            raise ValueError('Empty package notices: ' + package['id'])
        markdown += f'## {package["name"]} {package["version"]}\n\nRepository: {package["repository"]}\n\nRevision: `{package["revision"]}`\n\n'
        has_license = False
        for doc in package['documents']:
            if hashlib.sha256(doc['text'].encode()).hexdigest() != doc['sha256']:
                raise ValueError('Notice integrity mismatch: ' + package['id'] + '/' + doc['path'])
            if not doc.get('localNotice') and not doc['sourceURL'].startswith(package['repository'].removesuffix('.git') + '/blob/' + package['revision'] + '/'):
                raise ValueError('Notice source does not match pinned revision.')
            has_license |= doc['path'].lower() in ('license', 'license.txt', 'license.md')
            markdown += f'### {doc["path"]}\n\nSource: {doc["sourceURL"]}\n\n```text\n{doc["text"].rstrip()}\n```\n\n'
        if not has_license:
            raise ValueError('Package root license missing: ' + package['id'])
    # Normalize only the Markdown rendering; original notice text/hashes stay intact.
    markdown = '\n'.join(line.rstrip() for line in markdown.splitlines()).rstrip() + '\n'
    if (root / 'THIRD_PARTY_NOTICES.md').read_text() != markdown:
        raise ValueError('Repository and bundled notices differ.')
    citadel = next(p for p in data['packages'] if p['id'] == 'citadel')
    if not any('All advertising materials' in d['text'] for d in citadel['documents']):
        raise ValueError('Blowfish embedded license missing.')
    if data['acknowledgement'] != 'This product includes software developed by Niels Provos.':
        raise ValueError('Required Blowfish acknowledgement missing.')
    if 'MARCOpenSourceScreen()' not in (root / 'MARC/Screens/SettingsScreen.swift').read_text():
        raise ValueError('Offline notices route missing.')
    if built is not None:
        candidates = [built / resource.name, built / 'Resources' / resource.name]
        if not any(p.is_file() and p.read_bytes() == resource.read_bytes() for p in candidates):
            raise ValueError('Built app is missing the current open-source notices.')
    return len(data['packages'])

if __name__ == '__main__':
    try:
        count = verify(built=Path(sys.argv[1]) if len(sys.argv) > 1 else None)
        print(f'PASS: exact license/notice coverage for {count} packages (12 remote, 2 local); source and offline copies match')
        if len(sys.argv) > 1:
            print('PASS: current open-source notices included in built app')
    except (ValueError, KeyError, OSError) as error:
        raise SystemExit('License verification failed: ' + str(error))

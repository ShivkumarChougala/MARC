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
    actual = {p['id']: (p['repository'], p['revision'], p['version']) for p in data['packages']}
    if len(actual) != len(data['packages']) or actual != expected:
        raise ValueError('Dependency pins changed or notices are missing. Review and regenerate notices before release.')
    license_text = (root / 'LICENSE').read_text()
    if data['marcLicense'] != license_text or 'Copyright (c) 2026 Shivkumar Chougala' not in license_text:
        raise ValueError('MARC license differs from its bundled copy.')
    if 'Permission is hereby granted, free of charge' not in license_text:
        raise ValueError('MARC MIT license text missing.')
    markdown = '# Third-party notices\n\n' + data['introduction'] + '\n\n' + data['acknowledgement'] + '\n\n'
    markdown += 'These texts were retrieved from the exact revisions in `Package.resolved`. Embedded source notices are retained below along with root licenses and NOTICE files. Source comment wording is preserved; trailing whitespace is normalized in this Markdown copy. Bundled source notices remain verbatim.\n\n'
    for package in data['packages']:
        if not package['documents']:
            raise ValueError('Empty package notices: ' + package['id'])
        markdown += f'## {package["name"]} {package["version"]}\n\nRepository: {package["repository"]}\n\nRevision: `{package["revision"]}`\n\n'
        has_license = False
        for doc in package['documents']:
            if hashlib.sha256(doc['text'].encode()).hexdigest() != doc['sha256']:
                raise ValueError('Notice integrity mismatch: ' + package['id'] + '/' + doc['path'])
            if not doc['sourceURL'].startswith(package['repository'].removesuffix('.git') + '/blob/' + package['revision'] + '/'):
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
    return len(actual)

if __name__ == '__main__':
    try:
        count = verify(built=Path(sys.argv[1]) if len(sys.argv) > 1 else None)
        print(f'PASS: exact license/notice coverage for {count} pinned packages; source and offline copies match')
        if len(sys.argv) > 1:
            print('PASS: current open-source notices included in built app')
    except (ValueError, KeyError, OSError) as error:
        raise SystemExit('License verification failed: ' + str(error))

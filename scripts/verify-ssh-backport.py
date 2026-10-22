#!/usr/bin/env python3
"""Verify local SSH backport provenance, source integrity and the unchanged remote graph."""
from pathlib import Path
import hashlib
import json
import os
import sys

ROOT = Path(__file__).resolve().parents[1]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def pinset(pins):
    result = {}
    for p in pins:
        key = p['identity']
        if key in result:
            raise ValueError('Duplicate dependency identity: ' + key)
        result[key] = (p['kind'], p['location'], p['state'])
    return result

def verify(root=ROOT):
    vendor = root / 'Vendor'
    manifest_path = vendor / 'DEPENDENCIES.json'
    if vendor.is_symlink() or manifest_path.is_symlink():
        raise ValueError('Symlinked vendor inventory')
    manifest = json.loads(manifest_path.read_text())
    if manifest['upstreamFix'] != '31cdc3c3391a10460dedf1170530cf651d2ca496':
        raise ValueError('Unexpected upstream backport provenance')
    for package in manifest['packages']:
        rel = Path(package['path'])
        if rel.is_absolute() or '..' in rel.parts or rel.parts[0] != 'Vendor':
            raise ValueError('Unsafe vendor path')
        folder = root / rel
        if folder.is_symlink() or not folder.is_dir():
            raise ValueError('Missing or symlinked local dependency: ' + str(rel))
        expected = package['files']
        for item in folder.rglob('*'):
            if item.is_symlink():
                raise ValueError('Unexpected vendor symlink: ' + str(item))
            # SwiftPM-generated metadata is not runtime source; scratch products belong elsewhere.
            if item.is_file():
                name = item.relative_to(folder).as_posix()
                if name == 'Package.resolved' or name.startswith('.swiftpm/'):
                    continue
                if name not in expected:
                    raise ValueError('Unreviewed vendor file: ' + str(item))
        for name, sha in expected.items():
            file_rel = Path(name)
            if file_rel.is_absolute() or '..' in file_rel.parts:
                raise ValueError('Unsafe source inventory path')
            path = folder / file_rel
            if not path.is_file() or digest(path) != sha:
                raise ValueError('Vendor source differs: ' + str(path))
        for name, sha in package['upstreamFiles'].items():
            # Every upstream file must remain represented; deviations must be explicitly listed.
            if name not in expected:
                raise ValueError('Upstream file missing from local snapshot: ' + name)
            if expected[name] != sha and package['changes'].get(name) != 'modified':
                raise ValueError('Unrecorded upstream modification: ' + name)
    parser = (vendor / 'swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/NIOSSHSignature.swift').read_text()
    bounds = 'guard rByteView.count <= pointSize, sByteView.count <= pointSize else {'
    if (bounds not in parser or parser.index(bounds) > parser.index('let rByteStartingOffset') or
            'private init(r: ByteBuffer, s: ByteBuffer, pointSize: Int) throws' not in parser or
            'let helper = try ECDSASignatureHelper(' not in parser):
        raise ValueError('Required pre-copy ECDSA bounds/error propagation absent')
    expected_pins = pinset(manifest['remotePins'])
    lock = root / 'MARC.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
    if pinset(json.loads(lock.read_text())['pins']) != expected_pins or len(expected_pins) != 12:
        raise ValueError('App remote dependency graph changed')
    for folder, ids in [('swift-nio-ssh', {'swift-nio','swift-crypto','swift-atomics','swift-collections','swift-system','swift-asn1'}),
                        ('Citadel', {'bigint','swift-log','swift-nio','swift-crypto','swift-atomics','swift-collections','swift-system','swift-asn1'})]:
        lock = vendor / folder / 'Package.resolved'
        expected = {key: value for key, value in expected_pins.items() if key in ids}
        if pinset(json.loads(lock.read_text())['pins']) != expected:
            raise ValueError('Local package test graph changed: ' + folder)
    project = (root / 'MARC.xcodeproj/project.pbxproj').read_text()
    if 'isa = XCLocalSwiftPackageReference;' not in project or 'relativePath = Vendor/Citadel;' not in project:
        raise ValueError('App does not select the local Citadel package')
    if 'repositoryURL = "https://github.com/orlandos-nl/Citadel";' in project:
        raise ValueError('Unpatched remote Citadel still selected by app')
    if os.getenv('SWIFTCI_USE_LOCAL_DEPS') is not None:
        raise ValueError('SWIFTCI_USE_LOCAL_DEPS overrides reviewed dependencies; remove it for verification')
    for directory in [root / '.swiftpm/configuration', root / 'MARC.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/configuration',
                      vendor / 'Citadel/.swiftpm/configuration', vendor / 'swift-nio-ssh/.swiftpm/configuration']:
        path = directory / 'mirrors.json'
        if path.exists():
            raise ValueError('Package mirror configuration requires a separate provenance review: ' + str(path))
    return manifest

if __name__ == '__main__':
    try:
        verify()
        print('PASS: local SSH/Citadel snapshot integrity, upstream provenance, project routing and 12 reviewed remote pins')
        print('Native malformed-signature regression tests, Mac build and device verification are separate requirements.')
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise SystemExit('SSH backport verification failed: ' + str(error))

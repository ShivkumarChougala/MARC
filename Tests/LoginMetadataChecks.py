#!/usr/bin/env python3
"""Execute the production login metadata loader with a counting Keychain double."""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Components/MARCLoginFields.swift').read_text()
loader = source[source.index('    private func reload()'):source.index('\n}\n\n/// Add Server uses')]
loader = loader.replace('private func reload()', 'func reload()')
fixture = r'''
import Foundation
struct MARCLoginDraft {
    enum Method { case password, key }
    var method = Method.password
}
@MainActor enum MARCSSHKeyStore {
    struct Info { let name: String }
    enum Failure: Error { case locked }
    static var calls = 0
    static var fails = false
    static func entries() throws -> [Info] {
        calls += 1
        if fails { throw Failure.locked }
        return [Info(name: "Test key")]
    }
}
@MainActor final class Loader {
    var draft = MARCLoginDraft()
    var keys: [MARCSSHKeyStore.Info] = []
    var failure: String?
    __LOADER__
}
@main struct Checks {
    @MainActor static func main() {
        let form = Loader()
        MARCSSHKeyStore.fails = true
        form.reload()
        precondition(MARCSSHKeyStore.calls == 0 && form.failure == nil)
        form.draft.method = .key
        MARCSSHKeyStore.fails = false
        form.reload()
        precondition(MARCSSHKeyStore.calls == 1 && form.keys.first?.name == "Test key")
        MARCSSHKeyStore.fails = true
        form.reload()
        precondition(MARCSSHKeyStore.calls == 2 && form.failure != nil)
        form.draft.method = .password
        form.reload()
        precondition(MARCSSHKeyStore.calls == 2 && form.keys.isEmpty && form.failure == nil)
        print("PASS: password login skips SSH-key metadata reads; key login loads keys and password mode clears stale metadata errors")
    }
}
'''.replace('__LOADER__', loader)
compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('Swift compiler required. Run this check on your Mac.')
with tempfile.TemporaryDirectory(prefix='marc-login-metadata-') as directory:
    path = Path(directory) / 'Checks.swift'
    binary = Path(directory) / 'checks'
    path.write_text(fixture)
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(path), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True, timeout=30)

#!/usr/bin/env python3
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
monitor = (root / 'MARC/Services/SSHMonitor.swift').read_text()
model = monitor[monitor.index('struct MARCLaunchApplication:'):monitor.index('private struct MARCControlRequest:')]
selection = (root / 'MARC/Services/MARCQuickLaunchSelection.swift').read_text()
checks = r'''
@main struct SelectionChecks {
    static func main() {
        let defaults = MARCQuickLaunchSelection.defaults
        precondition(MARCQuickLaunchSelection.read("{}", mac: "A") == defaults)
        precondition(MARCQuickLaunchSelection.read("invalid", mac: "A") == defaults)
        let apps = (0..<8).map { MARCLaunchApplication(id: "dev.test.App\($0)", title: "App \($0)") }
        let saved = MARCQuickLaunchSelection.write(apps, mac: "A", storage: "{}")
        precondition(MARCQuickLaunchSelection.read(saved, mac: "A") == apps)
        precondition(MARCQuickLaunchSelection.read(saved, mac: "B") == defaults)
        let empty = MARCQuickLaunchSelection.write([], mac: "B", storage: saved)
        precondition(MARCQuickLaunchSelection.read(empty, mac: "B").isEmpty)
        precondition(MARCQuickLaunchSelection.read(empty, mac: "A") == apps)
        let reversed = Array(apps.prefix(3).reversed())
        let reordered = MARCQuickLaunchSelection.write(reversed, mac: "A", storage: empty)
        precondition(MARCQuickLaunchSelection.read(reordered, mac: "A") == reversed)
        let bad = MARCLaunchApplication(id: "bad;command", title: "Bad")
        precondition(MARCQuickLaunchSelection.cleaned([apps[0], apps[0], bad]) == [apps[0]])
        precondition(!MARCLaunchApplication.validID("com.app\n"))
        precondition(MARCQuickLaunchSelection.write(apps, mac: "", storage: saved) == saved)
        let many = (0...MARCQuickLaunchSelection.maximumCount).map {
            MARCLaunchApplication(id: "dev.test.Many\($0)", title: "App \($0)")
        }
        precondition(MARCQuickLaunchSelection.cleaned(many).count == MARCQuickLaunchSelection.maximumCount)
        print("PASS: per-Mac shortcuts, more than six apps, empty selection, ordering and bounded validation")
    }
}
'''

def main():
    compiler = shutil.which('swiftc')
    if not compiler: raise SystemExit('Run Quick Launch selection checks on your Mac.')
    with tempfile.TemporaryDirectory(prefix='marc-launch-selection-') as folder:
        folder = Path(folder)
        source = folder / 'Checks.swift'; source.write_text(selection + model + checks)
        subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(source), '-o', str(folder / 'checks')], check=True)
        subprocess.run([str(folder / 'checks')], check=True)

if __name__ == '__main__': main()

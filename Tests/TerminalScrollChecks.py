#!/usr/bin/env python3
"""Exercise the production scroll adapter against a small SwiftTerm API double.
The Xcode app build checks the real dependency. Phone testing checks rendering.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Screens/MARCTerminalScreen.swift').read_text()
adapter = source[source.index('private final class MARCScrollbackTerminalView:'):
                 source.index('@MainActor @Observable\nfinal class MARCTerminalSlot:')]
fixture = r'''
import Foundation
import CoreGraphics

enum SwiftTerm {
    class TerminalView {
        var contentOffset = CGPoint.zero
        var contentSize = CGSize(width: 400, height: 3000)
        var bounds = CGRect(x: 0, y: 0, width: 400, height: 200)
        var adjustedContentInset = Insets()
        struct Insets { var bottom: CGFloat = 0 }
        struct Dimensions { var rows = 20 }
        var terminalDimensions = Dimensions()
        var isDecelerating = false
        var isTracking = false
        var gridHeight: CGFloat = 200
        var redraws = 0
        var requests: [Int] = []
        var mutateOffsetDuringScroll = false
        func getOptimalFrameSize() -> CGRect {
            CGRect(x: 0, y: 0, width: 400, height: gridHeight)
        }
        func requestRedraw() { redraws += 1 }
        func scrollTo(row: Int, notifyAccessibility: Bool) {
            precondition(!notifyAccessibility)
            requests.append(row)
            if mutateOffsetDuringScroll { contentOffset.y += 0.1 }
        }
    }
}
'''
checks = r'''
@main struct Checks {
    static func main() {
        let view = MARCScrollbackTerminalView()
        view.contentOffset.y = 10
        precondition(view.redraws == 1 && view.requests.isEmpty)
        view.contentOffset.y = 10
        precondition(view.redraws == 1) // unchanged offsets do no work
        view.isTracking = true
        view.contentOffset.y = 125.5
        precondition(view.redraws == 2 && view.requests.isEmpty)
        view.isTracking = false
        view.isDecelerating = true
        view.contentOffset.y = 115.5
        precondition(view.requests == [11] && view.contentOffset.y == 115.5)
        view.contentOffset.y = 113.2
        precondition(view.requests == [11]) // no repeated buffer update within a row
        view.contentOffset.y = 99
        precondition(view.requests == [11, 9])
        view.contentOffset.y = -5
        precondition(view.requests.last == 0) // rubber-band overscroll is clamped
        view.contentOffset.y = 5000
        precondition(view.requests.last == 280)
        view.isDecelerating = false
        view.contentOffset.y = 100
        let count = view.requests.count
        view.isDecelerating = true
        view.contentOffset.y = 2810
        precondition(view.requests.count == count + 1) // new coast resets row cache

        let empty = MARCScrollbackTerminalView()
        empty.isDecelerating = true
        empty.terminalDimensions.rows = 0
        empty.contentOffset.y = 20
        empty.terminalDimensions.rows = 20
        empty.gridHeight = 0
        empty.contentOffset.y = 30
        empty.gridHeight = 200
        empty.contentSize.height = 200
        empty.contentOffset.y = 40
        precondition(empty.requests.isEmpty && empty.redraws == 3)

        let nested = MARCScrollbackTerminalView()
        nested.isDecelerating = true
        nested.mutateOffsetDuringScroll = true
        nested.contentOffset.y = 150
        precondition(nested.requests == [15] && nested.redraws == 1)
        print("PASS: Terminal snapshot refresh and momentum viewport checks")
    }
}
'''

def main():
    compiler = shutil.which('swiftc')
    if not compiler:
        raise SystemExit('Swift is required. Run this check on your Mac.')
    with tempfile.TemporaryDirectory(prefix='marc-scroll-checks-') as directory:
        directory = Path(directory)
        swift = directory / 'ScrollChecks.swift'
        swift.write_text(fixture + adapter + checks)
        executable = directory / 'scroll-checks'
        subprocess.run([compiler, '-swift-version', '5', '-parse-as-library',
                        str(swift), '-o', str(executable)], check=True)
        subprocess.run([str(executable)], check=True)

if __name__ == '__main__':
    main()

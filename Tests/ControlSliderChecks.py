#!/usr/bin/env python3
"""Exercise production slider touch completion with a minimal UIKit stand-in.
Actual rendering and touch routing still require an iPhone/simulator check.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Components/MARCCompactControl.swift').read_text()
tracking = source[source.index('private final class MARCTouchSlider:'):]
support = r'''
import Foundation
class UITouch {}
class UIEvent {}
class UISlider {
    enum Event { case valueChanged }
    var minimumValue: Float = 0
    var maximumValue: Float = 100
    var value: Float = 40
    var isEnabled = true
    var acceptsTouch = true
    var changes = 0
    func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool { acceptsTouch }
    func endTracking(_ touch: UITouch?, with event: UIEvent?) {}
    func cancelTracking(with event: UIEvent?) {}
    func accessibilityIncrement() {}
    func accessibilityDecrement() {}
    func sendActions(for event: Event) { changes += 1 }
}
'''
checks = r'''
@main struct SliderChecks {
    static func main() {
        let slider = MARCTouchSlider()
        var editing = false
        var commits = 0
        slider.started = { editing = true }
        slider.finished = { committed in editing = false; if committed { commits += 1 } }
        for _ in 0..<20 {
            precondition(slider.beginTracking(UITouch(), with: nil) && editing)
            slider.endTracking(nil, with: nil)
            precondition(!editing)
        }
        precondition(commits == 20)
        _ = slider.beginTracking(UITouch(), with: nil)
        slider.cancelTracking(with: nil)
        slider.endTracking(nil, with: nil)
        precondition(!editing && commits == 20)
        slider.acceptsTouch = false
        precondition(!slider.beginTracking(UITouch(), with: nil) && !editing)
        slider.endTracking(nil, with: nil)
        precondition(commits == 20)
        slider.value = 99
        slider.accessibilityIncrement()
        precondition(slider.value == 100 && !editing && commits == 21 && slider.changes == 1)
        slider.value = 1
        slider.accessibilityDecrement()
        precondition(slider.value == 0 && !editing && commits == 22)
        slider.isEnabled = false
        slider.accessibilityIncrement()
        precondition(slider.value == 0 && commits == 22)
        print("PASS: slider release, cancellation, duplicate end events and accessibility adjustments")
    }
}
'''

def main():
    if not shutil.which('xcrun'):
        raise SystemExit('Run this check on your Mac (Xcode command line tools required).')
    with tempfile.TemporaryDirectory(prefix='marc-slider-checks-') as tmp:
        path = Path(tmp)
        swift = path / 'SliderChecks.swift'
        swift.write_text(support + tracking + checks)
        subprocess.run(['xcrun', 'swiftc', '-swift-version', '5', '-parse-as-library',
                        str(swift), '-o', str(path / 'checks')], check=True)
        subprocess.run([str(path / 'checks')], check=True)

if __name__ == '__main__':
    main()

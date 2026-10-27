#!/usr/bin/env python3
"""Exercise the production gallery label placement with crowded caption fixtures."""
from pathlib import Path
import re
import shutil
import sys
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'MARC/Screens/MARCFeatureGuideScreen.swift').read_text()
marker = 'private enum MARCPreviewLabelPlacement'
start = source.index(marker)
brace = source.index('{', start)
depth, end = 1, brace + 1
while depth:
    depth += (source[end] == '{') - (source[end] == '}')
    end += 1
production = source[start:end].replace('private enum ', 'enum ', 1)
notes = source[source.index('    var notes: [MARCPreviewNote]'):source.index('private struct MARCPreviewNote')]
counts = {name: block.count('.init(title:') for name, block in re.findall(
    r'case \.(\w+):\s+return \[(.*?)\n            \]', notes, re.S)}
assert counts == dict(status=4, system=4, statistics=2, processes=2, terminal=3, files=4, controls=3), counts
for title in ['System', 'Power & storage', 'Services & Docker', 'Top processes', 'Network', 'Storage', 'Add session', 'Upload', 'Back', 'Now Playing']:
    assert f'title: "{title}"' in notes
for x, y in re.findall(r'x: ([0-9.]+), y: ([0-9.]+)', notes):
    assert 0 < float(x) < 1 and 0 < float(y) < 1

checks = r'''
@main struct GalleryAnnotationChecks {
    static func main() {
        precondition(MARCPreviewLabelPlacement.centers(targets: [], heights: [], height: 240).isEmpty)
        var fixtures = 0
        for count in 1...4 {
            for heightScale in [CGFloat(44), 72, 108, 156] {
                let heights = (0..<count).map { heightScale + CGFloat($0 * 7) }
                for baseHeight in [CGFloat(240), 320, 474, 540] {
                    let height = max(baseHeight, heights.reduce(0, +) + CGFloat(count - 1) * 12 + 16)
                    for offset in [CGFloat(0), 0.12, 0.70, 0.95] {
                        // Crowded, top/bottom and ordinary targets must all retain readable gaps.
                        let targets = (0..<count).map { min(height, height * (offset + CGFloat($0) * 0.05)) }
                        let centers = MARCPreviewLabelPlacement.centers(targets: targets, heights: heights, height: height)
                        precondition(centers.count == count)
                        for index in centers.indices {
                            let top = centers[index] - heights[index] / 2
                            let bottom = centers[index] + heights[index] / 2
                            precondition(top >= 8 - 0.001 && bottom <= height - 8 + 0.001)
                            if index > 0 {
                                let previousBottom = centers[index - 1] + heights[index - 1] / 2
                                precondition(top - previousBottom >= 12 - 0.001)
                            }
                        }
                        fixtures += 1
                    }
                }
            }
        }
        // Isolated labels retain their target; existing two-label pages need no forced slots.
        precondition(MARCPreviewLabelPlacement.centers(targets: [120], heights: [60], height: 400) == [120])
        precondition(MARCPreviewLabelPlacement.centers(targets: [100, 300], heights: [50, 70], height: 400) == [100, 300])
        print("PASS: gallery caption placement, \(fixtures) crowded/large-text fixtures, readable gaps and preserved isolated targets")
    }
}
'''
if '--source-only' in sys.argv:
    print('PASS: gallery topic counts, updated Status labels and bounded screenshot anchors')
    print('NOT RUN: native Swift gallery placement fixtures (source-only mode)')
    raise SystemExit(0)
compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('Swift compiler required. Run this check on your Mac.')
with tempfile.TemporaryDirectory(prefix='marc-gallery-labels-') as directory:
    path = Path(directory) / 'GalleryAnnotationChecks.swift'
    path.write_text('import Foundation\n' + production + checks)
    binary = Path(directory) / 'gallery-label-checks'
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(path), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True, timeout=30)

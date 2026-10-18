#!/usr/bin/env python3
"""Compile production storage calculations and formatters without SSH or disk changes."""
from pathlib import Path
import shutil
import subprocess
import tempfile


def fixture_source():
    root = Path(__file__).resolve().parents[1]
    monitor = (root / 'MARC/Services/SSHMonitor.swift').read_text()
    snapshot = monitor[monitor.index('struct MacSnapshot:'):monitor.index('@MainActor @Observable final class SSHMonitor')]
    helper = (root / 'MARC/Services/MARCStatisticsData.swift').read_text()
    # Only byte formatting is needed; do not couple this fixture to history/chart types.
    helper = helper[:helper.index('    static func uptime(')] + '}\n'
    checks = r'''
@main struct StoragePresentationChecks {
    static func sample(total: Double, available: Double, dataUsed: Double = 0) -> MacSnapshot {
        MacSnapshot(hostname: "fixture", cpu: 0, memoryUsed: 0, memoryTotal: 0,
                    diskUsed: dataUsed, diskTotal: total, diskAvailable: available,
                    interface: nil, received: nil, sent: nil,
                    diskReadBytes: nil, diskWriteBytes: nil, details: nil, sampledAt: 0)
    }
    static func main() {
        // Shared APFS capacity: Data volume usage alone is not total occupied space.
        let disk = sample(total: 245_000_000_000, available: 95_060_000_000,
                          dataUsed: 122_630_000_000)
        precondition(disk.diskCapacityUsed == 149_940_000_000)
        precondition(abs(disk.diskPercent - 61.2) < 0.000001)
        precondition(disk.diskUsed == 122_630_000_000) // Preserve raw payload meaning.
        precondition(sample(total: 100, available: 30, dataUsed: 5).diskPercent == 70)
        precondition(sample(total: 100, available: 30, dataUsed: 65).diskPercent == 70)
        for (available, percent) in [(0.0, 100.0), (100, 0), (120, 0), (-5, 100)] {
            precondition(sample(total: 100, available: available).diskPercent == percent)
        }
        for total in [0.0, -1, .nan, .infinity] {
            precondition(sample(total: total, available: 10).diskPercent == 0)
        }
        for available in [Double.nan, .infinity, -.infinity] {
            precondition(sample(total: 100, available: available).diskCapacityUsed == 0)
            precondition(sample(total: 100, available: available).diskPercent == 0)
        }
        let huge = sample(total: .greatestFiniteMagnitude, available: 0)
        precondition(huge.diskCapacityUsed.isFinite && huge.diskPercent == 100)
        let decimal = MARCStatisticsData.storageBytes(95_060_000_000)
        let binary = MARCStatisticsData.byteCount(95_060_000_000)
        precondition(decimal == ByteCountFormatter.string(fromByteCount: 95_060_000_000, countStyle: .decimal))
        precondition(binary == ByteCountFormatter.string(fromByteCount: 95_060_000_000, countStyle: .binary))
        precondition(decimal != binary)
        precondition(MARCStatisticsData.storageBytes(nil) == "—")
        precondition(MARCStatisticsData.storageBytes(-1) == "—")
        precondition(MARCStatisticsData.storageBytes(.nan) == "—")
        precondition(MARCStatisticsData.storageBytes(.infinity) == "—")
        precondition(!MARCStatisticsData.storageBytes(.greatestFiniteMagnitude).isEmpty)
        // Foundation can spell out zero; do not require English digits or unit labels.
        let zero = MARCStatisticsData.storageBytes(0)
        precondition(!zero.isEmpty && zero != "—")
        print("PASS: consistent APFS capacity usage, decimal storage units, invalid values and preserved binary formatting")
    }
}
'''
    return ('import Foundation\nstruct SystemDetails: Decodable, Sendable {}\n' +
            snapshot + helper + checks)


def main():
    compiler = shutil.which('swiftc')
    if not compiler:
        raise SystemExit('Swift is required. Run storage presentation checks on your Mac.')
    with tempfile.TemporaryDirectory(prefix='marc-storage-presentation-') as directory:
        source = Path(directory) / 'StoragePresentation.swift'
        binary = Path(directory) / 'storage-presentation-checks'
        source.write_text(fixture_source())
        subprocess.run([compiler, '-swift-version', '5', '-parse-as-library',
                        str(source), '-o', str(binary)], check=True)
        subprocess.run([str(binary)], check=True)


if __name__ == '__main__':
    main()

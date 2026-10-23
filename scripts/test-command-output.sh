#!/bin/bash
set -euo pipefail
marc_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$marc_root"
python3 scripts/verify-ssh-backport.py
if ! command -v xcrun >/dev/null 2>&1; then
  echo 'STOP: Xcode command-line tools required for native command-output tests.' >&2
  exit 1
fi
marc_build="${MARC_BUILD_DIR:-$HOME/Library/Developer/Xcode/DerivedData/MARC-Verification}"
mkdir -p "$marc_build"
xcrun swift test \
  --package-path "$marc_root/Vendor/Citadel" \
  --scratch-path "$marc_build/OpenSSHKey-ASan-Release" \
  --configuration release \
  --disable-automatic-resolution \
  --sanitize address \
  --filter 'CitadelTests\.MARCBufferedCommandTests' \
  >"$marc_build/command-output-tests.log" 2>&1 || {
    tail -n 45 "$marc_build/command-output-tests.log"
    exit 1
  }
python3 - "$marc_root" "$marc_build/command-output-tests.log" <<'MARC_COMMAND_TEST_COUNT'
from pathlib import Path
import re
import sys
root, log_path = map(Path, sys.argv[1:])
log = log_path.read_text()
if not re.search(r'Executed 15 tests, with 0 failures \(0 unexpected\)', log):
    raise SystemExit('STOP: expected 15 command-output regression tests with zero failures; inspect ' + str(log_path))
if not re.search(r"Test Suite ['\"]MARCBufferedCommandTests['\"] passed", log):
    raise SystemExit('STOP: missing passed command-output XCTest suite')
methods = re.findall(r'func (test\w+)\(', (root / 'Vendor/Citadel/Tests/CitadelTests/MARCBufferedCommandTests.swift').read_text())
if len(methods) != 15:
    raise SystemExit('STOP: unexpected command-output test inventory')
for name in methods:
    if not any(name in line and 'passed' in line for line in log.splitlines()):
        raise SystemExit('STOP: regression test did not pass: ' + name)
if 'ERROR: AddressSanitizer:' in log or 'SUMMARY: AddressSanitizer:' in log:
    raise SystemExit('STOP: AddressSanitizer reported an error; inspect ' + str(log_path))
print('PASS: 15 command-output native regression tests executed with zero failures')
MARC_COMMAND_TEST_COUNT
python3 scripts/verify-ssh-backport.py

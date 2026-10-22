#!/bin/bash
set -euo pipefail
marc_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$marc_root"
python3 scripts/verify-ssh-backport.py
if ! command -v xcrun >/dev/null 2>&1; then
  echo 'STOP: Xcode command-line tools required for native private-key tests.' >&2
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
  --filter 'CitadelTests\.(MARCOpenSSHKeyTests|KeyTests)' \
  >"$marc_build/openssh-key-tests.log" 2>&1 || {
    tail -n 45 "$marc_build/openssh-key-tests.log"
    exit 1
  }
python3 - "$marc_root" "$marc_build/openssh-key-tests.log" <<'MARC_KEY_TEST_COUNT'
from pathlib import Path
import re
import sys
root, log_path = map(Path, sys.argv[1:])
log = log_path.read_text()
if not re.search(r'Executed 19 tests, with 0 failures \(0 unexpected\)', log):
    raise SystemExit('STOP: expected 19 private-key regression tests with zero failures; inspect ' + str(log_path))
for name in ('MARCOpenSSHKeyTests', 'KeyTests'):
    if not re.search(r"Test Suite ['\"]" + name + r"['\"] passed", log):
        raise SystemExit('STOP: missing passed XCTest suite: ' + name)
methods = re.findall(r'func (test\w+)\(', (root / 'Vendor/Citadel/Tests/CitadelTests/MARCOpenSSHKeyTests.swift').read_text())
if len(methods) != 10:
    raise SystemExit('STOP: unexpected private-key test inventory')
for name in methods:
    if not any(name in line and "passed" in line for line in log.splitlines()):
        raise SystemExit('STOP: regression test did not pass: ' + name)
if 'ERROR: AddressSanitizer:' in log or 'SUMMARY: AddressSanitizer:' in log:
    raise SystemExit('STOP: AddressSanitizer reported an error; inspect ' + str(log_path))
print('PASS: 19 private-key native regression tests executed with zero failures')
MARC_KEY_TEST_COUNT
python3 scripts/verify-ssh-backport.py

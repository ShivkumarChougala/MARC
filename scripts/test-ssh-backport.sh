#!/bin/bash
set -euo pipefail
marc_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$marc_root"
python3 scripts/verify-ssh-backport.py
if ! command -v xcrun >/dev/null 2>&1; then
  echo "Xcode command-line tools required for native SSH regression tests." >&2
  exit 1
fi
marc_build="${MARC_BUILD_DIR:-$HOME/Library/Developer/Xcode/DerivedData/MARC-Verification}"
mkdir -p "$marc_build"
# Native host tests; keep compiler products out of the source tree.
xcrun swift test \
  --package-path "$marc_root/Vendor/swift-nio-ssh" \
  --scratch-path "$marc_build/SSHBackport-ASan-Release" \
  --configuration release \
  --disable-automatic-resolution \
  --sanitize address \
  --filter 'MARC(ECDSASignature|CryptoDependency)Tests' \
  2>&1 | tee "$marc_build/ssh-backport-tests.log"
# A successful command must actually execute both reviewed XCTest classes.
python3 - "$marc_build/ssh-backport-tests.log" <<'MARC_TEST_COUNT'
from pathlib import Path
import re
import sys
log = Path(sys.argv[1]).read_text()
if not re.search(r'Executed 10 tests, with 0 failures \(0 unexpected\)', log):
    raise SystemExit('STOP: expected ten SSH/Crypto regression tests with zero failures; inspect the native log')
if 'ERROR: AddressSanitizer:' in log:
    raise SystemExit('STOP: AddressSanitizer reported an error')
print('PASS: ten SSH/Crypto native regression tests executed with zero failures')
MARC_TEST_COUNT
# Confirm that testing did not resolve to a different graph or alter reviewed source.
python3 scripts/verify-ssh-backport.py

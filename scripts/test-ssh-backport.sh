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
  --filter MARCECDSASignatureTests \
  2>&1 | tee "$marc_build/ssh-backport-tests.log"
# Confirm that testing did not resolve to a different graph or alter reviewed source.
python3 scripts/verify-ssh-backport.py

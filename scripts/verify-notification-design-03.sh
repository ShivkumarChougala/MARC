#!/bin/bash
set -euo pipefail
marc_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$marc_root"
if ! command -v xcrun >/dev/null 2>&1; then
    echo "Xcode is required. Run this script on your Mac." >&2
    exit 1
fi
marc_build="${MARC_BUILD_DIR:-$HOME/Library/Developer/Xcode/DerivedData/MARC-Verification}"
mkdir -p "$marc_build"
xcrun swiftc -swift-version 5 -default-isolation MainActor -parse-as-library \
    MARC/Services/MARCAlertRule.swift MARC/Services/MARCAlertStore.swift \
    Tests/CustomAlertChecks.swift -o "$marc_build/custom-alert-checks"
"$marc_build/custom-alert-checks"
xcrun swiftc -swift-version 5 -default-isolation MainActor -parse-as-library \
    MARC/Services/MARCAlertRule.swift MARC/Services/MARCNotificationThreshold.swift \
    Tests/AdvancedAlertChecks.swift -o "$marc_build/advanced-alert-checks"
"$marc_build/advanced-alert-checks"
xcrun swiftc -swift-version 5 -default-isolation MainActor -parse-as-library \
    MARC/Services/MARCNotificationThreshold.swift Tests/NotificationThresholdChecks.swift \
    -o "$marc_build/notification-threshold-checks"
"$marc_build/notification-threshold-checks"

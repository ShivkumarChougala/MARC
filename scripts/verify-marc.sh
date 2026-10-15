#!/bin/bash
set -euo pipefail
marc_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$marc_root"
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Xcode is required. Run this script on your Mac." >&2
    exit 1
fi
# Reuse one build folder so repeated checks do not fill the Mac's disk.
marc_build="${MARC_BUILD_DIR:-$HOME/Library/Developer/Xcode/DerivedData/MARC-Verification}"
mkdir -p "$marc_build"
echo "Build output and log: $marc_build"
xcodebuild -version
xcrun swiftc -swift-version 5 \
    MARC/Services/NearbyMacIndex.swift \
    MARC/Models/ServerProfile.swift \
    MARC/Services/HostKeyIdentity.swift \
    Tests/DiscoveryChecks.swift \
    -o "$marc_build/discovery-checks"
python3 Tests/FileActionChecks.py
xcrun swiftc -swift-version 5 \
    MARC/Services/MARCFileFormatting.swift \
    Tests/FileUIHelpersChecks.swift \
    -o "$marc_build/file-ui-checks"
"$marc_build/file-ui-checks"
"$marc_build/discovery-checks"
# Select the target platform by destination. Do not globally force -sdk or
# SDKROOT: Swift package build tools must remain native macOS executables.
xcodebuild \
    -project MARC.xcodeproj \
    -scheme MARC \
    -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$marc_build" \
    -onlyUsePackageVersionsFromResolvedFile \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | tee "$marc_build/build.log"
xcrun swift scripts/verify-plist.swift \
    "$marc_build/Build/Products/Debug-iphonesimulator/MARC.app/Info.plist"
echo "PASS: simulator build and generated plist verification. Log: $marc_build/build.log"

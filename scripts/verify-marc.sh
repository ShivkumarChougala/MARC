#!/bin/bash
set -euo pipefail
marc_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$marc_root"
python3 scripts/verify-source-hygiene.py
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Xcode is required. Run this script on your Mac." >&2
    exit 1
fi
# Reuse one build folder so repeated checks do not fill the Mac's disk.
marc_build="${MARC_BUILD_DIR:-$HOME/Library/Developer/Xcode/DerivedData/MARC-Verification}"
mkdir -p "$marc_build"
echo "Build output and log: $marc_build"
xcodebuild -version
python3 scripts/verify-privacy.py
xcrun swiftc -swift-version 5 \
    MARC/Services/NearbyMacIndex.swift \
    MARC/Models/ServerProfile.swift \
    MARC/Services/HostKeyIdentity.swift \
    Tests/DiscoveryChecks.swift \
    -o "$marc_build/discovery-checks"
xcrun swiftc -swift-version 5 \
    MARC/Services/MARCCollectorHealth.swift \
    Tests/CollectorHealthChecks.swift \
    -o "$marc_build/collector-health-checks"
"$marc_build/collector-health-checks"
python3 Tests/ConnectionLifecycleChecks.py
python3 Tests/TerminalFilesTaskChecks.py
python3 Tests/TerminalScrollChecks.py
python3 Tests/AIRequestChecks.py
python3 Tests/APIKeyStoreChecks.py
python3 Tests/APIProviderChecks.py
xcrun swiftc -swift-version 5 -parse-as-library \
    MARC/Services/MARCAIResponseReader.swift Tests/AIResponseChecks.swift \
    -o "$marc_build/ai-response-checks"
"$marc_build/ai-response-checks"
python3 Tests/ControlTaskChecks.py
python3 Tests/ControlSliderChecks.py
python3 Tests/QuickLaunchChecks.py
python3 Tests/MediaControlChecks.py
python3 Tests/DisplayControlChecks.py
python3 Tests/PlayerDiscoveryChecks.py
python3 Tests/InstalledAppChecks.py
python3 Tests/ApplicationCatalogChecks.py
python3 Tests/AudioWirelessChecks.py
python3 Tests/QuickLaunchSelectionChecks.py
python3 Tests/ProcessChecks.py
python3 Tests/SystemStatisticsChecks.py
python3 Tests/SystemDetailsChecks.py
python3 Tests/DiskCollectorChecks.py
python3 Tests/NetworkCollectorChecks.py
python3 Tests/StorageCollectorChecks.py
python3 Tests/StoragePresentationChecks.py
python3 Tests/LoginMetadataChecks.py
python3 Tests/SettingsChecks.py
python3 Tests/OnboardingChecks.py
python3 Tests/GalleryAnnotationChecks.py
xcrun swiftc -swift-version 5 \
    MARC/Services/MARCLocalDownload.swift \
    Tests/LocalDownloadChecks.swift \
    -o "$marc_build/local-download-checks"
"$marc_build/local-download-checks"
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
python3 scripts/verify-privacy.py \
    "$marc_build/Build/Products/Debug-iphonesimulator/MARC.app"
python3 scripts/verify-source-hygiene.py \
    "$marc_build/Build/Products/Debug-iphonesimulator/MARC.app"
echo "PASS: simulator build and generated plist verification. Log: $marc_build/build.log"

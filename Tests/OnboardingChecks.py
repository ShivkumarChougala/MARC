#!/usr/bin/env python3
"""Run actual first-launch policy and live-tour state transitions without SwiftUI or SSH."""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
policy = (root / 'MARC/Services/MARCOnboardingPolicy.swift').read_text()
hints = (root / 'MARC/Services/MARCLearningHint.swift').read_text()
placement = (root / 'MARC/Services/MARCGuidePlacement.swift').read_text()
tour = (root / 'MARC/Services/MARCGuidedTour.swift').read_text()
tour = tour.replace('import Observation\n', '').replace('@MainActor @Observable ', '@MainActor ')
checks = r'''
@main struct OnboardingChecks {
    @MainActor static func main() {
        precondition(MARCOnboardingPolicy.needsIntroduction(completedVersion: 0, hasSavedServers: false, profileReadFailed: false))
        precondition(!MARCOnboardingPolicy.needsIntroduction(completedVersion: 1, hasSavedServers: false, profileReadFailed: false))
        precondition(!MARCOnboardingPolicy.needsIntroduction(completedVersion: 0, hasSavedServers: true, profileReadFailed: false))
        precondition(!MARCOnboardingPolicy.needsIntroduction(completedVersion: 0, hasSavedServers: false, profileReadFailed: true))
        precondition(MARCOnboardingPolicy.migratedVersion(0, hasSavedServers: true, profileReadFailed: false) == 1)
        precondition(MARCOnboardingPolicy.migratedVersion(0, hasSavedServers: false, profileReadFailed: true) == 1)
        precondition(MARCOnboardingPolicy.migratedVersion(4, hasSavedServers: false, profileReadFailed: false) == 4)
        // Hints are quiet during setup, typing, inactive scenes and blocking presentations.
        precondition(MARCLearningHint.canPresent(dismissed: false, enabled: true, active: true,
            setupActive: false, blocked: false, keyboardVisible: false))
        let unavailable: [(Bool, Bool, Bool, Bool, Bool, Bool)] = [
            (true, true, true, false, false, false), // dismissed
            (false, false, true, false, false, false), // disconnected/busy target
            (false, true, false, false, false, false), // inactive scene
            (false, true, true, true, false, false), // setup owns guidance
            (false, true, true, false, true, false), // modal is open
            (false, true, true, false, false, true) // keyboard is visible
        ]
        for (dismissed, enabled, active, setup, blocked, keyboard) in unavailable {
            precondition(!MARCLearningHint.canPresent(dismissed: dismissed, enabled: enabled, active: active,
                setupActive: setup, blocked: blocked, keyboardVisible: keyboard))
        }
        let statusHints: [MARCLearningHint] = [.statusSystem, .status]
        precondition(MARCLearningHint.next(in: statusHints, dismissed: [], visible: ["statusSystem", "status"]) == .statusSystem)
        precondition(MARCLearningHint.next(in: statusHints, dismissed: ["statusSystem"], visible: ["statusSystem", "status"]) == .status)
        precondition(MARCLearningHint.next(in: statusHints, dismissed: [], visible: ["status"]) == .status,
                     "A hidden System card must not block Statistics guidance")
        let fileHints: [MARCLearningHint] = [.files, .filesFolders, .filesActions]
        let fileIDs = Set(fileHints.map(\.rawValue))
        precondition(MARCLearningHint.next(in: fileHints, dismissed: [], visible: fileIDs) == .files)
        precondition(MARCLearningHint.next(in: fileHints, dismissed: ["files"], visible: fileIDs) == .filesFolders)
        precondition(MARCLearningHint.next(in: fileHints, dismissed: ["files", "filesFolders"],
            visible: fileIDs) == .filesActions)
        precondition(MARCLearningHint.next(in: fileHints, dismissed: fileIDs, visible: fileIDs) == nil)
        precondition(MARCLearningHint.next(in: fileHints, dismissed: [], visible: []) == nil,
                     "Off-screen controls must never receive hints")
        precondition(MARCLearningHint.next(in: fileHints, dismissed: ["files"], visible: ["filesFolders"]) == .filesFolders,
                     "Empty folders can still explain navigation without inventing a file row")
        let systemHints: [MARCLearningHint] = [.systemCPU, .systemMemory, .systemStorage]
        precondition(MARCLearningHint.next(in: systemHints, dismissed: [], visible: ["systemMemory", "systemStorage"]) == .systemMemory,
                     "An off-screen CPU must not block visible System guidance")
        precondition(MARCLearningHint.next(in: systemHints, dismissed: ["systemMemory"], visible: ["systemMemory", "systemStorage"]) == .systemStorage)
        precondition(Set(MARCLearningHint.allCases.map(\.preferenceKey)).count == MARCLearningHint.allCases.count)
        let preferences = UserDefaults(suiteName: "marc-hint-checks-" + UUID().uuidString)!
        for hint in MARCLearningHint.allCases {
            preferences.set(true, forKey: hint.preferenceKey)
        }
        preferences.removeObject(forKey: MARCLearningHint.files.preferenceKey)
        precondition(!preferences.bool(forKey: MARCLearningHint.files.preferenceKey))
        precondition(preferences.bool(forKey: MARCLearningHint.processes.preferenceKey),
                     "Each hint must have its own dismissal key")
        // Per-topic replay must preserve other topics' dismissal preferences.
        for hint in fileHints { preferences.removeObject(forKey: hint.preferenceKey) }
        precondition(fileHints.allSatisfy { !preferences.bool(forKey: $0.preferenceKey) })
        precondition(preferences.bool(forKey: MARCLearningHint.systemCPU.preferenceKey))
        for hint in MARCLearningHint.allCases { preferences.removeObject(forKey: hint.preferenceKey) }

        // Next reviews only available explanations; selection/credentials stay real.
        var setupHints = MARCSetupHintProgress()
        precondition(setupHints.target(manual: false, selected: false, hasHost: false,
            hasDevices: false, ready: false) == "method")
        setupHints.review("method")
        precondition(setupHints.target(manual: false, selected: false, hasHost: false,
            hasDevices: false, ready: false) == "scan")
        setupHints.review("scan")
        precondition(setupHints.target(manual: false, selected: false, hasHost: false,
            hasDevices: false, ready: false) == nil, "Next cannot invent a nearby Mac")
        precondition(setupHints.target(manual: false, selected: false, hasHost: false,
            hasDevices: true, ready: false) == "device", "Real scan results resume guidance")
        setupHints.review("device")
        precondition(setupHints.target(manual: false, selected: false, hasHost: false,
            hasDevices: true, ready: true) == nil, "Credentials cannot bypass Mac selection")
        precondition(setupHints.target(manual: false, selected: true, hasHost: true,
            hasDevices: true, ready: false) == "login")
        setupHints.review("login")
        precondition(setupHints.target(manual: false, selected: true, hasHost: true,
            hasDevices: true, ready: false) == nil, "Next does not fill credentials")
        precondition(setupHints.target(manual: false, selected: true, hasHost: true,
            hasDevices: true, ready: true) == "connect")
        setupHints.review("connect")
        precondition(setupHints.target(manual: false, selected: true, hasHost: true,
            hasDevices: true, ready: true) == nil)
        setupHints.restartLogin()
        precondition(setupHints.target(manual: false, selected: true, hasHost: true,
            hasDevices: true, ready: false) == "login", "Changing Mac restores login guidance")
        var manualHints = MARCSetupHintProgress()
        precondition(manualHints.target(manual: true, selected: false, hasHost: false,
            hasDevices: false, ready: false) == "address")
        manualHints.review("address")
        precondition(manualHints.target(manual: true, selected: false, hasHost: false,
            hasDevices: false, ready: false) == "login")
        manualHints.review("login")
        precondition(manualHints.target(manual: true, selected: false, hasHost: true,
            hasDevices: false, ready: false) == nil)
        precondition(manualHints.target(manual: true, selected: false, hasHost: true,
            hasDevices: false, ready: true) == "connect")
        print("PASS: setup Next progression, real-result waiting, manual path and login restart without synthetic selection or credentials")

        let guide = MARCGuidedTour()
        precondition(!guide.active && guide.stage == .welcome)
        let formA = UUID(), formB = UUID()
        guide.setPresentation(formA, visible: true); guide.setPresentation(formA, visible: true)
        guide.setPresentation(formB, visible: true)
        guide.setPresentation(formA, visible: false)
        precondition(guide.hasBlockingPresentation, "An overlapping form must keep automatic start blocked")
        guide.setPresentation(formB, visible: false)
        precondition(!guide.hasBlockingPresentation)
        let initialFeedback = guide.feedbackID
        guide.startSetup()
        precondition(guide.flow == .setup && guide.stage == .welcome)
        precondition(guide.feedbackID != initialFeedback)
        guide.back(); precondition(guide.stage == .welcome)
        guide.connectionSucceeded()
        precondition(guide.active && !guide.finished, "Welcome cannot report connection success")
        guide.next(); precondition(guide.stage == .prepare)
        guide.connectionSucceeded()
        precondition(guide.active && !guide.finished, "Preparing the Mac is not a connection")
        guide.back(); precondition(guide.stage == .welcome)
        guide.next(); guide.next(); precondition(guide.stage == .addServer)
        guide.connectionSucceeded()
        precondition(guide.active && !guide.finished, "Pointing to Add server is not a connection")
        guide.back(); precondition(guide.stage == .prepare)
        guide.next(); precondition(guide.stage == .addServer)
        guide.next(); precondition(guide.stage == .connect)
        guide.next()
        precondition(guide.active && !guide.finished, "Continue cannot manufacture success")
        guide.back(); precondition(guide.stage == .addServer)
        guide.next(); guide.connectionSucceeded()
        precondition(!guide.active && guide.completedFlow == .setup && guide.finished && guide.feedback == .completion)
        let completion = guide.completionID
        guide.next(); guide.skip(); guide.connectionSucceeded()
        precondition(guide.completionID == completion, "Inactive actions must not complete twice")

        guide.startSetup()
        let beforeSkip = guide.feedbackID
        guide.skip()
        precondition(!guide.active && !guide.finished && guide.completedFlow == .setup && guide.feedbackID == beforeSkip,
                     "Skip must not produce success haptics")
        let connection = UUID()
        precondition(MARCFeatureAction.allCases.count == 6)
        precondition(Set(MARCFeatureAction.allCases.map(\.rawValue)).count == 6)
        precondition(MARCOnboardingPolicy.canStartFeatures(approvedConnection: connection, currentConnection: connection, connected: true))
        precondition(!MARCOnboardingPolicy.canStartFeatures(approvedConnection: nil, currentConnection: connection, connected: true))
        precondition(!MARCOnboardingPolicy.canStartFeatures(approvedConnection: UUID(), currentConnection: connection, connected: true))
        precondition(!MARCOnboardingPolicy.canStartFeatures(approvedConnection: connection, currentConnection: connection, connected: false))
        for action in MARCFeatureAction.allCases {
            guide.openFeature(action, connection: connection)
            precondition(!guide.active, "Show me must not start a sequential tour")
            precondition(guide.takeFeatureRequest(currentConnection: connection, connected: true) == action)
            precondition(guide.takeFeatureRequest(currentConnection: connection, connected: true) == nil,
                         "Each navigation request must be consumed only once")
        }
        guide.openFeature(.moveFile, connection: connection)
        precondition(guide.takeFeatureRequest(currentConnection: UUID(), connected: true) == nil)
        precondition(guide.featureRequest == nil, "A stale Mac request must be discarded")
        guide.openFeature(.runCommand, connection: connection)
        precondition(guide.takeFeatureRequest(currentConnection: connection, connected: false) == nil)
        guide.openFeature(.controlMac, connection: connection)
        guide.discardFeatureRequest()
        precondition(guide.featureRequest == nil)
        guide.openFeature(.checkMac, connection: connection)
        guide.startSetup()
        precondition(guide.featureRequest == nil)
        guide.openFeature(.runCommand, connection: connection)
        precondition(guide.featureRequest == nil, "Setup must not be interrupted by a feature request")
        guide.next(); guide.next(); guide.next()
        precondition(guide.active && !guide.finished)
        guide.connectionSucceeded()
        precondition(!guide.active && guide.finished && guide.completedFlow == .setup)
        var layouts = 0
        let widths: [CGFloat] = [320, 390, 667, 844]
        let heights: [CGFloat] = [280, 375, 568, 844]
        let cardHeights: [CGFloat] = [176, 244, 340, 600]
        for width in widths {
            for height in heights {
                for cardHeight in cardHeights {
                    let positions: [CGFloat] = [0, height * 0.3, height * 0.65, height - 60]
                    for y in positions {
                        let targetHeights: [CGFloat] = [32, 80, height]
                        for targetHeight in targetHeights {
                            let result = MARCGuidePlacement.resolve(size: CGSize(width: width, height: height),
                                target: CGRect(x: 12, y: y, width: width - 24, height: targetHeight), preferredHeight: cardHeight)
                            let viewport = CGRect(x: 0, y: 0, width: width, height: height)
                            precondition(viewport.contains(result.card), "Coach must remain inside the viewport")
                            if let focus = result.focus {
                                precondition(viewport.contains(focus))
                                let overlap = result.card.intersection(focus.insetBy(dx: -6, dy: -6))
                                precondition(overlap.isNull || overlap.isEmpty, "Coach must not cover the focused control")
                            }
                            layouts += 1
                        }
                    }
                }
            }
        }
        // Production setup caption placement must protect controls and discovery results.
        var setupLayouts = 0
        for width in widths {
            for height in heights {
                let size = CGSize(width: width, height: height)
                let viewport = CGRect(origin: .zero, size: size)
                for y in [CGFloat(20), height * 0.3, height - 60] {
                    let target = CGRect(x: 16, y: y, width: width - 32, height: 36)
                    let panel = CGRect(x: 16, y: y + 52, width: width - 32, height: 140)
                    for textHeight in [CGFloat(72), 112, 220, 900] {
                        for accessibility in [false, true] {
                            if let card = MARCGuidePlacement.setupCaption(size: size, target: target,
                                avoid: panel, preferredHeight: textHeight, accessibility: accessibility) {
                                precondition(viewport.contains(card))
                                precondition(card.height == textHeight, "Never clip large caption text")
                                precondition(!card.intersects(target.insetBy(dx: -8, dy: -8)))
                                precondition(!card.intersects(panel.insetBy(dx: -8, dy: -8)),
                                             "Guidance must not cover discovery rows or scan actions")
                                setupLayouts += 1
                            }
                        }
                    }
                }
            }
        }
        precondition(setupLayouts > 0)
        let setupSize = CGSize(width: 390, height: 700)
        let topTarget = CGRect(x: 16, y: 60, width: 358, height: 44)
        let protectedPanel = CGRect(x: 16, y: 120, width: 358, height: 180)
        let belowPanel = MARCGuidePlacement.setupCaption(size: setupSize, target: topTarget,
            avoid: protectedPanel, preferredHeight: 88)!
        precondition(belowPanel.minY == protectedPanel.maxY + 16)
        precondition(MARCGuidePlacement.setupCaption(size: setupSize,
            target: CGRect(x: 16, y: -10, width: 100, height: 44), preferredHeight: 88) == nil)
        precondition(MARCGuidePlacement.setupCaption(size: setupSize, target: topTarget,
            preferredHeight: 900) == nil, "Hide instead of covering controls or clipping text")
        precondition(MARCGuidePlacement.setupCaption(size: setupSize, target: .infinite,
            preferredHeight: 88) == nil)
        print("PASS: moving setup caption bounds, large text, off-screen targets and protected discovery rows")
        let missingTargets: [CGRect?] = [nil, CGRect.null, CGRect.infinite, CGRect(x: 10, y: -500, width: 20, height: 10)]
        for target in missingTargets {
            let result = MARCGuidePlacement.resolve(size: CGSize(width: 320, height: 568), target: target, preferredHeight: 244)
            precondition(result.focus == nil && result.card.height == 244)
        }
        print("PASS: contextual hint suppression, visible-target priority, empty folders, independent dismissal and per-topic replay")
        print("PASS: real setup progression, Back/Skip, first-launch migration and completion feedback")
        print("PASS: six real-screen destinations, one-shot navigation, stale/disconnected request rejection and setup ownership")
        print("PASS: setup guidance and \(layouts) coach placements without target overlap, including short windows and large text")
    }
}
'''
compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('Swift compiler required. Run this check on your Mac.')
with tempfile.TemporaryDirectory(prefix='marc-live-tour-checks-') as directory:
    path = Path(directory) / 'OnboardingChecks.swift'
    path.write_text(policy + hints + placement + tour + checks)
    binary = Path(directory) / 'onboarding-checks'
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(path), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True, timeout=30)

#!/usr/bin/env python3
"""Compile production Control Center methods with in-memory SSH replies.
No device controls, network requests or remote shell commands are executed.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
screen = (root / 'MARC/Screens/WorkspaceScreens.swift').read_text()
screen = screen[screen.index('struct ControlsScreen:'):screen.index('private struct MARCTerminationSheet:')]
monitor = (root / 'MARC/Services/SSHMonitor.swift').read_text()
transport_start = monitor.index('extension SSHMonitor {\n    var controlConnectionID:')
types = monitor[monitor.index('// MARK: - MARC live Control Center'):transport_start]
transport = monitor[transport_start:monitor.index('    private static let marcControlPython')]+ '\n}\n'
properties = screen[screen.index('    private var controlsEnabled:'):screen.index('    var body:')]
media = screen[screen.index('    private var playbackTarget:'):screen.index('    private func sectionTitle(')]
methods = screen[screen.index('    @MainActor\n    private func accept('):screen.rfind('\n}')]

support = r'''
import Foundation
enum MARCAIError: Error { case message(String) }
enum FixtureError: Error { case expected }
enum ScenePhase { case active, inactive, background }
@MainActor final class Gate {
    var entered = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; await withCheckedContinuation { continuation = $0 } }
    func open() { continuation?.resume(); continuation = nil }
}
@MainActor final class UINotificationFeedbackGenerator {
    enum FeedbackType { case error, success }
    func notificationOccurred(_ type: FeedbackType) {}
}
struct FixtureOutput { let readableBytesView: [UInt8] }
@MainActor final class SSHClient {
    static var requests: [[String: Any]] = []
    static var hook: (([String: Any]) async throws -> [String: Any])?
    static func reply(_ request: [String: Any], volume: Int = 30) -> [String: Any] {
        var result: [String: Any] = ["volume": volume, "brightness": 40,
            "bluetoothWritable": true, "wirelessIncluded": request["includeWireless"] as? Bool ?? false,
            "selectedDisplayID": request["displayID"] as? Int ?? 10]
        if request["action"] as? String == "volume" { result["volume"] = request["value"] }
        if request["action"] as? String == "brightness" { result["brightness"] = request["value"] }
        if result["wirelessIncluded"] as? Bool == true {
            result["wifiEnabled"] = true; result["wifiName"] = "Fixture LAN"
            result["bluetoothEnabled"] = true
        }
        return result
    }
    func executeCommand(_ command: String, maxResponseSize: Int, mergeStreams: Bool) async throws -> FixtureOutput {
        let argument = command.components(separatedBy: " ")[2]
        let request = try JSONSerialization.jsonObject(with: Data(base64Encoded: argument)!) as! [String: Any]
        Self.requests.append(request)
        let reply: [String: Any]
        if let hook = Self.hook { reply = try await hook(request) }
        else { reply = Self.reply(request) }
        let data = try JSONSerialization.data(withJSONObject: reply)
        return FixtureOutput(readableBytesView: Array(data))
    }
}
@MainActor final class SSHMonitor {
    struct Server { let id = UUID() }
    var connected = true
    var server: Server? = Server()
    var generation = UUID()
    var client: SSHClient? = SSHClient()
    static let marcControlPython = "fixture-only"
}
'''
harness = r'''
@MainActor final class ControlsHarness {
    let monitor = SSHMonitor()
    var scenePhase = ScenePhase.active
    var state: MARCControlState?
    var volume = 0.0
    var brightness = 0.0
    var selectedDisplayID: Int? = 10
    var editingBrightness = false
    var editingVolume = false
    var feedbackAction: MARCControlAction?
    var lastValue: Int?
    var noticeEvent = UUID()
    var busy = false
    var refreshing = false
    var failure: String?
    var notice: String?
    var wirelessReadAt: TimeInterval?
    var revision = UUID()
    var actionTask: Task<Void, Never>?
    var visible = true
    var controlConnection: UUID?
    var confirmWiFiOff = false
    var mediaPlayer = 0
    var confirmLock = false
    var showControlDetails = false
    var showMediaSetup = false
    var copiedMediaCommand = false
    var showDisplayActions = false
    init() { controlConnection = monitor.controlConnectionID }
    func dispatch(_ action: MARCControlAction, _ value: Int) { send(action, value: value) }
    func read(_ wireless: Bool = true) async { await refresh(wireless: wireless) }
    func leave() { visible = false; controlConnection = nil; stopControlWork() }
    func returnToConnection() { visible = true; controlConnection = monitor.controlConnectionID }
    func seed() throws {
        state = try JSONDecoder().decode(MARCControlState.self,
            from: JSONSerialization.data(withJSONObject: SSHClient.reply(["includeWireless": true])))
        volume = 30; brightness = 40
    }
}
'''
checks = r'''
@main struct ControlTaskChecks {
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<4000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Fixture did not reach expected boundary")
    }
    @MainActor static func main() async throws {
        let queued = ControlsHarness()
        queued.dispatch(.lock, 0); let queuedTask = queued.actionTask
        queued.leave(); await queuedTask?.value
        precondition(SSHClient.requests.isEmpty && !queued.busy && queued.actionTask == nil)
        await queued.read()
        precondition(SSHClient.requests.isEmpty)

        let swapped = ControlsHarness()
        let oldConnection = swapped.monitor.controlConnectionID
        swapped.dispatch(.wifi, 0); let swappedTask = swapped.actionTask
        swapped.monitor.generation = UUID()
        await swappedTask?.value
        precondition(SSHClient.requests.isEmpty)
        do {
            _ = try await swapped.monitor.marcControlRequest(.lock, expectedConnection: oldConnection)
            preconditionFailure("An old target must not reach SSH")
        } catch is CancellationError {}
        precondition(SSHClient.requests.isEmpty)

        let value = ControlsHarness(); try value.seed()
        value.dispatch(.volume, 30)
        precondition(value.actionTask == nil && SSHClient.requests.isEmpty)
        value.dispatch(.volume, 75); value.dispatch(.volume, 80)
        await value.actionTask?.value
        precondition(SSHClient.requests.count == 1 && value.volume == 75 && !value.busy)
        precondition(value.state?.wifiName == "Fixture LAN" && value.state?.bluetoothEnabled == true)
        precondition(value.actionTask == nil && value.failure == nil)

        let display = ControlsHarness()
        let beforeDisplay = SSHClient.requests.count
        display.dispatch(.brightness, 70); let displayTask = display.actionTask
        display.selectedDisplayID = 20
        await displayTask?.value
        precondition(SSHClient.requests.count == beforeDisplay)
        display.selectedDisplayID = 10
        display.dispatch(.brightness, 70); await display.actionTask?.value
        precondition(SSHClient.requests.last?["displayID"] as? Int == 10 && display.brightness == 70)

        let editing = ControlsHarness()
        let beforeEditing = SSHClient.requests.count
        editing.editingVolume = true; await editing.read()
        precondition(SSHClient.requests.count == beforeEditing)
        editing.editingVolume = false
        let editGate = Gate()
        SSHClient.hook = { request in await editGate.wait(); return SSHClient.reply(request, volume: 99) }
        let editRead = Task { await editing.read() }
        await waitFor { editGate.entered }
        editing.volume = 67; editing.editingVolume = true
        editGate.open(); await editRead.value
        precondition(editing.volume == 67 && editing.state == nil && !editing.refreshing)

        let refreshed = ControlsHarness(); let oldReadGate = Gate(); let newReadGate = Gate()
        var reads = 0
        SSHClient.hook = { request in
            reads += 1
            if reads == 1 { await oldReadGate.wait(); return SSHClient.reply(request, volume: 10) }
            await newReadGate.wait(); return SSHClient.reply(request, volume: 90)
        }
        let oldRead = Task { await refreshed.read() }
        await waitFor { oldReadGate.entered }
        refreshed.leave(); refreshed.monitor.generation = UUID(); refreshed.returnToConnection()
        let newRead = Task { await refreshed.read() }
        await waitFor { newReadGate.entered }
        oldReadGate.open(); await oldRead.value
        precondition(refreshed.refreshing && refreshed.state == nil && refreshed.failure == nil)
        newReadGate.open(); await newRead.value
        precondition(refreshed.volume == 90 && !refreshed.refreshing && refreshed.wirelessReadAt != nil)

        let replacement = ControlsHarness(); let actionGate = Gate(); var actions = 0
        SSHClient.hook = { request in
            actions += 1
            if actions == 1 { await actionGate.wait(); throw FixtureError.expected }
            return SSHClient.reply(request)
        }
        replacement.dispatch(.volume, 55); let oldAction = replacement.actionTask
        await waitFor { actionGate.entered }
        replacement.leave(); replacement.monitor.generation = UUID(); replacement.returnToConnection()
        replacement.dispatch(.volume, 45); await replacement.actionTask?.value
        actionGate.open(); await oldAction?.value
        precondition(replacement.volume == 45 && replacement.failure == nil && !replacement.busy)
        precondition(replacement.notice == "Volume set to 45%" && replacement.actionTask == nil)

        SSHClient.hook = nil
        let cancelled = ControlsHarness()
        let beforeCancel = SSHClient.requests.count
        let cancelledRead = Task { await cancelled.read() }; cancelledRead.cancel(); await cancelledRead.value
        precondition(SSHClient.requests.count == beforeCancel && !cancelled.refreshing)
        cancelled.dispatch(.playPause, 0); cancelled.dispatch(.playPause, 0)
        await cancelled.actionTask?.value
        precondition(SSHClient.requests.count == beforeCancel + 1)
        print("PASS: Control Center queued cancellation, connection/display binding, duplicate taps and stale task checks")
        print("PASS: control reads preserve editing values, current feedback and cached wireless state")
    }
}
'''

def fixture_source():
    # Replace the harness's final brace to append production methods unchanged.
    return (support + types + transport + harness[:harness.rfind('\n}')] +
            '\n' + properties + media + methods + '\n}\n' + checks)

def main():
    compiler = shutil.which('swiftc')
    if not compiler:
        raise SystemExit('Swift is required. Run Control Center checks on your Mac.')
    with tempfile.TemporaryDirectory(prefix='marc-control-checks-') as directory:
        directory = Path(directory)
        source = directory / 'ControlChecks.swift'
        source.write_text(fixture_source())
        binary = directory / 'control-checks'
        subprocess.run([compiler, '-swift-version', '5', '-parse-as-library',
                        str(source), '-o', str(binary)], check=True)
        subprocess.run([str(binary)], check=True, timeout=30)

if __name__ == '__main__':
    main()

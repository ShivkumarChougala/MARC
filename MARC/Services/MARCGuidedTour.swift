import Foundation
import Observation

enum MARCFeatureAction: String, CaseIterable, Equatable, Identifiable {
    case checkMac, inspectSystem, findProcess, moveFile, controlMac, runCommand
    var id: String { rawValue }
}
struct MARCFeatureRequest: Identifiable {
    let id = UUID()
    let action: MARCFeatureAction
    let connection: UUID
}
@MainActor @Observable final class MARCGuidedTour {
    enum Flow: Equatable { case setup }
    enum Feedback: Equatable { case selection, completion }
    private(set) var flow: Flow?
    enum Stage: Equatable { case welcome, prepare, addServer, connect }
    private(set) var stage: Stage = .welcome
    private(set) var completionID = UUID()
    private(set) var completedFlow: Flow?
    private(set) var finished = false
    private(set) var feedbackID = UUID()
    private(set) var feedback = Feedback.selection
    private(set) var featureRequest: MARCFeatureRequest?
    var keyboardVisible = false
    private var presentationBarriers: Set<UUID> = []
    var hasBlockingPresentation: Bool { !presentationBarriers.isEmpty }
    var active: Bool { flow != nil }

    func setPresentation(_ id: UUID, visible: Bool) {
        if visible { presentationBarriers.insert(id) }
        else { presentationBarriers.remove(id) }
    }
    func startSetup() {
        featureRequest = nil
        flow = .setup; stage = .welcome
        completedFlow = nil; finished = false
        feedback = .selection; feedbackID = UUID()
    }
    func next() {
        guard active else { return }
        switch stage {
        case .welcome: stage = .prepare
        case .prepare: stage = .addServer
        case .addServer: stage = .connect
        case .connect: return // Only a real connection can finish setup.
        }
        feedback = .selection; feedbackID = UUID()
    }
    func back() {
        guard active else { return }
        switch stage {
        case .welcome: return
        case .prepare: stage = .welcome
        case .addServer: stage = .prepare
        case .connect: stage = .addServer
        }
        feedback = .selection; feedbackID = UUID()
    }
    func connectionSucceeded() {
        guard active, stage == .connect else { return }
        end(finished: true)
    }
    func skip() { end(finished: false) }
    private func end(finished: Bool) {
        guard let flow else { return }
        completedFlow = flow; self.finished = finished; self.flow = nil
        completionID = UUID()
        if finished { feedback = .completion; feedbackID = UUID() }
    }
    func openFeature(_ action: MARCFeatureAction, connection: UUID) {
        guard !active else { return }
        featureRequest = MARCFeatureRequest(action: action, connection: connection)
    }
    func takeFeatureRequest(currentConnection: UUID, connected: Bool) -> MARCFeatureAction? {
        defer { featureRequest = nil }
        guard !active, connected, let request = featureRequest, request.connection == currentConnection else { return nil }
        return request.action
    }
    func discardFeatureRequest() { featureRequest = nil }

}

/// Reviewing a caption never supplies a host, credentials or connection success.
struct MARCSetupHintProgress {
    private(set) var reviewed: Set<String> = []
    mutating func review(_ target: String) { reviewed.insert(target) }
    mutating func restartLogin() { reviewed.subtract(["login", "connect"]) }

    func target(manual: Bool, selected: Bool, hasHost: Bool, hasDevices: Bool, ready: Bool) -> String? {
        if manual || selected {
            if manual && !hasHost && !reviewed.contains("address") { return "address" }
            if ready { return reviewed.contains("connect") ? nil : "connect" }
            return reviewed.contains("login") ? nil : "login"
        }
        if !reviewed.contains("method") { return "method" }
        let target = hasDevices ? "device" : "scan"
        return reviewed.contains(target) ? nil : target
    }
}

import Foundation

enum MARCOnboardingPolicy {
    static let currentVersion = 1
    static func needsIntroduction(completedVersion: Int, hasSavedServers: Bool,
                                  profileReadFailed: Bool) -> Bool {
        completedVersion < currentVersion && !hasSavedServers && !profileReadFailed
    }

    static func migratedVersion(_ stored: Int, hasSavedServers: Bool,
                                profileReadFailed: Bool) -> Int {
        // Existing installations can replay the guide from Settings. A failed
        // profile read must not be mistaken for a fresh installation.
        hasSavedServers || profileReadFailed ? max(stored, currentVersion) : stored
    }
}

/// Session-bound eligibility for the optional post-connection gallery invitation.
struct MARCExploreInvitation {
    enum Audience: String { case eligible, existing, handled }
    private(set) var connection: UUID?
    private(set) var replayingSetup = false
    private(set) var presented = false

    static func audience(stored: String, onboardingVersion: Int,
                         hasSavedServers: Bool, profileReadFailed: Bool) -> Audience {
        if let audience = Audience(rawValue: stored) { return audience }
        guard stored.isEmpty, onboardingVersion == 0, !hasSavedServers, !profileReadFailed else { return .existing }
        return .eligible
    }
    mutating func request(connection: UUID, currentConnection: UUID, connected: Bool,
                          audience: Audience, replayingSetup: Bool) -> Bool {
        guard self.connection == nil, connected, connection == currentConnection,
              audience == .eligible || replayingSetup else { return false }
        self.connection = connection
        self.replayingSetup = replayingSetup
        presented = false
        return true
    }
    func valid(currentConnection: UUID, connected: Bool, active: Bool) -> Bool {
        active && connected && connection == currentConnection
    }
    mutating func markPresented(currentConnection: UUID, connected: Bool, active: Bool) -> Bool {
        guard !presented, valid(currentConnection: currentConnection, connected: connected, active: active) else { return false }
        presented = true
        return true
    }
    mutating func cancel() { connection = nil; replayingSetup = false; presented = false }
}

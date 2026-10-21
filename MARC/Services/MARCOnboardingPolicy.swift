import Foundation

enum MARCOnboardingPolicy {
    static let currentVersion = 1
    static func canStartFeatures(approvedConnection: UUID?, currentConnection: UUID, connected: Bool) -> Bool {
        connected && approvedConnection == currentConnection
    }

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

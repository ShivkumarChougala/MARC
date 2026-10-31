import Foundation
import Observation

@MainActor @Observable final class MARCAlertStore {
    private(set) var rules: [MARCAlertRule] = []
    private(set) var failure: String?
    private(set) var readable = true
    private(set) var changeID = UUID()
    private let defaults: UserDefaults
    private let key = "marc.notifications.rules.v1"
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        guard let raw = defaults.object(forKey: key) else { return }
        guard let data = raw as? Data else {
            readable = false
            failure = "Saved alerts could not be loaded. Your saved data has been preserved."
            return
        }
        do {
            let decoded = try JSONDecoder().decode([MARCAlertRule].self, from: data)
            guard decoded.count <= 20, decoded.allSatisfy(\.isValid),
                  Set(decoded.map(\.id)).count == decoded.count else { throw CocoaError(.coderReadCorrupt) }
            rules = decoded
        } catch {
            readable = false
            failure = "Saved alerts could not be loaded. Your saved data has been preserved."
        }
    }
    @discardableResult func save(_ rule: MARCAlertRule) -> Bool {
        guard readable, rule.isValid else { return false }
        var next = rules
        if let index = next.firstIndex(where: { $0.id == rule.id }) {
            var updated = rule
            if updated != next[index] { updated.revision = UUID() }
            next[index] = updated
        } else {
            guard next.count < 20 else { failure = "You can save up to 20 custom alerts."; return false }
            next.append(rule)
        }
        return persist(next)
    }
    func setEnabled(_ id: UUID, _ enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        var next = rules
        next[index].enabled = enabled
        // Preserve the delivery latch across toggles; only edits create a new revision.
        _ = persist(next)
    }
    @discardableResult func remove(_ id: UUID) -> Bool {
        persist(rules.filter { $0.id != id })
    }
    private func persist(_ next: [MARCAlertRule]) -> Bool {
        guard readable else { return false }
        do {
            let data = try JSONEncoder().encode(next)
            defaults.set(data, forKey: key)
            rules = next
            changeID = UUID()
            failure = nil
            return true
        } catch {
            failure = "Your alert could not be saved. Try again."
            return false
        }
    }
}

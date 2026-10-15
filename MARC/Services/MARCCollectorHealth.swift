import Foundation

/// Local monotonic time governs liveness and display cadence. The remote wall
/// clock is retained in samples for charts, but cannot prevent new publication.
struct MARCCollectorHealth {
    enum Timeout: Equatable { case startup, stalled }
    let startupTimeout: TimeInterval
    let silenceTimeout: TimeInterval
    private var startedAt: TimeInterval?
    private var lastValidAt: TimeInterval?
    private var lastPublishedAt: TimeInterval?

    init(startupTimeout: TimeInterval = 90, silenceTimeout: TimeInterval = 90) {
        self.startupTimeout = startupTimeout
        self.silenceTimeout = silenceTimeout
    }

    mutating func start(at now: TimeInterval) {
        startedAt = now
        lastValidAt = nil
        lastPublishedAt = nil
    }

    mutating func reset() {
        startedAt = nil
        lastValidAt = nil
        lastPublishedAt = nil
    }

    /// Every decoded sample is a heartbeat, including those not yet displayed.
    mutating func received(at now: TimeInterval, publishInterval: TimeInterval) -> Bool {
        lastValidAt = now
        if let previous = lastPublishedAt, now - previous < publishInterval {
            return false
        }
        lastPublishedAt = now
        return true
    }

    func timeout(at now: TimeInterval) -> Timeout? {
        guard let startedAt else { return nil }
        if let lastValidAt {
            return now - lastValidAt >= silenceTimeout ? .stalled : nil
        }
        return now - startedAt >= startupTimeout ? .startup : nil
    }
}

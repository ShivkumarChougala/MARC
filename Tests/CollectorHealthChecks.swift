import Foundation

@main struct CollectorHealthChecks {
    static func main() {
        var health = MARCCollectorHealth()
        precondition(health.timeout(at: 1000) == nil)
        health.start(at: 100)
        precondition(health.timeout(at: 189.999) == nil)
        precondition(health.timeout(at: 190) == .startup)

        // Local elapsed time controls publication, regardless of remote time.
        health.start(at: 0)
        precondition(health.received(at: 1, publishInterval: 2))
        precondition(!health.received(at: 2, publishInterval: 2))
        precondition(health.received(at: 3, publishInterval: 2))
        precondition(!health.received(at: 4, publishInterval: 2))
        precondition(health.timeout(at: 93.999) == nil)
        precondition(health.timeout(at: 94) == .stalled,
                     "A decoded but undisplayed sample must refresh the heartbeat")

        for interval in [1.0, 2.0, 5.0] {
            health.start(at: 10)
            precondition(health.received(at: 10, publishInterval: interval))
            precondition(!health.received(at: 10 + interval / 2, publishInterval: interval))
            precondition(health.received(at: 10 + interval, publishInterval: interval))
        }
        health.reset()
        precondition(health.timeout(at: 10000) == nil, "A stopped collector must not time out")
        health.start(at: 1000)
        precondition(health.timeout(at: 1001) == nil)
        precondition(health.received(at: 1001, publishInterval: 5), "Reconnect must publish its first sample")
        print("PASS: collector startup, silence, cadence and reset boundary checks")
    }
}

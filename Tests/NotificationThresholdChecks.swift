import Foundation

@main struct NotificationThresholdChecks {
    static func main() {
        let policy = MARCNotificationThreshold.self
        precondition(policy.battery(percent: 20, source: "Battery Power", threshold: 20)!.low)
        precondition(!policy.battery(percent: 20.1, source: "Battery Power", threshold: 20)!.low)
        precondition(!policy.battery(percent: 19, source: "AC Power", threshold: 20)!.low)
        precondition(policy.battery(percent: 19, source: "AC Power", threshold: 20)!.recovered)
        precondition(!policy.battery(percent: 24.9, source: "Battery Power", threshold: 20)!.recovered)
        precondition(policy.battery(percent: 25, source: "Battery Power", threshold: 20)!.recovered)
        precondition(policy.battery(percent: .nan, source: "Battery Power", threshold: 20) == nil)
        precondition(policy.battery(percent: 101, source: "Battery Power", threshold: 20) == nil)
        precondition(policy.battery(percent: 10, source: "Unknown", threshold: 20) == nil)
        precondition(policy.battery(percent: 40, source: "Battery Power", threshold: 40)!.low)
        precondition(policy.storage(available: 10e9, total: 100e9, threshold: 10)!.low)
        precondition(!policy.storage(available: 10.1e9, total: 100e9, threshold: 10)!.low)
        precondition(!policy.storage(available: 10.9e9, total: 100e9, threshold: 10)!.recovered)
        precondition(policy.storage(available: 11e9, total: 100e9, threshold: 10)!.recovered)
        precondition(policy.storage(available: 0, total: 100e9, threshold: 10)!.low)
        precondition(policy.storage(available: 0, total: 0, threshold: 10) == nil)
        precondition(policy.storage(available: -1, total: 100e9, threshold: 10) == nil)
        precondition(policy.storage(available: .infinity, total: 100e9, threshold: 10) == nil)
        precondition(policy.storage(available: 101e9, total: 100e9, threshold: 10) == nil)
        precondition(policy.storage(available: 50e9, total: 100e9, threshold: 50)!.low)
        precondition(policy.shouldSend(low: true, latched: false, lastSent: 0, now: 10000))
        precondition(!policy.shouldSend(low: true, latched: true, lastSent: 0, now: 10000))
        precondition(!policy.shouldSend(low: false, latched: false, lastSent: 0, now: 10000))
        precondition(!policy.shouldSend(low: true, latched: false, lastSent: 9000, now: 10000))
        precondition(policy.shouldSend(low: true, latched: false, lastSent: 6400, now: 10000))
        print("PASS: notification thresholds, invalid data, charging, recovery and cooldown boundaries")
    }
}

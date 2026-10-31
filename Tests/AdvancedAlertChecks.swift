import Foundation

@main struct AdvancedAlertChecks {
    @MainActor static func main() throws {
        let batteryLimit = MARCNotificationThreshold.standardBatteryLimit
        let storageLimit = MARCNotificationThreshold.standardStorageFreePercent
        precondition(MARCNotificationThreshold.battery(percent: 20, source: "Battery Power", threshold: batteryLimit)!.low)
        precondition(!MARCNotificationThreshold.battery(percent: 20.1, source: "Battery Power", threshold: batteryLimit)!.low)
        precondition(!MARCNotificationThreshold.battery(percent: 10, source: "AC Power", threshold: batteryLimit)!.low)
        precondition(MARCNotificationThreshold.storage(available: 20e9, total: 200e9,
            threshold: storageLimit, percentage: true)!.low)
        precondition(!MARCNotificationThreshold.storage(available: 20.2e9, total: 200e9,
            threshold: storageLimit, percentage: true)!.low)
        precondition(MARCNotificationThreshold.storage(available: 0, total: 0,
            threshold: storageLimit, percentage: true) == nil)
        precondition(!MARCAlertRule().isValid, "New drafts must not be prefilled valid CPU rules")
        let mac = UUID(), session = UUID()
        var rule = MARCAlertRule()
        rule.name = "CPU load"; rule.duration = 0; rule.notifyOnRecovery = true
        let high = MARCAlertEngine.Sample(cpu: 95, memory: 80, battery: 10, storage: 5, onBattery: true, storageTotal: 100)
        let recovered = MARCAlertEngine.Sample(cpu: 50, memory: 30, battery: 60, storage: 30, onBattery: true, storageTotal: 100)
        let near = MARCAlertEngine.Sample(cpu: 89, memory: 30, battery: 60, storage: 30, onBattery: true, storageTotal: 100)
        var engine = MARCAlertEngine()
        func evaluate(_ sample: MARCAlertEngine.Sample, now: Double, wall: Double) -> [UUID] {
            engine.evaluate(rules: [rule], sample: sample, serverID: mac, session: session, now: now, wallTime: wall)
        }
        precondition(evaluate(high, now: 0, wall: 10000) == [rule.id])
        engine.markSent(rule, serverID: mac, wallTime: 10000)
        precondition(evaluate(high, now: 1, wall: 14000).isEmpty, "No reminders by default")
        _ = evaluate(near, now: 2, wall: 14001)
        precondition(engine.recoveries.isEmpty, "Recovery requires the margin, not just crossing the threshold")
        _ = evaluate(recovered, now: 3, wall: 14002)
        precondition(engine.recoveries == [rule.id])
        _ = evaluate(recovered, now: 4, wall: 14003)
        precondition(engine.recoveries == [rule.id], "Failed recovery delivery can retry")
        engine.markRecovered(rule, serverID: mac)
        _ = evaluate(recovered, now: 5, wall: 14004)
        precondition(engine.recoveries.isEmpty, "Successful recovery delivery is acknowledged once")
        let persisted = try JSONEncoder().encode(engine.deliveries)
        let decoded = try JSONDecoder().decode([String: MARCAlertEngine.Delivery].self, from: persisted)
        precondition(decoded == engine.deliveries)

        rule.repeatMinutes = 15
        engine = MARCAlertEngine()
        precondition(evaluate(high, now: 0, wall: 20000) == [rule.id])
        engine.markSent(rule, serverID: mac, wallTime: 20000)
        precondition(evaluate(high, now: 1, wall: 20899).isEmpty)
        precondition(evaluate(high, now: 2, wall: 20900) == [rule.id], "Repeat uses its own interval")
        engine.markSent(rule, serverID: mac, wallTime: 20900)
        precondition(evaluate(high, now: 3, wall: 20901).isEmpty)
        rule.repeatMinutes = 0
        rule.cooldownMinutes = 15
        _ = evaluate(recovered, now: 4, wall: 20902)
        precondition(evaluate(high, now: 5, wall: 21799).isEmpty)
        precondition(evaluate(high, now: 6, wall: 21800) == [rule.id])

        rule.metric = .storage; rule.storageUnit = .percent
        rule.comparison = .below; rule.threshold = 10; rule.repeatMinutes = 0
        rule.recoveryMargin = 5; engine = MARCAlertEngine()
        precondition(rule.isValid)
        precondition(evaluate(high, now: 0, wall: 30000) == [rule.id], "5 of 100 GB is 5% free")
        engine.markSent(rule, serverID: mac, wallTime: 30000)
        let thirteen = MARCAlertEngine.Sample(cpu: nil, memory: nil, battery: nil, storage: 13, onBattery: nil, storageTotal: 100)
        _ = evaluate(thirteen, now: 1, wall: 30001)
        precondition(engine.recoveries.isEmpty)
        _ = evaluate(recovered, now: 2, wall: 30002)
        precondition(engine.recoveries == [rule.id])
        let missingCapacity = MARCAlertEngine.Sample(cpu: nil, memory: nil, battery: nil, storage: 5, onBattery: nil)
        precondition(evaluate(missingCapacity, now: 3, wall: 40000).isEmpty)
        rule.storageUnit = .gb; rule.threshold = 2000; rule.recoveryMargin = nil
        precondition(rule.isValid, "GB thresholds must not stop at 500")
        rule.metric = .battery; rule.threshold = 100; rule.comparison = .below
        precondition(rule.isValid)
        let plugged = MARCAlertEngine.Sample(cpu: nil, memory: nil, battery: 10, storage: nil, onBattery: false)
        engine = MARCAlertEngine()
        _ = evaluate(high, now: 0, wall: 50000)
        engine.markSent(rule, serverID: mac, wallTime: 50000)
        _ = evaluate(plugged, now: 1, wall: 50001)
        precondition(engine.recoveries == [rule.id], "Plugging in clears the unplugged-only condition")

        let allBattery = MARCNotificationThreshold.battery(percent: 100, source: "Battery Power", threshold: 100)!
        precondition(allBattery.low && !allBattery.recovered)
        precondition(MARCNotificationThreshold.battery(percent: 100, source: "AC Power", threshold: 100)!.recovered)
        precondition(MARCNotificationThreshold.storage(available: 5e9, total: 100e9, threshold: 10, percentage: true)!.low)
        precondition(!MARCNotificationThreshold.storage(available: 12e9, total: 100e9, threshold: 10, percentage: true)!.recovered)
        precondition(MARCNotificationThreshold.storage(available: 13e9, total: 100e9, threshold: 10, percentage: true)!.recovered)
        precondition(MARCNotificationThreshold.storage(available: 0, total: 0, threshold: 10, percentage: true) == nil)
        precondition(!MARCNotificationThreshold.storage(available: 100e9, total: 100e9, threshold: 100, percentage: true)!.recovered)

        // Encode an old rule without any newly introduced fields; preserve its identity and defaults.
        var legacy = MARCAlertRule(); legacy.name = "Existing CPU alert"
        let raw = try JSONEncoder().encode(legacy)
        var object = try JSONSerialization.jsonObject(with: raw) as! [String: Any]
        for key in ["storageUnit", "repeatMinutes", "cooldownMinutes", "recoveryMargin", "notifyOnRecovery"] {
            object.removeValue(forKey: key)
        }
        let oldData = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(MARCAlertRule.self, from: oldData)
        precondition(restored.isValid && restored.id == legacy.id && restored.name == legacy.name)
        precondition(restored.repeatMinutes == nil && restored.storageUnit == nil)
        print("PASS: empty drafts, migration, free-storage units, full battery range, repeat, recovery and cooldown")
    }
}

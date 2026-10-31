import Foundation

@main struct CustomAlertChecks {
    @MainActor static func main() {
        var rule = MARCAlertRule()
        rule.name = "High CPU"
        let mac = UUID(), otherMac = UUID(), session = UUID()
        let high = MARCAlertEngine.Sample(cpu: 95, memory: 90, battery: 15, storage: 5, onBattery: true)
        let normal = MARCAlertEngine.Sample(cpu: 50, memory: 50, battery: 50, storage: 100, onBattery: true)
        func evaluate(_ engine: inout MARCAlertEngine, _ sample: MARCAlertEngine.Sample,
                      _ now: Double, _ currentSession: UUID? = nil, _ rules: [MARCAlertRule]? = nil,
                      _ server: UUID? = nil) -> [UUID] {
            engine.evaluate(rules: rules ?? [rule], sample: sample, serverID: server ?? mac,
                session: currentSession ?? session, now: now, wallTime: 10000 + now)
        }
        var engine = MARCAlertEngine()
        precondition(evaluate(&engine, high, 0).isEmpty)
        for t in stride(from: 5.0, through: 115, by: 5) { precondition(evaluate(&engine, high, t).isEmpty) }
        precondition(evaluate(&engine, high, 120) == [rule.id])
        engine.markSent(rule, serverID: mac, wallTime: 10120)
        precondition(evaluate(&engine, high, 125).isEmpty, "One alert per incident")
        precondition(evaluate(&engine, normal, 130).isEmpty)
        precondition(!engine.deliveries[MARCAlertEngine.key(rule, serverID: mac)]!.latched)
        rule.duration = 0
        precondition(evaluate(&engine, high, 135).isEmpty, "Recovery must not bypass cooldown")
        precondition(evaluate(&engine, high, 4000) == [rule.id])
        precondition(evaluate(&engine, high, 4001, nil, nil, otherMac) == [rule.id], "Macs have independent latches")

        rule.duration = 30
        engine = MARCAlertEngine()
        precondition(evaluate(&engine, high, 0).isEmpty)
        precondition(evaluate(&engine, high, 10).isEmpty)
        precondition(evaluate(&engine, high, 30).isEmpty, "Missing samples must reset duration")
        precondition(evaluate(&engine, high, 40, UUID()).isEmpty, "Reconnect must reset duration")
        engine.resetIntervals()
        precondition(evaluate(&engine, high, 50).isEmpty)
        let invalid = MARCAlertEngine.Sample(cpu: .nan, memory: nil, battery: nil, storage: nil, onBattery: nil)
        precondition(evaluate(&engine, invalid, 55).isEmpty)
        precondition(evaluate(&engine, high, 60).isEmpty)
        precondition(evaluate(&engine, high, 70).isEmpty)
        precondition(evaluate(&engine, high, 80).isEmpty)
        precondition(evaluate(&engine, high, 90) == [rule.id])
        var disabled = rule; disabled.enabled = false
        precondition(evaluate(&engine, high, 95, nil, [disabled]).isEmpty)
        precondition(evaluate(&engine, high, 100).isEmpty, "Paused rules lose elapsed duration")
        rule.serverID = otherMac
        precondition(evaluate(&engine, high, 110).isEmpty)
        rule.serverID = nil

        for metric in MARCAlertRule.Metric.allCases {
            rule.metric = metric; rule.duration = 0
            rule.comparison = metric == .battery || metric == .storage ? .below : .above
            rule.threshold = metric == .battery ? 20 : (metric == .storage ? 10 : 85)
            engine = MARCAlertEngine()
            precondition(evaluate(&engine, high, 0) == [rule.id], "All four metrics must trigger")
            engine.markSent(rule, serverID: mac, wallTime: 10000)
            precondition(evaluate(&engine, high, 5).isEmpty)
            _ = evaluate(&engine, normal, 10)
            precondition(!engine.deliveries[MARCAlertEngine.key(rule, serverID: mac)]!.latched)
        }
        rule.metric = .battery; rule.threshold = 20; rule.comparison = .below
        let plugged = MARCAlertEngine.Sample(cpu: nil, memory: nil, battery: 10, storage: nil, onBattery: false)
        precondition(evaluate(&engine, plugged, 15).isEmpty, "Battery rules require unplugged power")
        rule.metric = .cpu; rule.comparison = .above; rule.threshold = 90
        let exact = MARCAlertEngine.Sample(cpu: 90, memory: nil, battery: nil, storage: nil, onBattery: nil)
        precondition(evaluate(&engine, exact, 20).isEmpty, "Above is strict; equality must not trigger")
        rule.threshold = .infinity
        precondition(!rule.isValid)
        rule.threshold = 90; rule.name = "\n"
        precondition(!rule.isValid)
        rule.name = "High CPU"; rule.duration = 33
        precondition(!rule.isValid)
        rule.duration = 0

        let suite = "marc-alert-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MARCAlertStore(defaults: defaults)
        precondition(store.save(rule))
        let revision = store.rules[0].revision
        store.setEnabled(rule.id, false)
        precondition(store.rules[0].revision == revision)
        precondition(MARCAlertStore(defaults: defaults).rules[0].enabled == false)
        var updated = store.rules[0]; updated.threshold = 80
        precondition(store.save(updated))
        precondition(store.rules[0].revision != revision)
        precondition(store.remove(rule.id) && store.rules.isEmpty)
        let broken = Data("broken".utf8)
        defaults.set(broken, forKey: "marc.notifications.rules.v1")
        let corrupt = MARCAlertStore(defaults: defaults)
        precondition(!corrupt.readable && !corrupt.save(rule))
        precondition(defaults.data(forKey: "marc.notifications.rules.v1") == broken)
        defaults.removeObject(forKey: "marc.notifications.rules.v1")
        let capped = MARCAlertStore(defaults: defaults)
        for _ in 0..<20 { var next = rule; next.id = UUID(); precondition(capped.save(next)) }
        var extra = rule; extra.id = UUID()
        precondition(!capped.save(extra) && capped.rules.count == 20)
        print("PASS: custom alert metrics, session continuity, duration, recovery, cooldown, scope and persistence")
    }
}

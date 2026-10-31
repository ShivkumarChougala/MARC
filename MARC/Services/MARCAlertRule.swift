import Foundation

struct MARCAlertRule: Identifiable, Codable, Equatable {
    enum Metric: String, Codable, CaseIterable, Identifiable {
        case cpu, memory, battery, storage
        var id: String { rawValue }
        var title: String {
            switch self {
            case .cpu: return "CPU usage"
            case .memory: return "Memory usage"
            case .battery: return "Battery"
            case .storage: return "Free storage"
            }
        }
        var icon: String {
            switch self {
            case .cpu: return "cpu"
            case .memory: return "memorychip"
            case .battery: return "battery.25"
            case .storage: return "internaldrive"
            }
        }
        var unit: String { self == .storage ? " GB" : "%" }
        var range: ClosedRange<Double> { self == .storage ? 1...1_000_000 : 1...100 }
    }
    enum Comparison: String, Codable, CaseIterable, Identifiable {
        case above, below
        var id: String { rawValue }
        var title: String { self == .above ? "Above" : "Below" }
    }
    var id = UUID()
    var revision = UUID()
    var name = ""
    var metric: Metric = .cpu
    var comparison: Comparison = .above
    var threshold: Double = 90
    var duration: Int = 120
    var serverID: UUID? = nil
    var enabled = true
    // Optional fields preserve decoding of all existing Design 02 rules.
    enum StorageUnit: String, Codable, CaseIterable, Identifiable {
        case gb, percent
        var id: String { rawValue }
        var title: String { self == .gb ? "GB free" : "% free" }
    }
    var storageUnit: StorageUnit? = nil
    var repeatMinutes: Int? = nil
    var cooldownMinutes: Int? = nil
    var recoveryMargin: Double? = nil
    var notifyOnRecovery: Bool? = nil
    var unit: String { metric == .storage && storageUnit == .percent ? "%" : metric.unit }
    var valueRange: ClosedRange<Double> {
        metric == .storage && storageUnit != .percent ? 1...1_000_000 : 1...100
    }
    var defaultMargin: Double {
        metric == .storage && storageUnit != .percent ? max(1, threshold * 0.1) : (metric == .battery ? 5 : 3)
    }
    static let repeatOptions = [0, 15, 30, 60, 120, 360]
    static let cooldownOptions = [15, 30, 60, 120, 360]
    static let durations = [0, 30, 60, 120, 300, 600]
    static func durationLabel(_ seconds: Int) -> String {
        seconds == 0 ? "Immediately" : (seconds < 60 ? "\(seconds) seconds" : "\(seconds / 60) min")
    }
    var valueLabel: String { "\(Int(threshold))\(unit)" }
    var summary: String {
        "\(comparison.title) \(valueLabel)" + (duration > 0 ? " for \(Self.durationLabel(duration))" : "")
    }
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 40 &&
        !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) &&
        threshold.isFinite && valueRange.contains(threshold) && threshold.rounded() == threshold &&
        Self.durations.contains(duration) &&
        (repeatMinutes == nil || Self.repeatOptions.contains(repeatMinutes!)) &&
        (cooldownMinutes == nil || Self.cooldownOptions.contains(cooldownMinutes!)) &&
        (recoveryMargin == nil || (recoveryMargin!.isFinite && valueRange.contains(recoveryMargin!)))
    }
    func notificationBody() -> String {
        let condition = "\(metric.title) is \(comparison.rawValue) \(valueLabel)."
        guard duration > 0 else { return condition }
        return "\(metric.title) has stayed \(comparison.rawValue) \(valueLabel) for \(Self.durationLabel(duration))."
    }
}

/// Pure rule evaluator. Timers require consecutive valid readings from one SSH session.
/// Only delivery acknowledgement latches an alert; failed/unauthorized delivery can retry.
struct MARCAlertEngine {
    struct Sample {
        let cpu: Double?
        let memory: Double?
        let battery: Double?
        let storage: Double?
        let onBattery: Bool?
        var storageTotal: Double? = nil
        func value(for rule: MARCAlertRule) -> Double? {
            let metric = rule.metric
            let value: Double?
            switch metric {
            case .cpu: value = cpu
            case .memory: value = memory
            case .battery: value = onBattery == true ? battery : nil
            case .storage:
                if rule.storageUnit == .percent {
                    guard let storage, let storageTotal, storage.isFinite, storageTotal.isFinite,
                          storageTotal > 0, storage >= 0, storage <= storageTotal else { return nil }
                    value = storage / storageTotal * 100
                } else { value = storage }
            }
            guard let value, value.isFinite, value >= 0,
                  metric == .storage || value <= 100 else { return nil }
            return value
        }
    }
    struct Delivery: Codable, Equatable {
        var latched = false
        var lastSent: Double = 0
        var recoveryPending: Bool? = nil
    }
    private struct Interval {
        let session: UUID
        var since: Double?
        var lastSeen: Double
    }
    private var intervals: [String: Interval] = [:]
    var deliveries: [String: Delivery] = [:]
    private(set) var recoveries: [UUID] = []
    static func key(_ rule: MARCAlertRule, serverID: UUID) -> String {
        "\(serverID.uuidString).\(rule.id.uuidString).\(rule.revision.uuidString)"
    }
    mutating func resetIntervals() { intervals.removeAll(); recoveries.removeAll() }
    mutating func evaluate(rules: [MARCAlertRule], sample: Sample,
                           serverID: UUID, session: UUID, now: Double,
                           wallTime: Double, maximumGap: Double = 15,
                           defaultCooldownMinutes: Int = 60, defaultRepeatMinutes: Int = 0,
                           defaultRecovery: Bool = false) -> [UUID] {
        var candidates: [UUID] = []
        recoveries.removeAll()
        let validKeys = Set(rules.filter { $0.enabled && $0.isValid && ($0.serverID == nil || $0.serverID == serverID) }
            .map { Self.key($0, serverID: serverID) })
        intervals = intervals.filter { validKeys.contains($0.key) }
        for rule in rules where rule.enabled && rule.isValid && (rule.serverID == nil || rule.serverID == serverID) {
            let key = Self.key(rule, serverID: serverID)
            var delivery = deliveries[key] ?? Delivery()
            let recoveryEnabled = rule.notifyOnRecovery ?? defaultRecovery
            let plugged = rule.metric == .battery && sample.onBattery == false
            guard let value = sample.value(for: rule), now.isFinite, wallTime.isFinite else {
                if plugged {
                    if delivery.latched && recoveryEnabled { delivery.recoveryPending = true }
                    delivery.latched = false
                    if delivery.recoveryPending == true && recoveryEnabled { recoveries.append(rule.id) }
                    deliveries[key] = delivery
                }
                intervals.removeValue(forKey: key)
                continue
            }
            let margin = rule.recoveryMargin ?? rule.defaultMargin
            let percentage = rule.metric != .storage || rule.storageUnit == .percent
            let recoverAt = rule.comparison == .above ? max(0, rule.threshold - margin) :
                (percentage ? min(100, rule.threshold + margin) : rule.threshold + margin)
            let recovered = rule.comparison == .above ? value <= recoverAt : value >= recoverAt
            if recovered {
                if delivery.latched && recoveryEnabled { delivery.recoveryPending = true }
                delivery.latched = false
            }
            let matching = rule.comparison == .above ? value > rule.threshold : value < rule.threshold
            if matching { delivery.recoveryPending = false }
            if recovered && delivery.recoveryPending == true && recoveryEnabled { recoveries.append(rule.id) }
            deliveries[key] = delivery
            var interval = intervals[key] ?? Interval(session: session, since: nil, lastSeen: now)
            if interval.session != session || now < interval.lastSeen || now - interval.lastSeen > maximumGap {
                interval = Interval(session: session, since: nil, lastSeen: now)
            }
            interval.lastSeen = now
            if matching {
                if interval.since == nil { interval.since = now }
                let cooldown = Double(rule.cooldownMinutes ?? defaultCooldownMinutes) * 60
                let repeatEvery = Double(rule.repeatMinutes ?? defaultRepeatMinutes) * 60
                let ready = delivery.latched ? (repeatEvery > 0 && wallTime - delivery.lastSent >= repeatEvery) :
                    wallTime - delivery.lastSent >= cooldown
                if let since = interval.since, now - since >= Double(rule.duration), ready {
                    candidates.append(rule.id)
                }
            } else { interval.since = nil }
            intervals[key] = interval
        }
        return candidates
    }
    mutating func markSent(_ rule: MARCAlertRule, serverID: UUID, wallTime: Double) {
        deliveries[Self.key(rule, serverID: serverID)] = Delivery(latched: true, lastSent: wallTime)
    }
    mutating func markRecovered(_ rule: MARCAlertRule, serverID: UUID) {
        let key = Self.key(rule, serverID: serverID)
        if var state = deliveries[key] { state.recoveryPending = false; deliveries[key] = state }
    }
    mutating func retain(rules: [MARCAlertRule]) {
        let suffixes = rules.map { ".\($0.id.uuidString).\($0.revision.uuidString)" }
        deliveries = deliveries.filter { item in suffixes.contains(where: { item.key.hasSuffix($0) }) }
        intervals = intervals.filter { item in suffixes.contains(where: { item.key.hasSuffix($0) }) }
    }
}

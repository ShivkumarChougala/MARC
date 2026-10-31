import Foundation

/// Hysteresis and cooldown are independent: recovery never bypasses the cooldown.
struct MARCNotificationThreshold {
    static let standardBatteryLimit = 20
    static let standardStorageFreePercent = 10
    static func shouldSend(low: Bool, latched: Bool, lastSent: Double, now: Double, cooldown: Double = 3600) -> Bool {
        low && !latched && now - lastSent >= cooldown
    }

    static func battery(percent: Double, source: String, threshold: Int) -> (low: Bool, recovered: Bool)? {
        guard percent.isFinite, (0...100).contains(percent),
              ["Battery Power", "AC Power"].contains(source) else { return nil }
        return (source == "Battery Power" && percent <= Double(threshold),
                source == "AC Power" || (threshold < 100 && percent >= Double(min(100, threshold + 5))))
    }

    static func storage(available: Double, total: Double, threshold: Int, percentage: Bool = false) -> (low: Bool, recovered: Bool)? {
        guard total.isFinite, total > 0, available.isFinite,
              available >= 0, available <= total else { return nil }
        let free = percentage ? available / total * 100 : available / 1_000_000_000
        let low = free <= Double(threshold)
        return (low, !low && free >= (percentage ? min(100, Double(threshold) + 3) :
            Double(threshold) + max(1, Double(threshold) * 0.1)))
    }
}

import Foundation

enum MARCStatisticsData {
    static func percent(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "—" }
        return String(format: "%.0f%%", min(100, max(0, value)))
    }

    static func byteCount(_ value: Double?) -> String {
        guard let value, value.isFinite, value >= 0 else { return "—" }
        let count = value >= Double(Int64.max) ? Int64.max : Int64(value)
        return ByteCountFormatter.string(fromByteCount: count, countStyle: .binary)
    }

    static func uptime(_ value: Double?) -> String {
        guard let value, value.isFinite, value >= 0 else { return "—" }
        let rawMinutes = value / 60
        let minutes = rawMinutes >= Double(Int.max) ? Int.max : Int(rawMinutes)
        return minutes >= 1440
            ? "\(minutes / 1440)d \((minutes % 1440) / 60)h"
            : "\(minutes / 60)h \(minutes % 60)m"
    }

    static func window(_ history: [SystemHistoryPoint], end: Date,
                       duration: Double) -> [SystemHistoryPoint] {
        guard end.timeIntervalSince1970.isFinite,
              duration.isFinite, duration > 0 else { return [] }
        let start = end.addingTimeInterval(-duration)
        return history.filter {
            $0.date.timeIntervalSince1970.isFinite && $0.date >= start && $0.date <= end
        }.sorted { $0.date < $1.date }
    }

    static func value(_ point: SystemHistoryPoint, metric: String,
                      secondary: Bool = false) -> Double? {
        let raw: Double?
        switch (metric, secondary) {
        case ("CPU", false): raw = point.cpu
        case ("Memory", false): raw = point.memory
        case ("Server Load", false): raw = point.load
        case ("Network", false): raw = point.download.map { $0 / 1024 }
        case ("Network", true): raw = point.upload.map { $0 / 1024 }
        case ("Disk", false): raw = point.read.map { $0 / 1024 }
        case ("Disk", true): raw = point.write.map { $0 / 1024 }
        default: return nil
        }
        guard let raw, raw.isFinite, raw >= 0 else { return nil }
        return metric == "CPU" || metric == "Memory" ? min(100, raw) : raw
    }
}

// Prepare each visible card's values and axis scale once per input update.
struct MARCStatisticsSeries {
    struct Sample: Identifiable {
        let id: UUID
        let date: Date
        let primary: Double?
        let secondary: Double?
    }

    let samples: [Sample]
    let metric: String
    let ceiling: Double
    let primaryCount: Int
    let secondaryCount: Int

    var paired: Bool { metric == "Network" || metric == "Disk" }
    var hasSamples: Bool { primaryCount > 0 || secondaryCount > 0 }
    var rateDivisor: Double { paired && ceiling >= 1024 ? 1024 : 1 }
    var rateUnit: String { rateDivisor == 1024 ? "MB/s" : "KB/s" }

    init(history: [SystemHistoryPoint], metric: String) {
        self.metric = metric
        var prepared: [Sample] = []
        prepared.reserveCapacity(history.count)
        var highest = 0.0
        var primaryCount = 0
        var secondaryCount = 0
        for point in history {
            let primary = MARCStatisticsData.value(point, metric: metric)
            let secondary = MARCStatisticsData.value(point, metric: metric, secondary: true)
            if let primary { primaryCount += 1; highest = max(highest, primary) }
            if let secondary { secondaryCount += 1; highest = max(highest, secondary) }
            prepared.append(Sample(id: point.id, date: point.date,
                                   primary: primary, secondary: secondary))
        }
        samples = prepared
        self.primaryCount = primaryCount
        self.secondaryCount = secondaryCount
        if metric == "CPU" || metric == "Memory" {
            ceiling = 100
        } else {
            let padded = highest > Double.greatestFiniteMagnitude / 1.15 ? highest : highest * 1.15
            ceiling = max(metric == "Server Load" ? 1 : 0.1, padded)
        }
    }

    func axisLabel(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        if metric == "CPU" || metric == "Memory" { return String(format: "%.0f%%", value) }
        if metric == "Server Load" { return String(format: "%.2f", value) }
        return String(format: "%.1f", value / rateDivisor)
    }
}

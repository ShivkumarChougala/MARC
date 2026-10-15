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

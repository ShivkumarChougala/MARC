import SwiftUI
import Charts

struct LiveSystemDetailScreen: View {
    let store: ServerStore
    let openSettings: () -> Void
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    var body: some View {
        let m = store.monitor
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if let r = m.snapshot {

                    VStack(alignment: .leading, spacing: 4) {
                        Text(r.details?.model ?? "Mac")
                            .font(.system(size: 20, weight: .semibold))
                        Text(
                            (r.details?.osVersion ?? "").lowercased()
                                .hasPrefix("macos")
                            ? (r.details?.osVersion ?? "macOS")
                            : "macOS " + (r.details?.osVersion ?? "—")
                        )
                        .font(.system(size: 12))
                        .foregroundStyle(p.muted)

                        if !m.connected {
                            Text("Showing last readings")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let error = m.error {
                        Text(error).font(.system(size: 12)).foregroundStyle(p.accent)
                    }


                    SystemPanel(title: "CPU", subtitle: r.details?.architecture ?? "") {
                        HStack(alignment: .top, spacing: 10) {
                            Text(percent(r.cpu))
                                .font(.system(size: 36, weight: .medium))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(width: 88, alignment: .leading)
                            Spacer(minLength: 0)
                            DetailStat(title: "SYS",
                                value: percent(r.details?.cpuSystem),
                                color: Color(marcHex: 0xff565f), small: true)
                            DetailStat(title: "USER",
                                value: percent(r.details?.cpuUser),
                                color: Color(marcHex: 0x2dcc58), small: true)
                            DetailStat(title: "TASKS",
                                value: r.details?.tasks.map { String($0) } ?? "—",
                                small: true)
                        }

                        if let values = r.details?.coreUsage, !values.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(values.indices, id: \.self) { index in
                                    ReferenceCorePills(
                                        usage: values[index],
                                        system: nil
                                    )
                                    .accessibilityLabel(
                                        "Core \(index + 1), \(Int(values[index])) percent"
                                    )
                                }
                            }
                        }

                        Divider()
                        HStack(spacing: 8) {
                            DetailStat(title: "CORES",
                                value: r.details?.cores.map { String($0) } ?? "—",
                                small: true)
                            DetailStat(title: "IDLE",
                                value: percent(100 - r.cpu), small: true)
                            DetailStat(title: "UPTIME",
                                value: uptime(r.details?.uptime), small: true)
                            DetailStat(title: "LOAD · 1m",
                                value: r.details?.load.map {
                                    String(format: "%.2f", $0)
                                } ?? "—", small: true)
                        }
                    }

                    SystemPanel(title: "Memory", subtitle: bytes(r.memoryTotal)) {
                        HStack(spacing: 10) {
                            DetailStat(
                                title: "Available ≈",
                                value: bytes(max(0, r.memoryTotal - r.memoryUsed)),
                                small: true
                            )
                            DetailStat(
                                title: "Used",
                                value: bytes(r.memoryUsed),
                                color: Color(marcHex: 0xe5a000),
                                small: true
                            )
                            DetailStat(
                                title: "Swap",
                                value: bytes(r.details?.swap),
                                small: true
                            )
                            CompactMetricRing(
                                value: r.memoryPercent,
                                color: Color(marcHex: 0xe5a000)
                            )
                        }
                    }



                    SystemPanel(title: "Network", subtitle: r.interface ?? "Unavailable") {
                        HStack {
                            Text("↓ Download")
                                .foregroundStyle(Color(marcHex: 0x2eae7d))
                            Spacer()
                            Text(StatusFormat.speed(m.downloadRate))
                            Text(bytes(r.received))
                                .foregroundStyle(.secondary)
                                .frame(width: 82, alignment: .trailing)
                        }
                        HStack {
                            Text("↑ Upload")
                                .foregroundStyle(Color(marcHex: 0xe5a000))
                            Spacer()
                            Text(StatusFormat.speed(m.uploadRate))
                            Text(bytes(r.sent))
                                .foregroundStyle(.secondary)
                                .frame(width: 82, alignment: .trailing)
                        }
                        HStack {
                            Text(r.details?.ip ?? "—")
                            Spacer()
                            Text("Cumulative totals")
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 12))
                    .monospacedDigit()

                    SystemPanel(title: "Storage", subtitle: "Data · APFS") {
                        HStack(spacing: 10) {
                            DetailStat(title: "Used",
                                value: bytes(r.diskUsed), small: true)
                            DetailStat(title: "Available",
                                value: bytes(r.diskAvailable), small: true)
                            Text(percent(r.diskPercent))
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color(marcHex: 0xff8f24))
                                .monospacedDigit()
                        }
                        Divider()
                        VStack(spacing: 12) {
                            ReferenceIORow(
                                first: "I/O", second: "Speed",
                                third: "Total bytes", header: true)
                            ReferenceIORow(
                                first: "↓ Read",
                                second: StatusFormat.speed(m.diskReadRate),
                                third: bytes(r.diskReadBytes),
                                color: Color(marcHex: 0x2eae7d))
                            ReferenceIORow(
                                first: "↑ Write",
                                second: StatusFormat.speed(m.diskWriteRate),
                                third: bytes(r.diskWriteBytes),
                                color: Color(marcHex: 0xe5a000))
                        }
                        .frame(maxWidth: .infinity)
                    }

                    ReferenceStatistics(monitor: m)


                } else {
                    Text("Connect to a server in Settings to view system details.")
                        .font(.system(size: 14)).foregroundStyle(p.muted)
                    Button("Open Settings", action: openSettings)
                }
            }.padding(16).padding(.bottom, 110)
        }.scrollIndicators(.visible).marcCanvas()
            .navigationTitle("System").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }

    private func percent(_ value: Double?) -> String {
        value.map { String(format: "%.0f%%", $0) } ?? "—"
    }
    private func bytes(_ value: Double?) -> String {
        guard let value else { return "—" }
        return ByteCountFormatter.string(
            fromByteCount: Int64(max(0, value)), countStyle: .binary)
    }
    private func uptime(_ value: Double?) -> String {
        guard let value else { return "—" }
        let minutes = Int(value / 60)
        return minutes >= 1440
            ? "\(minutes / 1440)d \((minutes % 1440) / 60)h"
            : "\(minutes / 60)h \(minutes % 60)m"
    }

}

private struct DetailStat: View {
    let title: String
    let value: String
    var color = Color.primary
    var small = false
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(value).font(.system(size: small ? 12 : 19, weight: .semibold))
                .foregroundStyle(color).lineLimit(1)
                .minimumScaleFactor(0.7).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SystemPanel<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(subtitle).font(.system(size: 11)).foregroundStyle(p.muted)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            content
        }.padding(16)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(p.border.opacity(0.65), lineWidth: 0.5))
    }
}

private struct CompactMetricRing: View {
    let value: Double
    let color: Color

    private var fraction: Double {
        min(1, max(0, value / 100))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: 6)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(String(format: "%.0f%%", value))
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
        }
        .frame(width: 44, height: 44)
        .padding(3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Usage \(Int(value)) percent")
    }
}


private struct ReferenceCorePills: View {
    let usage: Double
    let system: Double?
    private let count = 34

    var body: some View {
        let active = Int(
            (min(100, max(0, usage)) / 100 * Double(count)).rounded()
        )
        let red = min(active, Int(
            (min(100, max(0, system ?? 0)) / 100 * Double(count)).rounded()
        ))

        GeometryReader { geometry in
            let gap = min(4.0, geometry.size.width / Double(count * 3))
            let pillWidth = max(
                0,
                (geometry.size.width - gap * Double(count - 1)) / Double(count)
            )

            HStack(spacing: gap) {
                ForEach(0..<count, id: \.self) { index in
                    Capsule()
                        .fill(index < red
                            ? Color(marcHex: 0xff565f)
                            : (index < active
                                ? Color(marcHex: 0x2dcc58)
                                : Color.secondary.opacity(0.20)))
                        .frame(width: pillWidth, height: 10)
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
        .frame(height: 10)
        .accessibilityElement(children: .ignore)
    }
}

private struct ReferenceIORow: View {
    let first: String
    let second: String
    let third: String
    var header = false
    var color: Color = .primary

    var body: some View {
        GeometryReader { geometry in
            let width = max(0, (geometry.size.width - 16) / 3)
            HStack(spacing: 8) {
                Text(first)
                    .foregroundStyle(header ? Color.secondary : color)
                    .frame(width: width, alignment: .leading)
                Text(second)
                    .frame(width: width, alignment: .center)
                Text(third)
                    .frame(width: width, alignment: .trailing)
            }
            .font(.system(
                size: header ? 10 : 12,
                weight: header ? .regular : .medium
            ))
            .foregroundStyle(header ? Color.secondary : Color.primary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(height: 20)
    }
}


private struct ReferenceStatistics: View {
    let monitor: SSHMonitor
    @State private var selection = "CPU"
    @State private var period = 300
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    private var points: [SystemHistoryPoint] {
        period == 300 ? monitor.history : monitor.archivedHistory
    }

    private func label(_ seconds: Int) -> String {
        switch seconds {
        case 900: return "15m"
        case 1800: return "30m"
        case 3600: return "1h"
        default: return "5m"
        }
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Statistics")
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                HStack(spacing: 2) {
                    ForEach([300, 900, 1800, 3600], id: \.self) { seconds in
                        Button {
                            period = seconds
                        } label: {
                            Text(label(seconds))
                                .font(.system(
                                    size: 10,
                                    weight: period == seconds ? .semibold : .medium
                                ))
                                .foregroundStyle(period == seconds ? p.accent : p.muted)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 6)
                                .background(
                                    period == seconds ? p.raised : Color.clear,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(
                            period == seconds ? .isSelected : []
                        )
                    }
                }
            }

            Picker("Graph", selection: $selection) {
                ForEach(["CPU", "Load", "Memory", "Network", "Disk"], id: \.self) {
                    Text($0).tag($0)
                }
            }
            .pickerStyle(.segmented)

            if points.count < 2 {
                Text(period == 300
                    ? "Collecting chart samples…"
                    : (monitor.archiveError ?? "Collecting saved history…"))
                    .font(.system(size: 12))
                    .foregroundStyle(p.muted)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ReferenceMetricChart(
                    history: points,
                    metric: selection == "Load" ? "Server Load" : selection,
                    duration: Double(period)
                )
            }
        }
        .padding(16)
        .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(p.border.opacity(0.65), lineWidth: 0.5)
        )
        .task(id: "\(period)-\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)") {
            guard period != 300 else { return }
            while !Task.isCancelled {
                await monitor.loadArchivedHistory(seconds: period)
                do {
                    try await Task.sleep(for: .seconds(30))
                } catch { return }
            }
        }
    }
}

private struct ReferenceMetricChart: View {
    let history: [SystemHistoryPoint]
    let metric: String
    var duration: Double = 300

    private let green = Color(marcHex: 0x2dcc58)
    private let orange = Color(marcHex: 0xff8f24)

    private var end: Date {
        history.last?.date ?? Date()
    }
    private var start: Date {
        end.addingTimeInterval(-duration)
    }

    private var samples: [SystemHistoryPoint] {
        history.filter { $0.date >= start && $0.date <= end }
    }
    private var percentage: Bool {
        metric == "CPU" || metric == "Memory"
    }
    private var paired: Bool {
        metric == "Network" || metric == "Disk"
    }
    private var ceiling: Double {
        if percentage { return 100.0 }

        var highest: Double = 0.0
        for point in samples {
            let firstValue: Double = self.primary(point) ?? 0.0
            let secondValue: Double = self.secondary(point) ?? 0.0
            highest = Swift.max(highest, firstValue)
            highest = Swift.max(highest, secondValue)
        }

        let minimum: Double = metric == "Server Load" ? 1.0 : 0.1
        return Swift.max(minimum, highest * 1.15)
    }

    private func primary(_ point: SystemHistoryPoint) -> Double? {
        switch metric {
        case "CPU": return point.cpu
        case "Server Load": return point.load
        case "Memory": return point.memory
        case "Network": return point.download.map { $0 / 1024 }
        default: return point.read.map { $0 / 1024 }
        }
    }

    private func secondary(_ point: SystemHistoryPoint) -> Double? {
        switch metric {
        case "Network": return point.upload.map { $0 / 1024 }
        case "Disk": return point.write.map { $0 / 1024 }
        default: return nil
        }
    }

    private func axisLabel(_ value: Double) -> String {
        if percentage { return String(format: "%.0f%%", value) }
        if metric == "Server Load" {
            return String(format: "%.2f", value)
        }
        return String(format: "%.1f", value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(metric)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if paired {
                    Text(metric == "Network" ? "↓ In" : "Read")
                        .foregroundStyle(green)
                    Text(metric == "Network" ? "↑ Out" : "Write")
                        .foregroundStyle(orange)
                    Text("KB/s").foregroundStyle(.secondary)
                } else if metric == "Memory" {
                    Text("Used %").foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 10))

            Chart {
                ForEach(samples) { point in
                    if let value = primary(point) {
                        if !paired {
                            AreaMark(
                                x: .value("Time", point.date),
                                yStart: .value("Base", 0),
                                yEnd: .value("Value", value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [green.opacity(0.25), green.opacity(0.01)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Value", value),
                            series: .value("Series", "Primary")
                        )
                        .foregroundStyle(green)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    if let value = secondary(point) {
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Value", value),
                            series: .value("Series", "Secondary")
                        )
                        .foregroundStyle(orange)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
            }
            .chartXScale(domain: start...end)
            .chartYScale(domain: 0...ceiling)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: [
                    start,
                    start.addingTimeInterval(duration / 3),
                    start.addingTimeInterval(duration * 2 / 3),
                    end
                ]) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(
                                .dateTime.hour().minute()
                            ))
                            .font(.system(size: 9, design: .monospaced))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) {
                    value in
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(axisLabel(number))
                                .font(.system(size: 9, design: .monospaced))
                        }
                    }
                }
            }
            .frame(height: 130)
        }
    }
}

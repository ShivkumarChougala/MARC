import SwiftUI
import Charts

struct MARCStatisticsScreen: View {
    let monitor: SSHMonitor
    @State private var period = 300
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var accentPreference = "coral"

    private var chartEnd: Date {
        monitor.snapshot.map { Date(timeIntervalSince1970: $0.sampledAt) } ?? Date()
    }

    private var points: [SystemHistoryPoint] {
        let history = period == 300 ? monitor.history :
            (monitor.archivedHistorySeconds == period ? monitor.archivedHistory : [])
        return MARCStatisticsData.window(history, end: chartEnd, duration: Double(period))
    }

    private var loadingArchive: Bool {
        period != 300 && monitor.connected &&
            (monitor.archivedHistorySeconds != period || monitor.archiveLoading)
    }

    private var emptyMessage: String {
        if !monitor.connected { return "Connect a Mac to collect chart samples." }
        if period == 300 { return "Collecting chart samples…" }
        if loadingArchive { return "Loading saved history…" }
        return monitor.archiveError ?? "No saved samples for this period."
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        let chartPoints = points
        let end = chartEnd
        ScrollView {
            LazyVStack(spacing: 10) {
                if period != 300, monitor.archivedHistorySeconds == period,
                   !chartPoints.isEmpty, let error = monitor.archiveError {
                    Text(error).font(.system(size: 12)).foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(["CPU", "Server Load", "Memory", "Network", "Disk"], id: \.self) { metric in
                    MARCStatisticsCard(monitor: monitor, metric: metric,
                        history: chartPoints, duration: Double(period), end: end,
                        emptyMessage: emptyMessage, palette: p)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.visible)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(monitor.server?.name ?? "No connected Mac")
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Spacer(minLength: 8)
                    TimelineView(.periodic(from: .now, by: 5)) { context in
                        let fresh = monitor.connected && monitor.updatedAt.map {
                            context.date.timeIntervalSince($0) < 12
                        } == true
                        HStack(spacing: 8) {
                            if loadingArchive {
                                ProgressView().controlSize(.mini).tint(p.accent)
                                    .accessibilityLabel("Loading saved history")
                            }
                            Circle()
                                .fill(fresh ? Color.green : (monitor.connected ? Color.orange : Color.gray))
                                .frame(width: 8, height: 8)
                                .accessibilityLabel(fresh ? "Live readings" : "Readings are not live")
                        }
                    }
                }
                Picker("Chart time range", selection: $period) {
                    Text("5m").tag(300)
                    Text("15m").tag(900)
                    Text("30m").tag(1800)
                    Text("1h").tag(3600)
                }.pickerStyle(.segmented)

            }
            .foregroundStyle(p.text)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(p.background)
            .overlay(alignment: .bottom) {
                Rectangle().fill(p.border.opacity(0.6)).frame(height: 0.5)
            }
        }
        .marcCanvas()
        .marcLiveReadings(enabled: monitor.connected)
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .tint(p.accent)
        // One shared request feeds all five charts, retaining the audited ownership rules.
        .task(id: "\(period)-\(monitor.statisticsConnectionID)-\(monitor.connected)-\(scenePhase)") {
            let requestedPeriod = period
            let connection = monitor.statisticsConnectionID
            guard !Task.isCancelled, requestedPeriod != 300,
                  monitor.connected, scenePhase == .active else { return }
            while !Task.isCancelled {
                await monitor.loadArchivedHistory(seconds: requestedPeriod,
                                                  expectedConnection: connection)
                guard !Task.isCancelled, monitor.connected,
                      monitor.statisticsConnectionID == connection else { return }
                do { try await Task.sleep(for: .seconds(30)) }
                catch { return }
            }
        }
    }
}

private struct MARCStatisticsCard: View {
    let monitor: SSHMonitor
    let metric: String
    let history: [SystemHistoryPoint]
    let duration: Double
    let end: Date
    let emptyMessage: String
    let palette: MARCPalette
    @Environment(\.dynamicTypeSize) private var dynamicType

    private var title: String {
        metric == "Server Load" ? "Load" : metric == "Disk" ? "Disk I/O" : metric
    }
    private var color: Color { metric == "Memory" ? .purple : palette.accent }
    var body: some View {
        let series = MARCStatisticsSeries(history: history, metric: metric)
        VStack(alignment: .leading, spacing: 8) {
            if dynamicType.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.subheadline.weight(.semibold))
                    summary
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(title).font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: true, vertical: false)
                    summary
                }
                .frame(minHeight: 30, alignment: .top)
            }
            if series.hasSamples {
                MARCStatisticsChart(series: series, duration: duration,
                                    primaryColor: color, end: end)
                    .id(duration)
            } else {
                Text(history.isEmpty ? emptyMessage : "No samples available for this metric.")
                    .font(.caption).foregroundStyle(palette.muted)
                    .frame(maxWidth: .infinity, minHeight: 90)
                    .multilineTextAlignment(.center)
            }
            footer
        }
        .foregroundStyle(palette.text)
        .padding(12)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(palette.border.opacity(0.65), lineWidth: 0.5))
        // Live samples update directly; inherited navigation animations should
        // not interpolate every chart mark or changing numeric value.
        .transaction { $0.animation = nil }
    }

    @ViewBuilder private var summary: some View {
        switch metric {
        case "CPU":
            reading(MARCStatisticsData.percent(monitor.snapshot?.cpu), number: monitor.snapshot?.cpu)
        case "Server Load":
            let load = monitor.snapshot?.details?.load
            reading(load.map { $0.isFinite && $0 >= 0 ? String(format: "%.2f", $0) : "—" } ?? "—",
                    label: "1m average", number: load)
        case "Memory":
            reading("\(MARCStatisticsData.byteCount(monitor.snapshot?.memoryUsed)) / \(MARCStatisticsData.byteCount(monitor.snapshot?.memoryTotal))",
                    label: "\(MARCStatisticsData.percent(monitor.snapshot?.memoryPercent)) used", number: monitor.snapshot?.memoryUsed)
        case "Network":
            pairedReadings(first: monitor.downloadRate, firstLabel: "Download",
                           second: monitor.uploadRate, secondLabel: "Upload")
        default:
            pairedReadings(first: monitor.diskReadRate, firstLabel: "Read",
                           second: monitor.diskWriteRate, secondLabel: "Write")
        }
    }

    private func reading(_ value: String, label: String? = nil, number: Double? = nil) -> some View {
        VStack(alignment: dynamicType.isAccessibilitySize ? .leading : .trailing, spacing: 3) {
            MARCLiveNumberText(text: value, value: number).font(.subheadline.weight(.semibold))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
            if let label {
                MARCLiveNumberText(text: label, value: number).font(.caption2).foregroundStyle(palette.muted)
            }
        }.frame(maxWidth: .infinity, alignment: dynamicType.isAccessibilitySize ? .leading : .trailing)
    }

    @ViewBuilder private func pairedReadings(first: Double?, firstLabel: String,
                                             second: Double?, secondLabel: String) -> some View {
        if dynamicType.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                directionalReading(first, symbol: "arrow.down", label: firstLabel, color: color)
                directionalReading(second, symbol: "arrow.up", label: secondLabel, color: .blue)
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                directionalReading(first, symbol: "arrow.down", label: firstLabel, color: color)
                directionalReading(second, symbol: "arrow.up", label: secondLabel, color: .blue)
            }
        }
    }

    private func directionalReading(_ value: Double?, symbol: String,
                                    label: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: symbol)
                .font(.caption.weight(.medium)).foregroundStyle(color)
            MARCLiveNumberText(text: StatusFormat.speed(value), value: value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: dynamicType.isAccessibilitySize ? .leading : .trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(StatusFormat.speed(value))")
    }

    private func detail(_ label: String, _ value: String, number: Double? = nil) -> some View {
        ViewThatFits(in: .horizontal) {
            if !dynamicType.isAccessibilitySize {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(label).foregroundStyle(palette.muted)
                    MARCLiveNumberText(text: value, value: number).foregroundStyle(palette.text).monospacedDigit()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(label).foregroundStyle(palette.muted)
                MARCLiveNumberText(text: value, value: number).foregroundStyle(palette.text).monospacedDigit()
            }
        }
        .font(.caption2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var footer: some View {
        if let r = monitor.snapshot {
            switch metric {
            case "Memory":
                HStack(alignment: .top, spacing: 16) {
                    detail("Available", MARCStatisticsData.byteCount(max(0, r.memoryTotal - r.memoryUsed)), number: max(0, r.memoryTotal - r.memoryUsed))
                    detail("Swap", MARCStatisticsData.byteCount(r.details?.swap), number: r.details?.swap)
                }
            case "Network":
                HStack(alignment: .top, spacing: 16) {
                    detail("Received", MARCStatisticsData.byteCount(r.received), number: r.received)
                    detail("Sent", MARCStatisticsData.byteCount(r.sent), number: r.sent)
                }
            case "Disk":
                VStack(spacing: 6) {
                    ProgressView(value: r.diskPercent.isFinite ? min(100, max(0, r.diskPercent)) : 0,
                                 total: 100).tint(palette.accent)
                        .modifier(MARCLiveValueMotion(value: r.diskPercent.isFinite ? r.diskPercent : 0))
                    HStack(alignment: .top, spacing: 16) {
                        detail("Used", MARCStatisticsData.byteCount(r.diskUsed), number: r.diskUsed)
                        detail("Available", MARCStatisticsData.byteCount(r.diskAvailable), number: r.diskAvailable)
                    }
                }
            default: EmptyView()
            }
        }
    }
}

private struct MARCStatisticsChart: View {
    let series: MARCStatisticsSeries
    let duration: Double
    let primaryColor: Color
    let end: Date
    @ScaledMetric(relativeTo: .body) private var chartHeight = 90.0
    private let secondaryColor = Color.blue
    private var start: Date { end.addingTimeInterval(-duration) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if series.paired {
                Text(series.rateUnit)
                    .font(.caption2).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Chart {
                ForEach(series.samples) { point in
                    if let value = point.primary {
                        if !series.paired {
                            AreaMark(
                                x: .value("Time", point.date),
                                yStart: .value("Base", 0),
                                yEnd: .value("Value", value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [primaryColor.opacity(0.25), primaryColor.opacity(0.01)],
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
                        .foregroundStyle(primaryColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        if series.primaryCount == 1 {
                            PointMark(x: .value("Time", point.date), y: .value("Value", value))
                                .foregroundStyle(primaryColor)
                        }
                    }
                    if let value = point.secondary {
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Value", value),
                            series: .value("Series", "Secondary")
                        )
                        .foregroundStyle(secondaryColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        if series.secondaryCount == 1 {
                            PointMark(x: .value("Time", point.date), y: .value("Value", value))
                                .foregroundStyle(secondaryColor)
                        }
                    }
                }
            }
            .chartXScale(domain: start...end)
            .chartYScale(domain: 0...series.ceiling)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: [
                    start,
                    start.addingTimeInterval(duration / 2),
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
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.1))
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(series.axisLabel(number))
                                .font(.system(size: 9, design: .monospaced))
                        }
                    }
                }
            }
            .frame(height: min(150, chartHeight))
            .modifier(MARCLiveValueMotion(value: series.samples.last?.date,
                                          allowsMotion: duration == 300))
        }
    }
}

import SwiftUI

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
                            MARCLiveNumberText(text: percent(r.cpu), value: r.cpu)
                                .font(.system(size: 36, weight: .medium))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(width: 88, alignment: .leading)
                            Spacer(minLength: 0)
                            DetailStat(title: "SYS",
                                value: percent(r.details?.cpuSystem),
                                color: Color(marcHex: 0xff565f), small: true, numericValue: r.details?.cpuSystem)
                            DetailStat(title: "USER",
                                value: percent(r.details?.cpuUser),
                                color: Color(marcHex: 0x2dcc58), small: true, numericValue: r.details?.cpuUser)
                            DetailStat(title: "TASKS",
                                value: r.details?.tasks.map { String($0) } ?? "—",
                                small: true, numericValue: r.details?.tasks.map(Double.init))
                        }

                        if let values = r.details?.coreUsage, !values.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(values.indices, id: \.self) { index in
                                    ReferenceCorePills(usage: values[index])
                                    .accessibilityLabel(
                                        "Core \(index + 1), \(MARCStatisticsData.percent(values[index]))"
                                    )
                                }
                            }
                        }

                        Divider()
                        HStack(spacing: 8) {
                            DetailStat(title: "CORES",
                                value: r.details?.cores.map { String($0) } ?? "—",
                                small: true, numericValue: r.details?.cores.map(Double.init))
                            DetailStat(title: "IDLE",
                                value: percent(100 - r.cpu), small: true, numericValue: 100 - r.cpu)
                            DetailStat(title: "UPTIME",
                                value: uptime(r.details?.uptime), small: true, numericValue: r.details?.uptime)
                            DetailStat(title: "LOAD · 1m",
                                value: r.details?.load.map {
                                    String(format: "%.2f", $0)
                                } ?? "—", small: true, numericValue: r.details?.load)
                        }
                    }

                    SystemPanel(title: "Memory", subtitle: bytes(r.memoryTotal)) {
                        HStack(spacing: 10) {
                            DetailStat(
                                title: "Available ≈",
                                value: bytes(max(0, r.memoryTotal - r.memoryUsed)),
                                small: true, numericValue: max(0, r.memoryTotal - r.memoryUsed)
                            )
                            DetailStat(
                                title: "Used",
                                value: bytes(r.memoryUsed),
                                color: Color(marcHex: 0xe5a000),
                                small: true, numericValue: r.memoryUsed
                            )
                            DetailStat(
                                title: "Swap",
                                value: bytes(r.details?.swap),
                                small: true, numericValue: r.details?.swap
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
                            MARCLiveNumberText(text: StatusFormat.speed(m.downloadRate), value: m.downloadRate)
                            MARCLiveNumberText(text: bytes(r.received), value: r.received)
                                .foregroundStyle(.secondary)
                                .frame(width: 82, alignment: .trailing)
                        }
                        HStack {
                            Text("↑ Upload")
                                .foregroundStyle(Color(marcHex: 0xe5a000))
                            Spacer()
                            MARCLiveNumberText(text: StatusFormat.speed(m.uploadRate), value: m.uploadRate)
                            MARCLiveNumberText(text: bytes(r.sent), value: r.sent)
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
                                value: bytes(r.diskUsed), small: true, numericValue: r.diskUsed)
                            DetailStat(title: "Available",
                                value: bytes(r.diskAvailable), small: true, numericValue: r.diskAvailable)
                            MARCLiveNumberText(text: percent(r.diskPercent), value: r.diskPercent)
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
                                color: Color(marcHex: 0x2eae7d),
                                secondNumber: m.diskReadRate, thirdNumber: r.diskReadBytes)
                            ReferenceIORow(
                                first: "↑ Write",
                                second: StatusFormat.speed(m.diskWriteRate),
                                third: bytes(r.diskWriteBytes),
                                color: Color(marcHex: 0xe5a000),
                                secondNumber: m.diskWriteRate, thirdNumber: r.diskWriteBytes)
                        }
                        .frame(maxWidth: .infinity)
                    }


                    batteryPanel(r.details)

                    NavigationLink {
                        MARCStatisticsScreen(monitor: m)
                    } label: {
                        HStack(spacing: 10) {
                            Label("Open Statistics", systemImage: "chart.bar.xaxis")
                                .font(.subheadline.weight(.medium))
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(p.muted)
                        }
                        .foregroundStyle(p.text)
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)


                } else {
                    Text("Connect to a server in Settings to view system details.")
                        .font(.system(size: 14)).foregroundStyle(p.muted)
                    Button("Open Settings", action: openSettings)
                }
            }.padding(16).padding(.bottom, 16)
        }.scrollIndicators(.visible).marcCanvas()
            .marcLiveReadings(enabled: m.connected)
            .navigationTitle("System").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }

    private func percent(_ value: Double?) -> String {
        MARCStatisticsData.percent(value)
    }
    private func bytes(_ value: Double?) -> String {
        MARCStatisticsData.byteCount(value)
    }
    private func uptime(_ value: Double?) -> String {
        MARCStatisticsData.uptime(value)
    }

    @ViewBuilder private func batteryPanel(_ details: SystemDetails?) -> some View {
        if details?.hasBattery == false {
            SystemPanel(title: "Power", subtitle: "") {
                Label("No built-in battery", systemImage: "powerplug")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        } else {
            SystemPanel(title: "Battery", subtitle: percent(details?.batteryPercent),
                        numericSubtitle: details?.batteryPercent) {
                if let value = details?.batteryPercent, value.isFinite {
                    ProgressView(value: min(100, max(0, value)), total: 100)
                        .tint(value <= 20 ? .orange : Color(marcHex: 0x2dcc58))
                        .modifier(MARCLiveValueMotion(value: value))
                        .accessibilityLabel("Battery charge")
                        .accessibilityValue(percent(value))
                }
                batteryRow("Status", value: MARCSystemDetailsData.batteryStatus(
                    state: details?.batteryState, source: details?.powerSource))
                Divider()
                batteryRow("Condition", value: details?.batteryCondition ?? "Unavailable")
                Divider()
                batteryRow("Maximum capacity", value: details?.batteryMaximumCapacity.map { percent($0) } ?? "Unavailable", numericValue: details?.batteryMaximumCapacity)
                Divider()
                batteryRow("Cycle count", value: details?.batteryCycleCount.map { String($0) } ?? "Unavailable", numericValue: details?.batteryCycleCount.map(Double.init))
            }
        }
    }

    private func batteryRow(_ title: String, value: String, numericValue: Double? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            MARCLiveNumberText(text: value, value: numericValue)
                .multilineTextAlignment(.trailing).monospacedDigit()
        }
        .font(.subheadline)
    }

}

private struct DetailStat: View {
    let title: String
    let value: String
    var color = Color.primary
    var small = false
    var numericValue: Double? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.7)
            MARCLiveNumberText(text: value, value: numericValue)
                .font(.system(size: small ? 12 : 19, weight: .semibold))
                .foregroundStyle(color).lineLimit(1)
                .minimumScaleFactor(0.7).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SystemPanel<Content: View>: View {
    let title: String
    let subtitle: String
    var numericSubtitle: Double? = nil
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Spacer()
                MARCLiveNumberText(text: subtitle, value: numericSubtitle).font(.system(size: 11)).foregroundStyle(p.muted)
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
        value.isFinite ? min(1, max(0, value / 100)) : 0
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
                .modifier(MARCLiveValueMotion(value: fraction))
            MARCLiveNumberText(text: MARCStatisticsData.percent(value), value: value)
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
        }
        .frame(width: 44, height: 44)
        .padding(3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Usage \(MARCStatisticsData.percent(value))")
    }
}


private struct ReferenceCorePills: View {
    let usage: Double
    private let count = 34

    private var activeColor: Color {
        switch MARCSystemDetailsData.coreLevel(usage) {
        case .normal: return Color(marcHex: 0x2dcc58)
        case .elevated: return Color(marcHex: 0xe5a000)
        case .high: return Color(marcHex: 0xff565f)
        case .unavailable: return .secondary
        }
    }

    var body: some View {
        let safeUsage = min(100, max(0, usage.isFinite ? usage : 0))
        let active = Int((safeUsage / 100 * Double(count)).rounded())

        GeometryReader { geometry in
            let gap = min(4.0, geometry.size.width / Double(count * 3))
            let pillWidth = max(
                0,
                (geometry.size.width - gap * Double(count - 1)) / Double(count)
            )

            HStack(spacing: gap) {
                ForEach(0..<count, id: \.self) { index in
                    Capsule()
                        .fill(index < active ? activeColor : Color.secondary.opacity(0.20))
                        .frame(width: pillWidth, height: 10)
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
            .modifier(MARCLiveValueMotion(value: safeUsage))
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
    var secondNumber: Double? = nil
    var thirdNumber: Double? = nil

    var body: some View {
        GeometryReader { geometry in
            let width = max(0, (geometry.size.width - 16) / 3)
            HStack(spacing: 8) {
                Text(first)
                    .foregroundStyle(header ? Color.secondary : color)
                    .frame(width: width, alignment: .leading)
                MARCLiveNumberText(text: second, value: secondNumber)
                    .frame(width: width, alignment: .center)
                MARCLiveNumberText(text: third, value: thirdNumber)
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

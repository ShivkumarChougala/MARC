import SwiftUI

struct HomeScreen: View {
    let store: ServerStore
    let openSettings: () -> Void
    @State private var controls = false
    @State private var customizing = false
    @State private var customizingAlerts = false
    @AppStorage("marc.alerts.storage") private var showStorageAlerts = true
    @AppStorage("marc.alerts.battery") private var showBatteryAlerts = true
    @AppStorage("marc.alerts.cpu") private var showCPUAlerts = true
    @AppStorage("marc.alerts.memory") private var showMemoryAlerts = true
    @AppStorage("marc.alerts.connection") private var showConnectionAlerts = true
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.status.order") private var sectionOrder = "system,powerStorage,alerts"
    @AppStorage("marc.status.hidden") private var hiddenSections = ""
    @AppStorage("marc.refreshInterval") private var refreshInterval = 2
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    private var visibleSections: [MARCStatusSection] {
        let hidden = Set(hiddenSections.split(separator: ",").map(String.init))
        return MARCStatusSection.ordered(sectionOrder).filter { !hidden.contains($0.rawValue) }
    }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        TimelineView(.periodic(from: .now, by: 5)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 10) {
                        Button { controls = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 19)).foregroundStyle(p.text)
                                .frame(width: 44, height: 44)
                                .background(p.raised, in: RoundedRectangle(cornerRadius: 13))
                                .overlay(RoundedRectangle(cornerRadius: 13).stroke(p.border, lineWidth: 1))
                        }.accessibilityLabel("Open Control Center")
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.monitor.snapshot?.details?.username
                                 ?? store.monitor.server?.username ?? "MARC")
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(p.text).lineLimit(1).minimumScaleFactor(0.75)
                            if let version = store.monitor.snapshot?.details?.osVersion, !version.isEmpty {
                                Text("macOS " + version).font(.system(size: 12)).foregroundStyle(p.muted)
                            }
                        }
                        Spacer(minLength: 4)
                        Button { customizing = true } label: {
                            Label("Customize", systemImage: "square.grid.2x2")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(p.accent).padding(.horizontal, 10)
                                .frame(minHeight: 44)
                                .background(p.raised, in: RoundedRectangle(cornerRadius: 13))
                                .overlay(RoundedRectangle(cornerRadius: 13).stroke(p.border, lineWidth: 1))
                        }.accessibilityLabel("Customize Status layout")
                    }
                    if let reading = store.monitor.snapshot {
                        let alerts = liveAlerts(reading: reading, now: context.date)
                        ForEach(visibleSections) { item in
                            section(item, reading: reading, alerts: alerts, palette: p)
                        }
                        if visibleSections.isEmpty {
                            Text("Choose sections in Customize.")
                                .font(.system(size: 13)).foregroundStyle(p.muted)
                        }
                        // Connection failures remain visible even when alerts are hidden.
                        if !visibleSections.contains(.alerts), showConnectionAlerts, let error = store.monitor.error {
                            Text(error).font(.system(size: 12)).foregroundStyle(.red)
                            Button("Open Settings", action: openSettings).tint(p.accent)
                        }
                    } else {
                        VStack(spacing: 14) {
                            Text(store.servers.isEmpty ? "Add your first server" : "No server is active")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Connect in Settings to see your Mac’s live data.")
                                .font(.system(size: 13)).foregroundStyle(p.muted)
                                .multilineTextAlignment(.center)
                            Button("Open Settings", action: openSettings)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 20).frame(height: 44)
                                .foregroundStyle(.white)
                                .background(p.accent, in: RoundedRectangle(cornerRadius: 12))
                            if let error = store.monitor.error {
                                Text(error).font(.system(size: 12)).foregroundStyle(.red)
                                    .textSelection(.enabled)
                            }
                        }.frame(maxWidth: .infinity).padding(.top, 60)
                    }
                }.padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 24)
            }.scrollIndicators(.hidden)
        }.marcCanvas().toolbar(.hidden, for: .navigationBar)
            .onAppear {
                sectionOrder = MARCStatusSection.ordered(sectionOrder).map(\.rawValue).joined(separator: ",")
                var hidden = Set(hiddenSections.split(separator: ",").map(String.init))
                if hidden.contains("power") && hidden.contains("storage") { hidden.insert("powerStorage") }
                hidden.remove("power")
                hidden.remove("storage")
                hiddenSections = hidden.sorted().joined(separator: ",")
            }
            .sheet(isPresented: $controls) {
                NavigationStack {
                    ControlsScreen(monitor: store.monitor).toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { controls = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $customizing) {
                MARCStatusCustomizeSheet(order: $sectionOrder, hidden: $hiddenSections)
            }
            .sheet(isPresented: $customizingAlerts) {
                MARCStatusAlertCustomizeSheet()
            }
    }
    @ViewBuilder
    private func section(_ item: MARCStatusSection, reading: MacSnapshot,
                         alerts: [MARCStatusAlert], palette: MARCPalette) -> some View {
        switch item {
        case .system:
            NavigationLink {
                LiveSystemDetailScreen(store: store, openSettings: openSettings)
            } label: {
                MARCOverviewSystemCard(reading: reading, monitor: store.monitor, palette: palette)
            }.buttonStyle(.plain)
        case .powerStorage:
            HStack(alignment: .top, spacing: 12) {
                MARCOverviewPowerCard(details: reading.details, palette: palette)
                    .frame(maxWidth: .infinity)
                MARCOverviewStorageCard(reading: reading, palette: palette)
                    .frame(maxWidth: .infinity)
            }
        case .alerts:
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Needs attention").font(.system(size: 18, weight: .semibold))
                        Spacer()
                        if !alerts.isEmpty {
                            Text(String(alerts.count)).font(.system(size: 13)).foregroundStyle(palette.muted)
                        }
                        Button { customizingAlerts = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 15)).foregroundStyle(palette.accent)
                                .frame(width: 44, height: 44)
                        }.accessibilityLabel("Customize alerts")
                    }.foregroundStyle(palette.text).padding(.horizontal, 8)
                    if alerts.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: allAlertChecksDisabled ? "bell.slash" : (hasFreshReadings ? "checkmark.circle" : "clock"))
                                .font(.system(size: 21))
                                .foregroundStyle(allAlertChecksDisabled || !hasFreshReadings
                                    ? palette.muted : Color(red: 0.18, green: 0.78, blue: 0.52))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(allAlertChecksDisabled ? "Alerts are off" : (hasFreshReadings ? "No active alerts" : "Waiting for live data"))
                                    .font(.system(size: 15, weight: .medium)).foregroundStyle(palette.text)
                                Text(allAlertChecksDisabled ? "Choose alerts to enable the checks you want."
                                     : (hasFreshReadings ? "No active alerts from your enabled checks." : "Reconnect to resume live checks."))
                                    .font(.system(size: 12)).foregroundStyle(palette.muted)
                            }
                            Spacer(minLength: 0)
                        }.padding(.vertical, 6)
                            .modifier(MARCOverviewSurface(palette: palette))
                    } else {
                    VStack(spacing: 0) {
                        ForEach(Array(alerts.prefix(3).enumerated()), id: \.element.id) { index, alert in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: alert.symbol)
                                    .font(.system(size: 19)).frame(width: 24)
                                    .foregroundStyle(Color(red: 1, green: 0.39, blue: 0.43))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(alert.title).font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(palette.text)
                                    Text(alert.detail).font(.system(size: 12)).foregroundStyle(palette.muted)
                                    if let action = alert.action {
                                        if alert.settings {
                                            Button(action, action: openSettings).tint(palette.accent)
                                                .font(.system(size: 12, weight: .medium))
                                        } else {
                                            NavigationLink(action) {
                                                LiveSystemDetailScreen(store: store, openSettings: openSettings)
                                            }.font(.system(size: 12, weight: .medium)).tint(palette.accent)
                                        }
                                    }
                                }
                                Spacer(minLength: 0)
                            }.padding(.vertical, 12)
                            if index < min(alerts.count, 3) - 1 {
                                Rectangle().fill(palette.border).frame(height: 1)
                            }
                        }
                        if alerts.count > 3 {
                            Text("\(alerts.count - 3) more alerts will appear as these clear.")
                                .font(.system(size: 11)).foregroundStyle(palette.muted)
                                .padding(.top, 8)
                        }
                    }.modifier(MARCOverviewSurface(palette: palette))
                    }
                }
        }
    }
    private var allAlertChecksDisabled: Bool {
        !showStorageAlerts && !showBatteryAlerts && !showCPUAlerts &&
        !showMemoryAlerts && !showConnectionAlerts
    }
    private var hasFreshReadings: Bool {
        guard store.monitor.connected, store.monitor.error == nil,
              let updated = store.monitor.updatedAt else { return false }
        return Date().timeIntervalSince(updated) <= Double(max(20, refreshInterval * 4))
    }
    private func sustained(_ threshold: Double, seconds: Double,
                           value: (SystemHistoryPoint) -> Double) -> Bool {
        let points = store.monitor.history
        guard let latest = points.last else { return false }
        let cutoff = latest.date.addingTimeInterval(-seconds)
        guard let baseline = points.last(where: { $0.date <= cutoff }) else { return false }
        let window = points.filter { $0.date >= baseline.date }
        guard window.count >= 2, window.allSatisfy({ value($0) >= threshold }) else { return false }
        let gapLimit = Double(max(8, refreshInterval * 3))
        return zip(window, window.dropFirst()).allSatisfy { pair in
            pair.1.date.timeIntervalSince(pair.0.date) <= gapLimit
        }
    }
    private func liveAlerts(reading: MacSnapshot, now: Date) -> [MARCStatusAlert] {
        rawLiveAlerts(reading: reading, now: now).filter { alert in
            switch alert.id {
            case "storage": return showStorageAlerts
            case "battery": return showBatteryAlerts
            case "cpu": return showCPUAlerts
            case "memory": return showMemoryAlerts
            case "connection", "stale": return showConnectionAlerts
            default: return false
            }
        }
    }
    private func rawLiveAlerts(reading: MacSnapshot, now: Date) -> [MARCStatusAlert] {
        if let error = store.monitor.error {
            return [MARCStatusAlert(id: "connection", symbol: "wifi.exclamationmark",
                title: "Monitoring interrupted", detail: error, action: "Open Settings", settings: true)]
        }
        if !store.monitor.connected || store.monitor.updatedAt.map({
            now.timeIntervalSince($0) > Double(max(20, refreshInterval * 4))
        }) == true {
            return [MARCStatusAlert(id: "stale", symbol: "clock.badge.exclamationmark",
                title: "Readings are no longer live", detail: "Reconnect to refresh this Mac’s data.",
                action: "Open Settings", settings: true)]
        }
        var alerts: [MARCStatusAlert] = []
        if reading.diskTotal > 0 {
            let fraction = max(0, min(1, 1 - reading.diskAvailable / reading.diskTotal))
            if fraction >= 0.90 {
                alerts.append(MARCStatusAlert(id: "storage", symbol: "internaldrive",
                    title: fraction >= 0.95 ? "Storage almost full" : "Storage running low",
                    detail: "\(MARCOverviewFormat.bytes(reading.diskAvailable)) available · \(Int((fraction * 100).rounded()))% used",
                    action: "View system", settings: false))
            }
        }
        if let details = reading.details, details.powerSource == "Battery Power",
           let percent = details.batteryPercent, percent < 20 {
            alerts.append(MARCStatusAlert(id: "battery", symbol: "battery.25",
                title: percent < 10 ? "Battery critically low" : "Battery running low",
                detail: "\(Int(percent.rounded()))% remaining · On battery", action: nil, settings: false))
        }
        if sustained(80, seconds: 30, value: { $0.cpu }) {
            alerts.append(MARCStatusAlert(id: "cpu", symbol: "cpu", title: "CPU staying high",
                detail: "Above 80% for 30 seconds.", action: "View system", settings: false))
        }
        if sustained(85, seconds: 60, value: { $0.memory }) {
            alerts.append(MARCStatusAlert(id: "memory", symbol: "memorychip", title: "Memory usage staying high",
                detail: "Above 85% for 60 seconds.", action: "View system", settings: false))
        }
        return alerts
    }
}

private enum MARCStatusSection: String, CaseIterable, Identifiable {
    case system, powerStorage, alerts
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .powerStorage: return "Power & Storage"
        case .alerts: return "Needs attention"
        }
    }
    static func ordered(_ stored: String) -> [Self] {
        var result: [Self] = []
        for raw in stored.split(separator: ",") {
            let migrated = raw == "power" || raw == "storage" ? "powerStorage" : String(raw)
            if let item = Self(rawValue: migrated), !result.contains(item) { result.append(item) }
        }
        for item in allCases where !result.contains(item) { result.append(item) }
        return result
    }
}
private struct MARCStatusAlert: Identifiable {
    let id: String
    let symbol: String
    let title: String
    let detail: String
    let action: String?
    let settings: Bool
}

private struct MARCStatusCustomizeSheet: View {
    @State private var customizingAlerts = false
    @Binding var order: String
    @Binding var hidden: String
    @AppStorage("marc.showPowerStatus") private var showPowerStatus = true
    @AppStorage("marc.powerRefreshSeconds") private var powerRefreshSeconds = 10
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private func shown(_ item: MARCStatusSection) -> Binding<Bool> {
        Binding(get: {
            !hidden.split(separator: ",").map(String.init).contains(item.rawValue)
        }, set: { enabled in
            var values = Set(hidden.split(separator: ",").map(String.init))
            if enabled { values.remove(item.rawValue) } else { values.insert(item.rawValue) }
            hidden = values.sorted().joined(separator: ",")
        })
    }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        NavigationStack {
            List {
                Section {
                    ForEach(MARCStatusSection.ordered(order)) { item in
                        Toggle(item.title, isOn: shown(item)).tint(p.accent)
                    }.onMove { indices, destination in
                        var items = MARCStatusSection.ordered(order)
                        items.move(fromOffsets: indices, toOffset: destination)
                        order = items.map(\.rawValue).joined(separator: ",")
                    }
                } header: {
                    Text("Status sections")
                } footer: {
                    Text("Drag the handles to reorder. Power & Storage always stay together. Needs attention shows active alerts or a brief status summary.")
                }
                Section {
                    Toggle("Show power status", isOn: $showPowerStatus).tint(p.accent)
                    Picker("Power refresh", selection: $powerRefreshSeconds) {
                        Text("5 seconds").tag(5)
                        Text("10 seconds").tag(10)
                        Text("30 seconds").tag(30)
                        Text("60 seconds").tag(60)
                    }.pickerStyle(.menu)
                } header: { Text("Power") }
                  footer: { Text("Refresh changes apply after reconnecting.") }
                Section {
                    Button { customizingAlerts = true } label: {
                        HStack {
                            Text("Choose alerts")
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 12))
                        }
                    }.foregroundStyle(p.accent)
                }
                Section {
                    Button("Reset layout") {
                        order = "system,powerStorage,alerts"
                        hidden = ""
                    }.foregroundStyle(p.accent)
                }
            }.environment(\.editMode, .constant(.active))
                .navigationTitle("Customize").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
                }
                .tint(p.accent)
        }.sheet(isPresented: $customizingAlerts) {
            MARCStatusAlertCustomizeSheet()
        }
    }
}

private struct MARCStatusAlertCustomizeSheet: View {
    @AppStorage("marc.alerts.storage") private var storage = true
    @AppStorage("marc.alerts.battery") private var battery = true
    @AppStorage("marc.alerts.cpu") private var cpu = true
    @AppStorage("marc.alerts.memory") private var memory = true
    @AppStorage("marc.alerts.connection") private var connection = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        NavigationStack {
            Form {
                Section {
                    Toggle("Storage", isOn: $storage)
                    Toggle("Battery", isOn: $battery)
                    Toggle("CPU", isOn: $cpu)
                    Toggle("Memory", isOn: $memory)
                    Toggle("Connection", isOn: $connection)
                } header: { Text("Show alerts for") }
                  footer: {
                    Text("Storage: 90% used. Battery: below 20% on battery. CPU: 80% for 30 seconds. Memory: 85% for 60 seconds. Connection: interrupted or stale readings.")
                }
                Section {
                    Button("Enable all alerts") {
                        storage = true
                        battery = true
                        cpu = true
                        memory = true
                        connection = true
                    }
                }
            }.tint(p.accent)
                .navigationTitle("Alerts").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
                }
        }
    }
}

private enum MARCOverviewFormat {
    private static func number(_ value: Double) -> String {
        String(format: value < 10 ? "%.1f" : "%.0f", value)
    }

    static func bytes(_ bytes: Double) -> String {
        guard bytes.isFinite, bytes >= 0 else { return "—" }
        if bytes < 1_000 {
            return String(format: "%.0f B", bytes)
        }
        if bytes < 1_000_000 {
            return number(bytes / 1_000) + " KB"
        }
        if bytes < 1_000_000_000 {
            return number(bytes / 1_000_000) + " MB"
        }
        return number(bytes / 1_000_000_000) + " GB"
    }

    static func rate(_ value: Double?) -> String {
        guard let value, value.isFinite, value >= 0 else { return "—" }
        if value < 1 { return "0 KB/s" }
        return bytes(value) + "/s"
    }
}

private struct MARCOverviewSurface: ViewModifier {
    let palette: MARCPalette
    func body(content: Content) -> some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(palette.border, lineWidth: 1))
    }
}

private struct MARCOverviewSystemCard: View {
    let reading: MacSnapshot
    let monitor: SSHMonitor
    let palette: MARCPalette
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("System").font(.system(size: 20, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 17, weight: .medium))
                    .foregroundStyle(palette.muted)
            }.foregroundStyle(palette.text)
            HStack(alignment: .top, spacing: 8) {
                cpu
                memory
                network
                disk
            }
        }.modifier(MARCOverviewSurface(palette: palette))
    }
    private var cpu: some View {
        MARCOverviewGauge(
            title: "CPU",
            percent: reading.cpu,
            tint: reading.cpu >= 80
                ? Color(red: 1, green: 0.39, blue: 0.43)
                : Color(red: 0.18, green: 0.78, blue: 0.52),
            palette: palette
        )
    }

    private var memory: some View {
        MARCOverviewGauge(
            title: "Memory",
            percent: reading.memoryPercent,
            tint: reading.memoryPercent >= 85
                ? Color(red: 1, green: 0.39, blue: 0.43)
                : Color(red: 0.18, green: 0.78, blue: 0.52),
            palette: palette
        )
    }

    private var network: some View {
        metrics(title: "Network", firstLabel: "↓ Download", first: monitor.downloadRate,
                secondLabel: "↑ Upload", second: monitor.uploadRate)
    }
    private var disk: some View {
        metrics(title: "Disk", firstLabel: "Read", first: monitor.diskReadRate,
                secondLabel: "Write", second: monitor.diskWriteRate)
    }
    private func metrics(title: String, firstLabel: String, first: Double?,
                         secondLabel: String, second: Double?) -> some View {
        VStack(spacing: 12) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(palette.muted)
            VStack(spacing: 7) {
                Text(firstLabel).font(.system(size: 11)).foregroundStyle(palette.muted)
                Text(MARCOverviewFormat.rate(first)).font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.text).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
            }
            VStack(spacing: 7) {
                Text(secondLabel).font(.system(size: 11)).foregroundStyle(palette.muted)
                Text(MARCOverviewFormat.rate(second)).font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.text).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
            }
        }.frame(maxWidth: .infinity)
    }
}

private struct MARCOverviewGauge: View {
    let title: String
    let percent: Double
    let tint: Color
    let palette: MARCPalette
    private var value: Double { percent.isFinite ? min(100, max(0, percent)) : 0 }
    var body: some View {
        VStack(spacing: 12) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(palette.muted)
            ZStack {
                Circle().stroke(palette.border, lineWidth: 4)
                Circle().trim(from: 0, to: value / 100)
                    .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(value.rounded()))%")
                    .font(.system(size: 21, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(tint).minimumScaleFactor(0.75).lineLimit(1)
            }.frame(width: 64, height: 64)
        }.frame(maxWidth: .infinity)
    }
}

private struct MARCOverviewPowerCard: View {
    @AppStorage("marc.showPowerStatus") private var showPowerStatus = true
    let details: SystemDetails?
    let palette: MARCPalette
    private var pluggedIn: Bool { details?.powerSource == "AC Power" }
    private var charging: Bool {
        details?.batteryState == "charging" ||
        details?.batteryState == "finishing charge"
    }
    private var status: String {
        guard let details else { return "Power data unavailable" }
        if details.hasBattery == false { return pluggedIn ? "External power" : "No battery detected" }
        switch details.batteryState {
        case "charging": return "Charging"
        case "charged": return "Fully charged"
        case "finishing charge": return "Charging"
        case "discharging": return "On battery"
        case .some: return pluggedIn ? "Not charging" : "On battery"
        case .none: return "Power data unavailable"
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Power", systemImage: "battery.100")
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(palette.text)
            Text(details?.batteryPercent.map { "\(Int(min(100, max(0, $0)).rounded()))%" }
                 ?? (details?.hasBattery == false && pluggedIn ? "AC" : "—"))
                .font(.system(size: 28, weight: .semibold)).monospacedDigit()
                .foregroundStyle(palette.text)
            if showPowerStatus {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    if charging { Image(systemName: "bolt.fill").foregroundStyle(palette.accent) }
                    Text(status).foregroundStyle(palette.muted)
                }.font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
            }
        }.frame(height: 132, alignment: .topLeading)
            .modifier(MARCOverviewSurface(palette: palette))
    }
}

private struct MARCOverviewStorageCard: View {
    let reading: MacSnapshot
    let palette: MARCPalette
    private var usedFraction: Double {
        guard reading.diskTotal > 0 else { return 0 }
        return min(1, max(0, 1 - reading.diskAvailable / reading.diskTotal))
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Storage", systemImage: "internaldrive")
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(palette.text)
            Text(reading.diskTotal > 0 ? MARCOverviewFormat.bytes(reading.diskAvailable) : "—")
                .font(.system(size: 28, weight: .semibold)).monospacedDigit()
                .foregroundStyle(palette.text).lineLimit(1).minimumScaleFactor(0.7)
            Text(reading.diskTotal > 0 ? "free of " + MARCOverviewFormat.bytes(reading.diskTotal) : "Storage data unavailable")
                .font(.system(size: 12)).foregroundStyle(palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.border)
                    Capsule().fill(
                        usedFraction >= 0.90
                            ? Color(red: 1, green: 0.39, blue: 0.43)
                            : Color(red: 0.18, green: 0.78, blue: 0.52)
                    )
                        .frame(width: geometry.size.width * usedFraction)
                }
            }.frame(height: 5).accessibilityHidden(true)
            if reading.diskTotal > 0 {
                Text("\(Int((usedFraction * 100).rounded()))% used")
                    .font(.system(size: 10)).foregroundStyle(palette.muted)
            }
        }.frame(height: 132, alignment: .topLeading)
            .modifier(MARCOverviewSurface(palette: palette))
    }
}

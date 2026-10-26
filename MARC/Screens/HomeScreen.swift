import SwiftUI

struct HomeScreen: View {
    let store: ServerStore
    let openSettings: () -> Void
    let openProcesses: (String) -> Void
    @State private var controls = false
    @State private var showingMacPicker = false
    @State private var pickerMac: ServerProfile?
    @State private var pickerManage = false
    @State private var loginMac: ServerProfile?
    @State private var switchingMac = false
    @State private var switchFailure: String?
    @State private var switchTask: Task<Void, Never>?
    @State private var statusVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.status.order") private var sectionOrder = "system,developer,processes"
    @AppStorage("marc.status.developerFirst") private var developerFirstApplied = false
    @AppStorage("marc.status.hidden") private var hiddenSections = ""
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue

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
                        Button {
                            pickerMac = nil
                            pickerManage = false
                            showingMacPicker = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(activeMac?.name ?? "Choose a Mac")
                                        .font(.system(size: 16, weight: .medium))
                                        .lineLimit(1).minimumScaleFactor(0.75)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                }.foregroundStyle(p.text)
                                if let activeMac {
                                    HStack(spacing: 5) {
                                        Image(systemName: "person.crop.circle").accessibilityHidden(true)
                                        Text(activeMac.username).lineLimit(1)
                                        if let uptime = statusUptime {
                                            Text("·").accessibilityHidden(true)
                                            Text("Uptime \(uptime)")
                                                .lineLimit(1).fixedSize(horizontal: true, vertical: false)
                                        }
                                    }.font(.system(size: 11)).foregroundStyle(p.muted)
                                }
                            }.frame(minHeight: 44, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .disabled(switchingMac || store.monitor.connecting)
                        .accessibilityLabel("Choose a saved Mac. Current: \(activeMac?.name ?? "none")")
                        .accessibilityValue(statusUptime.map { "Uptime " + $0 } ?? "")

                        Spacer(minLength: 4)

                    }
                    if let reading = store.monitor.snapshot {
                        if let received = store.monitor.updatedAt {
                            let age = max(0, Int(context.date.timeIntervalSince(received)))
                            if !store.monitor.connected || age >= 12 {
                                Label(
                                    "\(store.monitor.connected ? "Updates delayed" : "Disconnected") · last received \(age)s ago",
                                    systemImage: "clock.arrow.circlepath"
                                )
                                .font(.system(size: 12)).foregroundStyle(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityLabel("Readings are not live. Last update received \(age) seconds ago.")
                            }
                        }
                        ForEach(visibleSections) { item in
                            section(item, reading: reading, palette: p)
                        }
                        if visibleSections.isEmpty {
                            Text("Choose Status sections in Settings → General.")
                                .font(.system(size: 13)).foregroundStyle(p.muted)
                        }
                        // Connection failures remain visible independently of section customization.
                        if let error = store.monitor.error {
                            Text(error).font(.system(size: 12)).foregroundStyle(.red)
                            Button("Open Settings", action: openSettings).tint(p.accent)
                        }
                    } else {
                        let busy = switchingMac || store.monitor.connecting
                        let failure = busy ? nil : (switchFailure ?? store.monitor.error)
                        let issue = busy ? nil : store.monitor.connectionIssue
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                if busy {
                                    ProgressView().tint(p.accent)
                                } else {
                                    Image(systemName: failure == nil ? "laptopcomputer" : (issue?.symbol ?? "exclamationmark.circle"))
                                        .font(.system(size: 22)).foregroundStyle(p.accent)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(busy ? "Connecting…" : failure != nil ? (issue?.title ?? "Connection unavailable") : store.servers.isEmpty ? "Add your first Mac" : "Connect to your Mac")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(p.text)
                                    if let mac = activeMac {
                                        Text(mac.name).font(.system(size: 13))
                                            .foregroundStyle(p.muted)
                                    }
                                }
                            }
                            if let failure {
                                Text(issue?.detail ?? failure).font(.system(size: 13))
                                    .foregroundStyle(p.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            } else {
                                Text(busy ? "Establishing a secure SSH connection." : "Choose a Mac to see its live data.")
                                    .font(.system(size: 13)).foregroundStyle(p.muted)
                            }
                            if !busy {
                                HStack(spacing: 12) {
                                    if let mac = activeMac, issue?.canRetry != false {
                                        Button(failure == nil ? "Connect" : "Retry") {
                                            chooseMac(mac)
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(maxWidth: .infinity, minHeight: 46)
                                        .foregroundStyle(.white)
                                        .background(p.accent, in: RoundedRectangle(cornerRadius: 12))
                                    }
                                    Button(store.servers.isEmpty ? "Add Mac" : "Choose Mac") {
                                        if store.servers.isEmpty {
                                            openSettings()
                                        } else {
                                            pickerMac = nil
                                            pickerManage = false
                                            showingMacPicker = true
                                        }
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(maxWidth: .infinity, minHeight: 46)
                                    .foregroundStyle(p.text)
                                    .background(p.raised, in: RoundedRectangle(cornerRadius: 12))
                                }.buttonStyle(.plain)
                                Button(issue?.actionTitle ?? "Connection settings", action: openSettings)
                                    .font(.system(size: 13)).tint(p.muted)
                                    .frame(minHeight: 44)
                            }
                        }
                        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 20))
                        .padding(.top, 24)
                    }
                }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 20)
            }.scrollClipDisabled().scrollIndicators(.hidden)
                .environment(\.marcLiveMotionEnabled,
                    statusVisible && store.monitor.connected && store.monitor.updatedAt.map {
                        max(0, context.date.timeIntervalSince($0)) < 12
                    } == true)
        }.marcCanvas().marcNavigationTitle("Status")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { controls = true } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 19)).foregroundStyle(p.text)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Open Control Center")
                }
                .marcToolbarBackgroundHidden()
            }
            .onAppear {
                statusVisible = true
                let order = developerFirstApplied ? MARCStatusSection.ordered(sectionOrder) : MARCStatusSection.developerFirst(sectionOrder)
                sectionOrder = order.map(\.rawValue).joined(separator: ",")
                developerFirstApplied = true
                var hidden = Set(hiddenSections.split(separator: ",").map(String.init))
                if hidden.contains("power") && hidden.contains("storage") { hidden.insert("powerStorage") }
                hidden.remove("power")
                hidden.remove("storage")
                hidden.remove("statistics")
                hidden.remove("alerts")
                hiddenSections = hidden.sorted().joined(separator: ",")
            }
            .sheet(isPresented: $showingMacPicker, onDismiss: {
                let selected = pickerMac
                let manage = pickerManage
                pickerMac = nil; pickerManage = false
                if manage { openSettings() }
                else if let selected { chooseMac(selected) }
            }) {
                MARCMacPickerSheet(
                    servers: store.servers,
                    currentID: store.monitor.connected ? store.monitor.server?.id : nil,
                    choose: { server in pickerMac = server; showingMacPicker = false },
                    manage: { pickerManage = true; showingMacPicker = false }
                )
            }
            .sheet(item: $loginMac) { server in
                SSHConnectScreen(server: server, monitor: store.monitor)
            }
            .onChange(of: store.monitor.connected) { _, connected in
                if connected { switchFailure = nil }
            }
            .onChange(of: store.monitor.connecting) { _, connecting in
                if connecting { switchFailure = nil }
            }
            .onDisappear {
                statusVisible = false
                switchTask?.cancel(); switchTask = nil
            }
            .marcLearnOverlay([.statusSystem, .status], enabled: statusVisible && store.monitor.connected &&
                store.monitor.snapshot != nil && !controls && !showingMacPicker &&
                loginMac == nil && pickerMac == nil && !switchingMac)
            .sheet(isPresented: $controls) {
                NavigationStack {
                    ControlsScreen(monitor: store.monitor).toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { controls = false }
                        }
                        .marcToolbarBackgroundHidden()
                    }
                }
            }
    }
    private var activeMac: ServerProfile? {
        store.monitor.server ?? store.selected
    }

    private var statusUptime: String? {
        guard store.monitor.connected,
              store.monitor.server?.id == activeMac?.id,
              let seconds = store.monitor.snapshot?.details?.uptime,
              seconds.isFinite, seconds >= 0 else { return nil }
        return MARCStatisticsData.uptime(seconds)
    }

    private func chooseMac(_ server: ServerProfile) {
        guard !switchingMac, !store.monitor.connecting else { return }
        if store.monitor.connected && store.monitor.server?.id == server.id { return }
        connectMac(server)
    }

    private func connectMac(_ server: ServerProfile) {
        guard !switchingMac, !store.monitor.connecting else { return }
        switchFailure = nil
        guard store.servers.contains(where: { $0.id == server.id }) else { return }
        guard let saved = MARCCredentials.read(server.id), saved.hasLogin else {
            loginMac = server
            return
        }
        switchingMac = true
        switchTask = Task { @MainActor in
            defer { switchingMac = false; switchTask = nil }
            do {
                try Task.checkCancellation()
                try await store.switchToSavedServer(server)
            } catch is CancellationError {
                switchFailure = nil
            } catch {
                switchFailure = store.monitor.error ?? MARCConnectionIssue.message(error, login: MARCCredentials.read(server.id))
            }
        }
    }

    @ViewBuilder
    private func section(_ item: MARCStatusSection, reading: MacSnapshot,
                         palette: MARCPalette) -> some View {
        switch item {
        case .system:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("System").font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.text)
                    Spacer(minLength: 4)
                    NavigationLink {
                        LiveSystemDetailScreen(store: store, openSettings: openSettings)
                    } label: {
                        HStack(spacing: 5) {
                            Text("Details")
                            Image(systemName: "chevron.right")
                        }.font(.system(size: 13, weight: .medium))
                            .foregroundStyle(palette.accent)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("System details")
                }
                VStack(alignment: .leading, spacing: 8) {
                    if !hiddenSections.split(separator: ",").contains("powerStorage") {
                        HStack(spacing: 12) {
                            MARCOverviewPowerReading(details: reading.details, palette: palette, fontSize: 11)
                            MARCOverviewStorageReading(reading: reading, palette: palette, fontSize: 11)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    MARCOverviewSystemCard(reading: reading, monitor: store.monitor, palette: palette)
                }.padding(14)
                    .background(palette.text.opacity(scheme == .dark ? 0.025 : 0.018), in: RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(palette.text.opacity(scheme == .dark ? 0.09 : 0.07), lineWidth: 0.5)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
            }.marcLearnTarget(.statusSystem)
        case .processes:
            MARCOverviewProcesses(
                monitor: store.monitor, palette: palette,
                enabled: statusVisible && scenePhase == .active && !controls &&
                    !showingMacPicker && !switchingMac && loginMac == nil,
                openProcesses: { openProcesses("CPU") }
            ).marcLearnTarget(.status)
        case .developer:
            MARCDeveloperToolsView(monitor: store.monitor,
                enabled: statusVisible && scenePhase == .active && !controls &&
                    !showingMacPicker && !switchingMac && loginMac == nil)

        }
    }
}

private enum MARCStatusSection: String, CaseIterable, Identifiable {
    case system, developer, processes
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .processes: return "Top processes"
        case .developer: return "Developer Tools"
        }
    }
    static func developerFirst(_ stored: String) -> [Self] {
        var result = ordered(stored).filter { $0 != .developer }
        result.insert(.developer, at: result.firstIndex(of: .processes) ?? result.endIndex)
        return result
    }
    static func ordered(_ stored: String) -> [Self] {
        var result: [Self] = []
        for raw in stored.split(separator: ",") {
            // Retired standalone sections do not occupy space in the new layout.
            if let item = Self(rawValue: String(raw)), !result.contains(item) { result.append(item) }
        }
        for item in allCases where !result.contains(item) {
            result.append(item)
        }
        return result
    }
}
struct MARCStatusCustomizeSheet: View {
    @Binding var order: String
    @Binding var hidden: String
    @AppStorage("marc.showPowerStatus") private var showPowerStatus = true
    @AppStorage("marc.powerRefreshSeconds") private var powerRefreshSeconds = 10
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private func shown(_ key: String) -> Binding<Bool> {
        Binding(get: {
            !hidden.split(separator: ",").map(String.init).contains(key)
        }, set: { enabled in
            var values = Set(hidden.split(separator: ",").map(String.init))
            if enabled { values.remove(key) } else { values.insert(key) }
            hidden = values.sorted().joined(separator: ",")
        })
    }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        NavigationStack {
            List {
                Section {
                    ForEach(MARCStatusSection.ordered(order)) { item in
                        Toggle(item.title, isOn: shown(item.rawValue)).tint(p.accent)
                    }.onMove { indices, destination in
                        var items = MARCStatusSection.ordered(order)
                        items.move(fromOffsets: indices, toOffset: destination)
                        order = items.map(\.rawValue).joined(separator: ",")
                    }
                } header: {
                    Text("Status sections")
                } footer: {
                    Text("Drag the handles to reorder Status sections.")
                }
                Section {
                    Toggle("Battery & SSD in System", isOn: shown("powerStorage")).tint(p.accent)
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
                    Button("Reset layout") {
                        order = "system,developer,processes"
                        hidden = ""
                    }.foregroundStyle(p.accent)
                }
            }.environment(\.editMode, .constant(.active))
                .navigationTitle("Customize Status").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
                    .marcToolbarBackgroundHidden()
                }
                .tint(p.accent)
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

private struct MARCOverviewGaugeReading {
    enum Kind: Equatable { case percentage, load, swap }
    let raw: Double?
    let kind: Kind
    private var valid: Double? {
        guard let raw, raw.isFinite, raw >= 0 else { return nil }
        return raw
    }
    var value: Double? {
        guard let raw = valid else { return nil }
        switch kind {
        case .percentage: return min(100, raw)
        case .load: return raw
        case .swap: return raw / (raw > 0 && raw < 1_073_741_824 ? 1_048_576 : 1_073_741_824)
        }
    }
    var text: String {
        guard let value else { return "—" }
        if kind == .percentage { return String(format: "%.0f%%", value) }
        return String(format: value >= 1000 ? "%.2g" : "%.1f", value)
    }
    var unit: String? {
        guard kind == .swap else { return nil }
        return valid.map { $0 > 0 && $0 < 1_073_741_824 ? "MB" : "GB" }
    }
    var progress: Double? { kind == .percentage ? value.map { $0 / 100 } : nil }
    var caption: String {
        switch kind {
        case .percentage: return ""
        case .load: return "1-min avg"
        case .swap: return "Used"
        }
    }
    var spoken: String { text + (unit.map { " " + $0 } ?? "") }
}

private struct MARCOverviewSystemCard: View {
    let reading: MacSnapshot
    let monitor: SSHMonitor
    let palette: MARCPalette
    @State private var showLoad = false
    @State private var showSwap = false
    @State private var feedbackTrigger = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            cpu
            memory
            network
            disk
        }.frame(maxWidth: .infinity).padding(.vertical, 4)
            .sensoryFeedback(.selection, trigger: feedbackTrigger)
            .onChange(of: monitor.server?.id) { _, _ in
                showLoad = false
                showSwap = false
            }
    }

    private var cpu: some View {
        let readingValue = MARCOverviewGaugeReading(raw: showLoad ? reading.details?.load : reading.cpu,
            kind: showLoad ? .load : .percentage)
        return Button {
            showLoad.toggle()
            feedbackTrigger &+= 1
        } label: {
            MARCOverviewGauge(title: showLoad ? "Load" : "CPU", reading: readingValue,
                tint: reading.cpu >= 80 ? Color(red: 1, green: 0.39, blue: 0.43)
                    : Color(red: 0.18, green: 0.78, blue: 0.52), palette: palette)
                .id(showLoad).transition(.opacity)
        }.buttonStyle(.plain)
            .frame(maxWidth: .infinity).contentShape(Rectangle())
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: showLoad)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(showLoad ? "One-minute load average" : "CPU usage")
            .accessibilityValue(readingValue.spoken)
            .accessibilityHint(showLoad ? "Shows CPU usage" : "Shows load average")
    }

    private var memory: some View {
        let readingValue = MARCOverviewGaugeReading(raw: showSwap ? reading.details?.swap : reading.memoryPercent,
            kind: showSwap ? .swap : .percentage)
        return Button {
            showSwap.toggle()
            feedbackTrigger &+= 1
        } label: {
            MARCOverviewGauge(title: showSwap ? "Swap" : "Memory", reading: readingValue,
                tint: reading.memoryPercent >= 85 ? Color(red: 1, green: 0.39, blue: 0.43)
                    : Color(red: 0.18, green: 0.78, blue: 0.52), palette: palette)
                .id(showSwap).transition(.opacity)
        }.buttonStyle(.plain)
            .frame(maxWidth: .infinity).contentShape(Rectangle())
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: showSwap)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(showSwap ? "Swap used" : "Memory usage")
            .accessibilityValue(readingValue.spoken)
            .accessibilityHint(showSwap ? "Shows memory usage" : "Shows swap used")
    }

    private var network: some View {
        metrics(title: "Network", firstLabel: "Download", first: monitor.downloadRate,
                secondLabel: "Upload", second: monitor.uploadRate)
    }
    private var disk: some View {
        metrics(title: "Disk", firstLabel: "Read", first: monitor.diskReadRate,
                secondLabel: "Write", second: monitor.diskWriteRate)
    }
    private func metrics(title: String, firstLabel: String, first: Double?,
                         secondLabel: String, second: Double?) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(palette.muted)
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    MARCLiveNumberText(text: MARCOverviewFormat.rate(first), value: first)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(palette.text).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
                    Text(firstLabel).font(.system(size: 11)).foregroundStyle(palette.muted)
                }
                VStack(spacing: 4) {
                    MARCLiveNumberText(text: MARCOverviewFormat.rate(second), value: second)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(palette.text).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
                    Text(secondLabel).font(.system(size: 11)).foregroundStyle(palette.muted)
                }
            }.frame(height: 76)
        }.frame(maxWidth: .infinity)
    }
}

private struct MARCOverviewGauge: View {
    let title: String
    let reading: MARCOverviewGaugeReading
    let tint: Color
    let palette: MARCPalette
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(palette.muted)
            ZStack {
                if reading.kind == .percentage {
                    Circle().stroke(palette.border, lineWidth: 4)
                    Circle().trim(from: 0, to: reading.progress ?? 0)
                        .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .modifier(MARCLiveValueMotion(value: reading.value))
                } else {
                    Circle().stroke(reading.value == nil ? palette.border : tint, lineWidth: 1.5)
                }
                VStack(spacing: 0) {
                    MARCLiveNumberText(text: reading.text, value: reading.value)
                        .font(.system(size: reading.kind == .swap ? 15 : 19, weight: .semibold))
                        .monospacedDigit().foregroundStyle(palette.text).minimumScaleFactor(0.65).lineLimit(1)
                    if let unit = reading.unit {
                        Text(unit).font(.system(size: 9, weight: .medium)).foregroundStyle(palette.text)
                    }
                }.padding(.horizontal, 4)
            }.frame(width: 54, height: 54)
                .frame(height: 76)
                .overlay(alignment: .bottom) {
                    Text(reading.caption).font(.system(size: 9)).foregroundStyle(palette.muted)
                        .lineLimit(1)
                }
        }.frame(maxWidth: .infinity).contentShape(Rectangle())
    }
}

private struct MARCOverviewPowerReading: View {
    @AppStorage("marc.showPowerStatus") private var showPowerStatus = true
    let details: SystemDetails?
    let palette: MARCPalette
    var fontSize: CGFloat = 12
    private var batteryPercent: Double? {
        guard let value = details?.batteryPercent, value.isFinite else { return nil }
        return min(100, max(0, value))
    }
    private var pluggedIn: Bool { details?.powerSource == "AC Power" }
    private var status: String {
        guard let details else { return "Power data unavailable" }
        if details.hasBattery == false { return pluggedIn ? "External power" : "No battery detected" }
        switch details.batteryState {
        case "charging", "finishing charge": return "Charging"
        case "charged": return "Fully charged"
        case "discharging": return "On battery"
        case .some: return pluggedIn ? "Not charging" : "On battery"
        case .none: return "Power data unavailable"
        }
    }
    var body: some View {
        HStack(spacing: 5) {
            Text(details?.hasBattery == false ? "Power" : "Battery").foregroundStyle(palette.muted)
            MARCLiveNumberText(
                text: batteryPercent.map { "\(Int($0.rounded()))%" }
                    ?? (details?.hasBattery == false && pluggedIn ? "AC" : "—"),
                value: batteryPercent)
                .foregroundStyle(palette.text).monospacedDigit()
        }.font(.system(size: fontSize)).lineLimit(1).minimumScaleFactor(0.8)
            .accessibilityElement(children: .combine)
            .accessibilityValue(showPowerStatus ? status : "")
    }
}

private struct MARCOverviewStorageReading: View {
    let reading: MacSnapshot
    let palette: MARCPalette
    var fontSize: CGFloat = 12
    private var percent: Double? {
        guard reading.diskTotal.isFinite, reading.diskTotal > 0, reading.diskAvailable.isFinite, reading.diskPercent.isFinite else { return nil }
        return min(100, max(0, reading.diskPercent))
    }
    var body: some View {
        HStack(spacing: 5) {
            Text("SSD").foregroundStyle(palette.muted)
            MARCLiveNumberText(text: percent.map { "\(Int($0.rounded()))%" } ?? "—", value: percent)
                .foregroundStyle(palette.text).monospacedDigit()
        }.font(.system(size: fontSize)).lineLimit(1).minimumScaleFactor(0.8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Storage used")
            .accessibilityValue(percent.map { "\(Int($0.rounded())) percent" } ?? "Storage data unavailable")
    }
}

private struct MARCOverviewProcesses: View {
    let monitor: SSHMonitor
    let palette: MARCPalette
    let enabled: Bool
    let openProcesses: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @State private var rows: [MARCProcess] = []
    @State private var processConnection: UUID?
    @State private var failure: String?
    @State private var received = false

    private var active: Bool { enabled && scenePhase == .active && monitor.connected }
    private var current: Bool { active && processConnection == monitor.processConnectionID }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Top processes").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.text).accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Button(action: openProcesses) {
                    HStack(spacing: 4) {
                        Text("View all")
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .medium))
                    }.font(.system(size: 13)).foregroundStyle(palette.accent)
                        .frame(minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("View all processes, sorted by CPU")
            }
            VStack(spacing: 0) {
                if current, !rows.isEmpty {
                    HStack(spacing: 8) {
                        Text("Name").frame(maxWidth: .infinity, alignment: .leading)
                        Text("PID").frame(width: 44, alignment: .trailing)
                        Text("CPU").frame(width: 48, alignment: .trailing)
                        Text("Memory").frame(width: 64, alignment: .trailing)
                    }.font(.system(size: 11)).foregroundStyle(palette.muted)
                        .padding(.bottom, 6).accessibilityHidden(true)
                    ForEach(rows) { process in
                        HStack(spacing: 8) {
                            Image(systemName: "macwindow").font(.system(size: 16))
                                .foregroundStyle(palette.muted).accessibilityHidden(true)
                            Text(process.name).font(.system(size: 13, weight: .medium))
                                .foregroundStyle(palette.text).lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(String(process.pid)).font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(palette.muted).lineLimit(1).minimumScaleFactor(0.8)
                                .frame(width: 44, alignment: .trailing)
                                .accessibilityLabel("Process ID \(process.pid)")
                            MARCLiveNumberText(text: String(format: "%.1f%%", process.cpu), value: process.cpu)
                                .frame(width: 48, alignment: .trailing)
                            MARCLiveNumberText(text: ByteCountFormatter.string(
                                fromByteCount: MARCProcessRows.memoryBytes(process.memory), countStyle: .binary),
                                value: process.memory)
                                .frame(width: 64, alignment: .trailing)
                        }.font(.system(size: 12)).foregroundStyle(palette.text)
                            .monospacedDigit().frame(minHeight: 44)
                            .accessibilityElement(children: .combine)
                        if process.id != rows.last?.id {
                            Rectangle().fill(palette.border.opacity(0.5)).frame(height: 0.5)
                                .accessibilityHidden(true)
                        }
                    }
                } else {
                    Text(!monitor.connected ? "Connect a Mac to see its processes."
                         : !active ? "Process updates paused."
                         : failure ?? (received ? "No processes available." : "Loading processes…"))
                        .font(.system(size: 12)).foregroundStyle(palette.muted)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                if current, !rows.isEmpty, let failure {
                    Text(failure).font(.system(size: 11)).foregroundStyle(palette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: "\(monitor.processConnectionID)-\(active)") {
            await refreshProcesses()
        }
    }

    private func refreshProcesses() async {
        guard !Task.isCancelled else { return }
        let connection = monitor.processConnectionID
        processConnection = connection
        rows = []
        failure = nil
        received = false
        guard active else { return }
        while !Task.isCancelled && active && monitor.processConnectionID == connection {
            do {
                let stream = try await monitor.processUpdates(expectedConnection: connection)
                for try await response in stream {
                    guard !Task.isCancelled, active,
                          monitor.processConnectionID == connection else { return }
                    let next = Array(MARCProcessRows.visible(response.processes, query: "", sorting: "CPU").prefix(3))
                    if next != rows {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) { rows = next }
                    }
                    received = true
                    failure = nil
                }
                guard !Task.isCancelled, active,
                      monitor.processConnectionID == connection else { return }
                failure = "Process updates stopped. Retrying…"
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, active,
                      monitor.processConnectionID == connection else { return }
                failure = "Process updates delayed. Retrying…"
            }
            do { try await Task.sleep(for: .seconds(3)) }
            catch { return }
        }
    }
}

private struct MARCMacPickerSheet: View {
    let servers: [ServerProfile]
    let currentID: UUID?
    let choose: (ServerProfile) -> Void
    let manage: () -> Void
    @State private var pendingMac: ServerProfile?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(spacing: 0) {
            HStack {
                Text("Your Macs").font(.system(size: 20, weight: .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 44, height: 44)
                }.tint(p.muted).accessibilityLabel("Close Mac picker")
            }.padding(.horizontal, 20).padding(.top, 12)

            ScrollView {
                VStack(spacing: 10) {
                    if servers.isEmpty {
                        Text("Add a Mac in Settings to get started.")
                            .font(.system(size: 13)).foregroundStyle(p.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 20)
                    }
                    ForEach(servers) { server in
                        Button {
                            if currentID == server.id { choose(server) }
                            else { pendingMac = server }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "laptopcomputer")
                                    .font(.system(size: 20)).foregroundStyle(p.accent)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(server.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(p.text)
                                    Text("\(server.username)@\(server.host):\(server.port)")
                                        .font(.system(size: 11)).foregroundStyle(p.muted)
                                        .lineLimit(2).multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 8)
                                if pendingMac?.id == server.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20)).foregroundStyle(p.accent)
                                        .accessibilityLabel("Selected")
                                } else if currentID == server.id {
                                    Text("Active").font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(p.muted)
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                            .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(server.name), \(server.username)\(currentID == server.id ? ", active Mac" : "")")
                    }
                }.padding(.horizontal, 20).padding(.vertical, 12)
            }.scrollIndicators(.hidden)

            if let pendingMac {
                VStack(spacing: 12) {
                    Divider()
                    if currentID != nil {
                        Text("Switching closes your current terminal sessions.")
                            .font(.system(size: 12)).foregroundStyle(p.muted)
                            .multilineTextAlignment(.center)
                    }
                    Button { choose(pendingMac) } label: {
                        Text("\(currentID == nil ? "Connect to" : "Switch to") \(pendingMac.name)")
                            .font(.system(size: 14, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12).padding(.vertical, 12)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(.white)
                            .background(p.accent, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }.padding(.horizontal, 20).padding(.bottom, 8)
            }
            Button(action: manage) {
                HStack {
                    Text("Manage servers").font(.system(size: 13, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11))
                }
                .foregroundStyle(p.muted).frame(minHeight: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain).padding(.horizontal, 24).padding(.bottom, 12)
        }
        .marcCanvas()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}

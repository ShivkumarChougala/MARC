import SwiftUI
import UIKit

struct MARCNotificationSettings: View {
    var servers: [ServerProfile] = []
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue
    @AppStorage("marc.notifications.enabled") private var enabled = false
    @AppStorage("marc.notifications.transfers") private var transfers = true
    @AppStorage("marc.notifications.sound") private var sound = false
    @AppStorage("marc.notifications.battery") private var battery = false
    @AppStorage("marc.notifications.storage") private var storage = false
    @State private var requesting = false
    @State private var sendingTest = false
    @State private var testScheduled = false
    @State private var editing: MARCAlertRule?
    private var notifications: MARCNotifications { .shared }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(spacing: 0) {
                    if notifications.authorized {
                        toggleRow("Notifications", icon: "bell", value: Binding(
                            get: { enabled }, set: { value in
                                if value { enabled = true } else { notifications.disable() }
                            }))
                    } else {
                        Button {
                            if notifications.denied { openSettings() }
                            else {
                                requesting = true
                                Task { await notifications.enable(); requesting = false }
                            }
                        } label: {
                            MARCNotificationActionRow(
                                title: notifications.denied ? "Open iOS Settings" : "Enable notifications",
                                icon: notifications.denied ? "gearshape" : "bell",
                                detail: notifications.denied ? "Allow notifications for MARC" : nil,
                                external: notifications.denied)
                        }.buttonStyle(.plain).disabled(requesting)
                    }
                }.background(p.surface, in: RoundedRectangle(cornerRadius: 16))
                Group {
                    MARCSettingsGroup(title: "Mac alerts") {
                        toggleRow("Low battery", icon: "battery.25", value: $battery,
                            detail: "\(MARCNotificationThreshold.standardBatteryLimit)% or below · Unplugged")
                        MARCSettingsDivider()
                        toggleRow("Low storage", icon: "internaldrive", value: $storage,
                            detail: "\(MARCNotificationThreshold.standardStorageFreePercent)% free or less")
                    }
                    customAlerts
                }.disabled(!enabled || !notifications.authorized)
                MARCSettingsGroup(title: "Delivery") {
                    toggleRow("File transfers", icon: "arrow.up.arrow.down", value: $transfers)
                    MARCSettingsDivider()
                    toggleRow("Sound", icon: "speaker.wave.2", value: $sound)
                }.disabled(!enabled || !notifications.authorized)
                MARCSettingsGroup(title: "Setup & testing") {
                    Button {
                        sendingTest = true
                        testScheduled = false
                        Task {
                            testScheduled = await notifications.scheduleTestNotification()
                            sendingTest = false
                        }
                    } label: {
                        MARCNotificationActionRow(title: sendingTest ? "Scheduling test…" : "Send test notification",
                            icon: "bell.badge")
                    }.buttonStyle(.plain)
                        .disabled(sendingTest || !enabled || !notifications.authorized)
                        .accessibilityHint("Schedules a test on this iPhone in five seconds. No Mac connection is needed.")
                    if !notifications.denied {
                        MARCSettingsDivider()
                        Button { openSettings() } label: {
                            MARCNotificationActionRow(title: "Open iOS Settings", icon: "gearshape",
                                detail: "Notifications for MARC", external: true)
                        }.buttonStyle(.plain)
                            .accessibilityHint("Opens MARC’s notification options in the Settings app.")
                    }
                }
                if testScheduled && enabled && notifications.authorized {
                    Text("Test scheduled · 5 seconds. Check Notification Center if needed.")
                        .marcNotificationFont(12, relativeTo: .footnote).foregroundStyle(p.muted)
                }
                if let failure = notifications.failure ?? notifications.ruleStore.failure {
                    Text(failure).marcNotificationFont(12, relativeTo: .footnote).foregroundStyle(p.muted)
                }
            }.padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 16)
        }.scrollIndicators(.hidden)
        .marcCanvas().marcNavigationTitle("Notifications").tint(p.accent)
        .task { await notifications.refreshAuthorization() }
        .onChange(of: phase) { _, phase in
            if phase == .active { Task { await notifications.refreshAuthorization() } }
        }
        .onChange(of: enabled) { _, _ in testScheduled = false }
        .onDisappear { testScheduled = false }
        .sheet(item: $editing) { rule in
            MARCCustomAlertEditor(rule: rule, servers: servers, store: notifications.ruleStore)
        }
    }

    private var customAlerts: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Custom alerts").marcNotificationFont(13, weight: .semibold, relativeTo: .footnote).foregroundStyle(p.muted)
                Spacer()
                if !notifications.ruleStore.rules.isEmpty {
                    Button { editing = MARCAlertRule() } label: {
                        Image(systemName: "plus").font(.system(size: 18, weight: .medium))
                            .frame(minWidth: 44, minHeight: 44)
                    }.buttonStyle(.plain).foregroundStyle(p.accent).accessibilityLabel("Create alert")
                        .disabled(!notifications.ruleStore.readable || notifications.ruleStore.rules.count >= 20)
                }
            }.padding(.leading, 14)
            VStack(spacing: 0) {
                if notifications.ruleStore.rules.isEmpty {
                    Button { editing = MARCAlertRule() } label: {
                        MARCSettingsSupportRow(title: "Create alert", icon: "plus", external: false)
                    }.buttonStyle(.plain).disabled(!notifications.ruleStore.readable)
                }
                ForEach(notifications.ruleStore.rules) { rule in
                    if rule.id != notifications.ruleStore.rules.first?.id { MARCSettingsDivider() }
                    HStack(spacing: 12) {
                        MARCSettingsRowIcon(symbol: rule.metric.icon)
                        Button { editing = rule } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(rule.name).marcNotificationFont(14, weight: .semibold)
                                    Image(systemName: "chevron.right").marcNotificationFont(11, relativeTo: .caption2).foregroundStyle(p.muted)
                                }
                                Text("\(rule.summary) · \(targetLabel(for: rule))")
                                    .marcNotificationFont(12, relativeTo: .caption).foregroundStyle(p.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityHint("Edit alert")
                        Toggle(rule.name, isOn: Binding(
                            get: { notifications.ruleStore.rules.first(where: { $0.id == rule.id })?.enabled ?? false },
                            set: { notifications.ruleStore.setEnabled(rule.id, $0) }))
                            .labelsHidden().fixedSize()
                    }.padding(14).frame(minHeight: 64)
                }
            }.background(p.surface, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func targetLabel(for rule: MARCAlertRule) -> String {
        guard let id = rule.serverID else { return "All Macs" }
        return servers.first(where: { $0.id == id })?.name ?? "Mac unavailable"
    }

    private func toggleRow(_ title: String, icon: String, value: Binding<Bool>, detail: String? = nil) -> some View {
        let p = MARCPalette(dark: scheme == .dark)
        return HStack(spacing: 12) {
            MARCSettingsRowIcon(symbol: icon)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).marcNotificationFont(15).foregroundStyle(p.text)
                if let detail {
                    Text(detail).marcNotificationFont(12, relativeTo: .caption).foregroundStyle(p.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Toggle(title, isOn: value).labelsHidden().fixedSize()
        }.padding(.horizontal, 14).padding(.vertical, detail == nil ? 10 : 12)
            .frame(minHeight: detail == nil ? 50 : 64)
    }
    private func openSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct MARCCustomAlertEditor: View {
    let servers: [ServerProfile]
    let store: MARCAlertStore
    @State private var draft: MARCAlertRule
    @State private var metric: MARCAlertRule.Metric?
    @State private var comparison: MARCAlertRule.Comparison?
    @State private var threshold = ""
    @State private var margin = ""
    @State private var sendingTest = false
    @State private var testFeedback: String?
    @State private var advancedExpanded = false
    @AppStorage("marc.notifications.enabled") private var notificationsEnabled = false
    @State private var confirmingDelete = false
    @State private var showingHelp = false
    private let preservesCustomRecovery: Bool
    @AppStorage("marc.notifications.repeatMinutes") private var defaultRepeatMinutes = 0
    @AppStorage("marc.notifications.cooldownMinutes") private var defaultCooldownMinutes = 60
    @AppStorage("marc.notifications.recovery") private var defaultRecovery = false
    private var defaultRepeatLabel: String {
        let minutes = MARCAlertRule.repeatOptions.contains(defaultRepeatMinutes) ? defaultRepeatMinutes : 0
        return minutes == 0 ? "Once per incident" : "Every \(minutes) min"
    }
    private var defaultCooldownLabel: String {
        let minutes = MARCAlertRule.cooldownOptions.contains(defaultCooldownMinutes) ? defaultCooldownMinutes : 60
        return "\(minutes) min"
    }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue
    @FocusState private var marginFocused: Bool
    private var existing: Bool { store.rules.contains { $0.id == draft.id } }
    private var validTarget: Bool { draft.serverID == nil || servers.contains { $0.id == draft.serverID } }
    private var candidate: MARCAlertRule? {
        guard let metric, let comparison,
              let number = Int(threshold.trimmingCharacters(in: .whitespaces)) else { return nil }
        var result = draft
        result.name = result.name.trimmingCharacters(in: .whitespacesAndNewlines)
        result.metric = metric; result.comparison = comparison; result.threshold = Double(number)
        if margin.trimmingCharacters(in: .whitespaces).isEmpty { result.recoveryMargin = nil }
        else {
            guard let number = Int(margin.trimmingCharacters(in: .whitespaces)) else { return nil }
            result.recoveryMargin = Double(number)
        }
        return result.isValid && validTarget ? result : nil
    }
    private var thresholdUnit: String {
        metric == .storage && draft.storageUnit != .percent ? "GB" : "%"
    }
    private var thresholdChoices: [Int] {
        var values = thresholdUnit == "GB" ? [5, 10, 20, 50, 100, 200, 500, 1_000] :
            Array(stride(from: 10, through: 100, by: 10))
        // Keep an older saved threshold selectable without rounding or migrating it.
        if let saved = store.rules.first(where: { $0.id == draft.id }), saved.isValid,
           saved.metric == metric,
           (metric != .storage || (saved.storageUnit ?? .gb) == (draft.storageUnit ?? .gb)) {
            let savedValue = Int(saved.threshold)
            if !values.contains(savedValue) {
                values.append(savedValue)
                values.sort()
            }
        }
        return values
    }
    private var thresholdPlaceholder: String {
        guard metric != nil else { return "Select value" }
        return thresholdUnit == "GB" ? "Select GB" : "Select percentage"
    }
    private func thresholdLabel(_ value: Int) -> String {
        thresholdUnit == "GB" ? "\(value) GB" : "\(value)%"
    }

    private func previewDetails(for rule: MARCAlertRule) -> String {
        let timing = rule.duration == 0 ? "Immediately" : "For \(MARCAlertRule.durationLabel(rule.duration))"
        let minutes = rule.repeatMinutes ?? defaultRepeatMinutes
        let repeatLabel = minutes == 0 ? "Once per incident" : "Every \(minutes) min"
        return "\(timing) · \(repeatLabel)"
    }
    private func previewCondition(for rule: MARCAlertRule) -> String {
        let target: String
        if let id = rule.serverID {
            target = servers.first(where: { $0.id == id })?.name ?? "Mac unavailable"
        } else { target = "All Macs" }
        return "\(rule.metric.title) \(rule.comparison.rawValue) \(rule.valueLabel) · \(target)"
    }

    init(rule: MARCAlertRule, servers: [ServerProfile], store: MARCAlertStore) {
        self.servers = servers; self.store = store
        let saved = store.rules.contains { $0.id == rule.id }
        self.preservesCustomRecovery = saved && rule.recoveryMargin != nil
        var initial = rule
        if !saved { initial.duration = 0; initial.repeatMinutes = 0 }
        _draft = State(initialValue: initial)
        _metric = State(initialValue: saved ? rule.metric : nil)
        _comparison = State(initialValue: saved ? rule.comparison : nil)
        _threshold = State(initialValue: saved ? String(Int(rule.threshold)) : "")
        _margin = State(initialValue: rule.recoveryMargin.map { String(Int($0)) } ?? "")
    }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Text("Name")
                        TextField("e.g. High CPU", text: $draft.name)
                            .multilineTextAlignment(.trailing).textInputAutocapitalization(.sentences)
                            .accessibilityLabel("Alert name")
                    }
                    Picker("Mac", selection: $draft.serverID) {
                        Text("All Macs").tag(UUID?.none)
                        ForEach(servers) { server in Text(server.name).tag(Optional(server.id)) }
                        if let id = draft.serverID, !validTarget { Text("Mac unavailable").tag(Optional(id)) }
                    }
                } header: { Text("Alert").marcNotificationFont(13, weight: .semibold, relativeTo: .footnote) }
                Section {
                    Picker("Metric", selection: $metric) {
                        Text("Choose metric").tag(MARCAlertRule.Metric?.none)
                        ForEach(MARCAlertRule.Metric.allCases) { item in Text(item.title).tag(Optional(item)) }
                    }
                    Picker("Condition", selection: $comparison) {
                        Text("Choose condition").tag(MARCAlertRule.Comparison?.none)
                        ForEach(MARCAlertRule.Comparison.allCases) { item in Text(item.title).tag(Optional(item)) }
                    }.disabled(metric == nil)
                    if metric == .storage {
                        Picker("Measure", selection: Binding(
                            get: { draft.storageUnit ?? .gb }, set: { draft.storageUnit = $0; threshold = ""; margin = "" })) {
                            ForEach(MARCAlertRule.StorageUnit.allCases) { item in Text(item.title).tag(item) }
                        }
                    }
                    Picker("Threshold", selection: $threshold) {
                        Text(thresholdPlaceholder).tag("")
                        ForEach(thresholdChoices, id: \.self) { value in
                            Text(thresholdLabel(value)).tag(String(value))
                        }
                    }.pickerStyle(.menu)
                        .disabled(metric == nil || comparison == nil)
                        .accessibilityHint("Choose a preset threshold in \(thresholdUnit).")
                } header: { Text("Condition").marcNotificationFont(13, weight: .semibold, relativeTo: .footnote) }
                  footer: {
                    if metric == .battery {
                        Text("While unplugged").marcNotificationFont(12, relativeTo: .footnote).foregroundStyle(p.muted)
                    }
                }
                if let rule = candidate {
                    Section {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "bell").marcNotificationFont(17)
                                .foregroundStyle(p.accent).frame(width: 22).padding(.top, 2)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(rule.name).marcNotificationFont(14, weight: .semibold)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(previewCondition(for: rule))
                                    .marcNotificationFont(12, relativeTo: .caption).foregroundStyle(p.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(previewDetails(for: rule))
                                    .marcNotificationFont(12, relativeTo: .caption).foregroundStyle(p.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }.padding(.vertical, 4).accessibilityElement(children: .combine)
                            .accessibilityLabel("Alert summary")
                            .accessibilityValue("\(rule.name). \(previewCondition(for: rule)). \(previewDetails(for: rule))")
                        Button {
                            sendingTest = true
                            testFeedback = nil
                            Task {
                                let scheduled = await MARCNotifications.shared.scheduleTestNotification(rule: rule)
                                if candidate == rule {
                                    testFeedback = scheduled ? "Test scheduled · 5 seconds." :
                                        (MARCNotifications.shared.failure ?? "The test could not be sent.")
                                }
                                sendingTest = false
                            }
                        } label: {
                            Label(sendingTest ? "Scheduling test…" : "Send test alert", systemImage: "bell.badge")
                                .marcNotificationFont(15)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }.buttonStyle(.borderless)
                            .disabled(sendingTest || !MARCNotifications.shared.authorized ||
                                !notificationsEnabled)
                            .accessibilityHint("Sends a sample of this alert in five seconds without saving it.")
                    } footer: {
                        Text(testFeedback ?? "Sends a sample without saving.")
                            .marcNotificationFont(12, relativeTo: .footnote)
                    }
                }
                Section {
                    MARCNotificationAdvancedHeader(isExpanded: $advancedExpanded) { showingHelp = true }
                    if advancedExpanded {
                        Picker("Alert after", selection: $draft.duration) {
                            ForEach(MARCAlertRule.durations, id: \.self) { seconds in
                                Text(MARCAlertRule.durationLabel(seconds)).tag(seconds)
                            }
                        }
                        Picker("Repeat", selection: $draft.repeatMinutes) {
                            Text("Default · \(defaultRepeatLabel)").tag(Int?.none)
                            ForEach(MARCAlertRule.repeatOptions, id: \.self) { minutes in
                                Text(minutes == 0 ? "Once per incident" : "Every \(minutes) min").tag(Optional(minutes))
                            }
                        }
                        Picker("Time between new alerts", selection: $draft.cooldownMinutes) {
                            Text("Default · \(defaultCooldownLabel)").tag(Int?.none)
                            ForEach(MARCAlertRule.cooldownOptions, id: \.self) { minutes in
                                Text("\(minutes) min").tag(Optional(minutes))
                            }
                        }
                        Picker("Notify on recovery", selection: $draft.notifyOnRecovery) {
                            Text(defaultRecovery ? "Default · On" : "Default · Off").tag(Bool?.none)
                            Text("On").tag(Optional(true))
                            Text("Off").tag(Optional(false))
                        }
                        if preservesCustomRecovery {
                            HStack {
                                Text("Recovery margin")
                                Spacer()
                                TextField("Automatic", text: $margin).multilineTextAlignment(.trailing)
                                    .keyboardType(.numberPad).focused($marginFocused).frame(maxWidth: 110)
                                    .accessibilityLabel("Recovery margin")
                                    .accessibilityHint("Your existing custom setting, in threshold units. Clear it to use automatic recovery.")
                            }.disabled(metric == nil)
                        }
                    }
                }
                if existing {
                    Section {
                        Button(role: .destructive) { confirmingDelete = true } label: {
                            Label("Delete alert", systemImage: "trash")
                        }
                    }
                }
                if let failure = store.failure { Text(failure).marcNotificationFont(12, relativeTo: .footnote).foregroundStyle(p.muted) }
            }
            .marcNotificationFont(15)
            .environment(\.defaultMinListRowHeight, 50)
            .scrollContentBackground(.hidden).background(p.background)
            .navigationTitle(existing ? "Edit alert" : "Create alert").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.marcNotificationFont(15)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { if let rule = candidate, store.save(rule) { dismiss() } }
                        .disabled(candidate == nil || !store.readable)
                        .marcNotificationFont(15, weight: .semibold)
                }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { marginFocused = false } }
            }
            .onChange(of: metric) { _, _ in comparison = nil; threshold = ""; margin = "" }
            .onChange(of: candidate) { _, _ in testFeedback = nil }
            .sheet(isPresented: $showingHelp) { MARCNotificationHelp() }
            .confirmationDialog("Delete this alert?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete alert", role: .destructive) { if store.remove(draft.id) { dismiss() } }
            }
        }.tint(p.accent).presentationDragIndicator(.visible)
    }
}

private struct MARCNotificationAdvancedHeader: View {
    @Binding var isExpanded: Bool
    var showHelp: () -> Void
    var body: some View {
        HStack(spacing: 0) {
            Button { isExpanded.toggle() } label: {
                Text("Advanced").frame(minHeight: 44, alignment: .leading)
            }.buttonStyle(.plain)
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
                .accessibilityHint("Shows or hides more alert settings.")
            Button(action: showHelp) {
                Image(systemName: "questionmark.circle").marcNotificationFont(14)
                    .frame(minWidth: 44, minHeight: 44)
            }.buttonStyle(.borderless).accessibilityLabel("Help with alert settings")
            Spacer(minLength: 0)
            Button { isExpanded.toggle() } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .marcNotificationFont(12, relativeTo: .caption)
                    .frame(minWidth: 44, minHeight: 44)
            }.buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse Advanced" : "Expand Advanced")
        }
    }
}

private struct MARCNotificationActionRow: View {
    let title: String
    let icon: String
    var detail: String? = nil
    var external = false
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        HStack(spacing: 12) {
            MARCSettingsRowIcon(symbol: icon)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).marcNotificationFont(15).foregroundStyle(p.text)
                if let detail {
                    Text(detail).marcNotificationFont(12, relativeTo: .caption).foregroundStyle(p.muted)
                }
            }.fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            if external {
                Image(systemName: "arrow.up.right").marcNotificationFont(12, relativeTo: .caption)
                    .foregroundStyle(p.muted).accessibilityHidden(true)
            }
        }.padding(.horizontal, 14).padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: detail == nil ? 50 : 64)
            .contentShape(Rectangle()).accessibilityElement(children: .combine)
    }
}

private struct MARCNotificationHelp: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        NavigationStack {
            Form {
                explanation("Alert after", "Waits until the reading stays past your limit for this long. Immediately skips the wait.")
                explanation("Repeat", "Get one alert for each problem, or regular reminders until it clears.")
                explanation("Time between new alerts", "If a problem clears and comes back, wait this long after the last alert before alerting again. Repeat reminders use their own timing.")
                explanation("Notify on recovery", "Lets you know when things are back to normal. MARC ignores small changes near your limit to avoid repeated alerts.")
                explanation("Default", "Uses your saved notification setting. The current value is shown beside Default. You can choose a different value for this alert.")
                explanation("Test notification", "Sends a test to this iPhone after 5 seconds. No Mac is needed. This checks notifications, not Mac monitoring. Focus or iOS settings may hide or delay it.")
                explanation("Monitoring", "Keep MARC open and connected to your Mac for checks. Checks may pause when you leave the app.")
            }.marcNotificationFont(15)
                .scrollContentBackground(.hidden).background(p.background)
                .navigationTitle("Alert controls").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }.marcNotificationFont(15, weight: .semibold)
                    }
                }
        }.tint(p.accent).presentationDragIndicator(.visible)
    }
    private func explanation(_ title: String, _ message: String) -> some View {
        Section {
            Text(message).fixedSize(horizontal: false, vertical: true)
        } header: {
            Text(title).marcNotificationFont(13, weight: .semibold, relativeTo: .footnote)
        }
    }
}

// Match MARC's existing settings sizes while retaining Dynamic Type scaling.
private struct MARCNotificationFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    init(size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: relativeTo)
        self.weight = weight
    }
    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}

private extension View {
    func marcNotificationFont(_ size: CGFloat, weight: Font.Weight = .regular,
                              relativeTo: Font.TextStyle = .subheadline) -> some View {
        modifier(MARCNotificationFont(size: size, weight: weight, relativeTo: relativeTo))
    }
}

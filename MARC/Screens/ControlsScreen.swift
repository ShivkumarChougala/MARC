import Foundation
import SwiftUI
import UIKit

struct ControlsScreen: View {
    // Compact native controls with explicit Mac app launch actions.
    let monitor: SSHMonitor
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicType
    // Observe accent changes here because MARCPalette reads the saved value directly.
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue
    @AppStorage("marc.quickLaunch.v1") private var quickLaunchStorage = "{}"
    @State private var quickLaunchApps = MARCQuickLaunchSelection.defaults
    @State private var quickLaunchScrollID: String?
    @State private var showQuickLaunch = false
    @State private var lastApplicationID: String?
    @State private var state: MARCControlState?
    @State private var volume = 0.0
    @State private var brightness = 0.0
    @State private var selectedDisplayID: Int?
    @State private var editingBrightness = false
    @State private var feedbackAction: MARCControlAction?
    @State private var lastValue: Int?
    @State private var noticeEvent = UUID()
    @State private var editingVolume = false
    @State private var busy = false
    @State private var refreshing = false
    @State private var failure: String?
    @State private var notice: String?
    @State private var wirelessReadAt: TimeInterval?
    @State private var revision = UUID()
    @State private var actionTask: Task<Void, Never>?
    @State private var visible = false
    @State private var controlConnection: UUID?

    @State private var confirmWiFiOff = false
    @State private var mediaPlayer = 0
    @State private var showControlDetails = false
    @State private var showMediaSetup = false
    @State private var copiedMediaCommand = false
    private var controlsEnabled: Bool { usable && !busy }

    private var wirelessPlaceholder: String {
        guard monitor.connected else { return "Not connected" }
        if wirelessReadAt != nil { return "Unavailable" }
        return failure != nil && !refreshing ? "Not checked" : "Checking…"
    }

    private var usable: Bool {
        visible && monitor.connected && scenePhase == .active &&
            controlConnection == monitor.controlConnectionID
    }
    private var connectionID: String {
        "\(visible)-\(monitor.controlConnectionID)-\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)-\(scenePhase)"
    }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if monitor.connected, let server = monitor.server {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(server.username)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(p.text)
                        if let version = monitor.snapshot?.details?.osVersion,
                           !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(version.lowercased().hasPrefix("macos") ? version : "macOS " + version)
                                .font(.system(size: 12))
                                .foregroundStyle(p.muted)
                        }
                    }
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
                if refreshing && state == nil {
                    ProgressView().controlSize(.small).tint(p.accent)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Reading Mac controls")
                }
                if !monitor.connected {
                    Text("Connect to a Mac in Settings to use these controls.")
                        .font(.footnote).foregroundStyle(p.muted)
                        .padding(.bottom, 4)
                }

                let wirelessLayout = dynamicType.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) :
                    AnyLayout(HStackLayout(alignment: .top, spacing: 12))
                wirelessLayout {
                    controlCard(p) {
                        connectionRow("Wi-Fi", symbol: "wifi",
                            enabled: state?.wifiEnabled,
                            writable: state?.wifiEnabled != nil,
                            action: .wifi, palette: p)
                    }
                    controlCard(p) {
                        connectionRow("Bluetooth", symbol: "antenna.radiowaves.left.and.right",
                            enabled: state?.bluetoothEnabled,
                            writable: state?.bluetoothWritable == true && state?.bluetoothEnabled != nil,
                            action: .bluetooth, palette: p)
                    }
                }

                controlCard(p) {
                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            send(.mute, value: state?.muted == true ? 0 : 1)
                        } label: {
                            controlIcon(state?.muted == true ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                        color: state?.muted == true ? p.accent : p.muted)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .buttonStyle(.plain)
                        .disabled(!controlsEnabled || state?.muted == nil || editingVolume || editingBrightness)
                        .accessibilityLabel(state?.muted == true ? "Unmute Mac" : "Mute Mac")
                        MARCCompactControl(value: $volume, title: "Volume",
                            available: state?.volume != nil,
                            enabled: controlsEnabled && !editingBrightness, palette: p,
                            editing: { editingVolume = $0 },
                            commit: { send(.volume, value: Int(volume.rounded())) })

                    }
                }
                controlCard(p) {
                    HStack(alignment: .top, spacing: 10) {
                        controlIcon("sun.max.fill", color: p.muted)
                        VStack(alignment: .leading, spacing: 2) {
                            if state == nil || state?.brightness != nil {
                                MARCCompactControl(value: $brightness, title: "Brightness",
                                    available: state?.brightness != nil,
                                    enabled: controlsEnabled && !editingVolume, palette: p,
                                    editing: { editingBrightness = $0 },
                                    commit: { send(.brightness, value: Int(brightness.rounded())) })
                            } else {
                                Text("Brightness").font(.subheadline.weight(.medium))
                                    .foregroundStyle(p.text)
                                Text("Unavailable for this display. Use its brightness controls.")
                                    .font(.caption).foregroundStyle(p.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }

                controlCard(p) {
                    let pickerLayout = dynamicType.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) :
                        AnyLayout(HStackLayout(alignment: .center, spacing: 12))
                    pickerLayout {
                        audioOutputSelector(p)
                        if (state?.displays?.count ?? 0) > 1 {
                            if !dynamicType.isAccessibilitySize { Divider().frame(height: 40) }
                            displaySelector(p)
                        }
                    }
                }

                nowPlayingCard(p)
                controlCard(p) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            sectionTitle("Quick Launch", p)
                            Spacer()
                            Button("Edit") {
                                UISelectionFeedbackGenerator().selectionChanged()
                                showQuickLaunch = true
                            }
                                .font(.caption.weight(.medium)).tint(p.accent)
                                .frame(minWidth: 44, minHeight: 44)
                                .disabled(!controlsEnabled || editingVolume || editingBrightness)
                                .marcLearnTarget(.controls)
                        }
                        if quickLaunchApps.isEmpty {
                            Text("Tap Edit to add apps from your Mac.")
                                .font(.caption).foregroundStyle(p.muted)
                        }
                        ScrollView(.horizontal) {
                            HStack(alignment: .top, spacing: 8) {
                                ForEach(quickLaunchApps) { app in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        send(.launchApp, value: 0, applicationID: app.id)
                                    } label: {
                                        VStack(spacing: 7) {
                                            MARCLaunchIcon(app: app)
                                                .overlay {
                                                    if busy && feedbackAction == .launchApp && lastApplicationID == app.id {
                                                        ZStack {
                                                            RoundedRectangle(cornerRadius: 13).fill(.black.opacity(0.45))
                                                            ProgressView().tint(.white)
                                                        }
                                                    }
                                                }
                                            Text(busy && feedbackAction == .launchApp && lastApplicationID == app.id ? "Opening…" : app.title)
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(p.text).lineLimit(2)
                                                .multilineTextAlignment(.center)
                                        }
                                        .containerRelativeFrame(.horizontal,
                                            count: dynamicType.isAccessibilitySize ? 1 : 3, spacing: 8)
                                        .frame(minHeight: 72, alignment: .top)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!controlsEnabled || editingVolume || editingBrightness)
                                    .opacity(usable ? 1 : 0.45)
                                    .accessibilityLabel("Open \(app.title) on your Mac")
                                    .accessibilityValue(busy && feedbackAction == .launchApp && lastApplicationID == app.id ? "Opening" : "")
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition(id: $quickLaunchScrollID, anchor: .leading)
                        .scrollIndicators(.visible)

                    }
                }
            }.padding(.horizontal, 16).padding(.vertical, 10)
        }.scrollIndicators(.hidden).marcCanvas()
            .marcLiveReadings(enabled: usable && !editingVolume && !editingBrightness)
            .overlay(alignment: .bottom) { floatingFeedback(p) }
            .marcLearnOverlay(.controls, enabled: controlsEnabled &&
                !editingVolume && !editingBrightness && !showQuickLaunch && !showControlDetails &&
                !showMediaSetup && !confirmWiFiOff && notice == nil && failure == nil)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !controlDetails.isEmpty {
                        Button {
                            showControlDetails = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel("Control availability details")
                    }
                }
                .marcToolbarBackgroundHidden()
            }
            .alert("Control availability", isPresented: $showControlDetails) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(controlDetails)
            }
            .sheet(isPresented: $showQuickLaunch) {
                let mac = monitor.server?.id.uuidString ?? ""
                let connection = monitor.controlConnectionID
                MARCQuickLaunchEditor(selected: quickLaunchApps) {
                    let response = try await monitor.marcControlRequest(includeWireless: false,
                        expectedConnection: connection, includeApplications: true, applicationsOnly: true)
                    guard usable, monitor.server?.id.uuidString == mac else { throw CancellationError() }
                    guard let apps = response.applications, response.applicationsError == nil else {
                        throw MARCAIError.message("Installed apps could not be read.")
                    }
                    return apps
                } save: { apps in
                    guard usable, controlConnection == connection, monitor.server?.id.uuidString == mac else { return }
                    let previousIDs = Set(quickLaunchApps.map(\.id))
                    let selected = MARCQuickLaunchSelection.cleaned(apps)
                    quickLaunchStorage = MARCQuickLaunchSelection.write(selected, mac: mac, storage: quickLaunchStorage)
                    // Update the visible source immediately; do not wait for AppStorage observation.
                    quickLaunchApps = selected
                    quickLaunchScrollID = selected.last(where: { !previousIDs.contains($0.id) })?.id ?? selected.first?.id
                    if failure == nil {
                        feedbackAction = .launchApp
                        lastValue = nil
                        lastApplicationID = nil
                        notice = "Quick Launch updated"
                        noticeEvent = UUID()
                    }
                }
                .tint(p.accent)
            }
            .navigationTitle("Control Center").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Turn off the Mac’s Wi-Fi?", isPresented: $confirmWiFiOff,
                                titleVisibility: .visible) {
                Button("Turn off Wi-Fi", role: .destructive) { send(.wifi, value: 0) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("If this SSH connection uses Wi-Fi, it will disconnect. You may need to turn Wi-Fi back on at the Mac.")
            }

            .sheet(isPresented: $showMediaSetup) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(state?.mediaHelperInstalled == true ? "Browser music is enabled" : "Enable browser music")
                            .font(.title3.weight(.semibold))
                        Text(state?.mediaError ?? state?.mediaSetupMessage ?? "Connect to your Mac to check setup.")
                            .font(.subheadline)
                        if state?.mediaHelperInstalled != true, let command = state?.mediaInstallCommand {
                            Text(command)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                            Button {
                                UIPasteboard.general.string = command
                                copiedMediaCommand = true
                            } label: {
                                Label(copiedMediaCommand ? "Command copied" : "Copy command",
                                      systemImage: copiedMediaCommand ? "checkmark" : "doc.on.doc")
                            }
                            .buttonStyle(.borderedProminent)
                            Text("Close this panel, open MARC’s Terminal, paste and run the command, then return here.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else if state?.mediaHelperInstalled != true {
                            Link("Set up Homebrew on your Mac", destination: URL(string: "https://brew.sh")!)
                        }
                        Button {
                            Task {
                                await refresh(wireless: false)
                                if state?.mediaHelperInstalled == true && state?.mediaError == nil {
                                    showMediaSetup = false
                                }
                            }
                        } label: {
                            HStack {
                                Text("Check again")
                                if refreshing { ProgressView() }
                            }
                        }
                        .disabled(!usable || busy || refreshing)
                        Spacer()
                    }
                    .padding(22)
                    .navigationTitle("Music setup")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showMediaSetup = false }
                        }
                        .marcToolbarBackgroundHidden()
                    }
                    .tint(p.accent)
                }
                .presentationDetents([.medium, .large])
            }
            .onAppear { visible = true }
            .onChange(of: quickLaunchStorage, initial: true) { _, _ in reloadQuickLaunch() }
            .onChange(of: monitor.server?.id) { _, _ in reloadQuickLaunch() }
            .task(id: connectionID) {
                guard !Task.isCancelled else { return }
                stopControlWork()
                controlConnection = monitor.controlConnectionID
                brightness = 0
                selectedDisplayID = nil
                state = nil
                volume = 0
                wirelessReadAt = nil
                guard usable else { return }
                while !Task.isCancelled && usable {
                    let wireless = wirelessReadAt.map { ProcessInfo.processInfo.systemUptime - $0 >= 30 } ?? true
                    await refresh(wireless: wireless)
                    do { try await Task.sleep(for: .seconds(5)) }
                    catch { return }
                }
            }
            .onDisappear {
                visible = false
                controlConnection = nil
                stopControlWork()
            }
            .task(id: noticeEvent) {
                guard notice != nil else { return }
                let event = noticeEvent
                do { try await Task.sleep(for: .seconds(2)) }
                catch { return }
                guard !Task.isCancelled, noticeEvent == event, usable else { return }
                notice = nil
            }
    }
    private var controlDetails: String {
        let errors = [
            state?.wifiError, state?.bluetoothError,
            state?.brightnessError, state?.audioOutputError, state?.audioError
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return Array(Set(errors)).sorted().joined(separator: "\n\n")
    }

    @ViewBuilder
    private func floatingFeedback(_ p: MARCPalette) -> some View {
        // Routine actions stay in their cards; failures retain explicit retry controls.
        if failure != nil || (notice != nil && feedbackAction == .launchApp) {
            VStack(spacing: 12) {
                if let failure {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(failure)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 24) {
                        Button("Dismiss") {
                            self.failure = nil
                            feedbackAction = nil
                        }
                        Button("Retry") {
                            if let action = feedbackAction, let value = lastValue {
                                if action == .wifi && value == 0 {
                                    confirmWiFiOff = true
                                } else {
                                    send(action, value: value, applicationID: lastApplicationID)
                                }
                            } else {
                                Task { await refresh(wireless: true) }
                            }
                        }
                    }
                    .tint(p.accent)
                } else if let notice {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(p.accent)
                    Text(notice).multilineTextAlignment(.center)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(p.text)
            .padding(20)
            .frame(maxWidth: 280)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.15), radius: 18, y: 6)
            .padding(24)
            .allowsHitTesting(!busy && failure != nil)
            .accessibilityElement(children: .contain)
        }
    }

    private var playbackTarget: Int {
        state?.mediaHelperInstalled == true ? 2 : mediaPlayer
    }
    private var mediaAvailable: Bool {
        if state?.mediaHelperInstalled == true { return state?.nowPlaying != nil }
        return state?.mediaPlayers?.contains(mediaPlayer == 1 ? "Spotify" : "Music") == true
    }

    private func sectionTitle(_ title: String, _ p: MARCPalette) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(p.text)
    }

    private func reloadQuickLaunch() {
        quickLaunchApps = MARCQuickLaunchSelection.read(quickLaunchStorage,
            mac: monitor.server?.id.uuidString ?? "")
        if !quickLaunchApps.contains(where: { $0.id == quickLaunchScrollID }) {
            quickLaunchScrollID = quickLaunchApps.first?.id
        }
    }

    private func controlCard<Content: View>(
        _ p: MARCPalette, @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(p.border.opacity(0.45), lineWidth: 0.5))
    }

    private func controlIcon(_ symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .accessibilityHidden(true)
    }

    private var selectedDisplayName: String {
        state?.displays?.first(where: { $0.id == selectedDisplayID })?.name ??
            state?.displayName ?? "Mac display"
    }

    private func displaySelector(_ p: MARCPalette) -> some View {
        Menu {
            ForEach(state?.displays ?? []) { display in
                Button {
                    guard selectedDisplayID != display.id else { return }
                    selectedDisplayID = display.id
                    // A display switch supersedes any background read of the old display.
                    revision = UUID()
                    refreshing = false
                    state?.brightness = nil
                    feedbackAction = nil
                    failure = nil
                    notice = nil
                    Task { await refresh(wireless: false) }
                } label: {
                    if display.id == selectedDisplayID {
                        Label(display.name + (display.supported ? "" : " · Status only"), systemImage: "checkmark")
                    } else {
                        Text(display.name + (display.supported ? "" : " · Status only"))
                    }
                }
            }
        } label: {
            pickerLabel("Display", value: selectedDisplayName, updating: false, p)
        }
        .disabled(!controlsEnabled || editingVolume || editingBrightness)
        .accessibilityLabel("Choose Mac display")
        .accessibilityValue(selectedDisplayName)
    }

    private func audioOutputSelector(_ p: MARCPalette) -> some View {
        Menu {
            ForEach(state?.outputs ?? []) { output in
                Button { send(.output, value: output.id) } label: {
                    if output.id == state?.audioOutputID {
                        Label(output.name, systemImage: "checkmark")
                    } else { Text(output.name) }
                }
            }
        } label: {
            pickerLabel("Audio Output", value: state?.audioOutputName ?? (state == nil ? "Checking…" : "Unavailable"),
                        updating: busy && feedbackAction == .output, p)
        }
        .disabled(!controlsEnabled || editingVolume || editingBrightness || (state?.outputs?.isEmpty ?? true))
        .accessibilityLabel("Choose Mac audio output")
        .accessibilityValue(state?.audioOutputName ?? "Unavailable")
    }

    private func pickerLabel(_ title: String, value: String, updating: Bool, _ p: MARCPalette) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundStyle(p.muted)
                Text(value).font(.footnote.weight(.medium)).foregroundStyle(p.text)
                    .lineLimit(dynamicType.isAccessibilitySize ? 2 : 1)
            }
            Spacer(minLength: 0)
            if updating {
                ProgressView().controlSize(.small).tint(p.accent)
            } else {
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(p.muted)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func nowPlayingCard(_ p: MARCPalette) -> some View {
        controlCard(p) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Now Playing").font(.caption.weight(.medium)).foregroundStyle(p.muted)
                    Spacer(minLength: 8)
                    Text(state?.nowPlaying?.source ??
                         (state?.mediaHelperInstalled == true ? "Automatic" : "Music / Spotify"))
                        .font(.caption2).foregroundStyle(p.muted).lineLimit(1)
                }
                if dynamicType.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 10) {
                        mediaDescription(p)
                        playbackControls(p)
                    }
                } else {
                    HStack(spacing: 8) {
                        mediaDescription(p)
                        playbackControls(p)
                    }
                }
                if state?.mediaHelperInstalled != true {
                    Button("Enable browser music") { showMediaSetup = true }
                        .font(.caption.weight(.medium)).tint(p.accent)
                        .frame(minHeight: 44, alignment: .leading)
                        .disabled(!usable)
                } else if state?.mediaError != nil {
                    Button("Playback details") { showMediaSetup = true }
                        .font(.caption).tint(p.accent)
                        .frame(minHeight: 44, alignment: .leading)
                }
            }
        }
    }

    private func mediaDescription(_ p: MARCPalette) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note")
                .font(.system(size: 21)).foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(LinearGradient(colors: [p.accent, .purple.opacity(0.7)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 11))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(state?.nowPlaying?.title ?? (state == nil ? "Checking playback…" :
                     (mediaAvailable ? (mediaPlayer == 1 ? "Spotify" : "Music") : "Nothing playing")))
                    .font(.subheadline.weight(.semibold)).foregroundStyle(p.text)
                    .lineLimit(2)
                Text(state?.nowPlaying?.artist ??
                     (state?.nowPlaying?.playing == true ? "Playing" :
                      (state?.nowPlaying?.playing == false ? "Paused" : "Playback on your Mac")))
                    .font(.caption).foregroundStyle(p.muted).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func playbackControls(_ p: MARCPalette) -> some View {
        HStack(spacing: 0) {
            playbackButton("Previous track", "backward.end.fill", .previousTrack, p)
            playbackButton("Play or pause",
                state?.nowPlaying?.playing == true ? "pause.fill" :
                    (state?.nowPlaying?.playing == false ? "play.fill" : "playpause.fill"), .playPause, p)
            playbackButton("Next track", "forward.end.fill", .nextTrack, p)
        }
        .fixedSize(horizontal: true, vertical: false)
    }



    private func playbackButton(
        _ title: String, _ symbol: String,
        _ action: MARCControlAction, _ p: MARCPalette
    ) -> some View {
        Button {
            send(action, value: playbackTarget)
        } label: {
            Group {
                if busy && feedbackAction == action {
                    ProgressView().controlSize(.small).tint(p.accent)
                } else {
                    Image(systemName: symbol)
                }
            }
                .font(.system(size: action == .playPause ? 22 : 16))
                .foregroundStyle(p.accent)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .disabled(!controlsEnabled || editingVolume || editingBrightness || !mediaAvailable ||
                  (action != .playPause && state?.nowPlaying?.prohibitsSkip == true))
        .accessibilityLabel(title)
    }

    private func connectionRow(
        _ title: String, symbol: String, enabled: Bool?,
        writable: Bool, action: MARCControlAction, palette p: MARCPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                controlIcon(symbol,
                            color: enabled == true ? (action == .wifi ? .green : .blue) : p.muted)
                Spacer(minLength: 0)
                if writable {
                    Toggle(title, isOn: Binding(
                        get: { enabled ?? false },
                        set: { desired in
                            if action == .wifi && !desired { confirmWiFiOff = true }
                            else { send(action, value: desired ? 1 : 0) }
                        }
                    ))
                    .labelsHidden()
                    .tint(action == .wifi ? Color.green : Color.blue)
                    .disabled(!controlsEnabled || editingVolume || editingBrightness)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(p.text)
            }

            if !writable {
                Text(enabled == nil ? wirelessPlaceholder : "Status only")
                    .font(.system(size: 11))
                    .foregroundStyle(p.muted)
                    .accessibilityLabel(enabled.map { $0 ? "On, status only" : "Off, status only" } ?? wirelessPlaceholder)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)
    }
    @MainActor
    private func accept(_ response: MARCControlState) {
        var merged = response
        if !response.wirelessIncluded, let previous = state {
            merged.wifiEnabled = previous.wifiEnabled
            merged.wifiInterface = previous.wifiInterface
            merged.wifiName = previous.wifiName
            merged.wifiError = previous.wifiError
            merged.bluetoothEnabled = previous.bluetoothEnabled
            merged.bluetoothWritable = previous.bluetoothWritable
            merged.bluetoothError = previous.bluetoothError
        }

        state = merged
        if merged.mediaHelperInstalled != true, !mediaAvailable, let first = merged.mediaPlayers?.first {
            mediaPlayer = first == "Spotify" ? 1 : 0
        }
        if let actualDisplay = response.selectedDisplayID {
            selectedDisplayID = actualDisplay
        } else if let displays = response.displays, let selected = selectedDisplayID,
                  !displays.contains(where: { $0.id == selected }) {
            selectedDisplayID = nil
        } else if selectedDisplayID == nil, let first = response.displays?.first {
            selectedDisplayID = first.id
        }
        if !editingVolume, let actual = response.volume { volume = Double(actual) }
        if !editingBrightness, let actual = response.brightness { brightness = Double(actual) }
        if response.wirelessIncluded { wirelessReadAt = ProcessInfo.processInfo.systemUptime }
    }
    @MainActor
    private func stopControlWork() {
        revision = UUID()
        actionTask?.cancel()
        actionTask = nil
        busy = false
        refreshing = false
        editingVolume = false
        editingBrightness = false
        feedbackAction = nil
        lastValue = nil
        failure = nil
        notice = nil
        confirmWiFiOff = false
        showControlDetails = false
        showMediaSetup = false
        copiedMediaCommand = false
        showQuickLaunch = false
        lastApplicationID = nil
    }
    @MainActor
    private func refresh(wireless: Bool) async {
        guard !Task.isCancelled, usable, !busy, !refreshing,
              !editingVolume, !editingBrightness else { return }
        refreshing = true
        let token = revision
        let connection = monitor.controlConnectionID
        let display = selectedDisplayID
        defer { if revision == token { refreshing = false } }
        do {
            let response = try await monitor.marcControlRequest(includeWireless: wireless,
                displayID: display, expectedConnection: connection)
            guard revision == token, usable, selectedDisplayID == display,
                  !busy, !editingVolume, !editingBrightness, !Task.isCancelled else { return }
            accept(response)
            if failure == "Live controls could not refresh. Tap Retry." { failure = nil }
        } catch is CancellationError {} catch {
            guard revision == token, usable, selectedDisplayID == display, !Task.isCancelled else { return }
            feedbackAction = nil
            failure = "Live controls could not refresh. Tap Retry."
        }
    }
    @MainActor
    private func send(_ action: MARCControlAction, value: Int, applicationID: String? = nil) {
        guard controlsEnabled else { return }
        let connection = monitor.controlConnectionID
        let display = selectedDisplayID
        // Avoid sending unchanged settings back to the Mac.
        switch action {
        case .volume: if state?.volume == value { return }
        case .brightness: if state?.brightness == value { return }
        case .mute: if state?.muted == (value == 1) { return }
        case .wifi: if state?.wifiEnabled == (value == 1) { return }
        case .bluetooth: if state?.bluetoothEnabled == (value == 1) { return }
        case .output: if state?.audioOutputID == value { return }
        case .launchApp:
            guard applicationID.map(MARCLaunchApplication.validID) ?? (MARCQuickLaunchApp(rawValue: value) != nil) else { return }
        case .read, .lock, .displaySleep, .displayWake, .playPause, .previousTrack, .nextTrack: break
        }
        busy = true
        feedbackAction = action
        lastValue = value
        lastApplicationID = applicationID
        failure = nil
        notice = nil
        revision = UUID()
        // User actions supersede background reads. Their old replies cannot own this flag.
        refreshing = false
        let token = revision
        actionTask = Task { @MainActor in
            defer { if revision == token { busy = false; actionTask = nil } }
            do {
                try Task.checkCancellation()
                guard revision == token, usable, selectedDisplayID == display,
                      controlConnection == connection else { throw CancellationError() }
                let response = try await monitor.marcControlRequest(action, value: value,
                    includeWireless: action == .wifi || action == .bluetooth,
                    displayID: display, expectedConnection: connection, applicationID: applicationID)
                guard revision == token, usable, selectedDisplayID == display, !Task.isCancelled else { return }
                accept(response)
                if let error = response.actionError {
                    failure = error
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    // Routine controls already update inline; only launches show a success toast.
                    if action == .launchApp {
                        notice = applicationID == nil ? "\(MARCQuickLaunchApp(rawValue: value)?.title ?? "App") launch requested" : "App launch requested"
                    }
                }
                if notice != nil { noticeEvent = UUID() }
            } catch is CancellationError {} catch {
                guard revision == token, usable, selectedDisplayID == display, !Task.isCancelled else { return }
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                if action == .wifi && value == 0 {
                    failure = "Could not confirm Wi-Fi off. The SSH connection may have stopped."
                } else { failure = "The Mac could not complete this request. Check the connection and try again." }
                if let actual = state?.volume { volume = Double(actual) }
                if let actual = state?.brightness { brightness = Double(actual) }
            }
        }
    }
}

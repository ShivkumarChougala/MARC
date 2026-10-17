import Foundation
import SwiftUI
import UIKit

struct ControlsScreen: View {
    // MARC control grid v2
    let monitor: SSHMonitor
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
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
    @State private var confirmLock = false
    @State private var showControlDetails = false
    @State private var showMediaSetup = false
    @State private var copiedMediaCommand = false
    @State private var showDisplayActions = false
    private var controlsEnabled: Bool { usable && !busy && !refreshing }

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
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(monitor.server?.name ?? "No connected Mac")
                            .font(.system(size: 21, weight: .semibold))
                        if let version = monitor.snapshot?.details?.osVersion {
                            Text("macOS " + version).font(.system(size: 12)).foregroundStyle(p.muted)
                        }
                    }
                    Spacer()
                }
                if !monitor.connected {
                    Text("Connect to a Mac in Settings to use these controls.")
                        .font(.system(size: 13)).foregroundStyle(p.muted)
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Quick Actions", p)
                    HStack(spacing: 10) {
                        quickButton("Lock Mac", "lock.fill", p) {
                            confirmLock = true
                        }
                        quickButton("Display", "display", p) {
                            showDisplayActions = true
                        }
                        quickButton("Play / pause", "playpause.fill", p,
                                    available: mediaAvailable) {
                            send(.playPause, value: playbackTarget)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Connections", p)

                    connectionRow(
                        "Wi-Fi", symbol: "wifi",
                        enabled: state?.wifiEnabled,
                        detail: state?.wifiName ?? "Mac wireless",
                        writable: state?.wifiEnabled != nil,
                        action: .wifi, palette: p
                    )

                    Divider().overlay(p.border)

                    connectionRow(
                        "Bluetooth",
                        symbol: "antenna.radiowaves.left.and.right",
                        enabled: state?.bluetoothEnabled,
                        detail:
                            (state?.bluetoothWritable == true ? "Mac Bluetooth" : "Status only"),
                        writable: state?.bluetoothWritable == true &&
                            state?.bluetoothEnabled != nil,
                        action: .bluetooth, palette: p
                    )

                }
                .padding(16)
                .background(p.surface, in: RoundedRectangle(cornerRadius: 20))

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Volume", p)

                        MARCVerticalControl(
                            value: $volume,
                            title: "Mac volume",
                            symbol: "speaker.wave.2.fill",
                            available: state?.volume != nil,
                            enabled: controlsEnabled && !editingBrightness,
                            palette: p
                        ) { editing in
                            editingVolume = editing
                            if !editing {
                                send(.volume, value: Int(volume.rounded()))
                            }
                        }

                        Text(state?.audioOutputName ?? "Audio output unavailable")
                            .font(.system(size: 12))
                            .foregroundStyle(p.muted)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Brightness", p)

                        MARCVerticalControl(
                            value: $brightness,
                            title: "Display brightness",
                            symbol: "sun.max.fill",
                            available: state?.brightness != nil,
                            enabled: controlsEnabled && !editingVolume,
                            palette: p
                        ) { editing in
                            editingBrightness = editing
                            if !editing {
                                send(.brightness, value: Int(brightness.rounded()))
                            }
                        }

                        Menu {
                            ForEach(state?.displays ?? []) { display in
                                Button {
                                    guard selectedDisplayID != display.id else { return }
                                    selectedDisplayID = display.id
                                    state?.brightness = nil
                                    feedbackAction = nil
                                    failure = nil
                                    notice = nil
                                    Task { await refresh(wireless: false) }
                                } label: {
                                    Text(display.name +
                                         (display.supported ? "" : " · Status only"))
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text(
                                    state?.displays?.first(where: {
                                        $0.id == selectedDisplayID
                                    })?.name ?? state?.displayName ?? "Choose display"
                                )
                                .lineLimit(2)

                                Spacer(minLength: 0)

                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9))
                            }
                            .font(.system(size: 12))
                            .foregroundStyle(p.accent)
                            .frame(minHeight: 36)
                        }
                        .disabled(
                            !controlsEnabled || editingBrightness ||
                            (state?.displays?.isEmpty ?? true)
                        )
                        .accessibilityLabel("Choose Mac display")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 20))
                }



                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "hifispeaker.fill")
                            .foregroundStyle(p.accent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Audio output")
                                .font(.system(size: 13))
                                .foregroundStyle(p.muted)

                            Menu {
                                ForEach(state?.outputs ?? []) { output in
                                    Button {
                                        send(.output, value: output.id)
                                    } label: {
                                        if output.id == state?.audioOutputID {
                                            Label(output.name, systemImage: "checkmark")
                                        } else {
                                            Text(output.name)
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(state?.audioOutputName ?? "Unavailable")
                                        .lineLimit(2)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10))
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(p.text)
                                .frame(minHeight: 44)
                            }
                            .disabled(
                                !controlsEnabled || (state?.outputs?.isEmpty ?? true)
                            )
                            .accessibilityLabel("Choose Mac audio output")
                        }

                        Spacer(minLength: 0)

                        Button {
                            send(.mute, value: state?.muted == true ? 0 : 1)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName:
                                    state?.muted == true ?
                                    "speaker.slash.fill" : "speaker.wave.2.fill"
                                )
                                Text(state?.muted == true ? "Unmute" : "Mute")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(state?.muted == true ? p.accent : p.text)
                            .frame(width: 64, height: 64)
                            .background(
                                p.accent.opacity(state?.muted == true ? 0.16 : 0.07),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!controlsEnabled || state?.muted == nil)
                        .accessibilityLabel(
                            state?.muted == true ? "Unmute Mac" : "Mute Mac"
                        )
                    }


                }
                .padding(16)
                .background(p.surface, in: RoundedRectangle(cornerRadius: 20))


                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        sectionTitle("Now Playing", p)
                        Spacer()
                        Text(state?.nowPlaying?.source ??
                             (state?.mediaHelperInstalled == true ? "Automatic" : "Music / Spotify"))
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                            .lineLimit(1)
                    }
                    if let playing = state?.nowPlaying {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(playing.title)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(2)
                            Text(playing.artist ?? (playing.playing == true ? "Playing" : "Paused"))
                                .font(.system(size: 12))
                                .foregroundStyle(p.muted)
                                .lineLimit(1)
                        }
                        .frame(height: 54, alignment: .topLeading)
                    } else {
                        Text(state?.mediaHelperInstalled == true ?
                             "Start playback on your Mac." :
                             "Open Music or Spotify, or enable browser music below.")
                            .font(.system(size: 12))
                            .foregroundStyle(p.muted)
                            .frame(height: 54, alignment: .topLeading)
                    }
                    HStack(spacing: 24) {
                        Spacer()
                        playbackButton("Previous track", "backward.end.fill", .previousTrack, p)
                        playbackButton("Play or pause",
                            state?.nowPlaying?.playing == true ? "pause.fill" :
                                (state?.nowPlaying?.playing == false ? "play.fill" : "playpause.fill"),
                            .playPause, p)
                        playbackButton("Next track", "forward.end.fill", .nextTrack, p)
                        Spacer()
                    }
                    if state?.mediaHelperInstalled != true {
                        Button("Enable browser music") { showMediaSetup = true }
                            .font(.system(size: 12, weight: .medium))
                            .tint(p.accent)
                            .disabled(!usable)
                    } else if state?.mediaError != nil {
                        Button("Playback details") { showMediaSetup = true }
                            .font(.system(size: 12))
                            .tint(p.accent)
                    }
                }
                .padding(16)
                .background(p.surface, in: RoundedRectangle(cornerRadius: 20))
            }.padding(16)
        }.scrollIndicators(.hidden).marcCanvas()
            .marcLiveReadings(enabled: usable && !editingVolume && !editingBrightness)
            .overlay { floatingFeedback(p) }
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
            }
            .alert("Control availability", isPresented: $showControlDetails) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(controlDetails)
            }
            .navigationTitle("Control Center").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Turn off the Mac’s Wi-Fi?", isPresented: $confirmWiFiOff,
                                titleVisibility: .visible) {
                Button("Turn off Wi-Fi", role: .destructive) { send(.wifi, value: 0) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("If this SSH connection uses Wi-Fi, it will disconnect. You may need to turn Wi-Fi back on at the Mac.")
            }

            .confirmationDialog(
                "Lock this Mac?", isPresented: $confirmLock,
                titleVisibility: .visible
            ) {
                Button("Lock Mac") { send(.lock, value: 0) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Lock the signed-in Mac session. Unlock it at the Mac when you return.")
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
                    }
                    .tint(p.accent)
                }
                .presentationDetents([.medium, .large])
            }
            .confirmationDialog("Display", isPresented: $showDisplayActions, titleVisibility: .visible) {
                Button("Display on") { send(.displayWake, value: 0) }
                Button("Display off") { send(.displaySleep, value: 0) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Display on wakes the screen. A locked Mac stays locked.")
            }

            .onAppear { visible = true }
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
        if busy || failure != nil || notice != nil {
            VStack(spacing: 12) {
                if busy {
                    ProgressView().tint(p.accent)
                    Text("Updating…")
                } else if let failure {
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
                                } else if action == .lock {
                                    confirmLock = true
                                } else {
                                    send(action, value: value)
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
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(p.text)
    }

    private func quickButton(
        _ title: String, _ symbol: String, _ p: MARCPalette,
        available: Bool = true, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(p.accent)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(p.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 88)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(!controlsEnabled || !available)
        .opacity(available ? 1 : 0.5)
    }

    private func playbackButton(
        _ title: String, _ symbol: String,
        _ action: MARCControlAction, _ p: MARCPalette
    ) -> some View {
        Button {
            send(action, value: playbackTarget)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: action == .playPause ? 25 : 20))
                .foregroundStyle(p.accent)
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
        .disabled(!controlsEnabled || !mediaAvailable ||
                  (action != .playPause && state?.nowPlaying?.prohibitsSkip == true))
        .accessibilityLabel(title)
    }

    private func connectionRow(
        _ title: String, symbol: String, enabled: Bool?, detail: String,
        writable: Bool, action: MARCControlAction, palette p: MARCPalette
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 19))
                .foregroundStyle(enabled == true ? p.accent : p.muted)
                .frame(width: 42, height: 42)
                .background(
                    p.accent.opacity(enabled == true ? 0.12 : 0.04),
                    in: RoundedRectangle(cornerRadius: 13)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(p.text)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(p.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            if writable {
                Toggle(title, isOn: Binding(
                    get: { enabled ?? false },
                    set: { desired in
                        if action == .wifi && !desired {
                            confirmWiFiOff = true
                        } else {
                            send(action, value: desired ? 1 : 0)
                        }
                    }
                ))
                .labelsHidden()
                .tint(p.accent)
                .disabled(!controlsEnabled)
            } else {
                Text(enabled.map { $0 ? "On" : "Off" } ?? "Unavailable")
                    .font(.system(size: 11))
                    .foregroundStyle(p.muted)
            }
        }
        .frame(minHeight: 48)
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
        confirmLock = false
        showDisplayActions = false
        showControlDetails = false
        showMediaSetup = false
        copiedMediaCommand = false
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
            if failure == "Live controls could not refresh. Tap refresh to retry." { failure = nil }
        } catch is CancellationError {} catch {
            guard revision == token, usable, selectedDisplayID == display, !Task.isCancelled else { return }
            feedbackAction = nil
            failure = "Live controls could not refresh. Tap refresh to retry."
        }
    }
    @MainActor
    private func send(_ action: MARCControlAction, value: Int) {
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
        case .read, .lock, .displaySleep, .displayWake, .playPause, .previousTrack, .nextTrack: break
        }
        busy = true
        feedbackAction = action
        lastValue = value
        failure = nil
        notice = nil
        revision = UUID()
        let token = revision
        actionTask = Task { @MainActor in
            defer { if revision == token { busy = false; actionTask = nil } }
            do {
                try Task.checkCancellation()
                guard revision == token, usable, selectedDisplayID == display,
                      controlConnection == connection else { throw CancellationError() }
                let response = try await monitor.marcControlRequest(action, value: value,
                    includeWireless: action == .wifi || action == .bluetooth,
                    displayID: display, expectedConnection: connection)
                guard revision == token, usable, selectedDisplayID == display, !Task.isCancelled else { return }
                accept(response)
                if let error = response.actionError {
                    failure = error
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    switch action {
                    case .volume: notice = "Volume set to \(response.volume ?? value)%"
                    case .mute: notice = value == 1 ? "Muted" : "Unmuted"
                    case .wifi: notice = value == 1 ? "Wi-Fi on" : "Wi-Fi off"
                    case .bluetooth: notice = value == 1 ? "Bluetooth on" : "Bluetooth off"
                    case .output: notice = "Output: " + (response.audioOutputName ?? "Updated")
                    case .brightness: notice = "Brightness set to \(response.brightness ?? value)%"

                    case .lock: notice = response.screenLocked == true ? "Mac locked" : "Lock requested"
                    case .displaySleep: notice = "Display-off requested"
                    case .displayWake: notice = "Display wake requested"
                    case .playPause, .previousTrack, .nextTrack:
                        notice = "Playback command sent"
                    case .read: break
                    }
                }
                noticeEvent = UUID()
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

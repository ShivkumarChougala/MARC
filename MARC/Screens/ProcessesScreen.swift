import Foundation
import SwiftUI

struct ProcessesScreen: View {
    let monitor: SSHMonitor
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @Binding var terminating: MARCProcessTarget?
    @State private var scrolling = false
    @State private var scrollOrder: [String] = []
    @State private var processConnection: UUID?
    @State private var sorting = "CPU"
    @State private var processes: [MARCProcess] = []
    @State private var failure: String?
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    private var currentConnection: Bool {
        monitor.connected && processConnection == monitor.processConnectionID
    }

    private var visible: [MARCProcess] {
        guard currentConnection else { return [] }
        return MARCProcessRows.visible(processes, query: query, sorting: sorting,
                                       frozenOrder: scrolling ? scrollOrder : [])
    }

    private func accept(_ result: [MARCProcess]) {
        guard result != processes else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            processes = result
        }
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        let rows = visible
        VStack(spacing: 0) {
            HStack {
                Text("Processes").font(.title3.weight(.semibold))
                Spacer(minLength: 8)
                MARCLiveNumberText(text: "\(monitor.connected ? monitor.processTotalCount : 0) total",
                                   value: Double(monitor.connected ? monitor.processTotalCount : 0))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(p.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let failure {
                        Text(failure)
                            .font(.system(size: 12))
                            .foregroundStyle(p.accent)
                            .padding(.vertical, 12)
                    }
                    if !monitor.connected {
                        Text("Connect to a Mac in Settings to view running processes.")
                            .font(.system(size: 13))
                            .foregroundStyle(p.muted)
                            .padding(.vertical, 12)
                    } else if !currentConnection || processes.isEmpty {
                        VStack(spacing: 4) {
                            if failure == nil { ProgressView().padding(.bottom, 6) }
                            Text(failure == nil ? "Loading processes…" : "Waiting for live process data…")
                        }
                        .frame(maxWidth: .infinity)
                            .font(.system(size: 13))
                            .foregroundStyle(p.muted)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(rows) { process in
                            Button {
                                guard currentConnection else { return }
                                searchFocused = false
                                terminating = MARCProcessTarget(process: process, connection: monitor.processConnectionID)
                            } label: {
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(process.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(p.text)
                                            .lineLimit(1)
                                        Text("\(process.pid) · \(process.user)")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(p.muted)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    MARCLiveNumberText(text: String(format: "%.1f%%", process.cpu), value: process.cpu)
                                        .foregroundStyle(Color(marcHex: 0x2dcc58))
                                        .frame(width: 52, alignment: .trailing)
                                    MARCLiveNumberText(text: ByteCountFormatter.string(
                                        fromByteCount: MARCProcessRows.memoryBytes(process.memory),
                                        countStyle: .binary
                                    ), value: process.memory)
                                    .foregroundStyle(p.text)
                                    .frame(width: 72, alignment: .trailing)
                                }
                                .font(.system(size: 11))
                                .monospacedDigit()
                                .padding(.vertical, 10)
                                .frame(minHeight: 56)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(p.border.opacity(0.5))
                                    .frame(height: 0.5)
                                    .allowsHitTesting(false)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityHint("Opens termination confirmation")
                        }
                        if rows.isEmpty {
                            Text("No matching processes.")
                                .font(.system(size: 12))
                                .foregroundStyle(p.muted)
                                .padding(.vertical, 12)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollClipDisabled()
            .scrollIndicators(.visible)
            .scrollDismissesKeyboard(.interactively)
            .marcListHeaderFade()
            .safeAreaInset(edge: .top, spacing: 0) {
                processControls(palette: p)
            }
            .onScrollPhaseChange { _, phase in
                if phase != .idle && !scrolling {
                    scrollOrder = visible.map(\.id)
                }
                scrolling = phase != .idle
                if !scrolling { scrollOrder = [] }
            }
        }
        .marcCanvas()
        .marcLiveReadings(enabled: currentConnection && !scrolling)
        .navigationTitle("Processes")
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: query) { _, _ in scrolling = false; scrollOrder = [] }
        .onChange(of: sorting) { _, _ in scrolling = false; scrollOrder = [] }
        .onDisappear {
            processConnection = nil
            terminating = nil
            scrolling = false
            scrollOrder = []
        }
        .task(id: "\(monitor.processConnectionID)-\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)") {
            guard !Task.isCancelled else { return }
            let connection = monitor.processConnectionID
            processConnection = connection
            terminating = nil
            scrolling = false
            processes = []
            scrollOrder = []
            failure = nil
            guard monitor.connected else { return }

            while !Task.isCancelled && monitor.connected && monitor.processConnectionID == connection {
                do {
                    let stream = try await monitor.processUpdates(expectedConnection: connection)
                    for try await response in stream {
                        guard !Task.isCancelled, monitor.connected,
                              monitor.processConnectionID == connection else { return }
                        accept(response.processes)
                        failure = nil
                    }
                    guard !Task.isCancelled, monitor.connected,
                          monitor.processConnectionID == connection else { return }
                    failure = "Process stream stopped. Retrying…"
                } catch is CancellationError {
                    return
                } catch {
                    guard !Task.isCancelled, monitor.connected,
                          monitor.processConnectionID == connection else { return }
                    failure = "Updates delayed. Reconnecting process stream…"
                }
                do {
                    try await Task.sleep(for: .seconds(3))
                } catch { return }
            }
        }
    }

    private func processControls(palette p: MARCPalette) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(p.muted)
                    TextField("Search processes", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                        .submitLabel(.done)
                        .onSubmit { searchFocused = false }
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(p.muted)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear process search")
                    }
                }
                .font(.system(size: 13))
                .padding(.leading, 12)
                .padding(.trailing, query.isEmpty ? 12 : 0)
                .frame(minHeight: 44)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(p.border.opacity(0.6), lineWidth: 0.5))
                Menu {
                    Picker("Sort processes", selection: $sorting) {
                        Text("CPU").tag("CPU")
                        Text("Memory").tag("Memory")
                        Text("Name").tag("Name")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(sorting)
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .medium))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(p.text)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(p.border.opacity(0.6), lineWidth: 0.5))
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Sort processes")
                .accessibilityValue(sorting)
            }
            HStack(spacing: 8) {
                Text("NAME / PID").frame(maxWidth: .infinity, alignment: .leading)
                Text("CPU").frame(width: 52, alignment: .trailing)
                Text("MEMORY").frame(width: 72, alignment: .trailing)
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(p.muted)
            .frame(minHeight: 28)
        }
        .padding(.horizontal, 16)
    }
}

struct MARCProcessConfirmation: View {
    let target: MARCProcessTarget
    let monitor: SSHMonitor
    let dismiss: () -> Void

    var body: some View {
        MARCTerminationSheet(process: target.process, terminate: {
            try await monitor.terminateProcess(target.process, expectedConnection: target.connection)
        }, dismiss: dismiss)
        .id(target.id)
    }
}

private struct MARCTerminationSheet: View {
    let process: MARCProcess
    let terminate: () async throws -> Void

    let dismiss: () -> Void
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @State private var busy = false
    @State private var failure: String?
    @State private var visible = false
    @State private var requestID = UUID()
    @State private var task: Task<Void, Never>?

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ZStack {
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { }
                .accessibilityHidden(true)
            ViewThatFits(in: .vertical) {
                confirmation(palette: p)
                ScrollView { confirmation(palette: p) }
            }
            .frame(maxWidth: 300)
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityAction(.escape) { if !busy { dismiss() } }
        .onAppear { visible = true }
        .onDisappear { stopTermination() }
    }

    private func confirmation(palette p: MARCPalette) -> some View {
        VStack(spacing: 12) {
            Text("Terminate process?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(p.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 5) {
                Text(process.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(p.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("PID \(process.pid) · \(process.user)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(p.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Unsaved work may be lost.")
                .font(.system(size: 12))
                .foregroundStyle(p.muted)
            if let failure {
                Text(failure)
                    .font(.system(size: 12))
                    .foregroundStyle(p.accent)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(p.raised, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(p.text)
                }
                .disabled(busy)
                Button(action: confirmTermination) {
                    HStack(spacing: 6) {
                        if busy { ProgressView().tint(.white) }
                        Text(busy ? "Terminating…" : "Terminate")
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(marcHex: 0xd84350), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .disabled(busy || process.pid <= 1 || process.started == nil)
            }
            .font(.system(size: 14, weight: .semibold))
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(p.border.opacity(0.6), lineWidth: 0.5))
    }

    @MainActor
    private func stopTermination() {
        visible = false
        requestID = UUID()
        task?.cancel()
        task = nil
        busy = false
    }

    @MainActor
    private func confirmTermination() {
        guard visible, !busy, process.pid > 1, process.started != nil else { return }
        busy = true
        failure = nil
        let request = UUID()
        requestID = request
        task = Task { @MainActor in
            defer { if requestID == request { busy = false; task = nil } }
            do {
                try Task.checkCancellation()
                guard visible, requestID == request else { throw CancellationError() }
                try await terminate()
                try Task.checkCancellation()
                guard visible, requestID == request else { return }
                dismiss()
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled, visible, requestID == request else { return }
                failure = error.localizedDescription
            }
        }
    }
}

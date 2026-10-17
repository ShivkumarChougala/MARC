import Foundation
import SwiftUI

struct ProcessesScreen: View {
    let monitor: SSHMonitor
    var onClose: (() -> Void)? = nil
    @State private var query = ""
    @State private var terminating: MARCProcessTarget?
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
        VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Group {
                        if let onClose {
                            Button(action: onClose) {
                                Label("Back", systemImage: "chevron.left")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(p.accent)
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Return to previous screen")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Processes")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(p.muted)
                        .lineLimit(1)
                        .layoutPriority(1)
                    MARCLiveNumberText(text: "\(monitor.connected ? monitor.processTotalCount : 0) total",
                                       value: Double(monitor.connected ? monitor.processTotalCount : 0))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(p.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(minHeight: 44)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(p.muted)
                    TextField("Search all processes", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(p.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .font(.system(size: 13))
                .padding(12)
                .background(p.surface, in: RoundedRectangle(cornerRadius: 14))

                Picker("Sort", selection: $sorting) {
                    Text("CPU").tag("CPU")
                    Text("Memory").tag("Memory")
                    Text("Name").tag("Name")
                }
                .pickerStyle(.segmented)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                if let failure {
                    Text(failure)
                        .font(.system(size: 12))
                        .foregroundStyle(p.accent)
                }
                if !monitor.connected {
                    Text("Connect to a Mac in Settings to view running processes.")
                        .font(.system(size: 13))
                        .foregroundStyle(p.muted)
                } else if !currentConnection || processes.isEmpty {
                    Text(failure == nil ? "Loading processes…" : "Waiting for live process data…")
                        .font(.system(size: 13))
                        .foregroundStyle(p.muted)
                } else {
                    HStack {
                        Text("PROCESS / PID")
                        Spacer()
                        Text("CPU").frame(width: 52, alignment: .trailing)
                        Text("MEMORY").frame(width: 72, alignment: .trailing)
                    }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(p.muted)
                    .padding(.horizontal, 12)

                    ForEach(rows) { process in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(process.name)
                                    .font(.system(size: 13, weight: .medium))
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
                            .frame(width: 72, alignment: .trailing)
                        }
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .padding(12)
                        .background(
                            p.surface, in: RoundedRectangle(cornerRadius: 12)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard currentConnection else { return }
                            terminating = MARCProcessTarget(process: process, connection: monitor.processConnectionID)
                        }
                        .accessibilityHint("Tap for termination confirmation")
                    }

                    if rows.isEmpty {
                        Text("No matching processes.")
                            .font(.system(size: 12))
                            .foregroundStyle(p.muted)
                    }


                }
                    }
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.visible)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .marcCanvas()
        .marcLiveReadings(enabled: currentConnection && !scrolling)
        .sheet(item: $terminating) { target in
            MARCTerminationSheet(process: target.process) {
                try await monitor.terminateProcess(target.process, expectedConnection: target.connection)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onScrollPhaseChange { _, phase in
            if phase != .idle && !scrolling {
                scrollOrder = visible.map(\.id)
            }
            scrolling = phase != .idle
            if !scrolling { scrollOrder = [] }
        }
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
}

private struct MARCTerminationSheet: View {
    let process: MARCProcess
    let terminate: () async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @State private var busy = false
    @State private var failure: String?
    @State private var visible = false
    @State private var requestID = UUID()
    @State private var task: Task<Void, Never>?

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 22))
                        .foregroundStyle(p.accent)
                        .frame(width: 44, height: 44)
                        .background(p.raised, in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(process.name)
                            .font(.system(size: 17, weight: .semibold))
                            .lineLimit(2)
                        Text("PID \(process.pid) · \(process.user)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(p.muted)
                            .lineLimit(1)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("CPU").foregroundStyle(p.muted)
                        Text(String(format: "%.1f%%", process.cpu))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Memory").foregroundStyle(p.muted)
                        Text(ByteCountFormatter.string(
                            fromByteCount: MARCProcessRows.memoryBytes(process.memory),
                            countStyle: .binary
                        ))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 12))
                .monospacedDigit()
                .padding(14)
                .background(p.surface, in: RoundedRectangle(cornerRadius: 14))

                Text("Terminate this process? Unsaved work may be lost.")
                    .font(.system(size: 12))
                    .foregroundStyle(p.muted)

                if let failure {
                    Text(failure)
                        .font(.system(size: 12))
                        .foregroundStyle(p.accent)
                }

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(p.raised, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(p.text)
                    }
                    .disabled(busy)

                    Button(action: confirmTermination) {
                        HStack(spacing: 8) {
                            if busy { ProgressView().tint(.white) }
                            Text(busy ? "Terminating…" : "Terminate")
                        }
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(
                            Color(marcHex: 0xd84350),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(busy || process.pid <= 1 || process.started == nil)
                }
                .font(.system(size: 14, weight: .semibold))
                .buttonStyle(.plain)
            }
            .padding(20)
            .padding(.top, 12)
        }
        .marcCanvas()
        .presentationDetents([.height(350), .medium])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(busy)
        .onAppear { visible = true }
        .onDisappear { stopTermination() }
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

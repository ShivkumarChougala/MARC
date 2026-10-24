import Foundation
import SwiftUI
import Observation
import UIKit

struct ProcessesScreen: View {
    let monitor: SSHMonitor
    @State private var query = ""
    @State private var headerMotion = MARCProcessHeaderMotion()
    @State private var searchFocused = false
    @Binding var terminating: MARCProcessTarget?
    @State private var scrolling = false
    @State private var scrollOrder: [String] = []
    @State private var processConnection: UUID?
    @Binding var sorting: String
    @State private var processes: [MARCProcess] = []
    @State private var failure: String?
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue

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
        GeometryReader { viewport in
            let topInset = viewport.safeAreaInsets.top
            let bottomInset = viewport.safeAreaInsets.bottom
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Keep scroll content geometry stable while the overlay changes size.
                        Color.clear.frame(height: (searchFocused || !query.isEmpty ? 44 : headerMotion.expandedHeight) + topInset)
                            .accessibilityHidden(true)
                        Group {
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
                                            MARCRollingNumberText(text: String(format: "%.1f%%", process.cpu), value: process.cpu)
                                                .foregroundStyle(Color(marcHex: 0x2dcc58))
                                                .frame(width: 52, alignment: .trailing)
                                            MARCRollingNumberText(text: ByteCountFormatter.string(
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
                    }
                    .padding(.bottom, 70 + bottomInset)
                }
                .scrollClipDisabled()
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    let distance = max(0, geometry.contentOffset.y + geometry.contentInsets.top)
                    let progress = min(1, max(0, (distance - 12) / 100))
                    return (progress * 120).rounded() / 120
                } action: { _, progress in
                    // Follow the gesture directly instead of queuing time-based animations.
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { headerMotion.progress = progress }
                }
                .scrollIndicators(.visible)
                .scrollDismissesKeyboard(.interactively)
                .onScrollPhaseChange { _, phase in
                    if phase != .idle && !scrolling {
                        scrollOrder = visible.map(\.id)
                    }
                    scrolling = phase != .idle
                    if !scrolling { scrollOrder = [] }
                }
                .ignoresSafeArea(.container, edges: [.top, .bottom])
                .frame(height: viewport.size.height + topInset + bottomInset)
                .offset(y: -topInset)

                MARCProcessHeader(motion: headerMotion, query: $query,
                                  sorting: $sorting, searchFocused: $searchFocused,
                                  count: monitor.connected ? monitor.processTotalCount : 0,
                                  palette: p)
            }
            .frame(width: viewport.size.width, height: viewport.size.height, alignment: .top)
        }
        .marcCanvas()
        .marcLearnOverlay(.processes, enabled: currentConnection && !processes.isEmpty &&
            !searchFocused && !scrolling && terminating == nil)
        .navigationTitle("Processes")
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: query) { _, _ in scrolling = false; scrollOrder = [] }
        .onChange(of: sorting) { _, _ in scrolling = false; scrollOrder = [] }
        .onDisappear {
            headerMotion.progress = 0
            searchFocused = false
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

// Per-pixel scrolling updates this model, observed only by the small header view.
// The process screen reads expandedHeight, not progress, so it does not re-sort
// process rows on every intermediate header frame.
@MainActor @Observable
private final class MARCProcessHeaderMotion {
    var progress: CGFloat = 0
    var expandedHeight: CGFloat = 144
}

private struct MARCProcessHeader: View {
    let motion: MARCProcessHeaderMotion
    @Binding var query: String
    @Binding var sorting: String
    @Binding var searchFocused: Bool
    let count: Int
    let palette: MARCPalette
    @FocusState private var fieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title3) private var headerTitleSize: CGFloat = 20

    var body: some View {
        let p = palette
        let raw = motion.progress
        // Smooth endpoints without delayed animations chasing the gesture.
        let progress = reduceMotion ? (raw >= 0.5 ? 1.0 : 0.0) : raw * raw * (3 - 2 * raw)
        let searching = fieldFocused || !query.isEmpty
        let expanded = searching ? 0 : 1 - progress
        let titleProgress = searching ? 0 : progress
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Processes")
                    .font(.system(size: headerTitleSize, weight: .semibold))
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                MARCRollingNumberText(text: "\(count) total", value: Double(count))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(p.muted)
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .opacity(Double(expanded)).accessibilityHidden(searching || progress >= 0.5)
            }
            .frame(height: 32 * expanded, alignment: .top)
            .clipped()
            .opacity(Double(expanded))
            .accessibilityHidden(searching || progress >= 0.5)
            HStack(spacing: 0) {
                Text("Processes")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1).minimumScaleFactor(0.75)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(width: 86 * titleProgress, alignment: .leading)
                    .clipped()
                    .opacity(Double(titleProgress))
                    .accessibilityHidden(searching || progress < 0.5)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.trailing, 8 * titleProgress)
                processSearchField(palette: p, compact: searching || progress > 0.5)
                    .padding(.trailing, 8)
                processSortMenu(palette: p)
            }
            .padding(.vertical, 2 * expanded)
            processColumnLabels(palette: p)
                .frame(height: 22 * expanded, alignment: .top)
                .clipped()
                .opacity(Double(expanded))
                .accessibilityHidden(searching || progress >= 0.5)
        }
        .padding(.horizontal, 16)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { height in
            guard !searching, height > 0 else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                if progress == 0, abs(height - motion.expandedHeight) > 0.5 {
                    motion.expandedHeight = height
                }
            }
        }
        // The blur is inside the header only; exposed process rows remain sharp.
        .background {
            MARCProcessScrollUnderSurface(palette: p)
                .mask(LinearGradient(stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.72),
                    .init(color: .black.opacity(0.5), location: 0.88),
                    .init(color: .clear, location: 1)
                ], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea(.container, edges: .top)
        }
        .onChange(of: searchFocused) { _, focused in fieldFocused = focused }
        .onChange(of: fieldFocused) { _, focused in searchFocused = focused }
    }

    private func processSearchField(palette p: MARCPalette, compact: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(p.muted)
            TextField(compact ? "Search" : "Search processes", text: $query)
                .accessibilityLabel("Search processes")
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(minHeight: 44)
                .focused($fieldFocused)
                .submitLabel(.search)
                .onSubmit { fieldFocused = false }
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
        .font(.system(size: 14))
        .padding(.leading, 11)
        .padding(.trailing, query.isEmpty ? 11 : 0)
        .frame(minHeight: 44)
        .background { Capsule().fill(p.raised).frame(height: 38) }
        .overlay { Capsule().stroke(p.border.opacity(0.6), lineWidth: 0.5).frame(height: 38) }
        .contentShape(Rectangle())
    }

    private func processSortMenu(palette p: MARCPalette) -> some View {
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
            .padding(.horizontal, 11)
            .frame(minHeight: 44)
            .background { Capsule().fill(p.raised).frame(height: 38) }
            .overlay { Capsule().stroke(p.border.opacity(0.6), lineWidth: 0.5).frame(height: 38) }
            .contentShape(Rectangle())
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Sort processes")
        .accessibilityValue(sorting)
        .marcLearnTarget(.processes)
    }

    private func processColumnLabels(palette p: MARCPalette) -> some View {
        HStack(spacing: 8) {
            Text("NAME / PID").frame(maxWidth: .infinity, alignment: .leading)
            Text("CPU").frame(width: 52, alignment: .trailing)
            Text("MEMORY").frame(width: 72, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(p.muted)
        .frame(minHeight: 22)
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
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue
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
            MARCFirstUseTip(key: "process-review", message: "Check the name and PID above. Cancel leaves this process running.")
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

// Backdrop for the Processes header only. No duplicate list or data stream.
private struct MARCProcessScrollUnderSurface: View {
    let palette: MARCPalette

    var body: some View {
        MARCProcessUnderlayBlur(dark: palette.dark)
            .overlay(palette.background.opacity(0.35))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct MARCProcessUnderlayBlur: UIViewRepresentable {
    let dark: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    final class Coordinator {
        var animator: UIViewPropertyAnimator?
        var dark: Bool?
        var reduced: Bool?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        let state = context.coordinator
        guard state.dark != dark || state.reduced != reduceTransparency else { return }
        state.animator?.stopAnimation(true)
        state.animator = nil
        view.effect = nil
        view.backgroundColor = .clear
        state.dark = dark
        state.reduced = reduceTransparency
        if reduceTransparency {
            view.backgroundColor = UIColor(MARCPalette(dark: dark).background)
        } else {
            // A paused animator gives a light native backdrop blur, without the
            // full-strength material slab or a duplicated process-list snapshot.
            let effect = UIBlurEffect(style: dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
            let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                view.effect = effect
            }
            animator.fractionComplete = 0.18
            state.animator = animator
        }
    }

    static func dismantleUIView(_ view: UIVisualEffectView, coordinator: Coordinator) {
        coordinator.animator?.stopAnimation(true)
        coordinator.animator = nil
        view.effect = nil
    }
}

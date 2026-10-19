
import SwiftUI
import UIKit
import Observation
import Citadel
import NIOCore
@preconcurrency import NIOSSH
@preconcurrency import SwiftTerm

@MainActor
@Observable
final class MARCTerminalSession {
    private(set) var aiServerID: UUID?
    var controlArmed = false
    var altArmed = false

    func sendKeyboard(_ bytes: [UInt8]) {
        guard ready, !bytes.isEmpty else { return }
        let output = MARCTerminalInput.modified(bytes, control: controlArmed, alt: altArmed)
        controlArmed = false
        altArmed = false
        send(output)
    }
    @ObservationIgnored private var marcClearSequenceTail = ""
    @ObservationIgnored private var marcInputLine = ""
    @ObservationIgnored private var marcInputLineKnown = true
    var status = "Offline"
    var failure: String?
    var ready = false

    @ObservationIgnored var view: SwiftTerm.TerminalView?
    @ObservationIgnored private var client: SSHClient?
    @ObservationIgnored private var writer: TTYStdinWriter?
    @ObservationIgnored private var token = UUID()
    @ObservationIgnored private var writes: Task<Void, Never>?
    @ObservationIgnored private var resizing: Task<Void, Never>?
    @ObservationIgnored private var cols = 80
    @ObservationIgnored private var rows = 24

    func receive(_ bytes: [UInt8]) {
        guard let view else { return }

        let sequence = marcClearSequenceTail +
            String(decoding: bytes, as: UTF8.self)
        let cleared = sequence.contains("\u{1B}[2J") ||
            sequence.contains("\u{1B}[3J")
        marcClearSequenceTail = String(sequence.suffix(8))

        view.feed(byteArray: bytes[...])

        if cleared {
            let connection = token
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view,
                      self.token == connection else { return }
                view.layoutIfNeeded()
                view.scroll(toPosition: 1)
                view.setNeedsDisplay()
            }
        }
    }

    func run(server: ServerProfile) async {
        guard !Task.isCancelled else { return }
        aiServerID = server.id
        let current = UUID()
        token = current
        marcInputLine = ""
        marcInputLineKnown = true
        marcClearSequenceTail = ""
        ready = false
        controlArmed = false
        altArmed = false
        failure = nil
        status = "Connecting"
        var opened: SSHClient?

        do {
            guard let saved = MARCCredentials.read(server.id) else {
                throw NSError(
                    domain: "MARC", code: 1,
                    userInfo: [NSLocalizedDescriptionKey:
                        "Connect to this server in Settings first."]
                )
            }

            let validator = try SSHConnectionTest.hostKeyValidator(server: server, publicHostKey: saved.hostKey)
            let username = server.username
            let authentication = try MARCLogin.authentication(saved, username: username)
            var settings = SSHClientSettings(
                host: server.host,
                port: server.port,
                authenticationMethod: authentication,
                hostKeyValidator: validator
            )
            settings.connectTimeout = .seconds(10)

            let connection = try await SSHClient.connect(to: settings)
            opened = connection
            guard token == current, !Task.isCancelled else {
                throw CancellationError()
            }
            client = connection

            let request = SSHChannelRequestEvent.PseudoTerminalRequest(
                wantReply: true,
                term: "xterm-256color",
                terminalCharacterWidth: cols,
                terminalRowHeight: rows,
                terminalPixelWidth: 0,
                terminalPixelHeight: 0,
                terminalModes: SSHTerminalModes([:])
            )

            try await connection.withPTY(request) { inbound, outbound in
                guard self.token == current, !Task.isCancelled else {
                    throw CancellationError()
                }

                self.writer = outbound
                self.ready = true
                self.status = "Connected"
                try await outbound.changeSize(
                    cols: self.cols, rows: self.rows,
                    pixelWidth: 0, pixelHeight: 0
                )

                for try await event in inbound {
                    guard self.token == current, !Task.isCancelled else {
                        throw CancellationError()
                    }
                    switch event {
                    case .stdout(let buffer), .stderr(let buffer):
                        self.receive(Array(buffer.readableBytesView))
                    }
                }
            }

            if token == current {
                status = "Session ended"
            }
        } catch {
            if token == current, !Task.isCancelled,
               !(error is CancellationError) {
                failure = MARCConnectionIssue.message(error, login: MARCCredentials.read(server.id))
                status = "Disconnected"
            }
        }

        if token == current {
            ready = false
            writer = nil
            client = nil
            writes?.cancel()
            writes = nil
            resizing?.cancel()
            resizing = nil
            controlArmed = false
            altArmed = false
        }
        if let opened {
            try? await opened.close()
        }
    }

    func stop() {
        aiServerID = nil
        token = UUID()
        ready = false
        controlArmed = false
        altArmed = false
        writer = nil
        resizing?.cancel()
        resizing = nil
        writes?.cancel()
        writes = nil
        let previous = client
        client = nil
        status = "Offline"
        if let previous {
            Task { try? await previous.close() }
        }
    }

    func send(_ bytes: [UInt8]) {
        guard ready, let writer, !bytes.isEmpty else { return }
        let outgoing = marcPrepareInput(bytes)
        let current = token
        let previous = writes
        writes = Task { @MainActor [weak self] in
            await previous?.value
            guard !Task.isCancelled, let self,
                  self.token == current else { return }
            do {
                var buffer = ByteBuffer()
                buffer.writeBytes(outgoing)
                try await writer.write(buffer)
            } catch {
                guard self.token == current else { return }
                self.failure = error.localizedDescription
                self.stop()
            }
        }
    }


    private func marcPrepareInput(_ bytes: [UInt8]) -> [UInt8] {
        var result: [UInt8] = []

        for byte in bytes {
            if byte == 13 || byte == 10 {
                if marcInputLineKnown &&
                    marcInputLine.trimmingCharacters(in: .whitespaces) == "clear" {
                    // Replace the submitted input line, then execute the
                    // explicit screen + scrollback + cursor-home sequence.
                    result.append(21)
                    result.append(contentsOf: Array(
                        "printf '\\033[2J\\033[3J\\033[H'".utf8
                    ))
                }

                result.append(byte)
                marcInputLine = ""
                marcInputLineKnown = true
                continue
            }

            result.append(byte)

            switch byte {
            case 3, 21:
                marcInputLine = ""
                marcInputLineKnown = true
            case 8, 127:
                if marcInputLineKnown && !marcInputLine.isEmpty {
                    marcInputLine.removeLast()
                }
            case 32...126:
                if marcInputLineKnown {
                    marcInputLine.append(Character(UnicodeScalar(byte)))
                    if marcInputLine.count > 128 {
                        marcInputLineKnown = false
                    }
                }
            default:
                marcInputLineKnown = false
            }
        }

        return result
    }

    func resize(cols: Int, rows: Int) {
        guard cols > 0, rows > 0 else { return }
        guard self.cols != cols || self.rows != rows else { return }
        self.cols = cols
        self.rows = rows
        guard let writer, resizing == nil else { return }
        let current = token
        resizing = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { if self.token == current { self.resizing = nil } }
            while !Task.isCancelled && self.token == current {
                let latestCols = self.cols
                let latestRows = self.rows
                do {
                    try await writer.changeSize(cols: latestCols, rows: latestRows,
                                                pixelWidth: 0, pixelHeight: 0)
                } catch {
                    if self.token == current, !Task.isCancelled {
                        self.failure = error.localizedDescription
                    }
                    return
                }
                guard self.cols != latestCols || self.rows != latestRows else { return }
            }
        }
    }

}

struct MARCTerminalSurface: UIViewRepresentable {
    let session: MARCTerminalSession
    let dark: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeUIView(context: Context) -> SwiftTerm.TerminalView {
        let view = session.view ?? MARCScrollbackTerminalView(frame: .zero)
        // The SwiftUI scrolling strip owns terminal shortcuts.
        view.inputAccessoryView = nil
        view.isOpaque = false
        view.contentMode = .redraw
        view.layer.shouldRasterize = false
        view.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        view.terminalDelegate = context.coordinator
        session.view = view
        applyTheme(view)
        view.setContentCompressionResistancePriority(
            .defaultLow, for: .vertical
        )
        view.setContentHuggingPriority(
            .defaultLow, for: .vertical
        )
        return view
    }

    func updateUIView(
        _ view: SwiftTerm.TerminalView, context: Context
    ) {
        applyTheme(view)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: SwiftTerm.TerminalView,
        context: Context
    ) -> CGSize? {
        CGSize(
            width: max(0, proposal.width ?? 0),
            height: max(0, proposal.height ?? 0)
        )
    }

    private func applyTheme(_ view: SwiftTerm.TerminalView) {
        let background = dark
            ? UIColor(red: 17/255, green: 17/255, blue: 19/255, alpha: 1)
            : UIColor(red: 245/255, green: 245/255, blue: 247/255, alpha: 1)
        let foreground = dark
            ? UIColor(white: 0.93, alpha: 1)
            : UIColor(white: 0.13, alpha: 1)
        // Colour setters invalidate SwiftTerm's render caches. Ordinary SwiftUI
        // updates must not repeatedly invalidate an unchanged terminal palette.
        if !view.nativeBackgroundColor.isEqual(background) {
            view.nativeBackgroundColor = background
            view.setNeedsDisplay(view.bounds)
        }
        if !view.nativeForegroundColor.isEqual(foreground) {
            view.nativeForegroundColor = foreground
        }
    }

    static func dismantleUIView(
        _ view: SwiftTerm.TerminalView, coordinator: Coordinator
    ) {
        _ = view.resignFirstResponder()
        view.terminalDelegate = nil
        // Workspace owns the shell and retained screen buffer.
        // Removing the visible view must not terminate that shell.
    }

    final class Coordinator: NSObject, TerminalViewDelegate {
        let session: MARCTerminalSession
        init(session: MARCTerminalSession) {
            self.session = session
        }

        func send(source: SwiftTerm.TerminalView, data: ArraySlice<UInt8>) {
            session.sendKeyboard(Array(data))
        }
        func sizeChanged(
            source: SwiftTerm.TerminalView, newCols: Int, newRows: Int
        ) {
            session.resize(cols: newCols, rows: newRows)
        }
        func setTerminalTitle(source: SwiftTerm.TerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(
            source: SwiftTerm.TerminalView, directory: String?
        ) {}
        func scrolled(source: SwiftTerm.TerminalView, position: Double) {}
        func rangeChanged(
            source: SwiftTerm.TerminalView, startY: Int, endY: Int
        ) {}
        func requestOpenLink(
            source: SwiftTerm.TerminalView,
            link: String, params: [String: String]
        ) {}
        func clipboardCopy(
            source: SwiftTerm.TerminalView, content: Data
        ) {
            // Remote output does not automatically overwrite the clipboard.
        }
    }
}


// CG drawing reads SwiftTerm's prepared snapshot, not the live terminal buffer.
// Refresh that snapshot when UIKit scrolls, rather than repainting stale rows.
private final class MARCScrollbackTerminalView: SwiftTerm.TerminalView {
    private var synchronizingViewport = false
    private var lastMomentumRow: Int?

    override var contentOffset: CGPoint {
        didSet {
            guard contentOffset != oldValue, !synchronizingViewport else { return }

            // SwiftTerm tracks finger-down scrolling itself. During momentum,
            // keep its buffer viewport aligned with UIKit using the public API.
            // Leave programmatic offsets and alternate screens to SwiftTerm.
            if isDecelerating && !isTracking {
                let rows = terminalDimensions.rows
                let gridHeight = getOptimalFrameSize().height
                if rows > 0, gridHeight > 0, contentSize.height > gridHeight {
                    let cellHeight = gridHeight / CGFloat(rows)
                    let maximum = max(0, contentSize.height - bounds.height + adjustedContentInset.bottom)
                    let offsetY = min(max(contentOffset.y, 0), maximum)
                    let row = Int(floor(offsetY / cellHeight))
                    if row != lastMomentumRow {
                        synchronizingViewport = true
                        // SwiftTerm's scroller leaves the physical offset alone
                        // while decelerating, until it reaches the live bottom.
                        scrollTo(row: row, notifyAccessibility: false)
                        synchronizingViewport = false
                        lastMomentumRow = row
                    }
                }
            } else {
                lastMomentumRow = nil
            }
            // setNeedsDisplay alone draws the previous prepared snapshot.
            // SwiftTerm coalesces this signal through its frame driver.
            requestRedraw()
        }
    }
}

@MainActor @Observable
final class MARCTerminalSlot: Identifiable {
    let id = UUID()
    let number: Int
    let session = MARCTerminalSession()
    @ObservationIgnored var task: Task<Void, Never>?

    init(number: Int) { self.number = number }
}

@MainActor @Observable
final class MARCTerminalWorkspace {
    var slots: [MARCTerminalSlot] = []
    var selectedID: UUID?
    var pendingDirectoryCommand: String?

    func stageDirectory(_ path: String) -> Bool {
        guard let command = MARCFileFormatting.shellDirectoryCommand(path) else { return false }
        pendingDirectoryCommand = command
        return true
    }

    private var server: ServerProfile?
    private var nextNumber = 1

    var selected: MARCTerminalSlot? {
        slots.first { $0.id == selectedID } ?? slots.first
    }

    func prepare(server: ServerProfile) {
        clearIfDifferent(server.id)
        self.server = server
        if slots.isEmpty {
            add()
        } else {
            for slot in slots where slot.task == nil {
                start(slot)
            }
        }
    }

    func add() {
        guard server != nil else { return }
        _ = selected?.session.view?.resignFirstResponder()
        let slot = MARCTerminalSlot(number: nextNumber)
        nextNumber += 1
        slots.append(slot)
        selectedID = slot.id
        start(slot)
    }

    func select(_ slot: MARCTerminalSlot) {
        _ = selected?.session.view?.resignFirstResponder()
        selectedID = slot.id
    }

    func reconnectSelected() {
        guard let slot = selected else { return }
        _ = slot.session.view?.resignFirstResponder()
        slot.task?.cancel()
        slot.task = nil
        slot.session.stop()
        start(slot)
    }

    func close(_ slot: MARCTerminalSlot) {
        _ = slot.session.view?.resignFirstResponder()
        slot.task?.cancel()
        slot.task = nil
        slot.session.stop()
        slots.removeAll { $0.id == slot.id }
        if selectedID == slot.id {
            selectedID = slots.last?.id
        }
    }

    func pause() {
        for slot in slots {
            _ = slot.session.view?.resignFirstResponder()
            slot.task?.cancel()
            slot.task = nil
            slot.session.stop()
        }
    }

    func clearIfDifferent(_ id: UUID?) {
        guard let old = server?.id, old != id else { return }
        pause()
        slots.removeAll()
        selectedID = nil
        server = nil
        pendingDirectoryCommand = nil
        nextNumber = 1
    }

    private func start(_ slot: MARCTerminalSlot) {
        guard let server else { return }
        let session = slot.session
        slot.task = Task { @MainActor in
            await session.run(server: server)
        }
    }
}

struct TerminalScreen: View {
    let monitor: SSHMonitor
    let workspace: MARCTerminalWorkspace
    let navigate: (Int) -> Void
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingSessions = false
    @State private var aiFocused = false

    private var connectionID: String {
        "\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)-\(scenePhase == .active)"
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        GeometryReader { geometry in
            VStack(spacing: 0) {
            HStack {
                Button { navigate(-1) } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(p.accent).frame(minHeight: 44)
                }.buttonStyle(.plain)
                    .accessibilityLabel("Return to previous screen")
                Spacer()
                Text("Terminal").font(.system(size: 13, weight: .medium)).foregroundStyle(p.muted)
            }
            .padding(.horizontal, 12)
            .background(p.background)
            ZStack {
                ForEach(workspace.slots) { slot in
                    MARCTerminalSurface(
                        session: slot.session, dark: scheme == .dark
                    )
                    .opacity(workspace.selected?.id == slot.id ? 1 : 0)
                    .allowsHitTesting(workspace.selected?.id == slot.id)
                    .accessibilityHidden(workspace.selected?.id != slot.id)
                    .zIndex(workspace.selected?.id == slot.id ? 1 : 0)
                }

                if let session = workspace.selected?.session, session.status == "Connecting" {
                    MARCActivityCard(title: "Connecting to Terminal")
                        .zIndex(3)
                }
                if workspace.slots.isEmpty {
                    Text(monitor.connected
                         ? "Tap + to open a shell"
                         : "Connect a Mac in Settings")
                        .font(.system(size: 13))
                        .foregroundStyle(p.muted)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .frame(
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity
            )
            .clipped()
            .layoutPriority(-1)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button {
                        guard let session = workspace.selected?.session,
                              session.ready else { return }
                        guard let copied = UIPasteboard.general.string else {
                            session.failure = "The clipboard has no text."
                            return
                        }

                        let value = copied.trimmingCharacters(in: .newlines)
                        guard !value.isEmpty else { return }
                        guard !value.unicodeScalars.contains(where: {
                            $0.value < 32 || $0.value == 127 ||
                            (0x80...0x9f).contains($0.value) ||
                            $0.value == 0x2028 || $0.value == 0x2029
                        }) else {
                            session.failure = "Paste one command line at a time."
                            return
                        }

                        session.failure = nil
                        session.send(Array(value.utf8))
                    } label: {
                        Image(systemName: "document.on.clipboard")
                            .frame(width: 40, height: 40)
                            .background(
                                p.raised,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                    }
                    .disabled(workspace.selected?.session.ready != true)
                    .accessibilityLabel("Paste command into terminal")


                    Button {
                        _ = workspace.selected?.session.view?.resignFirstResponder()
                        showingSessions = true
                    } label: {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(monitor.server?.name ?? "Terminal")
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                                Text(workspace.selected.map {
                                    "Session \($0.number) · \($0.session.status)"
                                } ?? "No shell")
                                .font(.system(size: 10))
                                .foregroundStyle(p.muted)
                                .lineLimit(1)
                            }
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            p.accent.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .contentShape(Rectangle())
                    }

                    Button {
                        workspace.reconnectSelected()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 40, height: 40)
                            .background(p.raised, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!monitor.connected || workspace.selected == nil)
                    .accessibilityLabel("Reconnect current session")

                    Button {
                        workspace.add()
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 40, height: 40)
                            .background(p.raised, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!monitor.connected)
                    .accessibilityLabel("New terminal session")
                }
                .buttonStyle(.plain)
                .foregroundStyle(p.accent)

                if let slot = workspace.selected {
                    MARCTerminalAI(session: slot.session, focusChanged: { aiFocused = $0 })
                        .id(slot.id)
                    if !aiFocused {
                        MARCTerminalKeyStrip(session: slot.session)
                    }

                    if let failure = slot.session.failure {
                        Text(failure)
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .top
            )
        }

        .marcCanvas()
        .toolbar(.hidden, for: .navigationBar)
        .task(id: connectionID) {
            guard scenePhase == .active, monitor.connected,
                  let server = monitor.server else {
                workspace.pause()
                return
            }
            workspace.prepare(server: server)
        }
        .sheet(isPresented: $showingSessions) {
            sessionPicker
        }
        .alert("Show location in Terminal", isPresented: Binding(
            get: { workspace.pendingDirectoryCommand != nil && workspace.selected?.session.ready == true },
            set: { if !$0 { workspace.pendingDirectoryCommand = nil } }
        )) {
            Button("Insert at prompt") {
                if let command = workspace.pendingDirectoryCommand {
                    workspace.selected?.session.send(Array(command.utf8))
                }
                workspace.pendingDirectoryCommand = nil
                _ = workspace.selected?.session.view?.becomeFirstResponder()
            }
            Button("Cancel", role: .cancel) { workspace.pendingDirectoryCommand = nil }
        } message: {
            Text((workspace.pendingDirectoryCommand ?? "") + "\n\nMake sure the shell is at an empty prompt. This inserts the command without running it.")
        }
    }

    private var sessionPicker: some View {
        let p = MARCPalette(dark: scheme == .dark)
        return VStack(spacing: 0) {
            HStack {
                Text("Terminal sessions")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button("Done") { showingSessions = false }
                    .foregroundStyle(p.accent)
            }
            .padding(20)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(workspace.slots) { slot in
                        HStack(spacing: 10) {
                            Button {
                                workspace.select(slot)
                                showingSessions = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Session \(slot.number)")
                                            .font(.system(size: 14, weight: .medium))
                                        Text(slot.session.status)
                                            .font(.system(size: 11))
                                            .foregroundStyle(p.muted)
                                    }
                                    Spacer()
                                    if workspace.selected?.id == slot.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(p.accent)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                workspace.close(slot)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(p.muted)
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("Close session \(slot.number)")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(p.surface, in: RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        workspace.add()
                        showingSessions = false
                    } label: {
                        Label("New session", systemImage: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(p.accent)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(p.surface, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(!monitor.connected)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .foregroundStyle(p.text)
        .marcCanvas()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

extension MARCTerminalSession {
    func localAI(body: Data) async throws -> Data {
        try Task.checkCancellation()
        guard ready, let client else {
            throw MARCAIError.message("Connect the terminal first.")
        }
        let current = token
        let encoded = body.base64EncodedString()
        let command = """
        python3 - <<'MARC_AI'
        import base64, json, urllib.request
        body = base64.b64decode('\(encoded)')
        try:
            request = urllib.request.Request(
                'http://127.0.0.1:11434/api/chat',
                data=body,
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            with urllib.request.urlopen(request, timeout=120) as response:
                data = response.read(262145)
            if len(data) > 262144:
                raise ValueError('AI response too large')
            print(data.decode('utf-8'))
        except Exception:
            print(json.dumps({'error':
                'Local AI request failed. Check Ollama is running and the model is installed on this Mac.'}))
        MARC_AI
        """
        let output = try await client.executeCommand(
            command, maxResponseSize: 262144, mergeStreams: false
        )
        guard token == current, !Task.isCancelled else {
            throw CancellationError()
        }
        return Data(output.readableBytesView)
    }
}

enum MARCAIError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let text): return text }
    }
}

extension MARCTerminalSession {
    var aiConnectionID: UUID { token }
}

@MainActor
struct MARCKeyboardContainer<Content: View>: UIViewControllerRepresentable {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> Controller {
        Controller(content: content)
    }

    func updateUIViewController(
        _ controller: Controller, context: Context
    ) {
        controller.host.rootView = AnyView(
            content.ignoresSafeArea(.keyboard, edges: .bottom)
        )
    }

    final class Controller: UIViewController {
        let host: UIHostingController<AnyView>

        init(content: Content) {
            host = UIHostingController(
                rootView: AnyView(
                    content.ignoresSafeArea(.keyboard, edges: .bottom)
                )
            )
            super.init(nibName: nil, bundle: nil)
            host.safeAreaRegions = [.container]
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            let terminalBackground = UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 17/255, green: 17/255, blue: 19/255, alpha: 1)
                    : UIColor(red: 245/255, green: 245/255, blue: 247/255, alpha: 1)
            }
            view.backgroundColor = terminalBackground
            host.view.backgroundColor = terminalBackground

            addChild(host)
            view.addSubview(host.view)
            host.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                host.view.bottomAnchor.constraint(
                    equalTo: view.keyboardLayoutGuide.topAnchor
                )
            ])

            host.didMove(toParent: self)
        }
    }
}

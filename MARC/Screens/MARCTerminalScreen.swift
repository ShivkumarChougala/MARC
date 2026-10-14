
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
    var aiCommandHistory: [String] = []
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
        aiServerID = server.id
        let current = UUID()
        token = current
        marcInputLine = ""
        marcInputLineKnown = true
        marcClearSequenceTail = ""
        ready = false
        failure = nil
        status = "Connecting"
        var opened: SSHClient?

        do {
            guard let saved = try MARCCredentials.read(server.id) else {
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
        }
        if let opened {
            try? await opened.close()
        }
    }

    func stop() {
        aiServerID = nil
        token = UUID()
        ready = false
        writer = nil
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
        guard let writer else { return }
        let current = token
        Task { @MainActor [weak self] in
            guard let self, self.token == current else { return }
            do {
                try await writer.changeSize(
                    cols: cols, rows: rows,
                    pixelWidth: 0, pixelHeight: 0
                )
            } catch {
                if self.token == current {
                    self.failure = error.localizedDescription
                }
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
        let view = session.view ?? SwiftTerm.TerminalView(frame: .zero)
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
        view.nativeBackgroundColor = dark
            ? UIColor(red: 17/255, green: 17/255, blue: 19/255, alpha: 1)
            : UIColor(red: 245/255, green: 245/255, blue: 247/255, alpha: 1)
        view.nativeForegroundColor = dark
            ? UIColor(white: 0.93, alpha: 1)
            : UIColor(white: 0.13, alpha: 1)
    }

    static func dismantleUIView(
        _ view: SwiftTerm.TerminalView, coordinator: Coordinator
    ) {
        view.resignFirstResponder()
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
            session.send(Array(data))
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
        selected?.session.view?.resignFirstResponder()
        let slot = MARCTerminalSlot(number: nextNumber)
        nextNumber += 1
        slots.append(slot)
        selectedID = slot.id
        start(slot)
    }

    func select(_ slot: MARCTerminalSlot) {
        selected?.session.view?.resignFirstResponder()
        selectedID = slot.id
    }

    func reconnectSelected() {
        guard let slot = selected else { return }
        slot.session.view?.resignFirstResponder()
        slot.task?.cancel()
        slot.task = nil
        slot.session.stop()
        start(slot)
    }

    func close(_ slot: MARCTerminalSlot) {
        slot.session.view?.resignFirstResponder()
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
            slot.session.view?.resignFirstResponder()
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
                        guard let view = workspace.selected?.session.view else {
                            return
                        }
                        if view.isFirstResponder {
                            view.resignFirstResponder()
                        } else {
                            view.becomeFirstResponder()
                        }
                    } label: {
                        Image(systemName: "keyboard")
                            .frame(width: 40, height: 40)
                            .background(p.raised, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Toggle terminal keyboard")

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
                        workspace.selected?.session.view?.resignFirstResponder()
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
                    MARCTerminalAI(session: slot.session)
                        .id(slot.id)

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

struct MARCTerminalAI: View {
    let session: MARCTerminalSession
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @AppStorage("marc.ai.provider") private var provider = "off"
    @AppStorage("marc.ai.localModel") private var localModel = ""
    @AppStorage("marc.ai.apiModel") private var apiModel = ""
    @AppStorage("marc.ai.endpoint") private var endpoint = ""
    @AppStorage("marc.ai.localServer") private var localServer = ""

    @State private var prompt = ""
    @State private var command = ""
    @State private var failure: String?
    @State private var busy = false
    @State private var requestTask: Task<Void, Never>?
    @State private var requestID = UUID()
    @FocusState private var promptFocused: Bool

    private let credentialID =
        UUID(uuidString: "8769682D-2807-4706-81D8-28512948AB21")!

    private var canRequest: Bool {
        guard session.ready, !busy,
              !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return false }
        if provider == "local" {
            return !localModel.isEmpty &&
                localServer == session.aiServerID?.uuidString
        }
        return provider == "api" &&
            !apiModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var insertable: Bool {
        let value = command.trimmingCharacters(in: .whitespacesAndNewlines)
        return session.ready && !busy && !value.isEmpty &&
            !value.unicodeScalars.contains {
                $0.value < 32 || $0.value == 127 ||
                (0x80...0x9f).contains($0.value) ||
                $0.value == 0x2028 || $0.value == 0x2029
            }
    }

    private var modelLabel: String {
        if provider == "local" {
            if localServer != session.aiServerID?.uuidString {
                return "Select this Mac’s model in Settings"
            }
            return localModel.isEmpty ? "Choose a model in Settings" : localModel
        }
        if provider == "api" {
            return apiModel.isEmpty ? "Configure API in Settings" : apiModel
        }
        return "Enable in Settings"
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundStyle(p.accent)

                TextField(
                    provider == "off" ? "Enable AI in Settings" : "Ask AI for a command…",
                    text: $prompt, axis: .vertical
                )
                .font(.system(size: 13))
                .lineLimit(1...2)
                .focused($promptFocused)
                .onChange(of: prompt) { old, new in
                    if old != new && !busy {
                        command = ""
                        failure = nil
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(busy || provider == "off")

                Button {
                    if busy { cancelRequest() }
                    else { generate() }
                } label: {
                    Group {
                        if busy {
                            ProgressView()
                                .controlSize(.small)
                                .tint(p.accent)
                        } else {
                            Text("AI")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .foregroundStyle(p.accent)
                    .frame(width: 36, height: 36)
                    .background(p.accent.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!busy && !canRequest)
                .accessibilityLabel(busy ? "Cancel generation" : "Generate command")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(p.border, lineWidth: 1)
            )

            if busy {
                HStack(spacing: 6) {
                    Text("Generating command…")
                        .font(.system(size: 10))
                        .foregroundStyle(p.muted)
                    Spacer()
                    Text("Tap spinner to cancel")
                        .font(.system(size: 9))
                        .foregroundStyle(p.muted)
                }
                .padding(.horizontal, 4)
            }

            if promptFocused && !busy &&
                !session.aiCommandHistory.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 7) {
                        ForEach(session.aiCommandHistory, id: \.self) { previous in
                            Button {
                                command = previous
                                failure = nil
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 9))
                                        .foregroundStyle(p.accent)
                                    Text(previous)
                                        .font(.system(size: 11, design: .monospaced))
                                        .lineLimit(1)
                                        .frame(maxWidth: 200, alignment: .leading)
                                }
                                .foregroundStyle(p.muted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    p.surface,
                                    in: Capsule()
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Review recent command: \(previous)")
                        }
                    }
                    .padding(.horizontal, 1)
                }
                .scrollIndicators(.hidden)
            }

            if !command.isEmpty {
                HStack(spacing: 8) {
                    ScrollView(.horizontal) {
                        Button(action: runCommand) {
                            Text(command)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(p.text)
                                .padding(.vertical, 11)
                                .padding(.horizontal, 12)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!insertable)
                    }
                    .scrollIndicators(.hidden)

                    Button(action: runCommand) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(p.accent)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .disabled(!insertable)
                    .accessibilityLabel("Run generated command")

                    Button { command = "" } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                            .frame(width: 32, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss generated command")
                }
                .background(p.raised, in: RoundedRectangle(cornerRadius: 12))

                if !insertable {
                    Text("Reconnect the shell, or generate a single-line command.")
                        .font(.system(size: 10))
                        .foregroundStyle(p.muted)
                }
            }

            if let failure {
                Text(failure)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .onChange(of: session.aiConnectionID) { _, _ in
            cancelRequest()
            command = ""
            failure = nil
        }
        .onChange(of: provider) { _, _ in
            cancelRequest()
            command = ""
            failure = nil
        }
        .onDisappear { cancelRequest() }
    }

    private func runCommand() {
        guard insertable else { return }
        let value = command.trimmingCharacters(in: .whitespacesAndNewlines)
        promptFocused = false
        session.view?.resignFirstResponder()
        session.aiCommandHistory.removeAll { $0 == value }
        session.aiCommandHistory.insert(value, at: 0)
        if session.aiCommandHistory.count > 8 {
            session.aiCommandHistory.removeLast(
                session.aiCommandHistory.count - 8
            )
        }
        session.send(Array((value + "\r").utf8))
        command = ""
        prompt = ""
    }

    private func cancelRequest() {
        requestID = UUID()
        requestTask?.cancel()
        requestTask = nil
        busy = false
    }

    private func generate() {
        guard canRequest else { return }
        let connection = session.aiConnectionID
        let chosenProvider = provider
        let model = (provider == "local" ? localModel : apiModel)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let requestPrompt = prompt
        let key = MARCCredentials.read(credentialID)?.password ?? ""
        let urlText = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = UUID()
        requestID = id
        busy = true
        failure = nil
        command = ""

        requestTask = Task { @MainActor in
            defer { if requestID == id { busy = false } }
            do {
                guard !model.isEmpty else {
                    throw MARCAIError.message("Enter a model name.")
                }
                let messages: [[String: String]] = [
                    [
                        "role": "system",
                        "content":
                            "Suggest exactly one single-line macOS shell command for the user's request. Output only the command, without markdown or explanations. Use macOS command syntax. Prefer non-destructive operations. If the request is unclear, return an empty response."
                    ],
                    ["role": "user", "content": requestPrompt]
                ]
                let body = try JSONSerialization.data(withJSONObject: [
                    "model": model,
                    "messages": messages,
                    "stream": false
                ])

                let data: Data
                if chosenProvider == "local" {
                    data = try await session.localAI(body: body)
                } else {
                    guard let url = URL(string: urlText),
                          url.scheme?.lowercased() == "https",
                          url.host != nil,
                          url.user == nil, url.password == nil else {
                        throw MARCAIError.message(
                            "Enter a valid HTTPS chat completions endpoint."
                        )
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.timeoutInterval = 120
                    request.httpBody = body
                    request.setValue(
                        "application/json", forHTTPHeaderField: "Content-Type"
                    )
                    if !key.isEmpty {
                        request.setValue(
                            "Bearer \(key)", forHTTPHeaderField: "Authorization"
                        )
                    }

                    let (received, response) =
                        try await URLSession.shared.data(for: request)
                    guard let http = response as? HTTPURLResponse,
                          (200...299).contains(http.statusCode) else {
                        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                        throw MARCAIError.message(
                            "API request failed (HTTP \(status)). Check endpoint, model and key."
                        )
                    }
                    guard received.count <= 262144 else {
                        throw MARCAIError.message("AI response exceeded its limit.")
                    }
                    data = received
                }

                try Task.checkCancellation()
                guard requestID == id else { return }

                guard let json = try JSONSerialization.jsonObject(
                    with: data
                ) as? [String: Any] else {
                    throw MARCAIError.message("Invalid AI response.")
                }
                if let error = json["error"] as? String {
                    throw MARCAIError.message(error)
                }

                let result: String?
                if chosenProvider == "local" {
                    result = (json["message"] as? [String: Any])?["content"] as? String
                } else {
                    let choices = json["choices"] as? [[String: Any]]
                    result = (choices?.first?["message"] as? [String: Any])?["content"] as? String
                }

                var cleaned = (result ?? "").trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                if cleaned.hasPrefix("```") {
                    var lines = cleaned.components(separatedBy: "\n")
                    lines.removeFirst()
                    if lines.last?.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) == "```" {
                        lines.removeLast()
                    }
                    cleaned = lines.joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                guard !cleaned.isEmpty else {
                    throw MARCAIError.message(
                        "No command returned. Try a more specific request."
                    )
                }
                guard session.aiConnectionID == connection,
                      session.ready else {
                    throw MARCAIError.message("The terminal connection changed. Generate again.")
                }
                command = cleaned
            } catch {
                guard requestID == id, !Task.isCancelled else { return }
                failure = error.localizedDescription
            }
        }
    }
}

extension MARCTerminalSession {
    var aiConnectionID: UUID { token }
}

struct MARCTerminalAISettings: View {
    let monitor: SSHMonitor
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @Environment(\.dismiss) private var dismiss

    @AppStorage("marc.ai.provider") private var provider = "off"
    @AppStorage("marc.ai.localModel") private var localModel = ""
    @AppStorage("marc.ai.localServer") private var localServer = ""
    @AppStorage("marc.ai.apiModel") private var apiModel = ""
    @AppStorage("marc.ai.endpoint") private var endpoint = ""

    @State private var models: [String] = []
    @State private var apiKey = ""
    @State private var loading = false
    @State private var failure: String?
    @State private var notice: String?
    @State private var reload = 0

    private let credentialID =
        UUID(uuidString: "8769682D-2807-4706-81D8-28512948AB21")!

    private var discoveryID: String {
        "\(provider)-\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)-\(reload)"
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 40, height: 40)
                        .background(p.raised, in: Circle())
                }
                .foregroundStyle(p.accent)
                .accessibilityLabel("Back")
                Text("Terminal & AI")
                    .font(.system(size: 19, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Provider")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(p.muted)
                        Picker("Provider", selection: $provider) {
                            Text("Off").tag("off")
                            Text("Local").tag("local")
                            Text("API").tag("api")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    .background(
                        p.surface, in: RoundedRectangle(cornerRadius: 16)
                    )

                    if provider == "local" {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Installed models")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(monitor.connected
                                         ? (monitor.server?.name ?? "Connected Mac")
                                         : "Connect a Mac in Settings")
                                        .font(.system(size: 11))
                                        .foregroundStyle(p.muted)
                                }
                                Spacer()
                                if loading {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Button { reload += 1 } label: {
                                        Image(systemName: "arrow.clockwise")
                                            .frame(width: 40, height: 40)
                                    }
                                    .foregroundStyle(p.accent)
                                    .disabled(!monitor.connected)
                                    .accessibilityLabel("Refresh installed models")
                                }
                            }
                            .padding(14)

                            ForEach(models, id: \.self) { model in
                                Divider().padding(.horizontal, 14)
                                Button {
                                    select(model)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "cube")
                                            .foregroundStyle(p.muted)
                                        Text(model)
                                            .font(.system(size: 13))
                                            .lineLimit(2)
                                        Spacer()
                                        if localModel == model &&
                                            localServer == monitor.server?.id.uuidString {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(p.accent)
                                        }
                                    }
                                    .foregroundStyle(p.text)
                                    .padding(.horizontal, 16)
                                    .frame(minHeight: 54)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            if !loading && models.isEmpty && monitor.connected &&
                                failure == nil {
                                Text("No installed models found.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(p.muted)
                                    .padding(16)
                            }
                        }
                        .background(
                            p.surface, in: RoundedRectangle(cornerRadius: 16)
                        )

                        Text("Uses Ollama on this Mac through SSH. The model choice is remembered separately for each Mac.")
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 4)
                    }

                    if provider == "api" {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("API connection")
                                .font(.system(size: 14, weight: .semibold))
                            fieldTitle("Chat completions endpoint", palette: p)
                            TextField(
                                "https://…/v1/chat/completions",
                                text: $endpoint
                            )
                            .keyboardType(.URL)
                            .font(.system(size: 12))
                            Divider()
                            fieldTitle("Model", palette: p)
                            TextField("Model name", text: $apiModel)
                                .font(.system(size: 13))
                            Divider()
                            fieldTitle("API key", palette: p)
                            SecureField("Optional for keyless providers", text: $apiKey)
                                .font(.system(size: 13))

                            Button(action: saveKey) {
                                HStack {
                                    Text("Save API key")
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(p.accent)
                                .padding(12)
                                .background(
                                    p.raised,
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .background(
                            p.surface, in: RoundedRectangle(cornerRadius: 16)
                        )

                        Text("Use a compatible HTTPS chat completions endpoint. The API key is stored in Keychain; provider, endpoint and model choices save automatically.")
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 4)
                    }

                    if provider == "off" {
                        Text("Choose Local or API to enable Ask AI in the terminal.")
                            .font(.system(size: 12))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 4)
                    }

                    if let notice {
                        Text(notice)
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                    }
                    if let failure {
                        Text(failure)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(p.text)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .marcCanvas()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            apiKey = MARCCredentials.read(credentialID)?.password ?? ""
        }
        .onDisappear { apiKey = "" }
        .task(id: discoveryID) {
            await discoverModels()
        }
    }

    private func fieldTitle(
        _ title: String, palette: MARCPalette
    ) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(palette.muted)
    }

    private func select(_ model: String) {
        guard monitor.connected, let id = monitor.server?.id else { return }
        localModel = model
        localServer = id.uuidString
        UserDefaults.standard.set(
            model, forKey: "marc.ai.model.\(id.uuidString)"
        )
    }

    @MainActor
    private func discoverModels() async {
        models = []
        failure = nil
        notice = nil
        guard provider == "local", monitor.connected,
              let serverID = monitor.server?.id else {
            loading = false
            return
        }

        let discovery = discoveryID
        loading = true
        defer {
            if discoveryID == discovery { loading = false }
        }

        do {
            let names = try await monitor.marcInstalledAIModels()
            try Task.checkCancellation()
            guard discoveryID == discovery,
                  monitor.server?.id == serverID else { return }
            models = names

            let remembered = UserDefaults.standard.string(
                forKey: "marc.ai.model.\(serverID.uuidString)"
            ) ?? (localServer == serverID.uuidString ? localModel : "")

            localServer = serverID.uuidString
            localModel = names.contains(remembered) ? remembered : ""
            if names.count == 1, let only = names.first {
                select(only)
            }
        } catch {
            guard !Task.isCancelled, discoveryID == discovery else { return }
            failure = error.localizedDescription
        }
    }

    private func saveKey() {
        do {
            try MARCCredentials.save(
                credentialID, password: apiKey, hostKey: ""
            )
            notice = apiKey.isEmpty ? "API key cleared." : "API key saved."
            failure = nil
        } catch {
            failure = "Could not save the API key."
        }
    }
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
            host.safeAreaRegions = []
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

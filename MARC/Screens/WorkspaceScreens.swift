import QuickLook
import CoreTransferable
import PhotosUI
import NIOCore
@preconcurrency import Citadel
import UniformTypeIdentifiers
import Observation
import UIKit
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


struct MARCRemoteEntry: Identifiable {
    let name: String
    let path: String
    let directory: Bool
    let size: UInt64?
    let modified: Date?
    let mode: UInt32?
    var id: String { path }
}

struct MARCFileDestination: Equatable {
    let connection: UUID
    let path: String
}

@MainActor @Observable
final class MARCRemoteFiles {
    var entries: [MARCRemoteEntry] = []
    var path = ""
    var home = ""
    var ready = false
    var busy = false
    var transferring = false
    var progress = 0.0
    var transferName = ""
    var transferBytes: UInt64 = 0
    var transferTotal: UInt64?
    var transferPhase = "Starting"
    var previewTransfer = false
    var uploadingTransfer = false
    var cancellingTransfer = false
    var activity = ""
    var failure: String?
    var notice: String?
    var downloaded: MARCLocalDownload?
    var lastUploadedPath: String?
    var completionTitle: String?
    var completionEvent = UUID()
    var completionPath = ""

    @ObservationIgnored private var ssh: SSHClient?
    @ObservationIgnored private var sftp: SFTPClient?
    @ObservationIgnored private var folderServerID: UUID?
    @ObservationIgnored private var operation: Task<Void, Never>?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var lastProgressUpdate: ContinuousClock.Instant?

    func stop() {
        generation = UUID()
        operation?.cancel()
        operation = nil
        ready = false
        busy = false
        transferring = false
        progress = 0
        transferName = ""
        transferBytes = 0
        transferTotal = nil
        transferPhase = ""
        previewTransfer = false
        uploadingTransfer = false
        cancellingTransfer = false
        lastProgressUpdate = nil
        activity = ""
        failure = nil
        notice = nil
        completionTitle = nil
        completionPath = ""
        lastUploadedPath = nil
        downloaded = nil
        entries = []
        path = ""
        home = ""
        let oldSFTP = sftp
        let oldSSH = ssh
        sftp = nil
        ssh = nil
        Task {
            try? await oldSFTP?.close()
            try? await oldSSH?.close()
        }
    }

    func prepare(server: ServerProfile) async {
        guard !Task.isCancelled else { return }
        if folderServerID == server.id && ready { return }
        stop()
        await connect(server: server)
    }

    func connect(server: ServerProfile) async {
        guard !Task.isCancelled else { return }
        folderServerID = server.id
        let id = generation
        busy = true
        failure = nil
        notice = nil
        var opened: SSHClient?
        var subsystem: SFTPClient?

        do {
            guard let saved = MARCCredentials.read(server.id) else {
                throw MARCAIError.message("Connect this server in Settings first.")
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
            try checkOperation(id)
            let client = try await connection.openSFTP()
            subsystem = client
            try checkOperation(id)

            let initial = try await client.getRealPath(atPath: ".")
            let preferenceKey = "marc.files.lastFolder.\(server.id.uuidString)"
            let remembered = UserDefaults.standard.string(
                forKey: preferenceKey
            )
            var destination = initial
            let rows: [MARCRemoteEntry]

            if let remembered, remembered != initial {
                do {
                    let canonical = try await client.getRealPath(
                        atPath: remembered
                    )
                    rows = try await listing(canonical, using: client)
                    destination = canonical
                } catch {
                    try checkOperation(id)
                    rows = try await listing(initial, using: client)
                }
            } else {
                rows = try await listing(initial, using: client)
            }
            try checkOperation(id)

            ssh = connection
            sftp = client
            home = initial
            path = destination
            UserDefaults.standard.set(destination, forKey: preferenceKey)
            entries = rows
            ready = true
            busy = false
        } catch {
            try? await subsystem?.close()
            try? await opened?.close()
            guard generation == id else { return }
            busy = false
            if !Task.isCancelled {
                failure = "Could not open Files: \(error.localizedDescription)"
            }
        }
    }

    private func listing(
        _ requested: String, using client: SFTPClient
    ) async throws -> [MARCRemoteEntry] {
        let batches = try await client.listDirectory(atPath: requested)
        return batches.flatMap(\.components)
            .filter {
                $0.filename != "." && $0.filename != ".." &&
                !$0.filename.contains("/") &&
                !$0.filename.contains("\0")
            }
            .map {
                let mode = $0.attributes.permissions
                let directory = mode.map { ($0 & 0xF000) == 0x4000 }
                    ?? $0.longname.hasPrefix("d")
                return MARCRemoteEntry(
                    name: $0.filename,
                    path: joined(requested, $0.filename),
                    directory: directory,
                    size: $0.attributes.size,
                    modified: $0.attributes.accessModificationTime?.modificationTime,
                    mode: mode
                )
            }
            .sorted {
                if $0.directory != $1.directory { return $0.directory }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    private func checkOperation(_ id: UUID) throws {
        try Task.checkCancellation()
        guard generation == id else { throw CancellationError() }
    }

    private func joined(_ parent: String, _ name: String) -> String {
        parent == "/" ? "/" + name : parent + "/" + name
    }

    func browse(_ requested: String) {
        guard ready, !busy, let client = sftp else { return }
        let id = generation
        busy = true
        activity = "Opening folder"
        failure = nil
        notice = nil

        operation = Task { @MainActor in
            defer { if generation == id { busy = false; operation = nil } }
            do {
                try checkOperation(id)
                let canonical = try await client.getRealPath(atPath: requested)
                try checkOperation(id)
                let rows = try await listing(canonical, using: client)
                try Task.checkCancellation()
                guard generation == id else { return }
                path = canonical
                if let serverID = folderServerID {
                    UserDefaults.standard.set(
                        canonical,
                        forKey: "marc.files.lastFolder.\(serverID.uuidString)"
                    )
                }
                entries = rows
            } catch {
                guard generation == id, !Task.isCancelled else { return }
                failure = error.localizedDescription
            }
        }
    }

    private func publishTransferProgress(
        completed: UInt64, total: UInt64
    ) {
        let now = ContinuousClock.now
        if let previous = lastProgressUpdate,
           previous.duration(to: now) < .milliseconds(200) {
            return
        }
        lastProgressUpdate = now
        transferBytes = completed
        transferTotal = total

        let value = total > 0
            ? min(1, Double(completed) / Double(total)) : 0
        if progress != value { progress = value }
    }

    func cancelTransfer() {
        guard transferring, !cancellingTransfer else { return }
        cancellingTransfer = true
        operation?.cancel()
    }

    private func beginTransfer(name: String, preview: Bool = false, upload: Bool = false) {
        transferName = name
        transferBytes = 0
        transferTotal = nil
        transferPhase = preview ? "Preparing preview" : (upload ? "Starting upload" : "Starting download")
        previewTransfer = preview
        uploadingTransfer = upload
        cancellingTransfer = false
        completionTitle = nil
        progress = 0
        lastProgressUpdate = nil
    }

    func captureDestination() -> MARCFileDestination? {
        guard ready, !busy else { return nil }
        return MARCFileDestination(connection: generation, path: path)
    }

    func matchesDestination(_ destination: MARCFileDestination) -> Bool {
        ready && generation == destination.connection && path == destination.path
    }

    func upload(_ url: URL, to expectedDestination: MARCFileDestination? = nil) {
        if let expectedDestination, !matchesDestination(expectedDestination) {
            failure = "The upload destination changed. Select the file again."
            return
        }
        guard ready, !busy, let client = sftp else { return }
        let id = generation
        let folder = path
        let name = url.lastPathComponent
        guard !name.isEmpty, name != ".", name != "..",
              !name.contains("/"), !name.contains("\0") else { return }

        let destination = joined(folder, name)
        if entries.contains(where: { $0.path == destination }) {
            failure = "A file named \(name) already exists. Rename it before uploading."
            return
        }

        let temporary = joined(folder, ".marc-upload-\(UUID().uuidString).part")
        busy = true
        transferring = true
        beginTransfer(name: name, upload: true)
        activity = "Uploading \(name)"
        failure = nil
        notice = nil

        operation = Task { @MainActor in
            let scoped = url.startAccessingSecurityScopedResource()
            defer {
                if scoped { url.stopAccessingSecurityScopedResource() }
                let mediaFolder = url.deletingLastPathComponent()
                if mediaFolder.lastPathComponent.hasPrefix("MARCPhotoImport-") &&
                    mediaFolder.deletingLastPathComponent().standardizedFileURL ==
                    FileManager.default.temporaryDirectory.standardizedFileURL {
                    try? FileManager.default.removeItem(at: mediaFolder)
                }
                if generation == id {
                    busy = false
                    transferring = false
                    operation = nil
                }
            }

            var remote: SFTPFile?
            var local: MARCTransferIO?
            var created = false

            do {
                try checkOperation(id)
                let values = try url.resourceValues(
                    forKeys: [.isRegularFileKey, .fileSizeKey]
                )
                guard values.isRegularFile == true else {
                    throw MARCAIError.message("Choose a file rather than a folder.")
                }
                let total = UInt64(max(0, values.fileSize ?? 0))
                transferTotal = total
                let input = try MARCTransferIO(forReadingFrom: url)
                local = input
                let file = try await client.openFile(
                    filePath: temporary,
                    flags: [.write, .create, .forceCreate]
                )
                remote = file
                created = true
                try checkOperation(id)
                transferPhase = "Uploading"
                var offset: UInt64 = 0

                while true {
                    try checkOperation(id)
                    let data = try await input.readChunk()
                    try checkOperation(id)
                    if data.isEmpty { break }
                    var buffer = ByteBuffer()
                    buffer.writeBytes(data)
                    try await file.write(buffer, at: offset)
                    offset += UInt64(data.count)
                    if generation == id {
                        publishTransferProgress(completed: offset, total: total)
                    }
                }

                guard offset == total else {
                    throw MARCAIError.message(
                        "The local file changed during upload. Select it again."
                    )
                }
                try checkOperation(id)
                transferBytes = offset
                progress = 1
                transferPhase = "Verifying upload"
                let uploadedAttributes = try await client.getAttributes(
                    at: temporary
                )
                guard uploadedAttributes.size == offset else {
                    throw MARCAIError.message(
                        "Upload verification failed. Please retry."
                    )
                }
                try await file.close()
                remote = nil
                try await input.close()
                local = nil
                try checkOperation(id)

                transferPhase = "Finishing upload"
                try await client.rename(at: temporary, to: destination)
                created = false
                guard generation == id else { return }
                // The rename committed the verified file. A refresh failure or
                // late cancellation must not claim that this upload failed.
                progress = 1
                path = folder
                lastUploadedPath = destination
                completionEvent = UUID()
                completionTitle = "Upload complete"
                completionPath = destination
                notice = nil
                do {
                    let rows = try await listing(folder, using: client)
                    try checkOperation(id)
                    entries = rows
                } catch {
                    if generation == id, !Task.isCancelled {
                        failure = "Upload complete, but the folder could not refresh. Tap Refresh."
                    }
                }
            } catch {
                try? await remote?.close()
                try? await local?.close()
                if created { try? await client.remove(at: temporary) }
                guard generation == id else { return }
                if Task.isCancelled {
                    notice = "Upload cancelled."
                } else {
                    failure = "Upload failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func download(_ entry: MARCRemoteEntry, archiveDirectory: String? = nil, forPreview: Bool = false) {
        guard ready, !busy, !entry.directory, let client = sftp else { return }
        let id = generation
        busy = true
        transferring = true
        beginTransfer(name: entry.name, preview: forPreview)
        activity = forPreview ? "Preparing preview" : "Downloading \(entry.name)"
        let archiveConnection = ssh
        downloaded = nil
        failure = nil
        notice = nil

        operation = Task { @MainActor in
            defer {
                if let archiveDirectory, let archiveConnection {
                    Task {
                        _ = try? await MARCFileBridge.request(
                            ["action": "cleanupArchive", "path": archiveDirectory],
                            using: archiveConnection
                        )
                    }
                }
                if generation == id {
                    busy = false
                    transferring = false
                    operation = nil
                }
            }
            var remote: SFTPFile?
            var local: MARCTransferIO?
            var localDownload: MARCLocalDownload?
            // Keep the local lease through handle cleanup on every error path.
            defer { withExtendedLifetime(localDownload) {} }

            do {
                try checkOperation(id)
                let attributes = try await client.getAttributes(at: entry.path)
                if let mode = attributes.permissions,
                   (mode & 0xF000) != 0x8000 {
                    throw MARCAIError.message("Download a regular file, not a folder or device.")
                }
                guard let total = attributes.size else {
                    throw MARCAIError.message("The server did not provide this file’s size.")
                }

                try checkOperation(id)
                transferTotal = total
                transferPhase = forPreview ? "Preparing preview" : "Downloading"
                let artifact = try MARCLocalDownload(name: entry.name, forPreview: forPreview)
                localDownload = artifact
                let destination = artifact.url
                guard FileManager.default.createFile(
                    atPath: destination.path, contents: nil
                ) else {
                    throw MARCAIError.message("Could not create the local download.")
                }

                let output = try MARCTransferIO(forWritingTo: destination)
                local = output
                let file = try await client.openFile(
                    filePath: entry.path, flags: [.read]
                )
                remote = file
                var offset: UInt64 = 0

                while offset < total {
                    try checkOperation(id)
                    let length = UInt32(min(UInt64(32768), total - offset))
                    let buffer = try await file.read(from: offset, length: length)
                    try checkOperation(id)
                    guard buffer.readableBytes > 0 else {
                        throw MARCAIError.message("The remote file changed during download.")
                    }
                    try await output.writeChunk(Data(buffer.readableBytesView))
                    offset += UInt64(buffer.readableBytes)
                    if generation == id {
                        publishTransferProgress(completed: offset, total: total)
                    }
                }

                try checkOperation(id)
                transferBytes = offset
                progress = 1
                transferPhase = forPreview ? "Opening preview" : "Verifying download"
                let final = try await client.getAttributes(at: entry.path)
                guard final.size == attributes.size,
                      final.accessModificationTime?.modificationTime ==
                        attributes.accessModificationTime?.modificationTime else {
                    throw MARCAIError.message("The remote file changed. Download it again.")
                }

                try await file.close()
                remote = nil
                try await output.close()
                local = nil
                try checkOperation(id)

                progress = 1
                // Quick Look / the save sheet is the completion feedback.
                // Preview needs a temporary local copy, not a second download toast.
                completionTitle = nil
                notice = nil
                downloaded = artifact
            } catch {
                try? await remote?.close()
                try? await local?.close()
                localDownload = nil
                guard generation == id else { return }
                if Task.isCancelled {
                    notice = forPreview ? "Preview cancelled." : "Download cancelled."
                } else {
                    failure = "\(forPreview ? "Preview" : "Download") failed: \(error.localizedDescription)"
                }
            }
        }
    }
    func perform(_ action: String, entry: MARCRemoteEntry,
                 extras: [String: Any] = [:], refresh: Bool = false) async throws -> MARCFileReply {
        try await perform(action, entry: entry, extras: extras, refresh: refresh, reservedArchive: false)
    }

    private func perform(_ action: String, entry: MARCRemoteEntry,
                         extras: [String: Any], refresh: Bool,
                         reservedArchive: Bool) async throws -> MARCFileReply {
        try Task.checkCancellation()
        guard ready, (!busy || reservedArchive), let ssh else {
            throw MARCAIError.message("Wait for the current operation, or reconnect Files.")
        }
        let token = generation
        busy = true
        switch action {
        case "archive": activity = "Preparing folder archive"
        case "permissions": activity = "Updating permissions"
        case "rename": activity = "Moving item"
        case "delete": activity = "Deleting item"
        case "readText": activity = "Opening text file"
        case "saveText": activity = "Saving text file"
        default: activity = "Loading file details"
        }
        defer { if generation == token, !reservedArchive { busy = false } }
        var request = extras
        request["action"] = action
        request["path"] = entry.path
        request["home"] = home
        var staged: String?
        var stagedFile: SFTPFile?
        let stagingClient = sftp
        do {
            // Transfer edited text through SFTP: a 1 MB document must not become
            // a huge shell argument. The action request only contains its path.
            if action == "saveText" {
                guard let encoded = extras["data"] as? String,
                      let data = Data(base64Encoded: encoded), data.count <= 1048576,
                      let stagingClient else {
                    throw MARCAIError.message("Save UTF-8 text up to 1 MB.")
                }
                let parent = (entry.path as NSString).deletingLastPathComponent
                let temporary = joined(parent, ".marc-edit-input-\(UUID().uuidString).part")
                staged = temporary
                let file = try await stagingClient.openFile(
                    filePath: temporary, flags: [.write, .create, .forceCreate]
                )
                stagedFile = file
                try checkOperation(token)
                _ = try await MARCFileBridge.request(
                    ["action": "permissions", "path": temporary, "mode": 0o600],
                    using: ssh
                )
                var offset = 0
                while offset < data.count {
                    try checkOperation(token)
                    let end = min(data.count, offset + 32768)
                    var buffer = ByteBuffer()
                    buffer.writeBytes(data[offset..<end])
                    try await file.write(buffer, at: UInt64(offset))
                    offset = end
                }
                try await file.close()
                stagedFile = nil
                request.removeValue(forKey: "data")
                request["staged"] = temporary
            }
            try checkOperation(token)
            let reply = try await MARCFileBridge.request(request, using: ssh)
            if let staged, let stagingClient { try? await stagingClient.remove(at: staged) }
            staged = nil
            guard generation == token, !Task.isCancelled else {
                if let folder = reply.archiveDirectory {
                    _ = try? await MARCFileBridge.request(["action": "cleanupArchive", "path": folder], using: ssh)
                }
                throw CancellationError()
            }
            if refresh, let sftp {
                do {
                    let rows = try await listing(path, using: sftp)
                    guard generation == token else { throw CancellationError() }
                    entries = rows
                } catch is CancellationError { throw CancellationError() }
                catch {
                    try checkOperation(token)
                    failure = "The action completed, but the folder could not refresh. Tap Refresh."
                }
            }
            return reply
        } catch {
            try? await stagedFile?.close()
            if let staged, let stagingClient { try? await stagingClient.remove(at: staged) }
            throw error
        }
    }

    func downloadFolder(_ entry: MARCRemoteEntry) {
        guard ready, !busy else { return }
        let token = generation
        // Reserve ownership before the task is scheduled, as file transfers do.
        busy = true
        transferring = true
        beginTransfer(name: entry.name)
        transferPhase = "Preparing folder"
        activity = "Preparing folder archive"
        failure = nil
        notice = nil
        operation = Task { @MainActor in
            var handedOff = false
            defer {
                if generation == token, !handedOff {
                    busy = false
                    transferring = false
                    operation = nil
                }
            }
            do {
                try checkOperation(token)
                let result = try await perform("archive", entry: entry, extras: [:],
                                               refresh: false, reservedArchive: true)
                try checkOperation(token)
                guard let path = result.archive, let folder = result.archiveDirectory else {
                    throw MARCAIError.message("The folder archive could not be prepared.")
                }
                let archive = MARCRemoteEntry(
                    name: (path as NSString).lastPathComponent, path: path,
                    directory: false, size: nil, modified: nil, mode: nil
                )
                // Download is synchronous: ownership transfers without an await gap.
                busy = false
                handedOff = true
                download(archive, archiveDirectory: folder)
            } catch {
                guard generation == token else { return }
                if Task.isCancelled { notice = "Folder download cancelled." }
                else { failure = error.localizedDescription }
            }
        }
    }

}

struct FilesScreen: View {
    let monitor: SSHMonitor
    let files: MARCRemoteFiles
    var onShowTerminal: (String) -> Void = { _ in }
    var onClose: (() -> Void)? = nil
    @State private var selectedEntry: MARCRemoteEntry?
    @State private var actionSheetVisible = false
    @State private var pendingDownload: MARCLocalDownload?
    @State private var search = ""
    @State private var showHidden = false
    @State private var importing = false
    @State private var choosingPhoto = false
    @State private var photoSelection: PhotosPickerItem?
    @State private var preparingPhoto = false
    @State private var photoPreparationID = UUID()
    @State private var photoDestination: MARCFileDestination?
    @State private var importDestination: MARCFileDestination?
    @State private var export: MARCLocalDownload?
    @State private var preview: MARCLocalDownload?
    @State private var showTransferProgress = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @Environment(\.scenePhase) private var scenePhase

    private var connectionID: String {
        "\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)"
    }

    private var visibleEntries: [MARCRemoteEntry] {
        files.entries.filter {
            (showHidden || !$0.name.hasPrefix(".")) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(spacing: 12) {
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
                Text("Files")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(p.muted)
                    .lineLimit(1)
                    .layoutPriority(1)
                Menu {
                    Button {
                        importDestination = files.captureDestination()
                        importing = importDestination != nil
                    } label: {
                        Label("Files", systemImage: "folder")
                    }
                    Button {
                        photoSelection = nil
                        photoDestination = files.captureDestination()
                        choosingPhoto = photoDestination != nil
                    } label: {
                        Label("Photos & Videos", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 40, height: 40)
                }
                .disabled(!files.ready || files.busy || preparingPhoto)
                .accessibilityLabel("Choose upload source")
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(minHeight: 44)
            .foregroundStyle(p.accent)

            if preparingPhoto || files.transferring {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.mini).tint(p.accent)
                    Text(preparingPhoto ? "Preparing media…" :
                         (files.cancellingTransfer ? "Cancelling…" : files.transferPhase))
                        .font(.system(size: 11))
                        .foregroundStyle(p.muted)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }

            HStack(spacing: 10) {
                Button {
                    files.browse((files.path as NSString).deletingLastPathComponent)
                    search = ""
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 36)
                }
                .disabled(!files.ready || files.busy || files.path == "/")
                .accessibilityLabel("Parent folder")

                ScrollView(.horizontal) {
                    Text(files.path.isEmpty ? "Connecting…" : files.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(p.muted)
                        .textSelection(.enabled)
                }
                .scrollIndicators(.hidden)

                Button {
                    files.browse(files.home)
                    search = ""
                } label: {
                    Image(systemName: "house")
                        .frame(width: 32, height: 36)
                }
                .disabled(!files.ready || files.busy)
                .accessibilityLabel("Home folder")
            }
            .foregroundStyle(p.accent)
            .padding(.horizontal, 8)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(p.muted)
                TextField("Search this folder", text: $search)
                    .font(.system(size: 13))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button { showHidden.toggle() } label: {
                    Image(systemName: showHidden ? "eye" : "eye.slash")
                        .foregroundStyle(showHidden ? p.accent : p.muted)
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Toggle hidden files")
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 12))


            // Feedback participates in layout below Search, so navigation
            // can never cover its progress or Cancel control.
            if ((preparingPhoto || files.transferring) && showTransferProgress) || files.completionTitle != nil {
                Group {
                    if preparingPhoto && showTransferProgress {
                        MARCFileTransferCard(
                            title: "Preparing media", filename: "Photo or video",
                            symbol: "photo", detail: "Loading selected item…",
                            progress: nil, cancel: nil
                        )
                    } else if files.transferring && showTransferProgress {
                        MARCFileTransferCard(
                            title: files.cancellingTransfer ? "Cancelling…" : files.transferPhase,
                            filename: files.transferName,
                            symbol: files.previewTransfer ? "eye" : (files.uploadingTransfer ? "arrow.up" : "arrow.down"),
                            detail: transferDetail,
                            progress: files.transferTotal == nil || files.progress >= 1 ? nil : files.progress,
                            cancel: files.cancellingTransfer ? nil : { files.cancelTransfer() }
                        )
                    } else if let title = files.completionTitle {
                        MARCFileCompletionCard(
                            title: title,
                            filename: (files.completionPath as NSString).lastPathComponent
                        )
                        .allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            if let notice = files.notice, !files.busy, !preparingPhoto, !files.transferring, files.completionTitle == nil {
                Text(notice)
                    .font(.system(size: 12)).multilineTextAlignment(.center)
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
            }

            ScrollViewReader { scroll in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(visibleEntries) { entry in
                        HStack(spacing: 0) {
                            Button {
                                if entry.directory { open(entry) }
                                else { actionSheetVisible = true; selectedEntry = entry }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: entry.symbol)
                                        .font(.system(size: 21))
                                        .foregroundStyle(entry.directory ? p.accent : p.muted)
                                        .frame(width: 42, height: 44)
                                        .background(p.accent.opacity(entry.directory ? 0.13 : 0.04),
                                                    in: RoundedRectangle(cornerRadius: 12))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(entry.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(p.text).lineLimit(2)
                                        Text(detail(entry))
                                            .font(.system(size: 10)).foregroundStyle(p.muted)
                                        Text(MARCFileFormatting.permissions(entry.mode))
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(p.muted)
                                    }
                                    Spacer(minLength: 4)
                                }
                                .padding(.leading, 14).padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(entry.directory ? "Open folder" : "Details and actions")
                            Button { actionSheetVisible = true; selectedEntry = entry } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(p.muted)
                                    .frame(width: 48, height: 60)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Details and actions for \(entry.name)")
                        }
                        .background(entry.path == files.lastUploadedPath ? p.accent.opacity(0.12) : p.surface)
                        .disabled(files.busy || !files.ready)
                        .contextMenu {
                            Button("Details and actions") { actionSheetVisible = true; selectedEntry = entry }
                            Button("Copy path") { UIPasteboard.general.string = entry.path }
                        }
                        .id(entry.id)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if !files.busy && visibleEntries.isEmpty {
                    Text(files.ready
                         ? (search.isEmpty ? "This folder is empty." : "No matching files.")
                         : (monitor.connected ? "Files connection unavailable." : "Connect a Mac in Settings."))
                        .font(.system(size: 12))
                        .foregroundStyle(p.muted)
                        .padding(30)
                }
            }
            .contentMargins(.bottom, 16, for: .scrollContent)
            // Keep rows inside the list's allocated viewport above navigation.
            .clipped()
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: files.lastUploadedPath) { _, uploaded in
                guard let uploaded else { return }
                search = ""
                if (uploaded as NSString).lastPathComponent.hasPrefix(".") {
                    showHidden = true
                }
                Task { @MainActor in
                    await Task.yield()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scroll.scrollTo(uploaded, anchor: .top)
                    }
                }
            }
            }

        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showTransferProgress)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: files.completionTitle)

        .marcCanvas()
        .marcDelayedActivity(
            active: files.busy && !files.transferring && !preparingPhoto && selectedEntry == nil,
            title: files.ready ? files.activity : "Connecting to Files"
        )
        .task(id: preparingPhoto || files.transferring) {
            showTransferProgress = false
            guard preparingPhoto || files.transferring else { return }
            do {
                try await Task.sleep(for: .milliseconds(350))
                try Task.checkCancellation()
                showTransferProgress = true
            } catch {}
        }
        .task(id: files.completionEvent) {
            guard files.completionTitle != nil else { return }
            do {
                try await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    files.completionTitle = nil
                }
            } catch {}
        }

        .task(id: files.notice) {
            guard let notice = files.notice else { return }
            do {
                try await Task.sleep(for: .seconds(2))
                if files.notice == notice { files.notice = nil }
            } catch {}
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: connectionID) { _, _ in
            selectedEntry = nil
            pendingDownload = nil
            importing = false
            choosingPhoto = false
            photoSelection = nil
            photoPreparationID = UUID()
            preparingPhoto = false
        }
        .task(id: connectionID) {
            guard scenePhase != .background, monitor.connected,
                  let server = monitor.server else { return }
            await files.prepare(server: server)
        }
        .photosPicker(
            isPresented: $choosingPhoto,
            selection: $photoSelection,
            matching: .any(of: [.images, .videos]),
            preferredItemEncoding: .current
        )
        .task(id: photoSelection) {
            guard !Task.isCancelled, let item = photoSelection,
                  let destination = photoDestination else { return }
            let preparation = UUID()
            photoPreparationID = preparation
            let folder = destination.path
            preparingPhoto = true
            var imported: URL?

            defer { if photoPreparationID == preparation { preparingPhoto = false } }

            do {
                guard let media = try await item.loadTransferable(
                    type: MARCPhotoImport.self
                ) else {
                    throw MARCAIError.message(
                        "Could not prepare this photo or video."
                    )
                }
                imported = media.url
                try Task.checkCancellation()

                guard scenePhase != .background,
                      files.matchesDestination(destination),
                      files.ready, !files.busy else {
                    throw MARCAIError.message(
                        "The destination changed. Select the item again."
                    )
                }

                let destinationPath = folder == "/"
                    ? "/" + media.url.lastPathComponent
                    : folder + "/" + media.url.lastPathComponent

                guard !files.entries.contains(where: {
                    $0.path == destinationPath
                }) else {
                    throw MARCAIError.message(
                        "A file with this name already exists in this folder."
                    )
                }

                files.upload(media.url, to: destination)
                imported = nil
            } catch {
                if let imported {
                    try? FileManager.default.removeItem(
                        at: imported.deletingLastPathComponent()
                    )
                }
                if !Task.isCancelled, photoPreparationID == preparation,
                   files.matchesDestination(destination) {
                    files.failure = error.localizedDescription
                }
            }
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.item]
        ) { result in
            switch result {
            case .success(let url):
                guard let importDestination else { return }
                files.upload(url, to: importDestination)
            case .failure(let error):
                if let importDestination, files.matchesDestination(importDestination) {
                    files.failure = error.localizedDescription
                }
            }
        }
        .onAppear { receiveDownloadedFile() }
        .onDisappear {
            pendingDownload = nil
            if files.transferring && files.previewTransfer { files.cancelTransfer() }
        }
        .onChange(of: files.downloaded?.id) { _, _ in
            receiveDownloadedFile()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { presentDownloadedFile() }
        }
        .alert("Files", isPresented: Binding(
            get: { files.failure != nil },
            set: { if !$0 { files.failure = nil } }
        )) {
            Button("OK", role: .cancel) { files.failure = nil }
        } message: { Text(files.failure ?? "") }
        .sheet(item: $selectedEntry, onDismiss: {
            actionSheetVisible = false
            presentDownloadedFile()
        }) { entry in
            MARCFileActionSheet(
                entry: entry, files: files,
                open: { selectedEntry = nil; open(entry) },
                download: {
                    selectedEntry = nil
                    if entry.directory { files.downloadFolder(entry) }
                    else { files.download(entry) }
                },
                terminal: {
                    selectedEntry = nil
                    let path = entry.directory ? entry.path : (entry.path as NSString).deletingLastPathComponent
                    onShowTerminal(path)
                }
            )
        }
        .sheet(item: $preview, onDismiss: presentDownloadedFile) { item in
            MARCRemoteFilePreview(file: item)
        }
        .sheet(item: $export, onDismiss: presentDownloadedFile) { item in
            MARCFilesShareSheet(file: item)
        }
    }

    private var transferDetail: String {
        func bytes(_ count: UInt64) -> String {
            ByteCountFormatter.string(fromByteCount: Int64(clamping: count), countStyle: .file)
        }
        guard let total = files.transferTotal else {
            return files.transferPhase == "Preparing folder"
                ? "Packaging folder contents…" : "Connecting to your Mac…"
        }
        return "\(bytes(files.transferBytes)) of \(bytes(total))"
    }

    private func open(_ entry: MARCRemoteEntry) {
        if entry.directory {
            search = ""
            files.browse(entry.path)
        } else {
            files.download(entry, forPreview: true)
        }
    }

    private func receiveDownloadedFile() {
        guard let file = files.downloaded else { return }
        // Transfer ownership out of the connection model before presenting.
        pendingDownload = file
        files.downloaded = nil
        presentDownloadedFile()
    }

    private func presentDownloadedFile() {
        guard scenePhase == .active, !actionSheetVisible,
              selectedEntry == nil, preview == nil, export == nil,
              let file = pendingDownload else { return }
        pendingDownload = nil
        if file.forPreview { preview = file }
        else { export = file }
    }

    private func detail(_ entry: MARCRemoteEntry) -> String {
        let size = entry.directory ? "Folder" : entry.size.map {
            ByteCountFormatter.string(
                fromByteCount: Int64(clamping: $0), countStyle: .file
            )
        } ?? "File"
        guard let modified = entry.modified else { return size }
        return size + " · " + modified.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct MARCFilesShareSheet: UIViewControllerRepresentable {
    let file: MARCLocalDownload

    func makeCoordinator() -> Coordinator { Coordinator(file: file) }

    final class Coordinator {
        let file: MARCLocalDownload
        init(file: MARCLocalDownload) { self.file = file }
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [context.coordinator.file.url], applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ controller: UIActivityViewController, context: Context
    ) {}
}

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


private struct MARCPhotoImport: Transferable, Sendable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .data) { received in
            let folder = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "MARCPhotoImport-\(UUID().uuidString)",
                    isDirectory: true
                )
            try FileManager.default.createDirectory(
                at: folder, withIntermediateDirectories: true
            )

            do {
                let name = received.file.lastPathComponent
                guard !name.isEmpty, name != ".", name != ".." else {
                    throw MARCAIError.message("Invalid media filename.")
                }
                let destination = folder.appendingPathComponent(name)
                try FileManager.default.copyItem(
                    at: received.file, to: destination
                )
                return MARCPhotoImport(url: destination)
            } catch {
                try? FileManager.default.removeItem(at: folder)
                throw error
            }
        }
    }
}


// One compact transfer surface: progress ring, file identity, status and cancel.
// The ring advances only from bytes already transferred; no decorative looping.
private struct MARCFileTransferCard: View {
    let title: String
    let filename: String
    let symbol: String
    let detail: String
    let progress: Double?
    let cancel: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        let value = min(1, max(0, progress ?? 0))

        HStack(spacing: 12) {
            ZStack {
                Circle().fill(p.accent.opacity(0.06))
                Circle().stroke(p.accent.opacity(0.12), lineWidth: 2.5)
                if progress != nil {
                    Circle()
                        .trim(from: 0, to: CGFloat(value))
                        .stroke(p.accent.gradient, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .modifier(MARCLiveValueMotion(value: value))
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(p.accent)
                } else {
                    ProgressView().controlSize(.small).tint(p.accent)
                }
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(p.accent)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if progress != nil {
                        MARCLiveNumberText(text: "\(Int(value * 100))%", value: value * 100)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(p.text)
                    }
                }
                Text(filename)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(p.text)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(detail)
                    .font(.system(size: 10))
                    .monospacedDigit()
                    .foregroundStyle(p.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            if let cancel {
                Button(action: cancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(p.muted)
                        .frame(width: 28, height: 28)
                        .background(p.raised, in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel \(title.lowercased())")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, cancel == nil ? 16 : 6)
        .padding(.vertical, 14)
        .background(p.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(colors: [p.accent.opacity(0.22), p.border],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .marcLiveReadings(enabled: progress != nil)
    }
}

private struct MARCFileCompletionCard: View {
    let title: String
    let filename: String
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(p.accent)
                .frame(width: 44, height: 44)
                .background(p.accent.opacity(0.08), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(p.accent)
                Text(filename)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(p.text)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(p.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(p.border, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}


private struct MARCRemoteFilePreview: UIViewControllerRepresentable {
    let file: MARCLocalDownload

    func makeCoordinator() -> Coordinator {
        Coordinator(file: file)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let preview = QLPreviewController()
        preview.dataSource = context.coordinator

        let navigation = UINavigationController(rootViewController: preview)
        preview.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.close)
        )
        context.coordinator.navigation = navigation
        return navigation
    }

    func updateUIViewController(
        _ controller: UINavigationController, context: Context
    ) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let file: MARCLocalDownload
        weak var navigation: UINavigationController?

        init(file: MARCLocalDownload) {
            self.file = file
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            file.url as NSURL
        }

        @objc func close() {
            navigation?.dismiss(animated: true)
        }
    }
}


private actor MARCTransferIO {
    private var handle: FileHandle?

    init(forReadingFrom url: URL) throws {
        handle = try FileHandle(forReadingFrom: url)
    }

    init(forWritingTo url: URL) throws {
        handle = try FileHandle(forWritingTo: url)
    }

    func readChunk() throws -> Data {
        try Task.checkCancellation()
        guard let handle else {
            throw CocoaError(.fileReadUnknown)
        }
        return try handle.read(upToCount: 32768) ?? Data()
    }

    func writeChunk(_ data: Data) throws {
        try Task.checkCancellation()
        guard let handle else {
            throw CocoaError(.fileWriteUnknown)
        }
        try handle.write(contentsOf: data)
    }

    func close() throws {
        guard let current = handle else { return }
        try current.close()
        handle = nil
    }
}

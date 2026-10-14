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
    @State private var query = ""
    @State private var terminating: MARCProcess?
    @State private var scrolling = false
    @State private var scrollOrder: [Int] = []
    @State private var sorting = "CPU"
    @State private var processes: [MARCProcess] = []
    @State private var failure: String?
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    private func sortedRows(_ rows: [MARCProcess]) -> [MARCProcess] {
        rows.sorted {
            switch sorting {
            case "Memory":
                return $0.memory == $1.memory
                    ? $0.pid < $1.pid : $0.memory > $1.memory
            case "Name":
                let order = $0.name.localizedCaseInsensitiveCompare($1.name)
                return order == .orderedSame
                    ? $0.pid < $1.pid : order == .orderedAscending
            default:
                return $0.cpu == $1.cpu
                    ? $0.pid < $1.pid : $0.cpu > $1.cpu
            }
        }
    }

    private var visible: [MARCProcess] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates: [MARCProcess]
        if search.isEmpty {
            candidates = Array(processes.prefix(50))
        } else {
            candidates = processes.filter {
                $0.name.localizedCaseInsensitiveContains(search) ||
                $0.user.localizedCaseInsensitiveContains(search) ||
                String($0.pid).contains(search)
            }
        }

        let sorted = sortedRows(candidates)
        guard scrolling, !scrollOrder.isEmpty else { return sorted }
        let positions = Dictionary(
            uniqueKeysWithValues: scrollOrder.enumerated().map { ($0.element, $0.offset) }
        )
        return sorted.sorted {
            let left = positions[$0.pid] ?? Int.max
            let right = positions[$1.pid] ?? Int.max
            return left == right ? $0.pid < $1.pid : left < right
        }
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
        VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Processes")
                        .font(.system(size: 22, weight: .semibold))
                    Spacer()
                    Text("\(monitor.connected ? monitor.processTotalCount : 0) total")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(p.muted)
                }

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
                } else if processes.isEmpty {
                    Text("Loading processes…")
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

                    ForEach(visible) { process in
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

                            Text(String(format: "%.1f%%", process.cpu))
                                .foregroundStyle(Color(marcHex: 0x2dcc58))
                                .frame(width: 52, alignment: .trailing)

                            Text(ByteCountFormatter.string(
                                fromByteCount: Int64(process.memory),
                                countStyle: .binary
                            ))
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
                            guard monitor.connected else { return }
                            terminating = process
                        }
                        .accessibilityHint("Tap for termination confirmation")
                    }

                    if visible.isEmpty {
                        Text("No matching processes.")
                            .font(.system(size: 12))
                            .foregroundStyle(p.muted)
                    }


                }
                    }
                    .padding(.bottom, 96)
                }
                .scrollIndicators(.visible)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .marcCanvas()
        .sheet(item: $terminating) { process in
            MARCTerminationSheet(process: process) {
                try await monitor.terminateProcess(process)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onScrollPhaseChange { _, phase in
            if phase != .idle && !scrolling {
                scrollOrder = visible.map(\.pid)
            }
            scrolling = phase != .idle
            if !scrolling { scrollOrder = [] }
        }
        .task(id: "\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)") {
            processes = []
            scrollOrder = []
            failure = nil
            guard monitor.connected else { return }

            while !Task.isCancelled && monitor.connected {
                do {
                    let stream = try await monitor.processUpdates()
                    for try await response in stream {
                        guard !Task.isCancelled else { return }
                        accept(response.processes)
                        failure = nil
                    }
                    guard !Task.isCancelled else { return }
                    failure = "Process stream stopped. Retrying…"
                } catch is CancellationError {
                    return
                } catch {
                    guard !Task.isCancelled else { return }
                    failure = "Updates delayed. Reconnecting process stream…"
                }
                do {
                    try await Task.sleep(for: .seconds(3))
                } catch { return }
            }
        }
    }
}


private struct MARCRemoteEntry: Identifiable {
    let name: String
    let path: String
    let directory: Bool
    let size: UInt64?
    let modified: Date?
    var id: String { path }
}

private struct MARCFileExport: Identifiable {
    let id = UUID()
    let url: URL
}

@MainActor @Observable
private final class MARCRemoteFiles {
    var entries: [MARCRemoteEntry] = []
    var path = ""
    var home = ""
    var ready = false
    var busy = false
    var transferring = false
    var progress = 0.0
    var activity = ""
    var failure: String?
    var notice: String?
    var downloaded: URL?
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

    func connect(server: ServerProfile) async {
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
            let client = try await connection.openSFTP()
            subsystem = client
            try Task.checkCancellation()
            guard generation == id else { throw CancellationError() }

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
                    try Task.checkCancellation()
                    rows = try await listing(initial, using: client)
                }
            } else {
                rows = try await listing(initial, using: client)
            }
            try Task.checkCancellation()
            guard generation == id else { throw CancellationError() }

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
                    modified: $0.attributes.accessModificationTime?.modificationTime
                )
            }
            .sorted {
                if $0.directory != $1.directory { return $0.directory }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    private func joined(_ parent: String, _ name: String) -> String {
        parent == "/" ? "/" + name : parent + "/" + name
    }

    func browse(_ requested: String) {
        guard ready, !busy, let client = sftp else { return }
        let id = generation
        busy = true
        failure = nil
        notice = nil

        operation = Task { @MainActor in
            defer { if generation == id { busy = false; operation = nil } }
            do {
                let canonical = try await client.getRealPath(atPath: requested)
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

        let value = total > 0
            ? min(1, Double(completed) / Double(total)) : 0
        if progress != value { progress = value }
    }

    func cancelTransfer() {
        operation?.cancel()
    }

    func upload(_ url: URL) {
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
        progress = 0
        lastProgressUpdate = nil
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
                let values = try url.resourceValues(
                    forKeys: [.isRegularFileKey, .fileSizeKey]
                )
                guard values.isRegularFile == true else {
                    throw MARCAIError.message("Choose a file rather than a folder.")
                }
                let total = UInt64(max(0, values.fileSize ?? 0))
                let input = try MARCTransferIO(forReadingFrom: url)
                local = input
                let file = try await client.openFile(
                    filePath: temporary,
                    flags: [.write, .create, .forceCreate]
                )
                remote = file
                created = true
                var offset: UInt64 = 0

                while true {
                    try Task.checkCancellation()
                    guard generation == id else { throw CancellationError() }
                    let data = try await input.readChunk()
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
                try Task.checkCancellation()
                guard generation == id else { throw CancellationError() }

                try await client.rename(at: temporary, to: destination)
                created = false
                let rows = try await listing(folder, using: client)
                guard generation == id else { return }
                entries = rows
                progress = 1
                path = folder
                lastUploadedPath = destination
                completionEvent = UUID()
                completionTitle = "Upload complete"
                completionPath = destination
                notice = nil
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

    func download(_ entry: MARCRemoteEntry) {
        guard ready, !busy, !entry.directory, let client = sftp else { return }
        let id = generation
        busy = true
        transferring = true
        progress = 0
        lastProgressUpdate = nil
        activity = "Downloading \(entry.name)"
        downloaded = nil
        failure = nil
        notice = nil

        operation = Task { @MainActor in
            defer {
                if generation == id {
                    busy = false
                    transferring = false
                    operation = nil
                }
            }
            var remote: SFTPFile?
            var local: MARCTransferIO?
            var directory: URL?

            do {
                let attributes = try await client.getAttributes(at: entry.path)
                if let mode = attributes.permissions,
                   (mode & 0xF000) != 0x8000 {
                    throw MARCAIError.message("Download a regular file, not a folder or device.")
                }
                guard let total = attributes.size else {
                    throw MARCAIError.message("The server did not provide this file’s size.")
                }

                let folder = FileManager.default.temporaryDirectory
                    .appendingPathComponent("MARC-\(UUID().uuidString)", isDirectory: true)
                directory = folder
                try FileManager.default.createDirectory(
                    at: folder, withIntermediateDirectories: true
                )
                let destination = folder.appendingPathComponent(entry.name)
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
                    try Task.checkCancellation()
                    guard generation == id else { throw CancellationError() }
                    let length = UInt32(min(UInt64(32768), total - offset))
                    let buffer = try await file.read(from: offset, length: length)
                    guard buffer.readableBytes > 0 else {
                        throw MARCAIError.message("The remote file changed during download.")
                    }
                    try await output.writeChunk(Data(buffer.readableBytesView))
                    offset += UInt64(buffer.readableBytes)
                    if generation == id {
                        publishTransferProgress(completed: offset, total: total)
                    }
                }

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
                try Task.checkCancellation()
                guard generation == id else { throw CancellationError() }

                progress = 1
                completionEvent = UUID()
                completionTitle = "Download complete"
                completionPath = entry.path
                notice = "Choose Save to Files in the share sheet to keep your download."
                downloaded = destination
            } catch {
                try? await remote?.close()
                try? await local?.close()
                if let directory { try? FileManager.default.removeItem(at: directory) }
                guard generation == id else { return }
                if Task.isCancelled {
                    notice = "Download cancelled."
                } else {
                    failure = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct FilesScreen: View {
    let monitor: SSHMonitor
    @State private var files = MARCRemoteFiles()
    @State private var search = ""
    @State private var showHidden = false
    @State private var importing = false
    @State private var choosingPhoto = false
    @State private var photoSelection: PhotosPickerItem?
    @State private var preparingPhoto = false
    @State private var export: MARCFileExport?
    @State private var preview: MARCFileExport?
    @State private var previewRequested = false
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Files")
                        .font(.system(size: 22, weight: .semibold))
                    Text(monitor.server?.name ?? "No connected Mac")
                        .font(.system(size: 11))
                        .foregroundStyle(p.muted)
                }
                Spacer()
                Button {
                    files.browse(files.path)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 40, height: 40)
                }
                .disabled(!files.ready || files.busy)
                .accessibilityLabel("Refresh folder")

                Menu {
                    Button {
                        importing = true
                    } label: {
                        Label("Files", systemImage: "folder")
                    }
                    Button {
                        photoSelection = nil
                        choosingPhoto = true
                    } label: {
                        Label("Photos & Videos", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 40, height: 40)
                }
                .disabled(!files.ready || files.busy || preparingPhoto)
                .accessibilityLabel("Choose upload source")
            }
            .foregroundStyle(p.accent)

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





            if let failure = files.failure {
                Text(failure)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let notice = files.notice {
                Text(notice)
                    .font(.system(size: 11))
                    .foregroundStyle(p.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollViewReader { scroll in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(visibleEntries) { entry in
                        Button {
                            if entry.directory {
                                search = ""
                                files.browse(entry.path)
                            } else {
                                previewRequested = true
                                files.download(entry)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: entry.directory ? "folder.fill" : "doc")
                                    .font(.system(size: 20))
                                    .foregroundStyle(entry.directory ? p.accent : p.muted)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(p.text)
                                        .lineLimit(2)
                                    Text(detail(entry))
                                        .font(.system(size: 10))
                                        .foregroundStyle(p.muted)
                                }
                                Spacer(minLength: 6)
                                if entry.directory {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundStyle(p.muted)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                entry.path == files.lastUploadedPath
                                    ? p.accent.opacity(0.12) : p.surface
                            )
                            .overlay(alignment: .leading) {
                                if entry.path == files.lastUploadedPath {
                                    Rectangle()
                                        .fill(p.accent)
                                        .frame(width: 3)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(files.busy || !files.ready)
                        .contextMenu {
                            if !entry.directory {
                                Button {
                                    previewRequested = false
                                    files.download(entry)
                                } label: {
                                    Label("Download", systemImage: "arrow.down")
                                }
                                .disabled(files.busy || !files.ready)
                            }
                            Button {
                                UIPasteboard.general.string = entry.path
                            } label: {
                                Label("Copy path", systemImage: "document.on.document")
                            }
                        }
                        .accessibilityHint(
                            entry.directory
                                ? "Open folder"
                                : "Preview file. Long-press for Download."
                        )
                        .id(entry.id)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if files.busy && !files.transferring {
                    ProgressView().padding(24)
                } else if visibleEntries.isEmpty {
                    Text(files.ready
                         ? (search.isEmpty ? "This folder is empty." : "No matching files.")
                         : (monitor.connected ? "Files connection unavailable." : "Connect a Mac in Settings."))
                        .font(.system(size: 12))
                        .foregroundStyle(p.muted)
                        .padding(30)
                }
            }
            .contentMargins(.bottom, 88, for: .scrollContent)
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
        .marcCanvas()
        .overlay {
            if preparingPhoto || files.transferring ||
                files.completionTitle != nil {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
            if preparingPhoto {
                MARCFileTransferCard(
                    title: "Preparing photo or video",
                    progress: nil,
                    preparing: true,
                    cancel: nil
                )
            } else if files.transferring {
                MARCFileTransferCard(
                    title: files.activity,
                    progress: files.progress,
                    preparing: false,
                    cancel: { files.cancelTransfer() }
                )
            }
            if let title = files.completionTitle {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(marcHex: 0x2dcc58))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(p.text)
                        Text(files.completionPath)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(p.muted)
                            .lineLimit(3)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        files.completionTitle = nil
                        files.lastUploadedPath = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Dismiss transfer confirmation")
                }
                .padding(14)
                .background(p.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            Color(marcHex: 0x2dcc58).opacity(0.35),
                            lineWidth: 1
                        )
                )
            }
                    }
                    .frame(maxWidth: 340)
                    .padding(24)
                    .shadow(
                        color: .black.opacity(0.14),
                        radius: 20,
                        y: 8
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: preparingPhoto || files.transferring ||
                files.completionTitle != nil
        )
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

        .toolbar(.hidden, for: .navigationBar)
        .task(id: connectionID) {
            files.stop()
            guard scenePhase != .background, monitor.connected,
                  let server = monitor.server else { return }
            await files.connect(server: server)
        }
        .onDisappear {
            if !choosingPhoto && !importing && !preparingPhoto &&
                preview == nil && export == nil {
                files.stop()
            }
        }
        .photosPicker(
            isPresented: $choosingPhoto,
            selection: $photoSelection,
            matching: .any(of: [.images, .videos]),
            preferredItemEncoding: .current
        )
        .task(id: photoSelection) {
            guard let item = photoSelection else { return }
            let serverID = monitor.server?.id
            let folder = files.path
            preparingPhoto = true
            var imported: URL?

            defer { preparingPhoto = false }

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
                      monitor.server?.id == serverID,
                      files.path == folder,
                      files.ready, !files.busy else {
                    throw MARCAIError.message(
                        "The destination changed. Select the item again."
                    )
                }

                let destination = folder == "/"
                    ? "/" + media.url.lastPathComponent
                    : folder + "/" + media.url.lastPathComponent

                guard !files.entries.contains(where: {
                    $0.path == destination
                }) else {
                    throw MARCAIError.message(
                        "A file with this name already exists in this folder."
                    )
                }

                files.upload(media.url)
                imported = nil
            } catch {
                if let imported {
                    try? FileManager.default.removeItem(
                        at: imported.deletingLastPathComponent()
                    )
                }
                if !Task.isCancelled {
                    files.failure = error.localizedDescription
                }
            }
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.item]
        ) { result in
            switch result {
            case .success(let url): files.upload(url)
            case .failure(let error): files.failure = error.localizedDescription
            }
        }
        .onChange(of: files.downloaded) { _, url in
            guard let url else { return }
            if previewRequested {
                preview = MARCFileExport(url: url)
            } else {
                export = MARCFileExport(url: url)
            }
        }
        .sheet(item: $preview, onDismiss: cleanLocalDownload) { item in
            MARCRemoteFilePreview(url: item.url)
        }
        .sheet(item: $export, onDismiss: cleanLocalDownload) { item in
            MARCFilesShareSheet(url: item.url)
        }
    }

    private func cleanLocalDownload() {
        guard let url = files.downloaded else { return }
        let folder = url.deletingLastPathComponent()
        if folder.lastPathComponent.hasPrefix("MARC-") &&
            folder.deletingLastPathComponent().standardizedFileURL ==
            FileManager.default.temporaryDirectory.standardizedFileURL {
            try? FileManager.default.removeItem(at: folder)
        }
        files.downloaded = nil
        previewRequested = false
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
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [url], applicationActivities: nil
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
    @State private var wirelessReadAt: Date?
    @State private var revision = UUID()

@State private var confirmWiFiOff = false
    @State private var mediaPlayer = 0
    @State private var confirmLock = false
    @State private var showControlDetails = false
    @State private var showMediaSetup = false
    @State private var copiedMediaCommand = false
    @State private var showDisplayActions = false
    private var controlsEnabled: Bool { usable && !busy && !refreshing }

    private var usable: Bool { monitor.connected && scenePhase == .active }
    private var connectionID: String {
        "\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)-\(scenePhase)"
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
                    controlFeedback(for: [.lock, .displaySleep], palette: p)
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

                    controlFeedback(for: [.wifi, .bluetooth], palette: p)
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
                            enabled: controlsEnabled,
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
                            enabled: controlsEnabled,
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

                controlFeedback(for: [.volume, .brightness], palette: p)


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

                    controlFeedback(for: [.mute, .output], palette: p)

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

            .task(id: connectionID) {
                revision = UUID()
                busy = false
                refreshing = false
                editingVolume = false
                editingBrightness = false
                feedbackAction = nil
                brightness = 0
                selectedDisplayID = nil
                state = nil
                volume = 0
                failure = nil
                notice = nil
                wirelessReadAt = nil
                guard usable else { return }
                while !Task.isCancelled && usable {
                    let wireless = wirelessReadAt.map { Date().timeIntervalSince($0) >= 30 } ?? true
                    await refresh(wireless: wireless)
                    do { try await Task.sleep(for: .seconds(5)) }
                    catch { return }
                }
            }
            .onDisappear {
                revision = UUID()
                busy = false
                notice = nil
            }
            .task(id: noticeEvent) {
                guard notice != nil else { return }
                do { try await Task.sleep(for: .seconds(2)) }
                catch { return }
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

    private func controlFeedback(
        for actions: [MARCControlAction], palette: MARCPalette
    ) -> some View {
        EmptyView()
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
        if response.wirelessIncluded { wirelessReadAt = Date() }
    }
    @MainActor
    private func refresh(wireless: Bool) async {
        guard usable, !busy, !refreshing, !editingVolume, !editingBrightness else { return }
        refreshing = true
        let token = revision
        defer { if revision == token { refreshing = false } }
        do {
            let response = try await monitor.marcControlRequest(includeWireless: wireless, displayID: selectedDisplayID)
            guard revision == token, !busy, !editingVolume, !editingBrightness, !Task.isCancelled else { return }
            accept(response)
            if failure == "Live controls could not refresh. Tap refresh to retry." { failure = nil }
        } catch is CancellationError {} catch {
            guard revision == token, !Task.isCancelled else { return }
            feedbackAction = nil
            failure = "Live controls could not refresh. Tap refresh to retry."
        }
    }
    @MainActor
    private func send(_ action: MARCControlAction, value: Int) {
        guard controlsEnabled else { return }
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
        Task { @MainActor in
            defer { if revision == token { busy = false } }
            do {
                let response = try await monitor.marcControlRequest(action, value: value,
                    includeWireless: action == .wifi || action == .bluetooth, displayID: selectedDisplayID)
                guard revision == token, usable else { return }
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
                guard revision == token else { return }
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
                            fromByteCount: Int64(process.memory),
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

                    Button {
                        busy = true
                        failure = nil
                        Task { @MainActor in
                            defer { busy = false }
                            do {
                                try await terminate()
                                dismiss()
                            } catch {
                                failure = error.localizedDescription
                            }
                        }
                    } label: {
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
                    .disabled(busy)
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


private struct MARCFileTransferCard: View {
    let title: String
    let progress: Double?
    let preparing: Bool
    let cancel: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        let value = min(1, max(0, progress ?? 0))

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(p.accent.opacity(0.10))
                        .frame(width: 42, height: 42)
                        .scaleEffect(reduceMotion ? 1 : (pulsing ? 1.08 : 0.94))
                        .animation(
                            reduceMotion ? nil :
                                .easeInOut(duration: 0.85)
                                    .repeatForever(autoreverses: true),
                            value: pulsing
                        )

                    ProgressView()
                        .controlSize(.small)
                        .tint(p.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(p.text)
                        .lineLimit(2)
                    Text(preparing
                         ? "Preparing the selected item, including iCloud download if needed."
                         : "Keep MARC open until the transfer finishes.")
                        .font(.system(size: 10))
                        .foregroundStyle(p.muted)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                if !preparing {
                    Text("\(Int(value * 100))%")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(p.accent)
                        .monospacedDigit()
                }
            }

            if progress != nil {
                ProgressView(value: value)
                    .tint(p.accent)
            }

            if let cancel {
                HStack {
                    Spacer()
                    Button("Cancel transfer", action: cancel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(p.accent)
                        .frame(minHeight: 32)
                }
            }
        }
        .padding(14)
        .background(p.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(p.accent.opacity(0.30), lineWidth: 1)
        )
        .onAppear { pulsing = true }
    }
}


private struct MARCRemoteFilePreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
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
        let url: URL
        weak var navigation: UINavigationController?

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            url as NSURL
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

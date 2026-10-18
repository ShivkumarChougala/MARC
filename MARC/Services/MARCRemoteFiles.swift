import Foundation
import Observation
import Citadel
import NIOCore

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

struct MARCUploadConflict: Identifiable, Sendable {
    let id = UUID()
    let name: String
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
    var uploadConflict: MARCUploadConflict?
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
    @ObservationIgnored private var replacementChoice: CheckedContinuation<Bool, Never>?

    func stop() {
        if let conflict = uploadConflict { resolveUploadConflict(conflict.id, replace: false) }
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
        if let conflict = uploadConflict { resolveUploadConflict(conflict.id, replace: false) }
    }

    func resolveUploadConflict(_ id: UUID, replace: Bool) {
        guard uploadConflict?.id == id else { return }
        uploadConflict = nil
        let choice = replacementChoice
        replacementChoice = nil
        choice?.resume(returning: replace)
    }

    private func confirmReplacement(name: String, operationID: UUID) async -> Bool {
        let conflict = MARCUploadConflict(name: name)
        return await withTaskCancellationHandler {
            await withCheckedContinuation { choice in
                guard generation == operationID, !Task.isCancelled else {
                    choice.resume(returning: false)
                    return
                }
                replacementChoice = choice
                uploadConflict = conflict
                transferPhase = "Waiting for confirmation"
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.resolveUploadConflict(conflict.id, replace: false)
            }
        }
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
        guard ready, !busy, let client = sftp, let connection = ssh else { return }
        let id = generation
        let folder = path
        let name = url.lastPathComponent
        guard !name.isEmpty, name != ".", name != "..",
              !name.contains("/"), !name.contains("\0") else { return }

        let destination = joined(folder, name)
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
                let target = try await MARCFileBridge.request(
                    ["action": "uploadTarget", "path": destination], using: connection
                )
                try checkOperation(id)
                let replacementFingerprint = target.uploadFingerprint
                if replacementFingerprint != nil {
                    guard await confirmReplacement(name: name, operationID: id) else {
                        throw CancellationError()
                    }
                    try checkOperation(id)
                }
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
                if let replacementFingerprint {
                    _ = try await MARCFileBridge.request(
                        ["action": "replaceUpload", "path": destination, "staged": temporary,
                         "fingerprint": replacementFingerprint, "size": offset], using: connection
                    )
                } else {
                    try await client.rename(at: temporary, to: destination)
                }
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
                        failure = "Upload complete, but the folder could not refresh. Choose Reload Folder to update the list."
                    }
                }
            } catch {
                try? await remote?.close()
                try? await local?.close()
                if created { try? await client.remove(at: temporary) }
                guard generation == id else { return }
                if Task.isCancelled || error is CancellationError {
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
                    failure = "The action completed, but the folder could not refresh. Choose Reload Folder to update the list."
                }
            }
            try checkOperation(token)
            if action == "delete" {
                completionEvent = UUID()
                completionTitle = entry.directory ? "Folder deleted" : "File deleted"
                completionPath = entry.path
                notice = nil
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

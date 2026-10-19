#!/usr/bin/env python3
"""Compile production task owners against in-memory SSH/SFTP doubles on macOS.
Exercises cancellation and interleaving without network, Keychain or remote changes.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
terminal = (root / 'MARC/Screens/MARCTerminalScreen.swift').read_text()
files = (root / 'MARC/Services/MARCRemoteFiles.swift').read_text()
operations = (root / 'MARC/Services/MARCFileOperations.swift').read_text()
terminal_session = terminal[:terminal.index('struct MARCTerminalSurface:')]
terminal_session = '\n'.join(line for line in terminal_session.splitlines() if 'import ' not in line)
workspace = terminal[terminal.index('@MainActor @Observable\nfinal class MARCTerminalSlot:'):terminal.index('struct TerminalScreen:')]
remote_files = files[files.index('struct MARCRemoteEntry:'):files.index('private actor MARCTransferIO {')]
transfer_io = files[files.index('private actor MARCTransferIO {'):]
reply_types = operations[operations.index('struct MARCFileInfo:'):operations.index('enum MARCFileBridge {')]
formatting = (root / 'MARC/Services/MARCFileFormatting.swift').read_text()
local_download = (root / 'MARC/Services/MARCLocalDownload.swift').read_text()

support = r'''
struct ServerProfile {
    let id: UUID
    var name = "Fixture"
    var host = "test.invalid"
    var port = 22
    var username = "fixture"
}
enum MARCAIError: LocalizedError {
    case message(String)
    var errorDescription: String? { switch self { case .message(let message): return message } }
}
@MainActor enum SwiftTerm {
    final class TerminalView {
        func feed(byteArray: ArraySlice<UInt8>) {}
        func layoutIfNeeded() {}
        func scroll(toPosition: Double) {}
        func setNeedsDisplay() {}
        @discardableResult func resignFirstResponder() -> Bool { true }
    }
}
struct ByteBuffer {
    var readableBytesView: [UInt8] = []
    var readableBytes: Int { readableBytesView.count }
    mutating func writeBytes<C: Collection>(_ bytes: C) where C.Element == UInt8 { readableBytesView.append(contentsOf: bytes) }
}
enum FixtureEvent { case stdout(ByteBuffer), stderr(ByteBuffer) }
struct SSHTerminalModes { init(_ modes: [Int: Int]) {} }
enum SSHChannelRequestEvent {
    struct PseudoTerminalRequest {
        let wantReply: Bool
        let term: String
        let terminalCharacterWidth: Int
        let terminalRowHeight: Int
        let terminalPixelWidth: Int
        let terminalPixelHeight: Int
        let terminalModes: SSHTerminalModes
    }
}
struct SSHClientSettings {
    let host: String
    let port: Int
    let authenticationMethod: String
    let hostKeyValidator: String
    var connectTimeout: Duration = .seconds(10)
}
@MainActor final class Gate {
    var entered = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; await withCheckedContinuation { continuation = $0 } }
    func open() { continuation?.resume(); continuation = nil }
}
@MainActor final class TTYStdinWriter {
    var sizes: [(Int, Int)] = []
    var resizeHook: (() async -> Void)?
    func changeSize(cols: Int, rows: Int, pixelWidth: Int, pixelHeight: Int) async throws {
        sizes.append((cols, rows))
        if let hook = resizeHook { await hook() }
    }
    func write(_ buffer: ByteBuffer) async throws {}
}
@MainActor final class SSHClient {
    static var attempts = 0
    static var subsystemOpens = 0
    static var connectHook: ((String) async -> Void)?
    static let sftp = SFTPClient()
    static var latestWriter: TTYStdinWriter?
    private var continuation: AsyncThrowingStream<FixtureEvent, Error>.Continuation?
    static func connect(to settings: SSHClientSettings) async throws -> SSHClient {
        attempts += 1
        if let hook = connectHook { await hook(settings.host) }
        return SSHClient()
    }
    func openSFTP() async throws -> SFTPClient { Self.subsystemOpens += 1; return Self.sftp }
    func withPTY(_ request: SSHChannelRequestEvent.PseudoTerminalRequest,
                 body: @MainActor (AsyncThrowingStream<FixtureEvent, Error>, TTYStdinWriter) async throws -> Void) async throws {
        let writer = TTYStdinWriter(); Self.latestWriter = writer
        let stream = AsyncThrowingStream<FixtureEvent, Error> { continuation = $0 }
        try await body(stream, writer)
    }
    func close() async throws { continuation?.finish(); continuation = nil }
}
struct FixtureFlags: OptionSet {
    let rawValue: Int
    static let read = Self(rawValue: 1)
    static let write = Self(rawValue: 2)
    static let create = Self(rawValue: 4)
    static let forceCreate = Self(rawValue: 8)
}
struct FixtureTimes { var modificationTime = Date(timeIntervalSince1970: 100) }
struct FixtureAttributes {
    var size: UInt64?
    var permissions: UInt32? = 0o100644
    var accessModificationTime: FixtureTimes? = FixtureTimes()
}
struct FixtureEntry { let filename: String; let longname: String; let attributes: FixtureAttributes }
struct FixtureBatch { let components: [FixtureEntry] }
@MainActor final class SFTPClient {
    var data: [String: Data] = [:]
    var opens = 0
    var failRefreshAfterRename = false
    private var refreshFails = false
    var readHook: (() async -> Void)?
    var writeHook: (() async throws -> Void)?
    var failRead = false
    var closeFileHook: ((String) async -> Void)?
    func getRealPath(atPath path: String) async throws -> String { path == "." ? "/fixture" : path }
    func listDirectory(atPath path: String) async throws -> [FixtureBatch] {
        if refreshFails { refreshFails = false; throw MARCAIError.message("Fixture refresh failure") }
        return []
    }
    func getAttributes(at path: String) async throws -> FixtureAttributes {
        FixtureAttributes(size: UInt64(data[path]?.count ?? 0))
    }
    func openFile(filePath: String, flags: FixtureFlags) async throws -> SFTPFile {
        opens += 1
        if flags.contains(.create) { data[filePath] = Data() }
        return SFTPFile(client: self, path: filePath)
    }
    func rename(at path: String, to destination: String) async throws {
        guard data[destination] == nil else { throw MARCAIError.message("Fixture destination exists") }
        data[destination] = data.removeValue(forKey: path)
        refreshFails = failRefreshAfterRename
    }
    func remove(at path: String) async throws { data[path] = nil }
    func close() async throws {}
}
@MainActor final class SFTPFile {
    let client: SFTPClient
    let path: String
    init(client: SFTPClient, path: String) { self.client = client; self.path = path }
    func write(_ buffer: ByteBuffer, at offset: UInt64) async throws {
        var value = client.data[path] ?? Data()
        value.append(contentsOf: buffer.readableBytesView)
        client.data[path] = value
        if let hook = client.writeHook { try await hook() }
    }
    func read(from offset: UInt64, length: UInt32) async throws -> ByteBuffer {
        if let hook = client.readHook { await hook() }
        if client.failRead { throw MARCAIError.message("Fixture read failure") }
        let value = client.data[path] ?? Data()
        let start = min(Int(offset), value.count)
        let end = min(start + Int(length), value.count)
        return ByteBuffer(readableBytesView: Array(value[start..<end]))
    }
    func close() async throws { if let hook = client.closeFileHook { await hook(path) } }
}
@MainActor enum MARCFileBridge {
    static var actions: [String] = []
    static var failingAction: String?
    static var hook: ((String) async -> Void)?
    static func request(_ request: [String: Any], using ssh: SSHClient) async throws -> MARCFileReply {
        let action = request["action"] as! String
        actions.append(action)
        if action == failingAction { throw MARCAIError.message("Fixture action failure") }
        if let hook { await hook(action) }
        let sftp = SSHClient.sftp
        func fingerprint(_ data: Data) -> [String] { [String(data.count), data.base64EncodedString()] }
        if action == "uploadTarget" {
            let data = sftp.data[request["path"] as! String]
            return MARCFileReply(error: nil, info: nil, text: nil, archive: nil,
                archiveDirectory: nil, uploadFingerprint: data.map(fingerprint))
        }
        if action == "replaceUpload" {
            let path = request["path"] as! String
            let stage = request["staged"] as! String
            guard let original = sftp.data[path],
                  request["fingerprint"] as? [String] == fingerprint(original),
                  let replacement = sftp.data[stage],
                  request["size"] as? UInt64 == UInt64(replacement.count) else {
                throw MARCAIError.message("The destination changed")
            }
            sftp.data[path] = replacement
            sftp.data[stage] = nil
        }
        return MARCFileReply(error: nil, info: nil, text: nil,
            archive: action == "archive" ? "/fixture/archive.tar.gz" : nil,
            archiveDirectory: action == "archive" ? "/fixture/archive-temp" : nil)
    }
}
enum MARCCredentials {
    struct Saved { let hostKey = "fixture" }
    static func read(_ id: UUID) -> Saved? { Saved() }
}
enum SSHConnectionTest {
    static func hostKeyValidator(server: ServerProfile, publicHostKey: String) throws -> String { publicHostKey }
}
enum MARCLogin {
    static func authentication(_ login: MARCCredentials.Saved, username: String) throws -> String { "fixture" }
}
enum MARCConnectionIssue {
    static func message(_ error: Error, login: MARCCredentials.Saved?) -> String { error.localizedDescription }
}
extension MARCTerminalSession { func resizeIdleFixture() -> Bool { resizing == nil } }
extension MARCRemoteFiles { func operationFixture() -> Task<Void, Never>? { operation } }
'''
checks = r'''
@main struct TaskChecks {
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<20000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Fixture did not reach expected state")
    }
    @MainActor static func main() async throws {
        let a = ServerProfile(id: UUID(), host: "first.invalid")
        let b = ServerProfile(id: UUID(), host: "second.invalid")
        defer {
            for server in [a, b] { UserDefaults.standard.removeObject(forKey: "marc.files.lastFolder.\(server.id.uuidString)") }
        }
        let session = MARCTerminalSession()
        let cancelled = Task { await session.run(server: a) }
        cancelled.cancel(); await cancelled.value
        precondition(SSHClient.attempts == 0 && session.status == "Offline")

        let workspace = MARCTerminalWorkspace()
        workspace.prepare(server: a)
        workspace.reconnectSelected()
        await waitFor { workspace.selected?.session.ready == true }
        precondition(SSHClient.attempts == 1, "A cancelled queued shell must not start")
        let first = workspace.selected!
        let writer = SSHClient.latestWriter!
        let resizeGate = Gate()
        writer.resizeHook = { await resizeGate.wait() }
        let initialSizes = writer.sizes.count
        first.session.resize(cols: 100, rows: 30)
        await waitFor { resizeGate.entered }
        first.session.resize(cols: 120, rows: 40)
        first.session.resize(cols: 140, rows: 50)
        precondition(writer.sizes.count == initialSizes + 1)
        writer.resizeHook = nil; resizeGate.open()
        await waitFor { first.session.resizeIdleFixture() }
        precondition(writer.sizes.last!.0 == 140 && writer.sizes.last!.1 == 50)
        precondition(writer.sizes.count == initialSizes + 2, "Resize should coalesce pending dimensions")
        workspace.add()
        await waitFor { workspace.selected?.session.ready == true }
        let second = workspace.selected!
        let attempts = SSHClient.attempts
        workspace.select(first)
        precondition(first.session.ready && SSHClient.attempts == attempts)
        workspace.close(second)
        precondition(first.session.ready)
        first.session.controlArmed = true; first.session.altArmed = true
        workspace.pause()
        precondition(!first.session.ready && !first.session.controlArmed && !first.session.altArmed)

        let files = MARCRemoteFiles()
        let cancelledFiles = Task { await files.prepare(server: a) }
        cancelledFiles.cancel(); await cancelledFiles.value
        precondition(!files.busy && !files.ready && SSHClient.attempts == attempts)
        let connectGate = Gate()
        SSHClient.connectHook = { host in if host == a.host { await connectGate.wait() } }
        let oldConnect = Task { await files.prepare(server: a) }
        await waitFor { connectGate.entered }
        files.stop()
        await files.prepare(server: b)
        let subsystems = SSHClient.subsystemOpens
        connectGate.open(); await oldConnect.value; SSHClient.connectHook = nil
        precondition(files.ready && SSHClient.subsystemOpens == subsystems,
                     "A stale connection must not open an SFTP subsystem")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("MARC-task-fixture-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let upload = directory.appendingPathComponent("fixture.txt")
        let content = Data("fixture".utf8)
        try content.write(to: upload)
        let sftp = SSHClient.sftp
        let opens = sftp.opens
        let oldDestination = files.captureDestination()!
        files.upload(upload)
        let queuedUpload = files.operationFixture()
        files.stop()
        await files.prepare(server: b)
        await queuedUpload?.value
        precondition(sftp.opens == opens && files.transferTotal == nil && files.failure == nil)
        files.upload(upload, to: oldDestination)
        precondition(sftp.opens == opens && !files.busy && files.failure?.contains("destination changed") == true,
                     "A picker result from an old connection must not upload to a reconnected session")

        let folder = MARCRemoteEntry(name: "folder", path: "/fixture/folder", directory: true, size: nil, modified: nil, mode: nil)
        let actions = MARCFileBridge.actions.count
        files.downloadFolder(folder)
        precondition(files.busy && files.transferring)
        files.downloadFolder(folder); files.cancelTransfer()
        await waitFor { !files.busy }
        precondition(MARCFileBridge.actions.count == actions && files.notice?.contains("cancelled") == true)
        let archiveGate = Gate()
        MARCFileBridge.hook = { action in if action == "archive" { await archiveGate.wait() } }
        files.downloadFolder(folder)
        await waitFor { archiveGate.entered }
        files.cancelTransfer(); archiveGate.open()
        await waitFor { !files.busy }
        MARCFileBridge.hook = nil
        precondition(MARCFileBridge.actions.contains("cleanupArchive") && sftp.opens == opens)

        let transferGate = Gate()
        sftp.data["/fixture/archive.tar.gz"] = Data([4, 5])
        sftp.readHook = { await transferGate.wait() }
        let cleanups = MARCFileBridge.actions.filter { $0 == "cleanupArchive" }.count
        files.downloadFolder(folder)
        await waitFor { transferGate.entered }
        precondition(files.busy && files.transferring, "Archive handoff must retain transfer ownership")
        let folderTransfer = files.operationFixture()
        files.cancelTransfer(); sftp.readHook = nil; transferGate.open()
        await folderTransfer?.value
        await waitFor { MARCFileBridge.actions.filter { $0 == "cleanupArchive" }.count > cleanups }
        precondition(!files.busy && !files.transferring && files.downloaded == nil)

        let file = MARCRemoteEntry(name: "remote.txt", path: "/fixture/remote.txt", directory: false, size: 3, modified: nil, mode: nil)
        let beforeDelete = MARCFileBridge.actions.count
        let beforeDeleteFeedback = files.completionEvent
        let cancelledAction = Task { try await files.perform("delete", entry: file) }
        cancelledAction.cancel()
        if case .success = await cancelledAction.result { preconditionFailure("Cancelled action must fail") }
        precondition(MARCFileBridge.actions.count == beforeDelete && !files.busy)
        precondition(files.completionEvent == beforeDeleteFeedback)

        _ = try await files.perform("delete", entry: file, refresh: true)
        precondition(files.completionTitle == "File deleted" && files.completionPath == file.path)
        _ = try await files.perform("delete", entry: folder, refresh: true)
        precondition(files.completionTitle == "Folder deleted" && files.completionPath == folder.path)
        let deleteFeedback = files.completionEvent
        MARCFileBridge.failingAction = "delete"
        do {
            _ = try await files.perform("delete", entry: file)
            preconditionFailure("Failed deletion must throw")
        } catch {}
        MARCFileBridge.failingAction = nil
        precondition(files.completionEvent == deleteFeedback, "Failed deletion must not publish success")

        let deleteGate = Gate()
        MARCFileBridge.hook = { action in if action == "delete" { await deleteGate.wait() } }
        let interruptedDelete = Task { try await files.perform("delete", entry: file) }
        await waitFor { deleteGate.entered }
        interruptedDelete.cancel(); deleteGate.open()
        if case .success = await interruptedDelete.result { preconditionFailure("Cancelled deletion must not return success") }
        MARCFileBridge.hook = nil
        precondition(files.completionEvent == deleteFeedback, "Cancelled deletion must not publish success")
        print("PASS: file/folder deletion feedback; failed and cancelled actions do not publish success")

        let editGate = Gate()
        sftp.closeFileHook = { path in if path.contains(".marc-edit-input-") { await editGate.wait() } }
        let edit = Task { try await files.perform("saveText", entry: file, extras: ["data": ""]) }
        await waitFor { editGate.entered }
        edit.cancel(); sftp.closeFileHook = nil; editGate.open()
        if case .success = await edit.result { preconditionFailure("Cancelled edit must fail") }
        precondition(!MARCFileBridge.actions.contains("saveText"), "A cancelled staged edit must not commit")
        precondition(!sftp.data.keys.contains { $0.contains(".marc-edit-input-") })

        let replaceURL = directory.appendingPathComponent("replace.txt")
        let replacementBytes = Data("replacement content".utf8)
        try replacementBytes.write(to: replaceURL)
        let replacePath = "/fixture/replace.txt"
        let originalBytes = Data("original content".utf8)
        sftp.data[replacePath] = originalBytes
        let beforeReplace = files.completionEvent
        let beforeReplaceOpens = sftp.opens
        files.upload(replaceURL)
        let cancelReplacement = files.operationFixture()
        await waitFor { files.uploadConflict != nil }
        let cancelledConflict = files.uploadConflict!.id
        precondition(sftp.opens == beforeReplaceOpens, "Confirmation must precede remote staging")
        files.resolveUploadConflict(cancelledConflict, replace: false)
        await cancelReplacement?.value
        precondition(sftp.data[replacePath] == originalBytes && files.notice == "Upload cancelled.")
        precondition(files.completionEvent == beforeReplace && files.uploadConflict == nil && !files.busy)

        files.upload(replaceURL)
        let confirmedReplacement = files.operationFixture()
        await waitFor { files.uploadConflict != nil }
        files.resolveUploadConflict(files.uploadConflict!.id, replace: true)
        await confirmedReplacement?.value
        precondition(sftp.data[replacePath] == replacementBytes && files.completionTitle == "Upload complete")
        precondition(!sftp.data.keys.contains { $0.contains(".marc-upload-") })

        // The user agreed to replace the old bytes, not a later version.
        let newerBytes = Data("changed by another application".utf8)
        sftp.writeHook = { sftp.data[replacePath] = newerBytes }
        let beforeChangedReplace = files.completionEvent
        files.upload(replaceURL)
        let changedReplacement = files.operationFixture()
        await waitFor { files.uploadConflict != nil }
        files.resolveUploadConflict(files.uploadConflict!.id, replace: true)
        await changedReplacement?.value
        sftp.writeHook = nil
        precondition(sftp.data[replacePath] == newerBytes && files.failure?.contains("destination changed") == true)
        precondition(files.completionEvent == beforeChangedReplace)
        precondition(!sftp.data.keys.contains { $0.contains(".marc-upload-") })

        let replacingGate = Gate()
        sftp.writeHook = { await replacingGate.wait() }
        files.upload(replaceURL)
        let cancelledDuringReplacement = files.operationFixture()
        await waitFor { files.uploadConflict != nil }
        files.resolveUploadConflict(files.uploadConflict!.id, replace: true)
        await waitFor { replacingGate.entered }
        precondition(sftp.data[replacePath] == newerBytes, "Original stays intact while the stage uploads")
        files.cancelTransfer(); sftp.writeHook = nil; replacingGate.open()
        await cancelledDuringReplacement?.value
        precondition(sftp.data[replacePath] == newerBytes && files.notice == "Upload cancelled.")
        precondition(!sftp.data.keys.contains { $0.contains(".marc-upload-") })

        // Leaving the connection must release a waiting confirmation and make
        // its old Replace action inert on the replacement connection.
        files.upload(replaceURL)
        let oldReplacement = files.operationFixture()
        await waitFor { files.uploadConflict != nil }
        let oldConflict = files.uploadConflict!.id
        files.stop()
        await files.prepare(server: b)
        files.resolveUploadConflict(oldConflict, replace: true)
        await oldReplacement?.value
        precondition(files.ready && files.uploadConflict == nil && !files.busy && files.failure == nil)
        precondition(sftp.data[replacePath] == newerBytes)

        // Cancel only after bytes exist remotely; cleanup must remove the stage,
        // retain other files and avoid reporting success.
        let interruptedURL = directory.appendingPathComponent("interrupted.bin")
        try Data(repeating: 7, count: 70000).write(to: interruptedURL)
        let writeGate = Gate()
        sftp.writeHook = { await writeGate.wait() }
        let beforeInterrupted = files.completionEvent
        files.upload(interruptedURL)
        let interruptedTask = files.operationFixture()
        await waitFor { writeGate.entered }
        precondition(sftp.data.keys.contains { $0.contains(".marc-upload-") })
        files.cancelTransfer()
        sftp.writeHook = nil; writeGate.open()
        await interruptedTask?.value
        precondition(!files.busy && !files.transferring && files.notice == "Upload cancelled.")
        precondition(files.completionEvent == beforeInterrupted)
        precondition(sftp.data["/fixture/interrupted.bin"] == nil)
        precondition(!sftp.data.keys.contains { $0.contains(".marc-upload-") })

        // A write error after partial data follows the same cleanup path.
        sftp.writeHook = { throw MARCAIError.message("Fixture write failure") }
        files.upload(interruptedURL)
        await files.operationFixture()?.value
        sftp.writeHook = nil
        precondition(files.failure?.contains("Upload failed") == true && !files.busy)
        precondition(files.completionEvent == beforeInterrupted)
        precondition(!sftp.data.keys.contains { $0.contains(".marc-upload-") })

        // The directory listing may be stale: preserve a destination created
        // by another actor between upload startup and the final rename.
        let existingContent = Data("keep the other file".utf8)
        sftp.closeFileHook = { path in
            if path.contains(".marc-upload-") {
                sftp.data["/fixture/interrupted.bin"] = existingContent
            }
        }
        files.upload(interruptedURL)
        await files.operationFixture()?.value
        sftp.closeFileHook = nil
        precondition(sftp.data["/fixture/interrupted.bin"] == existingContent)
        precondition(files.failure?.contains("Upload failed") == true)
        precondition(files.completionEvent == beforeInterrupted)
        precondition(!sftp.data.keys.contains { $0.contains(".marc-upload-") })

        // Fail the second read after one chunk was stored locally. The lease
        // must remove the partial copy, without publishing a completed result.
        let partialEntry = MARCRemoteEntry(name: "partial.bin", path: "/fixture/partial.bin",
            directory: false, size: 70000, modified: nil, mode: nil)
        sftp.data[partialEntry.path] = Data(repeating: 3, count: 70000)
        let tempRoot = FileManager.default.temporaryDirectory
        let beforeFolders = Set(try FileManager.default.contentsOfDirectory(atPath: tempRoot.path)
            .filter { $0.hasPrefix("MARC-download-") })
        var partialReads = 0
        sftp.readHook = { partialReads += 1; sftp.failRead = partialReads > 1 }
        files.download(partialEntry)
        await files.operationFixture()?.value
        sftp.readHook = nil; sftp.failRead = false
        precondition(partialReads == 2 && files.downloaded == nil && !files.busy)
        precondition(files.failure?.contains("Download failed") == true)
        let afterFolders = Set(try FileManager.default.contentsOfDirectory(atPath: tempRoot.path)
            .filter { $0.hasPrefix("MARC-download-") })
        precondition(afterFolders.subtracting(beforeFolders).isEmpty,
                     "A failed partial download must not leave its local directory")

        sftp.failRefreshAfterRename = true
        files.upload(upload)
        await waitFor { !files.busy }
        precondition(sftp.data["/fixture/fixture.txt"] == content)
        precondition(files.completionTitle == "Upload complete")
        precondition(files.failure?.contains("Upload complete, but") == true)
        sftp.failRefreshAfterRename = false

        sftp.data[file.path] = Data([1, 2, 3])
        let readGate = Gate(); sftp.readHook = { await readGate.wait() }
        files.download(file)
        let oldDownload = files.operationFixture()
        await waitFor { readGate.entered }
        files.stop(); await files.prepare(server: b)
        sftp.readHook = nil; readGate.open()
        await oldDownload?.value
        precondition(files.downloaded == nil && files.ready && files.failure == nil && files.transferTotal == nil)

        files.download(file, forPreview: true)
        await files.operationFixture()?.value
        precondition(files.downloaded?.forPreview == true)
        let firstURL = files.downloaded!.url
        precondition(FileManager.default.fileExists(atPath: firstURL.path))
        files.download(file)
        precondition(!FileManager.default.fileExists(atPath: firstURL.path),
                     "Replacing an unpresented result must remove its local copy")
        await files.operationFixture()?.value
        var viewer = files.downloaded
        precondition(viewer?.forPreview == false)
        let secondURL = viewer!.url
        files.downloaded = nil
        files.stop()
        precondition(viewer?.url == secondURL && FileManager.default.fileExists(atPath: secondURL.path),
                     "A displayed local file must survive connection shutdown")
        viewer = nil
        precondition(!FileManager.default.fileExists(atPath: secondURL.path),
                     "Releasing the last viewer must clean its own local copy")
        print("PASS: partial upload cancellation/write failures, late destination conflicts and partial download cleanup")
        print("PASS: upload Replace/Cancel, stale confirmation, changed destination and replacement staging cleanup")
        print("PASS: Terminal/Files task races (queued cancellation, slot switching, resize coalescing, archive ownership, staged edits and committed uploads)")
        print("PASS: completed download replacement, preview purpose and displayed-file lifetime")
    }
}
'''

compiler = shutil.which('swiftc')
if not compiler:
    raise SystemExit('Swift compiler required. Run this check on your Mac.')
with tempfile.TemporaryDirectory(prefix='marc-task-checks-') as directory:
    source = Path(directory) / 'TaskChecks.swift'
    source.write_text('import Foundation\nimport Observation\n' + support + formatting + local_download + reply_types + terminal_session + workspace + remote_files + transfer_io + checks)
    binary = Path(directory) / 'task-checks'
    subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(source), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True, timeout=30)

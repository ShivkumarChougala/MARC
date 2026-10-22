import Foundation

/// Owns only MARC-created temporary files, never Files-provider URLs or exports.
/// One session per process prevents repeated preparation from sweeping live leases.
nonisolated final class MARCTemporaryFileStore: @unchecked Sendable {
    static let shared = MARCTemporaryFileStore(
        root: FileManager.default.temporaryDirectory
            .appendingPathComponent("MARC-TemporaryFiles-v1", isDirectory: true),
        legacyRoot: FileManager.default.temporaryDirectory
    )

    let root: URL
    private let legacyRoot: URL?
    private let session: URL
    private let lock = NSLock()
    private var prepared = false

    init(root: URL, legacyRoot: URL? = nil) {
        self.root = root
        self.legacyRoot = legacyRoot
        session = root.appendingPathComponent("session-\(UUID().uuidString)", isDirectory: true)
    }

    /// Run at launch; creation also calls this, so startup ordering is irrelevant.
    func prepare() throws {
        lock.lock()
        defer { lock.unlock() }
        guard !prepared else { return }
        try Self.ensurePrivateDirectory(root)
        try Self.ensurePrivateDirectory(session)
        // Never follow links or use a broad prefix as evidence of ownership.
        sweep(root, prefixes: ["session-"], excluding: session)
        if let legacyRoot {
            sweep(legacyRoot, prefixes: ["MARC-download-", "MARCPhotoImport-"])
        }
        prepared = true
    }

    func makeFile(name: String) throws -> MARCTemporaryFile {
        guard !name.isEmpty, name != ".", name != "..",
              !name.contains("/"), !name.contains("\0") else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        try prepare()
        let folder = session.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try Self.ensurePrivateDirectory(folder)
        let url = folder.appendingPathComponent(name, isDirectory: false)
        do {
            // Apply protection before any payload bytes reach disk.
            guard FileManager.default.createFile(
                atPath: url.path, contents: nil, attributes: Self.attributes(directory: false)
            ) else { throw CocoaError(.fileWriteUnknown) }
            try Self.verifyProtection(url)
            return MARCTemporaryFile(url: url, directory: folder)
        } catch {
            try? FileManager.default.removeItem(at: folder)
            throw error
        }
    }

    static func checkSpace(bytes: UInt64, at url: URL = FileManager.default.temporaryDirectory) throws {
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: url.path)
        guard let free = (attributes[.systemFreeSize] as? NSNumber)?.uint64Value,
              free >= 256 * 1024 * 1024, bytes <= free - 256 * 1024 * 1024 else {
            throw CocoaError(.fileWriteOutOfSpace)
        }
    }

    static func checkDownload(size: UInt64, forPreview: Bool) throws {
        let limit: UInt64 = forPreview ? 50 * 1024 * 1024 : 512 * 1024 * 1024
        guard size <= limit else {
            throw NSError(domain: "MARC.ResourceLimit", code: 1, userInfo: [
                NSLocalizedDescriptionKey: forPreview
                    ? "Preview supports files up to 50 MiB. Use Download for larger files."
                    : "Download supports files up to 512 MiB. Use another transfer tool for larger files."
            ])
        }
        try checkSpace(bytes: size)
    }

    /// Copies in bounded chunks into an already protected file. copyItem can
    /// preserve the provider's weaker protection, so it is intentionally avoided.
    func copyFile(from source: URL) throws -> MARCTemporaryFile {
        let manager = FileManager.default
        let type = try manager.attributesOfItem(atPath: source.path)[.type] as? FileAttributeType
        guard (try? manager.destinationOfSymbolicLink(atPath: source.path)) == nil,
              type == .typeRegular else { throw CocoaError(.fileReadUnsupportedScheme) }
        let size = (try manager.attributesOfItem(atPath: source.path)[.size] as? NSNumber)?.uint64Value
        guard let size else { throw CocoaError(.fileReadUnknown) }
        try Self.checkDownload(size: size, forPreview: false)
        var copied: UInt64 = 0
        let file = try makeFile(name: source.lastPathComponent)
        let input = try FileHandle(forReadingFrom: source)
        defer { try? input.close() }
        let output = try FileHandle(forWritingTo: file.url)
        defer { try? output.close() }
        while true {
            try Task.checkCancellation()
            let data = try input.read(upToCount: 32768) ?? Data()
            if data.isEmpty { break }
            guard copied <= size, UInt64(data.count) <= size - copied else {
                throw CocoaError(.fileReadUnknown)
            }
            try Self.checkSpace(bytes: UInt64(data.count), at: file.url.deletingLastPathComponent())
            try output.write(contentsOf: data)
            copied += UInt64(data.count)
        }
        try Task.checkCancellation()
        guard copied == size else { throw CocoaError(.fileReadUnknown) }
        try output.synchronize()
        try Self.verifyProtection(file.url)
        return file
    }

    private func sweep(_ directory: URL, prefixes: [String], excluding: URL? = nil) {
        guard let children = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil, options: []
        ) else { return } // Protected/temporarily unavailable leftovers retry next launch.
        for child in children {
            guard child.standardizedFileURL != excluding?.standardizedFileURL,
                  prefixes.contains(where: { Self.hasUUIDName(child.lastPathComponent, prefix: $0) }),
                  (try? FileManager.default.destinationOfSymbolicLink(atPath: child.path)) == nil,
                  let attributes = try? FileManager.default.attributesOfItem(atPath: child.path),
                  attributes[.type] as? FileAttributeType == .typeDirectory else { continue }
            // Foundation removes symlink entries inside a directory without following
            // them. A symlink in place of the candidate itself was rejected above.
            try? FileManager.default.removeItem(at: child)
        }
    }

    private static func hasUUIDName(_ name: String, prefix: String) -> Bool {
        guard name.hasPrefix(prefix) else { return false }
        let suffix = String(name.dropFirst(prefix.count))
        guard let uuid = UUID(uuidString: suffix) else { return false }
        return uuid.uuidString.caseInsensitiveCompare(suffix) == .orderedSame
    }

    private static func attributes(directory: Bool) -> [FileAttributeKey: Any] {
        var result: [FileAttributeKey: Any] = [.posixPermissions: directory ? 0o700 : 0o600]
        #if os(iOS)
        result[.protectionKey] = FileProtectionType.complete
        #endif
        return result
    }

    private static func ensurePrivateDirectory(_ url: URL) throws {
        let manager = FileManager.default
        guard (try? manager.destinationOfSymbolicLink(atPath: url.path)) == nil else {
            throw CocoaError(.fileWriteFileExists)
        }
        if let existing = try? manager.attributesOfItem(atPath: url.path) {
            guard existing[.type] as? FileAttributeType == .typeDirectory else {
                throw CocoaError(.fileWriteFileExists)
            }
            try manager.setAttributes(attributes(directory: true), ofItemAtPath: url.path)
        } else {
            try manager.createDirectory(at: url, withIntermediateDirectories: false,
                                        attributes: attributes(directory: true))
        }
        var excluded = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try excluded.setResourceValues(values)
        try verifyProtection(url)
    }

    private static func verifyProtection(_ url: URL) throws {
        #if os(iOS)
        let values = try FileManager.default.attributesOfItem(atPath: url.path)
        let value = values[.protectionKey]
        guard (value as? FileProtectionType) == .complete ||
                (value as? String) == FileProtectionType.complete.rawValue else {
            throw CocoaError(.fileWriteNoPermission)
        }
        #endif
    }
}

/// Immutable lease shared by transfer tasks, Quick Look and share controllers.
/// Lifetime is synchronized by ARC; cleanup touches only this lease's directory.
nonisolated final class MARCTemporaryFile: @unchecked Sendable {
    let url: URL
    private let directory: URL

    fileprivate init(url: URL, directory: URL) {
        self.url = url
        self.directory = directory
    }

    deinit { try? FileManager.default.removeItem(at: directory) }
}

final class MARCLocalDownload: Identifiable {
    let id = UUID()
    let forPreview: Bool
    private let file: MARCTemporaryFile
    var url: URL { file.url }

    init(name: String, forPreview: Bool) throws {
        file = try MARCTemporaryFileStore.shared.makeFile(name: name)
        self.forPreview = forPreview
    }
}

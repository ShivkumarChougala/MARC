import Foundation

@main
struct TemporaryFileChecks {
    static let fm = FileManager.default

    static func exists(_ url: URL) -> Bool { fm.fileExists(atPath: url.path) }
    static func mkdir(_ url: URL) throws {
        try fm.createDirectory(at: url, withIntermediateDirectories: false)
    }

    static func main() async throws {
        let fixture = fm.temporaryDirectory.appendingPathComponent("MARC-TempChecks-\(UUID().uuidString)")
        try mkdir(fixture)
        defer { try? fm.removeItem(at: fixture) }
        let root = fixture.appendingPathComponent("store")
        let legacy = fixture.appendingPathComponent("legacy")
        let outside = fixture.appendingPathComponent("outside")
        try mkdir(root); try mkdir(legacy); try mkdir(outside)
        let sentinel = outside.appendingPathComponent("keep.txt")
        try Data("keep".utf8).write(to: sentinel)

        let stale = root.appendingPathComponent("session-\(UUID().uuidString)")
        try mkdir(stale)
        try fm.createSymbolicLink(at: stale.appendingPathComponent("outside-link"), withDestinationURL: outside)
        let linked = root.appendingPathComponent("session-\(UUID().uuidString)")
        try fm.createSymbolicLink(at: linked, withDestinationURL: outside)
        let oldDownload = legacy.appendingPathComponent("MARC-download-\(UUID().uuidString)")
        let oldPhoto = legacy.appendingPathComponent("MARCPhotoImport-\(UUID().uuidString)")
        try mkdir(oldDownload); try mkdir(oldPhoto)
        let unknown = root.appendingPathComponent("session-not-a-uuid")
        let legacyUnknown = legacy.appendingPathComponent("MARCPhotoImport-user-keeps-this")
        try mkdir(unknown); try mkdir(legacyUnknown)
        let namedFile = legacy.appendingPathComponent("MARC-download-\(UUID().uuidString)")
        try Data("keep".utf8).write(to: namedFile)
        let legacyLink = legacy.appendingPathComponent("MARCPhotoImport-\(UUID().uuidString)")
        try fm.createSymbolicLink(at: legacyLink, withDestinationURL: outside)

        let store = MARCTemporaryFileStore(root: root, legacyRoot: legacy)
        try store.prepare()
        precondition(!exists(stale) && !exists(oldDownload) && !exists(oldPhoto), "Remove stale owned directories")
        precondition(exists(sentinel) && exists(linked) && exists(legacyLink), "Never follow candidate or nested links")
        precondition(exists(unknown) && exists(legacyUnknown) && exists(namedFile), "Preserve unrelated entries")

        var file: MARCTemporaryFile? = try store.makeFile(name: "résumé 'file'.txt")
        let url = file!.url
        let folder = url.deletingLastPathComponent()
        try Data("live".utf8).write(to: url)
        let attrs = try fm.attributesOfItem(atPath: url.path)
        precondition((attrs[.posixPermissions] as? NSNumber)?.intValue == 0o600)
        let folderAttrs = try fm.attributesOfItem(atPath: folder.path)
        precondition((folderAttrs[.posixPermissions] as? NSNumber)?.intValue == 0o700)
        try store.prepare()
        precondition(exists(url), "Repeated preparation must preserve active leases")
        var viewer = file
        file = nil
        precondition(exists(url) && viewer != nil, "A viewer keeps the lease")
        viewer = nil
        precondition(!exists(folder), "Last owner removes the directory")

        let source = outside.appendingPathComponent("photo.jpg")
        let payload = Data(repeating: 0xA5, count: 100_003)
        try payload.write(to: source)
        var media: MARCTemporaryFile? = try store.copyFile(from: source)
        let mediaURL = media!.url
        let copied = try Data(contentsOf: mediaURL)
        precondition(copied == payload, "Chunked copy matches")
        media = nil
        precondition(!exists(mediaURL.deletingLastPathComponent()) && exists(source), "Never delete provider source")

        for name in ["", ".", "..", "../escape", "/absolute", "a/b", "a\0b"] {
            do {
                _ = try store.makeFile(name: name)
                preconditionFailure("Unsafe filename accepted")
            } catch is CocoaError {}
        }
        do {
            _ = try store.copyFile(from: outside)
            preconditionFailure("Directory source accepted")
        } catch is CocoaError {}
        let sourceLink = outside.appendingPathComponent("photo-link.jpg")
        try fm.createSymbolicLink(at: sourceLink, withDestinationURL: source)
        do {
            _ = try store.copyFile(from: sourceLink)
            preconditionFailure("Symlink source accepted")
        } catch is CocoaError {}

        let cancelled = Task { () throws -> Bool in
            withUnsafeCurrentTask { $0?.cancel() }
            do {
                _ = try store.copyFile(from: source)
                return false
            } catch is CancellationError { return true }
        }
        let wasCancelled = try await cancelled.value
        precondition(wasCancelled, "Cancelled imports stop copying")
        // Inspect the actual session captured from our lease, not a scan of
        // unrelated fixtures. Foundation directory hints can make two URLs for
        // the same symlink compare unequal on macOS; URL inequality is not a
        // reliable way to exclude that link from directory enumeration.
        let currentSession = folder.deletingLastPathComponent()
        let children = try fm.contentsOfDirectory(at: currentSession, includingPropertiesForKeys: nil)
        precondition(children.isEmpty, "No incomplete imported copy remains")
        precondition(exists(linked) && exists(legacyLink) && exists(sentinel),
                     "Preserved symlinks and their target remain untouched")

        let redirected = fixture.appendingPathComponent("redirected")
        try fm.createSymbolicLink(at: redirected, withDestinationURL: outside)
        do {
            try MARCTemporaryFileStore(root: redirected).prepare()
            preconditionFailure("Symlink storage root accepted")
        } catch is CocoaError {}
        precondition(exists(sentinel))
        let blocked = fixture.appendingPathComponent("blocked")
        try Data().write(to: blocked)
        do {
            try MARCTemporaryFileStore(root: blocked).prepare()
            preconditionFailure("Regular-file storage root accepted")
        } catch is CocoaError {}

        // A new process/session sweeps simulated crash leftovers.
        let orphan = try store.makeFile(name: "orphan.txt")
        let orphanURL = orphan.url
        let restarted = MARCTemporaryFileStore(root: root)
        try restarted.prepare()
        precondition(!exists(orphanURL), "Restart sweeps previous session")
        withExtendedLifetime(orphan) {}
        precondition(exists(source) && exists(sentinel))
        print("PASS: native temporary-file cleanup, strict ownership, symlinks, shared leases, private modes, chunked imports and cancellation")
    }
}

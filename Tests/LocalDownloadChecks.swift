import Foundation

@main
struct LocalDownloadChecks {
    private final class Owner {
        var file: MARCLocalDownload?
    }

    private static func make(_ name: String, preview: Bool) throws -> MARCLocalDownload {
        let file = try MARCLocalDownload(name: name, forPreview: preview)
        try Data("fixture".utf8).write(to: file.url)
        return file
    }

    static func main() throws {
        for (size, preview) in [(UInt64(50 * 1024 * 1024 + 1), true),
                                (UInt64(512 * 1024 * 1024 + 1), false),
                                (UInt64.max, false)] {
            do {
                try MARCTemporaryFileStore.checkDownload(size: size, forPreview: preview)
                preconditionFailure("Oversized download accepted")
            } catch {
                precondition((error as NSError).domain == "MARC.ResourceLimit")
            }
        }
        do {
            try MARCTemporaryFileStore.checkSpace(bytes: UInt64.max)
            preconditionFailure("Impossible free-space request accepted")
        } catch let error as CocoaError {
            precondition(error.code == .fileWriteOutOfSpace)
        }
        // A sparse file verifies rejection without allocating a large payload.
        let sparseURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: sparseURL.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: sparseURL) }
        let sparse = try FileHandle(forWritingTo: sparseURL)
        try sparse.truncate(atOffset: 512 * 1024 * 1024 + 1)
        try sparse.close()
        do {
            _ = try MARCTemporaryFileStore.shared.copyFile(from: sparseURL)
            preconditionFailure("Oversized import accepted")
        } catch {
            precondition((error as NSError).domain == "MARC.ResourceLimit")
        }
        print("PASS: preview/download/import limits, integer overflow and insufficient-storage rejection")
        let connection = Owner()
        let viewer = Owner()
        let other = Owner()
        connection.file = try make("same name.txt", preview: true)
        let firstURL = connection.file!.url
        let firstFolder = firstURL.deletingLastPathComponent()
        precondition(connection.file!.forPreview)
        let permissions = try FileManager.default.attributesOfItem(atPath: firstFolder.path)
        precondition((permissions[.posixPermissions] as? NSNumber)?.intValue == 0o700)

        viewer.file = connection.file
        connection.file = nil
        precondition(FileManager.default.fileExists(atPath: firstURL.path))
        other.file = try make("same name.txt", preview: false)
        let secondURL = other.file!.url
        precondition(firstURL != secondURL && !other.file!.forPreview)
        other.file = nil
        precondition(!FileManager.default.fileExists(atPath: secondURL.deletingLastPathComponent().path))
        precondition(FileManager.default.fileExists(atPath: firstURL.path),
                     "Releasing another download must not affect a visible preview")
        viewer.file = nil
        precondition(!FileManager.default.fileExists(atPath: firstFolder.path))

        for _ in 0..<30 {
            let owner = Owner()
            owner.file = try make("repeat.txt", preview: true)
            let folder = owner.file!.url.deletingLastPathComponent()
            owner.file = nil
            precondition(!FileManager.default.fileExists(atPath: folder.path))
        }
        for invalid in ["", ".", "..", "../escape", "/absolute", "a/b", "a\0b"] {
            do {
                _ = try MARCLocalDownload(name: invalid, forPreview: true)
                preconditionFailure("Invalid local name accepted")
            } catch is CocoaError {}
        }
        let unicode = Owner()
        unicode.file = try make("résumé 'test'.txt", preview: false)
        precondition(unicode.file!.url.lastPathComponent == "résumé 'test'.txt")
        unicode.file = nil
        print("PASS: local download isolation, shared lifetime, repeated cleanup, permissions and safe names")
    }
}

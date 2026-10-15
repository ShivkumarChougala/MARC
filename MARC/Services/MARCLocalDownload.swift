import Foundation

/// A lease for one app-created temporary download. Keep it alive for as long
/// as Quick Look or the share controller needs the local file.
final class MARCLocalDownload: Identifiable {
    let id = UUID()
    let url: URL
    let forPreview: Bool
    private let directory: URL

    init(name: String, forPreview: Bool) throws {
        guard !name.isEmpty, name != ".", name != "..",
              !name.contains("/"), !name.contains("\0") else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("MARC-download-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: folder, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700]
        )
        directory = folder
        url = folder.appendingPathComponent(name, isDirectory: false)
        self.forPreview = forPreview
    }

    deinit {
        // Only the exact directory created by this instance is removed.
        // A controller retaining this lease keeps its file valid on disconnect.
        try? FileManager.default.removeItem(at: directory)
    }
}

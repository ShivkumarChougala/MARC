import Foundation
import CryptoKit

enum HostKeyIdentity {
    static func endpoint(host: String, port: Int) -> String {
        let host = host.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()
        return "\(host):\(port)"
    }

    /// Accept an exact fingerprint token, including within ssh-keygen output.
    static func matches(output: String, fingerprint: String) -> Bool {
        output.split(whereSeparator: { $0.isWhitespace }).contains { String($0) == fingerprint }
    }

    static func fingerprint(publicKey: String) throws -> String {
        let fields = publicKey.split(whereSeparator: { $0.isWhitespace })
        guard fields.count >= 2, let bytes = Data(base64Encoded: String(fields[1])), !bytes.isEmpty else {
            throw NSError(domain: "MARC.HostKey", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid SSH public host key."])
        }
        let digest = Data(SHA256.hash(data: bytes)).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        return "SHA256:" + digest
    }
}

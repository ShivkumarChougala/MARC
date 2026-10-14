import Foundation
import Citadel
import Crypto
import NIOSSH

enum MARCLoginError: LocalizedError {
    case missing, invalidKey
    var errorDescription: String? {
        switch self {
        case .missing:
            return "Enter a password or import an SSH private key."
        case .invalidKey:
            return "Could not open this key. Use an OpenSSH Ed25519 private key and check its passphrase. Other key types are not supported yet."
        }
    }
}

enum MARCLogin {
    static func key(_ login: MARCCredentials.Saved) throws -> Curve25519.Signing.PrivateKey {
        let selected = try login.keyID.map { try MARCSSHKeyStore.read($0) }
        let secret = selected?.privateKey ?? login.privateKey
        let secretPassphrase = selected?.passphrase ?? login.passphrase
        guard let text = secret, text.utf8.count <= 32768 else {
            throw MARCLoginError.invalidKey
        }
        let normalized = text.replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.hasPrefix("-----BEGIN OPENSSH PRIVATE KEY-----"),
              normalized.hasSuffix("-----END OPENSSH PRIVATE KEY-----") else {
            throw MARCLoginError.invalidKey
        }
        do {
            let passphrase = secretPassphrase.flatMap {
                $0.isEmpty ? nil : Data($0.utf8)
            }
            return try Curve25519.Signing.PrivateKey(
                sshEd25519: normalized, decryptionKey: passphrase
            )
        } catch { throw MARCLoginError.invalidKey }
    }

    static func authentication(
        _ login: MARCCredentials.Saved, username: String
    ) throws -> @Sendable () -> SSHAuthenticationMethod {
        guard login.hasLogin else { throw MARCLoginError.missing }
        if login.isKeyLogin {
            let parsed = try key(login)
            return { .ed25519(username: username, privateKey: parsed) }
        }
        return { .passwordBased(username: username, password: login.password) }
    }

    static func publicKey(_ login: MARCCredentials.Saved) throws -> String {
        let raw = try key(login).publicKey.rawRepresentation
        var blob = Data()
        for field in [Data("ssh-ed25519".utf8), raw] {
            var length = UInt32(field.count).bigEndian
            withUnsafeBytes(of: &length) { blob.append(contentsOf: $0) }
            blob.append(field)
        }
        return "ssh-ed25519 " + blob.base64EncodedString()
    }
}

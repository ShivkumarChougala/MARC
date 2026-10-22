import CCryptoBoringSSL
import Crypto
import Foundation
import NIOCore
import XCTest
@testable import Citadel

final class MARCOpenSSHKeyTests: XCTestCase {
    private func sampleKey() throws -> Curve25519.Signing.PrivateKey {
        try .init(rawRepresentation: Data((1...32).map { UInt8($0) }))
    }

    private func integer(_ value: UInt32) -> Data {
        var value = value.bigEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }

    private func field(_ data: Data) -> Data {
        integer(UInt32(data.count)) + data
    }

    private func field(_ text: String) -> Data { field(Data(text.utf8)) }

    private func plainPayload(padding: Int) throws -> Data {
        let key = try sampleKey()
        var payload = integer(0x12345678) + integer(0x12345678)
        payload += field("ssh-ed25519")
        payload += field(key.publicKey.rawRepresentation)
        payload += field(key.rawRepresentation + key.publicKey.rawRepresentation)
        // Choose a comment so that the requested padding produces whole blocks.
        let count = (8 - ((payload.count + 4 + padding) % 8)) % 8
        payload += field(String(repeating: "x", count: count))
        if padding > 0 { payload += Data((1...padding).map { UInt8($0) }) }
        XCTAssertEqual(payload.count % 8, 0)
        return payload
    }

    private func options(salt: Data = Data(repeating: 1, count: 16),
                         rounds: UInt32 = 4, trailing: Data = Data()) -> Data {
        field(salt) + integer(rounds) + trailing
    }

    private func envelope(_ payload: Data, cipher: String = "none", kdf: String = "none",
                          options: Data = Data(), publicTrailing: Data = Data(),
                          trailing: Data = Data()) throws -> String {
        let key = try sampleKey()
        let publicBlob = field("ssh-ed25519") + field(key.publicKey.rawRepresentation) + publicTrailing
        var encoded = Data("openssh-key-v1\0".utf8)
        encoded += field(cipher) + field(kdf) + field(options) + integer(1)
        encoded += field(publicBlob) + field(payload) + trailing
        return "-----BEGIN OPENSSH PRIVATE KEY-----\n" + encoded.base64EncodedString()
            + "\n-----END OPENSSH PRIVATE KEY-----\n"
    }

    private func assertLayoutError(_ text: String, file: StaticString = #filePath,
                                   line: UInt = #line) {
        XCTAssertThrowsError(try Curve25519.Signing.PrivateKey(sshEd25519: text), file: file, line: line) { error in
            XCTAssertEqual((error as? InvalidOpenSSHKey)?.reason, "invalidLayout", file: file, line: line)
        }
    }

    func testValidUnencryptedKeysAndFullBlockPaddingRoundTrip() throws {
        let key = try sampleKey()
        let message = Data("MARC key parser regression".utf8)
        for padding in 0...8 {
            let text = try envelope(plainPayload(padding: padding))
            let decoded = try Curve25519.Signing.PrivateKey(sshEd25519: text)
            XCTAssertEqual(decoded.rawRepresentation, key.rawRepresentation)
            let signature = try decoded.signature(for: message)
            XCTAssertTrue(key.publicKey.isValidSignature(signature, for: message))
        }
        // Exercise Citadel's own encoder, including its full-block padding case.
        for count in 0..<16 {
            let text = key.makeSSHRepresentation(comment: String(repeating: "x", count: count))
            XCTAssertEqual(try Curve25519.Signing.PrivateKey(sshEd25519: text).rawRepresentation,
                           key.rawRepresentation)
        }
    }

    func testEveryPaddingByteIncludingFinalByteIsValidated() throws {
        for padding in 1...8 {
            let original = try plainPayload(padding: padding)
            for offset in 0..<padding {
                var malformed = original
                malformed[malformed.count - padding + offset] = 0
                let text = try envelope(malformed)
                XCTAssertThrowsError(try Curve25519.Signing.PrivateKey(sshEd25519: text)) { error in
                    XCTAssertEqual((error as? InvalidOpenSSHKey)?.reason, "invalidPadding")
                }
            }
        }
    }

    func testEncryptedCipherWithNoKDFIsRejectedBeforeCrypto() throws {
        for cipher in ["aes128-ctr", "aes256-ctr"] {
            assertLayoutError(try envelope(Data(repeating: 0, count: 16), cipher: cipher))
        }
    }

    func testUnencryptedCipherWithBCryptIsRejectedBeforeCrypto() throws {
        assertLayoutError(try envelope(plainPayload(padding: 5), kdf: "bcrypt", options: options()))
    }

    func testAESRejectsWrongKeyAndIVLengths() throws {
        for (cipher, length) in [(CCryptoBoringSSL_EVP_aes_128_ctr()!, 16),
                                 (CCryptoBoringSSL_EVP_aes_256_ctr()!, 32)] {
            for keyLength in [0, length - 1, length + 1] {
                var buffer = ByteBuffer(bytes: [UInt8](repeating: 0, count: 16))
                XCTAssertThrowsError(try buffer.decryptAES(cipher: cipher,
                    key: [UInt8](repeating: 0, count: keyLength), iv: [UInt8](repeating: 0, count: 16)))
            }
            for ivLength in [0, 15, 17] {
                var buffer = ByteBuffer(bytes: [UInt8](repeating: 0, count: 16))
                XCTAssertThrowsError(try buffer.decryptAES(cipher: cipher,
                    key: [UInt8](repeating: 0, count: length), iv: [UInt8](repeating: 0, count: ivLength)))
            }
        }
    }

    func testEmptyOrMisalignedPrivatePayloadsAreRejected() throws {
        for count in [0, 1, 7, 9, 15, 17, 31] {
            let data = Data(repeating: 0, count: count)
            assertLayoutError(try envelope(data))
            for cipher in ["aes128-ctr", "aes256-ctr"] {
                assertLayoutError(try envelope(data, cipher: cipher, kdf: "bcrypt", options: options()))
            }
        }
    }

    func testMalformedBCryptOptionsAreRejected() throws {
        let malformed = [options(rounds: 0), options(salt: Data()),
                         options(trailing: Data([0])), Data([0, 0, 0, 16, 1])]
        for config in malformed {
            let text = try envelope(Data(repeating: 0, count: 16), cipher: "aes256-ctr",
                                    kdf: "bcrypt", options: config)
            XCTAssertThrowsError(try Curve25519.Signing.PrivateKey(sshEd25519: text)) { error in
                XCTAssertEqual((error as? InvalidOpenSSHKey)?.reason, "invalidOrUnsupportedBCryptConfig")
            }
        }
    }

    func testTrailingEnvelopeAndPublicKeyBytesAreRejected() throws {
        assertLayoutError(try envelope(plainPayload(padding: 5), trailing: Data([0])))
        assertLayoutError(try envelope(plainPayload(padding: 5), publicTrailing: Data([0])))
    }

    private func checkEncrypted(_ text: String, publicBytes: Data) throws {
        let key = try Curve25519.Signing.PrivateKey(sshEd25519: text,
                                                  decryptionKey: Data("MARC fixture only".utf8))
        XCTAssertEqual(key.publicKey.rawRepresentation, publicBytes)
        let message = Data("MARC encrypted key regression".utf8)
        let signature = try key.signature(for: message)
        XCTAssertTrue(key.publicKey.isValidSignature(signature, for: message))
        XCTAssertFalse(key.publicKey.isValidSignature(signature, for: Data("different".utf8)))
        XCTAssertThrowsError(try Curve25519.Signing.PrivateKey(sshEd25519: text))
        XCTAssertThrowsError(try Curve25519.Signing.PrivateKey(sshEd25519: text,
                                                            decryptionKey: Data()))
        XCTAssertThrowsError(try Curve25519.Signing.PrivateKey(sshEd25519: text,
                                                            decryptionKey: Data("wrong".utf8)))
    }

    func testValidEncryptedAES128KeyAndWrongPassphrase() throws {
        let fixture = """
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAACmFlczEyOC1jdHIAAAAGYmNyeXB0AAAAGAAAABASsZrTab
        hMQ2CLRWLx4zIfAAAABAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAID1RCG3tljXSjnyg
        0JvOL4+VB5oNin3DLvAAgqb2dgFRAAAAsKyM3gyzHxfbpVUuywXUPPeqZB8D3npW6KcguS
        mXmyKH8fE0uKevtLgA3StmFoK875k+56FbGZ7sW5co+6gOBKDdebiVHm+D6bdq4bKDskaM
        j71c+gg5LnMq4NVPD4kT9FkGrOnFMhXf5sQA7wALD+xXgs86q4kHuKbS7s4Z9fBq44nSVr
        80p4klb7h7USyL7+V2H2wgFdjvg2w+iu6KHEm3kVkYoZ2miQQ/QRkU74Mk
        -----END OPENSSH PRIVATE KEY-----
        """
        try checkEncrypted(fixture, publicBytes: Data([61,81,8,109,237,150,53,210,142,124,160,208,155,206,47,143,149,7,154,13,138,125,195,46,240,0,130,166,246,118,1,81]))
    }

    func testValidEncryptedAES256KeyAndWrongPassphrase() throws {
        let fixture = """
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABAMP1DQsM
        2IrRW552JakN2xAAAABAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAIBMmreBkcTTszOye
        KUdwX3bMeOKUmhvnd9XRote0dTJvAAAAsLBGQOHaIxl0oRG5m1FfClxZh/BiAKdvNvgM9A
        Z8+Gjqk3oEU7Atrn5FCxfu4t+4D19Hocndy+eT2nSIDynys1VcDF1Rl4hu/XQIY8YblU3S
        zlBP0Z0YcncofAkPSgy9To4URsakgyw96kaZ9F1e2txmCdhKRFVyEyRGr+Re0JuweV350G
        kP613+l2QK+UKXV2/OExDT/VZX4dCIPieUybnH28Ad6nqoG3cmBegDu1FI
        -----END OPENSSH PRIVATE KEY-----
        """
        try checkEncrypted(fixture, publicBytes: Data([19,38,173,224,100,113,52,236,204,236,158,41,71,112,95,118,204,120,226,148,154,27,231,119,213,209,162,215,180,117,50,111]))
    }
}

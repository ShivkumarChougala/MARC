import Crypto
import CryptoExtras
import Foundation
import XCTest

final class MARCCryptoDependencyTests: XCTestCase {
    func testMalformedRSADERPublicKeysThrowWithoutDoubleFree() throws {
        let malformed = Data([0x30, 0x06, 0x02, 0x01, 0x00, 0x02, 0x01, 0x00])
        for _ in 0..<8 {
            XCTAssertThrowsError(try _RSA.Signing.PublicKey(derRepresentation: malformed))
            XCTAssertThrowsError(try _RSA.Encryption.PublicKey(derRepresentation: malformed))
            XCTAssertThrowsError(try _RSA.BlindSigning.PublicKey<SHA384>(derRepresentation: malformed))
        }
    }

    func testMalformedRSAPEMPublicKeysThrowWithoutDoubleFree() throws {
        let malformed = """
        -----BEGIN PUBLIC KEY-----
        MAYCAQACAQ==
        -----END PUBLIC KEY-----
        """
        for _ in 0..<8 {
            XCTAssertThrowsError(try _RSA.Signing.PublicKey(pemRepresentation: malformed))
            XCTAssertThrowsError(try _RSA.Encryption.PublicKey(pemRepresentation: malformed))
            XCTAssertThrowsError(try _RSA.BlindSigning.PublicKey<SHA384>(pemRepresentation: malformed))
        }
    }

    func testValidRSAKeyAndSignatureStillWork() throws {
        let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
        let decoded = try _RSA.Signing.PublicKey(derRepresentation: privateKey.publicKey.derRepresentation)
        let message = Data("MARC Crypto dependency regression".utf8)
        let signature = try privateKey.signature(for: message)
        XCTAssertTrue(decoded.isValidSignature(signature, for: message))
        XCTAssertFalse(decoded.isValidSignature(signature, for: Data("Different message".utf8)))
    }

    func testVOPRFBlindAcceptsBoundaryAndRejectsOversizedInput() throws {
        if #available(macOS 13.0, *) {
            let key = P384._VOPRF.PrivateKey()
            XCTAssertNoThrow(try key.publicKey.blind(Data(repeating: 1, count: 65_535)))
            for count in [65_536, 65_537] {
                XCTAssertThrowsError(try key.publicKey.blind(Data(repeating: 1, count: count))) { error in
                    guard let cryptoError = error as? CryptoKitError else {
                        return XCTFail("Unexpected VOPRF rejection: \(error)")
                    }
                    switch cryptoError {
                    case .incorrectParameterSize: break
                    default: XCTFail("Unexpected VOPRF error: \(cryptoError)")
                    }
                }
            }
        } else {
            XCTFail("VOPRF regression tests require macOS 13 or newer")
        }
    }

    func testVOPRFEvaluateAcceptsBoundaryAndRejectsOversizedInput() throws {
        if #available(macOS 13.0, *) {
            let key = P384._VOPRF.PrivateKey()
            XCTAssertFalse(try key.evaluate(Data(repeating: 1, count: 65_535)).isEmpty)
            for count in [65_536, 65_537] {
                XCTAssertThrowsError(try key.evaluate(Data(repeating: 1, count: count))) { error in
                    guard let cryptoError = error as? CryptoKitError else {
                        return XCTFail("Unexpected VOPRF rejection: \(error)")
                    }
                    switch cryptoError {
                    case .incorrectParameterSize: break
                    default: XCTFail("Unexpected VOPRF error: \(cryptoError)")
                    }
                }
            }
        } else {
            XCTFail("VOPRF regression tests require macOS 13 or newer")
        }
    }
}

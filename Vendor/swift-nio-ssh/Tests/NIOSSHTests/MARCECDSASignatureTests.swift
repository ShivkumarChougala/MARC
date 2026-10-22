// Copyright (c) 2026 MARC contributors.
// SPDX-License-Identifier: Apache-2.0
// Regression coverage for the MARC backport of CVE-2026-43798.
import Crypto
import Foundation
import NIOCore
import XCTest
@testable import NIOSSH

final class MARCECDSASignatureTests: XCTestCase {
    private let curves = [("ecdsa-sha2-nistp256", 32),
                          ("ecdsa-sha2-nistp384", 48),
                          ("ecdsa-sha2-nistp521", 66)]

    private func buffer(_ identifier: String, r: [UInt8], s: [UInt8]) -> ByteBuffer {
        var components = ByteBufferAllocator().buffer(capacity: r.count + s.count + 8)
        components.writeSSHString(r)
        components.writeSSHString(s)
        var result = ByteBufferAllocator().buffer(capacity: components.readableBytes + 64)
        result.writeSSHString(Array(identifier.utf8))
        result.writeSSHString(&components)
        return result
    }

    private func assertRejected(_ identifier: String, r: [UInt8], s: [UInt8],
                                file: StaticString = #filePath, line: UInt = #line) {
        var input = buffer(identifier, r: r, s: s)
        XCTAssertThrowsError(try input.readSSHSignature(), file: file, line: line) { error in
            XCTAssertEqual((error as? NIOSSHError)?.type, .invalidSSHMessage,
                           file: file, line: line)
        }
    }

    func testOversizedComponentsThrowForEveryCurve() {
        for (identifier, width) in curves {
            let legal = Array(repeating: UInt8(1), count: width)
            for size in [width + 1, 4096] {
                let oversized = Array(repeating: UInt8(1), count: size)
                assertRejected(identifier, r: oversized, s: legal)
                assertRejected(identifier, r: legal, s: oversized)
                assertRejected(identifier, r: oversized, s: oversized)
                // A permitted sign-padding zero cannot conceal an oversized magnitude.
                assertRejected(identifier, r: [0] + oversized, s: legal)
                assertRejected(identifier, r: legal, s: [0] + oversized)
            }
        }
    }

    func testPreAuthenticationKeyExchangeReplyRejectsOversizedSignatures() {
        // The SSH message parser runs before the application's host-trust callback.
        let key = NIOSSHPublicKey(backingKey: .ed25519(Curve25519.Signing.PrivateKey().publicKey))
        for (identifier, width) in curves {
            for oversizedR in [true, false] {
                var host = ByteBufferAllocator().buffer(capacity: 64)
                host.writeSSHHostKey(key)
                let normal = [UInt8](repeating: 1, count: width)
                let oversized = [UInt8](repeating: 1, count: 4096)
                var signature = buffer(identifier, r: oversizedR ? oversized : normal,
                                       s: oversizedR ? normal : oversized)
                var message = ByteBufferAllocator().buffer(capacity: 8192)
                message.writeInteger(SSHMessage.KeyExchangeECDHReplyMessage.id)
                message.writeSSHString(&host)
                message.writeSSHString([UInt8](repeating: 1, count: 32))
                message.writeSSHString(&signature)
                XCTAssertThrowsError(try message.readSSHMessage()) { error in
                    XCTAssertEqual((error as? NIOSSHError)?.type, .invalidSSHMessage)
                }
            }
        }
    }

    func testBoundaryWidthsAndSignPaddingStillParse() throws {
        for (identifier, width) in curves {
            for length in [1, width - 1, width] {
                let component = Array(repeating: UInt8(1), count: length)
                for padded in [component, [0] + component] {
                    var input = buffer(identifier, r: padded, s: padded)
                    XCTAssertNotNil(try input.readSSHSignature())
                }
            }
        }
    }

    func testIncompleteSignatureReturnsNil() throws {
        for (identifier, width) in curves {
            let complete = buffer(identifier, r: [UInt8](repeating: 1, count: width),
                                   s: [UInt8](repeating: 1, count: width))
            for length in [0, 1, complete.readableBytes - 1] {
                var truncated = complete.getSlice(at: complete.readerIndex, length: length)!
                XCTAssertNil(try truncated.readSSHSignature())
            }
        }
    }

    private func checkRoundTrip(_ signature: NIOSSHSignature, publicKey: NIOSSHPublicKey,
                                digest: SHA256.Digest) throws {
        // Check the fixture before serialization as well as after decoding.
        XCTAssertTrue(publicKey.isValidSignature(signature, for: digest))
        var encoded = ByteBufferAllocator().buffer(capacity: 256)
        encoded.writeSSHSignature(signature)
        let decoded = try XCTUnwrap(encoded.readSSHSignature())
        XCTAssertEqual(decoded, signature)
        XCTAssertTrue(publicKey.isValidSignature(decoded, for: digest))
        let differentDigest = SHA256.hash(data: Data("MARC different message".utf8))
        XCTAssertFalse(publicKey.isValidSignature(decoded, for: differentDigest))
    }

    func testValidSignaturesStillVerifyForEveryCurve() throws {
        let digest = SHA256.hash(data: Data("MARC ECDSA backport regression".utf8))
        for _ in 0..<8 {
            // Use the SSH signing API used during key exchange. Its digest
            // overload signs the digest bytes through Crypto's DataProtocol
            // overload; a direct Crypto Digest overload has different semantics.
            let p256 = NIOSSHPrivateKey(p256Key: P256.Signing.PrivateKey())
            try checkRoundTrip(p256.sign(digest: digest), publicKey: p256.publicKey, digest: digest)
            let p384 = NIOSSHPrivateKey(p384Key: P384.Signing.PrivateKey())
            try checkRoundTrip(p384.sign(digest: digest), publicKey: p384.publicKey, digest: digest)
            let p521 = NIOSSHPrivateKey(p521Key: P521.Signing.PrivateKey())
            try checkRoundTrip(p521.sign(digest: digest), publicKey: p521.publicKey, digest: digest)
        }
    }
}

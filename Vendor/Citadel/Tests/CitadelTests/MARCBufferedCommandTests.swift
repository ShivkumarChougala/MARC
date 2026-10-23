import Foundation
import Logging
import NIO
import NIOEmbedded
import NIOConcurrencyHelpers
import XCTest
@testable import Citadel
@preconcurrency import NIOSSH

@MainActor
final class MARCBufferedCommandTests: XCTestCase {
    private enum TestError: Error { case transport }

    private func response(_ limit: Int, merge: Bool = false,
                          shell: String? = nil) throws -> (MARCBufferedCommand, EmbeddedChannel) {
        let value = try MARCBufferedCommand(maxResponseSize: limit, mergeStreams: merge, shellCommand: shell)
        let channel = EmbeddedChannel()
        channel.connect(to: try SocketAddress(ipAddress: "127.0.0.1", port: 22), promise: nil)
        channel.embeddedEventLoop.run()
        XCTAssertTrue(channel.isActive)
        try value.attach(channel)
        return (value, channel)
    }

    private func collect(_ response: MARCBufferedCommand) async throws -> String {
        var data = Data()
        for try await chunk in response.output {
            switch chunk {
            case .stdout(let bytes), .stderr(let bytes):
                data.append(contentsOf: bytes.readableBytesView)
            }
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func assertClosed(_ channel: EmbeddedChannel, file: StaticString = #filePath,
                              line: UInt = #line) {
        let closed = NIOLockedValueBox(false)
        channel.closeFuture.whenComplete { _ in closed.withLockedValue { $0 = true } }
        channel.embeddedEventLoop.run()
        XCTAssertTrue(closed.withLockedValue { $0 }, file: file, line: line)
    }

    private func assertOverflow(_ response: MARCBufferedCommand,
                                file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await collect(response)
            XCTFail("Overflow returned a successful/truncated response", file: file, line: line)
        } catch {
            guard case CitadelError.commandOutputTooLarge = error else {
                return XCTFail("Unexpected overflow error: \(error)", file: file, line: line)
            }
        }
    }

    func testOrderedOutputBelowBudgetClosesChannel() async throws {
        let (r, c) = try response(32)
        defer { try? c.finish() }
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "hello ")))
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "world")))
        r.receive(channel: c, event: .exit(0))
        r.receive(channel: c, event: .eof(nil))
        let result = try await collect(r)
        XCTAssertEqual(result, "hello world")
        assertClosed(c)
    }

    func testExactBudgetSucceeds() async throws {
        let (r, c) = try response(4)
        defer { try? c.finish() }
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "1234")))
        r.receive(channel: c, event: .eof(nil))
        let result = try await collect(r)
        XCTAssertEqual(result, "1234")
        assertClosed(c)
    }

    func testOversizedFirstChunkFailsAndCloses() async throws {
        let (r, c) = try response(4)
        defer { try? c.finish() }
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "12345")))
        await assertOverflow(r)
        assertClosed(c)
    }

    func testCumulativeOverflowAndLaterEventsCannotBecomeSuccess() async throws {
        let (r, c) = try response(4)
        defer { try? c.finish() }
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "1234")))
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "5")))
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "late")))
        r.receive(channel: c, event: .exit(0))
        r.receive(channel: c, event: .eof(nil))
        await assertOverflow(r)
        assertClosed(c)
    }

    func testMergedStderrSharesBudgetAndPreservesOrder() async throws {
        let (r, c) = try response(6, merge: true)
        defer { try? c.finish() }
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "out")))
        r.receive(channel: c, event: .stderr(ByteBuffer(string: "err")))
        r.receive(channel: c, event: .eof(nil))
        let result = try await collect(r)
        XCTAssertEqual(result, "outerr")
    }

    func testIgnoredStderrStillUsesBudget() async throws {
        let (r, c) = try response(4)
        defer { try? c.finish() }
        r.receive(channel: c, event: .stderr(ByteBuffer(string: "1234")))
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "5")))
        await assertOverflow(r)
        assertClosed(c)
    }

    func testIgnoredStderrIsNotReturned() async throws {
        let (r, c) = try response(6)
        defer { try? c.finish() }
        r.receive(channel: c, event: .stderr(ByteBuffer(string: "err")))
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "out")))
        r.receive(channel: c, event: .eof(nil))
        let result = try await collect(r)
        XCTAssertEqual(result, "out")
    }

    func testZeroBudgetAndEmptyChunks() async throws {
        let (r, c) = try response(0, merge: true)
        defer { try? c.finish() }
        for _ in 0..<1000 {
            r.receive(channel: c, event: .stdout(ByteBuffer()))
            r.receive(channel: c, event: .stderr(ByteBuffer()))
        }
        r.receive(channel: c, event: .eof(nil))
        let result = try await collect(r)
        XCTAssertEqual(result, "")
        XCTAssertThrowsError(try MARCBufferedCommand(maxResponseSize: -1, mergeStreams: false))
    }

    func testSlowConsumerQueueOverflowFailsWithoutTruncatedSuccess() async throws {
        let (r, c) = try response(4096)
        defer { try? c.finish() }
        for _ in 0..<257 { r.receive(channel: c, event: .stdout(ByteBuffer(string: "x"))) }
        r.receive(channel: c, event: .eof(nil))
        await assertOverflow(r)
        assertClosed(c)
    }

    func testCancellationBeforeChannelCreationRejectsLateAttach() async throws {
        let r = try MARCBufferedCommand(maxResponseSize: 32, mergeStreams: false)
        let c = EmbeddedChannel()
        defer { try? c.finish() }
        r.cancel()
        XCTAssertThrowsError(try r.attach(c)) { XCTAssertTrue($0 is CancellationError) }
        assertClosed(c)
        do { _ = try await collect(r); XCTFail("Cancelled response succeeded") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

    func testConsumerCancellationClosesChildOnly() async throws {
        let (r, c) = try response(32)
        let (other, otherChannel) = try response(32)
        defer { try? c.finish(); try? otherChannel.finish() }
        let entered = NIOLockedValueBox(false)
        let task = Task {
            entered.withLockedValue { $0 = true }
            return try await self.collect(r)
        }
        for _ in 0..<4000 {
            if entered.withLockedValue({ $0 }) { break }
            await Task.yield()
        }
        XCTAssertTrue(entered.withLockedValue { $0 }, "Consumer must start before cancellation")
        task.cancel()
        _ = await task.result
        assertClosed(c)
        let otherClosed = NIOLockedValueBox(false)
        otherChannel.closeFuture.whenComplete { _ in otherClosed.withLockedValue { $0 = true } }
        otherChannel.embeddedEventLoop.run()
        XCTAssertFalse(otherClosed.withLockedValue { $0 })
        other.receive(channel: otherChannel, event: .stdout(ByteBuffer(string: "alive")))
        other.receive(channel: otherChannel, event: .eof(nil))
        let result = try await collect(other)
        XCTAssertEqual(result, "alive")
    }

    func testNonzeroExitAndTransportErrorArePreserved() async throws {
        let (r, c) = try response(32)
        defer { try? c.finish() }
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "partial")))
        r.receive(channel: c, event: .exit(7))
        r.receive(channel: c, event: .eof(nil))
        do { _ = try await collect(r); XCTFail("Nonzero exit succeeded") }
        catch { XCTAssertEqual((error as? SSHClient.CommandFailed)?.exitCode, 7) }
        assertClosed(c)
        let (failed, failedChannel) = try response(32)
        defer { try? failedChannel.finish() }
        failed.receive(channel: failedChannel, event: .eof(TestError.transport))
        do { _ = try await collect(failed); XCTFail("Transport failure succeeded") }
        catch { guard case TestError.transport = error else { return XCTFail("Wrong transport error") } }
        assertClosed(failedChannel)
    }

    func testShellCommandIsSentExactlyOnce() async throws {
        let (r, c) = try response(32, shell: "printf ok")
        defer { r.cancel(); try? c.finish() }
        r.receive(channel: c, event: .channelSuccess)
        r.receive(channel: c, event: .channelSuccess)
        let packet = try XCTUnwrap(c.readOutbound(as: SSHChannelData.self))
        guard case .byteBuffer(let bytes) = packet.data else { return XCTFail("Expected command bytes") }
        XCTAssertEqual(String(buffer: bytes), "printf ok;exit\n")
        XCTAssertNil(try c.readOutbound(as: SSHChannelData.self))
    }

    func testExplicitCancellationIsIdempotentAndStopsLateOutput() async throws {
        let (r, c) = try response(32)
        defer { try? c.finish() }
        r.cancel(); r.cancel()
        r.receive(channel: c, event: .stdout(ByteBuffer(string: "late")))
        r.receive(channel: c, event: .eof(nil))
        do { _ = try await collect(r); XCTFail("Cancelled response succeeded") }
        catch { XCTAssertTrue(error is CancellationError) }
        assertClosed(c)
    }
    func testProductionHandlerRejectsOverflowBeforeConsumerReads() async throws {
        let (r, c) = try response(4)
        defer { try? c.finish() }
        try c.pipeline.syncOperations.addHandler(r.makeHandler(logger: Logger(label: "MARC test")))
        _ = try c.writeInbound(SSHChannelData(type: .channel, data: .byteBuffer(ByteBuffer(string: "12345"))))
        await assertOverflow(r)
        assertClosed(c)
    }

}

import Foundation
import Logging
import NIO
import NIOConcurrencyHelpers
@preconcurrency import NIOSSH

/// Finite command responses are budgeted on the producer's event loop, before
/// async enqueueing. Interactive streams do not use this collector.
final class MARCBufferedCommand: @unchecked Sendable {
    private struct State {
        var remaining: Int
        var ended = false
        var channel: Channel?
        var exitCode: Int?
        var failure: Error?
        var sentShellCommand = false
    }
    private enum Decision { case ignore, emit, overflow }
    private let state: NIOLockedValueBox<State>
    private let continuation: AsyncThrowingStream<ExecCommandOutput, Error>.Continuation
    let output: AsyncThrowingStream<ExecCommandOutput, Error>
    private let mergeStreams: Bool
    private let shellCommand: String?

    init(maxResponseSize: Int, mergeStreams: Bool, shellCommand: String? = nil) throws {
        guard maxResponseSize >= 0 else { throw CitadelError.commandOutputTooLarge }
        state = NIOLockedValueBox(State(remaining: maxResponseSize))
        self.mergeStreams = mergeStreams
        self.shellCommand = shellCommand
        let pair = AsyncThrowingStream<ExecCommandOutput, Error>.makeStream(bufferingPolicy: .bufferingOldest(256))
        output = pair.stream
        continuation = pair.continuation
        continuation.onTermination = { [weak self] _ in self?.cancel() }
    }

    /// Called during child-channel creation, before installing the handler.
    func attach(_ channel: Channel) throws {
        let accepted = state.withLockedValue { state in
            guard !state.ended else { return false }
            state.channel = channel
            return true
        }
        guard accepted else {
            channel.close(promise: nil)
            throw CancellationError()
        }
    }

    func checkOpen() throws {
        try Task.checkCancellation()
        let failure = state.withLockedValue { state -> Error? in
            guard state.ended else { return nil }
            return state.failure ?? CitadelError.channelFailure
        }
        if let failure { throw failure }
    }

    func makeHandler(logger: Logger) -> ExecCommandHandler {
        ExecCommandHandler(logger: logger) { [self] channel, event in
            receive(channel: channel, event: event)
        }
    }

    func receive(channel: Channel, event: ExecCommandHandler.Output) {
        switch event {
        case .stdout(let bytes): accept(bytes, stderr: false)
        case .stderr(let bytes): accept(bytes, stderr: true)
        case .eof(let error): complete(error)
        case .exit(let code):
            state.withLockedValue { if !$0.ended { $0.exitCode = code } }
        case .channelSuccess:
            guard let command = shellCommand else { return }
            let send = state.withLockedValue { state in
                guard !state.ended, !state.sentShellCommand else { return false }
                state.sentShellCommand = true
                return true
            }
            if send {
                channel.writeAndFlush(SSHChannelData(type: .channel,
                    data: .byteBuffer(ByteBuffer(string: command + ";exit\n"))), promise: nil)
            }
        }
    }

    private func accept(_ bytes: ByteBuffer, stderr: Bool) {
        let decision = state.withLockedValue { state -> Decision in
            guard !state.ended, bytes.readableBytes > 0 else { return .ignore }
            // Subtraction avoids integer overflow. Count discarded stderr too,
            // so it cannot bypass a finite command's total response budget.
            guard bytes.readableBytes <= state.remaining else { return .overflow }
            state.remaining -= bytes.readableBytes
            return stderr && !mergeStreams ? .ignore : .emit
        }
        switch decision {
        case .ignore: return
        case .overflow: complete(CitadelError.commandOutputTooLarge)
        case .emit:
            // Retain only these bytes, not a slice's potentially larger backing
            // allocation. Empty packets were already excluded above.
            var copy = ByteBufferAllocator().buffer(capacity: bytes.readableBytes)
            copy.writeBytes(bytes.readableBytesView)
            switch continuation.yield(stderr ? .stderr(copy) : .stdout(copy)) {
            case .enqueued: break
            case .dropped:
                // A full queue fails the whole request; never return truncated output.
                complete(CitadelError.commandOutputTooLarge)
            case .terminated: cancel()
            @unknown default: complete(CitadelError.commandOutputTooLarge)
            }
        }
    }

    private func complete(_ error: Error?) {
        let result = state.withLockedValue { state -> (Bool, Channel?, Int?) in
            guard !state.ended else { return (false, nil, nil) }
            state.ended = true
            if let error { state.failure = error }
            else if let code = state.exitCode, code != 0 {
                state.failure = SSHClient.CommandFailed(exitCode: code)
            }
            let channel = state.channel
            state.channel = nil
            return (true, channel, state.exitCode)
        }
        guard result.0 else { return }
        if let error { continuation.finish(throwing: error) }
        else if let code = result.2, code != 0 {
            continuation.finish(throwing: SSHClient.CommandFailed(exitCode: code))
        } else { continuation.finish() }
        result.1?.close(promise: nil)
    }

    /// Safe from a cancellation handler, including before channel creation.
    /// Only the command's child channel is closed; its parent connection lives.
    func cancel() {
        let result = state.withLockedValue { state -> (Bool, Channel?) in
            let needsFinish = !state.ended
            state.ended = true
            if needsFinish { state.failure = CancellationError() }
            let channel = state.channel
            state.channel = nil
            return (needsFinish, channel)
        }
        if result.0 { continuation.finish(throwing: CancellationError()) }
        result.1?.close(promise: nil)
    }
}

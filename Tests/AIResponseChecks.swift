import Foundation

enum MARCAIError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let value): return value }
    }
}
enum ResponseFixtureError: Error { case failed }

// Protect counters because cancellation callbacks may run on another executor.
final class ResponseProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var reads = 0
    private var cancellations = 0
    func advance() -> Int {
        lock.lock(); defer { lock.unlock() }
        let index = reads; reads += 1; return index
    }
    func cancel() { lock.lock(); cancellations += 1; lock.unlock() }
    var readCount: Int { lock.lock(); defer { lock.unlock() }; return reads }
    var cancelCount: Int { lock.lock(); defer { lock.unlock() }; return cancellations }
}

struct ResponseBytes: AsyncSequence, Sendable {
    typealias Element = UInt8
    let count: Int
    let probe: ResponseProbe
    var failureAt: Int? = nil
    var cancelAt: Int? = nil
    struct AsyncIterator: AsyncIteratorProtocol {
        let source: ResponseBytes
        mutating func next() async throws -> UInt8? {
            let index = source.probe.advance()
            if index == source.failureAt { throw ResponseFixtureError.failed }
            if index == source.cancelAt { withUnsafeCurrentTask { $0?.cancel() } }
            guard index < source.count else { return nil }
            return UInt8(index % 251)
        }
    }
    func makeAsyncIterator() -> AsyncIterator { AsyncIterator(source: self) }
}

@main struct AIResponseChecks {
    static func response(status: Int = 200, length: Int? = nil) -> HTTPURLResponse {
        let headers = length.map { ["Content-Length": String($0)] }
        return HTTPURLResponse(url: URL(string: "https://fixture.invalid/chat")!,
            statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
    }
    static func rejected(_ bytes: ResponseBytes, response: URLResponse, message: String) async throws {
        do {
            _ = try await MARCAIResponseReader.read(bytes, response: response) { bytes.probe.cancel() }
            preconditionFailure("Expected rejection")
        } catch let error as MARCAIError {
            precondition(error.localizedDescription.contains(message))
        }
        precondition(bytes.probe.cancelCount >= 1)
    }
    @MainActor static func main() async throws {
        let limit = 262144
        let normal = ResponseProbe()
        let body = try await MARCAIResponseReader.read(ResponseBytes(count: 16, probe: normal),
            response: response(length: 16)) { normal.cancel() }
        precondition(body == Data((0..<16).map { UInt8($0) }) && normal.cancelCount == 1)
        let empty = ResponseProbe()
        let emptyBody = try await MARCAIResponseReader.read(ResponseBytes(count: 0, probe: empty),
            response: response(length: 0)) { empty.cancel() }
        precondition(emptyBody.isEmpty && empty.cancelCount == 1)
        let exact = ResponseProbe()
        let exactBody = try await MARCAIResponseReader.read(ResponseBytes(count: limit, probe: exact),
            response: response(length: limit)) { exact.cancel() }
        precondition(exactBody.count == limit && exactBody.last == UInt8((limit - 1) % 251))

        let declaredLarge = ResponseProbe()
        try await rejected(ResponseBytes(count: 5_000_000, probe: declaredLarge),
            response: response(length: limit + 1), message: "exceeded its limit")
        precondition(declaredLarge.readCount == 0)
        for declaredLength in [nil, 10] as [Int?] {
            let large = ResponseProbe()
            try await rejected(ResponseBytes(count: 5_000_000, probe: large),
                response: response(length: declaredLength), message: "exceeded its limit")
            precondition(large.readCount == limit + 1, "Stop without consuming the complete oversized body")
        }
        let badStatus = ResponseProbe()
        try await rejected(ResponseBytes(count: 100, probe: badStatus),
            response: response(status: 401, length: 100), message: "HTTP 401")
        precondition(badStatus.readCount == 0)
        let nonHTTP = ResponseProbe()
        try await rejected(ResponseBytes(count: 10, probe: nonHTTP),
            response: URLResponse(url: URL(string: "https://fixture.invalid")!,
                mimeType: nil, expectedContentLength: 10, textEncodingName: nil), message: "HTTP 0")
        precondition(nonHTTP.readCount == 0)

        let failed = ResponseProbe()
        do {
            _ = try await MARCAIResponseReader.read(ResponseBytes(count: 100, probe: failed, failureAt: 5),
                response: response()) { failed.cancel() }
            preconditionFailure("Expected transport error")
        } catch ResponseFixtureError.failed {}
        precondition(failed.cancelCount >= 1 && failed.readCount == 6)

        let queued = ResponseProbe()
        let queuedTask = Task { @MainActor in
            try await MARCAIResponseReader.read(ResponseBytes(count: 100, probe: queued),
                response: response()) { queued.cancel() }
        }
        queuedTask.cancel()
        do { _ = try await queuedTask.value; preconditionFailure("Expected queued cancellation") }
        catch is CancellationError {}
        precondition(queued.readCount == 0 && queued.cancelCount >= 1)

        let cancelled = ResponseProbe()
        let cancelledTask = Task {
            try await MARCAIResponseReader.read(ResponseBytes(count: 100, probe: cancelled, cancelAt: 12),
                response: response()) { cancelled.cancel() }
        }
        do { _ = try await cancelledTask.value; preconditionFailure("Expected partial cancellation") }
        catch is CancellationError {}
        precondition(cancelled.readCount == 13 && cancelled.cancelCount >= 1)
        print("PASS: AI response streaming limits, declared/chunked sizes, HTTP failures and transport cleanup")
        print("PASS: queued and partial AI-response cancellation stop consumption without returning partial data")
    }
}

import Foundation

enum MARCAIResponseReader {
    // Bound the assembled body while it arrives, including chunked responses.
    // The caller supplies transport cancellation so early exits stop the request.
    nonisolated static func read<Bytes: AsyncSequence & Sendable>(
        _ bytes: Bytes, response: URLResponse,
        cancel: @escaping @Sendable () -> Void
    ) async throws -> Data where Bytes.Element == UInt8 {
        defer { cancel() }
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw MARCAIError.message(
                    "API request failed (HTTP \(status)). Check endpoint, model and key."
                )
            }
            let maximumBytes = 262144
            guard response.expectedContentLength <= Int64(maximumBytes) else {
                throw MARCAIError.message("AI response exceeded its limit.")
            }
            var data = Data()
            data.reserveCapacity(8192)
            for try await byte in bytes {
                try Task.checkCancellation()
                guard data.count < maximumBytes else {
                    throw MARCAIError.message("AI response exceeded its limit.")
                }
                data.append(byte)
            }
            try Task.checkCancellation()
            return data
        } onCancel: {
            cancel()
        }
    }
}

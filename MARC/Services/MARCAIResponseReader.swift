import Foundation

enum MARCAIResponseReader {
    // Bound the assembled body while it arrives, including chunked responses.
    // The caller supplies transport cancellation so early exits stop the request.
    nonisolated static func read<Bytes: AsyncSequence & Sendable>(
        _ bytes: Bytes, response: URLResponse, redacting secrets: [String] = [],
        cancel: @escaping @Sendable () -> Void
    ) async throws -> Data where Bytes.Element == UInt8 {
        defer { cancel() }
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse else {
                throw MARCAIError.message("API request failed (HTTP 0). Invalid server response.")
            }
            if !(200...299).contains(http.statusCode) {
                var errorBody = Data()
                // Read only a small error object; never retain an unlimited failure body.
                if response.expectedContentLength <= 8192 {
                    for try await byte in bytes {
                        try Task.checkCancellation()
                        if errorBody.count == 8192 { break }
                        errorBody.append(byte)
                    }
                }
                try Task.checkCancellation()
                throw MARCAIError.message(errorMessage(status: http.statusCode, data: errorBody, redacting: secrets))
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

    nonisolated static func errorMessage(status: Int, data: Data, redacting secrets: [String]) -> String {
        let fallback: String
        switch status {
        case 400: fallback = "The provider rejected this model or request. Choose a supported text model."
        case 401, 403: fallback = "Check the saved API key and its provider permissions."
        case 404: fallback = "This model or endpoint is unavailable. Reload models and select another."
        case 429: fallback = "The provider’s quota or rate limit was reached. Check your account or retry later."
        default: fallback = "The provider could not complete this request. Try again later."
        }
        guard data.count <= 8192,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "API request failed (HTTP \(status)). \(fallback)"
        }
        let message = (json["error"] as? [String: Any])?["message"] as? String
            ?? json["error"] as? String
        guard var safe = message else { return "API request failed (HTTP \(status)). \(fallback)" }
        for secret in secrets where !secret.isEmpty {
            safe = safe.replacingOccurrences(of: secret, with: "[redacted]")
        }
        safe = safe.replacingOccurrences(of: "(?:sk-|gsk_|AIza)[A-Za-z0-9_-]+", with: "[redacted]", options: .regularExpression)
        safe = String(safe.unicodeScalars.map {
            CharacterSet.controlCharacters.contains($0) ? " " : String($0)
        }.joined().prefix(400)).trimmingCharacters(in: .whitespacesAndNewlines)
        return "API request failed (HTTP \(status)). \(safe.isEmpty ? fallback : safe)"
    }
}

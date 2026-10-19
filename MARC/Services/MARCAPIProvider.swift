import Foundation

enum MARCAPIProvider: String, CaseIterable, Identifiable {
    case openAI, gemini, groq, custom
    var id: String { rawValue }
    var name: String {
        switch self {
        case .openAI: return "OpenAI"
        case .gemini: return "Google Gemini"
        case .groq: return "Groq"
        case .custom: return "Custom API"
        }
    }
    var endpoint: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1/chat/completions"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        case .groq: return "https://api.groq.com/openai/v1/chat/completions"
        case .custom: return ""
        }
    }
    static func identify(_ endpoint: String) -> Self {
        let value = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        return allCases.first { $0 != .custom && $0.endpoint == value } ?? .custom
    }
    static func catalogueURL(endpoint: String) throws -> URL {
        let provider = identify(endpoint)
        if provider == .gemini {
            // Native metadata identifies generation methods; the compatibility list does not.
            return URL(string: "https://generativelanguage.googleapis.com/v1beta/models?pageSize=100")!
        }
        guard provider != .custom,
              let url = URL(string: String(provider.endpoint.dropLast("chat/completions".count)) + "models") else {
            throw MARCAIError.message("Enter a model ID for this custom provider.")
        }
        return url
    }
    static func chatModelID(_ raw: String, provider: Self) -> String? {
        var id = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if provider == .gemini && id.hasPrefix("models/") { id = String(id.dropFirst(7)) }
        guard !id.isEmpty, id.utf8.count <= 200,
              id.unicodeScalars.allSatisfy({ $0.value >= 33 && $0.value <= 126 }) else { return nil }
        if provider == .gemini {
            // Keep the standard Gemini text family in this command-only picker.
            guard id.hasPrefix("gemini-"),
                  !["image", "tts", "audio", "live", "robotics", "computer-use"].contains(where: { id.lowercased().contains($0) }) else { return nil }
        }
        return id
    }
    static func requestModel(_ raw: String, endpoint: String) throws -> String {
        guard let id = chatModelID(raw, provider: identify(endpoint)) else {
            throw MARCAIError.message("Choose a text-generation model in Terminal & AI settings, then retry.")
        }
        return id
    }
    static func suggestedModel(in models: [String], endpoint: String) -> String? {
        // Suggestions are provider-specific and must occur in this key's live catalogue.
        // They do not establish account access, free quota or billing status.
        let preferred: [String]
        switch identify(endpoint) {
        case .gemini:
            // Documented free-tier candidates, checked 2026-10-19. Account quotas still apply.
            preferred = ["gemini-3.5-flash-lite", "gemini-3.1-flash-lite", "gemini-2.5-flash-lite"]
        case .openAI: preferred = ["gpt-4.1-mini", "gpt-4o-mini"]
        case .groq: preferred = ["openai/gpt-oss-20b", "openai/gpt-oss-120b"]
        case .custom: return nil
        }
        return preferred.first { models.contains($0) }
    }
    static func nextCatalogueURL(endpoint: String, data: Data, seenTokens: inout Set<String>) throws -> URL? {
        guard identify(endpoint) == .gemini else { return nil }
        guard data.count <= 262144,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MARCAIError.message("Invalid provider catalogue page.")
        }
        guard let raw = json["nextPageToken"] else { return nil }
        guard let token = raw as? String else { throw MARCAIError.message("Invalid provider catalogue page.") }
        if token.isEmpty { return nil }
        guard token.utf8.count <= 2048, seenTokens.insert(token).inserted,
              !token.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
            throw MARCAIError.message("Invalid provider catalogue page.")
        }
        var components = URLComponents(url: try catalogueURL(endpoint: endpoint), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "pageSize", value: "100"), URLQueryItem(name: "pageToken", value: token)]
        guard let url = components.url else { throw MARCAIError.message("Invalid provider catalogue page.") }
        return url
    }
    static func modelIDs(_ data: Data, provider: Self = .custom) throws -> [String] {
        guard data.count <= 262144,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json[provider == .gemini ? "models" : "data"] as? [[String: Any]], rows.count <= 2000 else {
            throw MARCAIError.message("The provider returned an invalid model catalogue.")
        }
        let ids = rows.compactMap { row -> String? in
            guard row["active"] as? Bool != false else { return nil }
            if provider == .gemini {
                guard let methods = row["supportedGenerationMethods"] as? [String], methods.contains("generateContent"),
                      let name = row["name"] as? String else { return nil }
                return chatModelID(name, provider: provider)
            }
            guard let id = row["id"] as? String else { return nil }
            return chatModelID(id, provider: provider)
        }
        return Array(Set(ids)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}

// Catalogue requests never follow a redirect with a saved API key.
enum MARCAPIModelCatalogue {
    @MainActor static func load(endpoint: String, selection: String) async throws -> [String] {
        try Task.checkCancellation()
        var url = try MARCAPIProvider.catalogueURL(endpoint: endpoint)
        let provider = MARCAPIProvider.identify(endpoint)
        let secret = try MARCAPIKeyStore.secret(selection: selection, endpoint: endpoint)
        let session = MARCAINoRedirect.session(timeout: 30)
        defer { session.invalidateAndCancel() }
        var ids = Set<String>()
        var tokens = Set<String>()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(30))
        for _ in 0..<10 {
            try Task.checkCancellation()
            guard clock.now < deadline else { throw MARCAIError.message("Loading models timed out. Please retry.") }
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            if !secret.isEmpty {
                if provider == .gemini { request.setValue(secret, forHTTPHeaderField: "x-goog-api-key") }
                else { request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization") }
            }
            let (bytes, response) = try await session.bytes(for: request)
            let data = try await MARCAIResponseReader.read(bytes, response: response, redacting: [secret]) { bytes.task.cancel() }
            try Task.checkCancellation()
            ids.formUnion(try MARCAPIProvider.modelIDs(data, provider: provider))
            guard ids.count <= 2000 else { throw MARCAIError.message("The provider catalogue exceeded its limit.") }
            guard let next = try MARCAPIProvider.nextCatalogueURL(endpoint: endpoint, data: data, seenTokens: &tokens) else {
                return ids.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            }
            url = next
        }
        throw MARCAIError.message("The provider catalogue exceeded its page limit.")
    }
}

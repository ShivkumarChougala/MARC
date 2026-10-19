#!/usr/bin/env python3
"""Production provider routing/parser and model-list task checks, without network or Keychain."""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
provider = (root / 'MARC/Services/MARCAPIProvider.swift').read_text()
provider = provider[:provider.index('// Catalogue requests')]
settings = (root / 'MARC/Screens/MARCTerminalAI.swift').read_text()
identity = settings[settings.index('    private var catalogueIdentity:'):settings.index('    var body:', settings.index('    private var catalogueIdentity:'))]
methods = settings[settings.index('    private func requestCatalogue('):settings.rfind('\n}')]

support = r'''
import Foundation
enum MARCAIError: Error { case message(String) }
@MainActor final class Gate {
    var entered = false
    var continuation: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; await withCheckedContinuation { continuation = $0 } }
    func open() { continuation?.resume(); continuation = nil }
}
@MainActor enum MARCAPIModelCatalogue {
    static var calls = 0
    static var hook: (() async throws -> [String])?
    static func load(endpoint: String, selection: String) async throws -> [String] {
        calls += 1
        return try await hook?() ?? ["fixture-model"]
    }
}
@MainActor final class CatalogueHarness {
    var provider = "api"
    var endpoint = "https://api.openai.com/v1/chat/completions"
    var selectedAPIKey = ""
    var apiKeysRevision = ""
    var apiModel = ""
    var catalogueModels: [String] = []
    var catalogueLoading = false
    var catalogueTask: Task<Void, Never>?
    var catalogueTaskID = UUID()
    var catalogueConsent = false
    var pendingCatalogue: [String]?
    var showingModelPicker = false
    var failure: String?
    var notice: String?
    func start() { requestCatalogue() }
    func approve() { loadCatalogue() }
    func cancel() { cancelCatalogue() }
'''

checks = r'''
@main struct ProviderChecks {
    static func rejects(_ action: () throws -> Void) {
        do { try action(); preconditionFailure("Expected rejection") } catch {}
    }
    @MainActor static func waitFor(_ condition: () -> Bool) async {
        for _ in 0..<4000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Fixture boundary not reached")
    }
    @MainActor static func main() async throws {
        for provider in MARCAPIProvider.allCases where provider != .custom {
            precondition(MARCAPIProvider.identify(provider.endpoint) == provider)
            let url = try MARCAPIProvider.catalogueURL(endpoint: provider.endpoint)
            precondition(url.scheme == "https" && url.host == URL(string: provider.endpoint)?.host)
            precondition(url.path.hasSuffix("/models"))
        }
        for invalid in ["", "http://api.openai.com/v1/chat/completions", "https://api.openai.com.evil.invalid/v1/chat/completions", MARCAPIProvider.gemini.endpoint + "?redirect=other"] {
            precondition(MARCAPIProvider.identify(invalid) == .custom)
            rejects { _ = try MARCAPIProvider.catalogueURL(endpoint: invalid) }
        }
        let rows: [[String: Any]] = [
            ["id": "b"], ["id": "a"], ["id": "a"], ["id": "hidden", "active": false],
            ["id": "bad\nmodel"], ["id": ""], ["id": String(repeating: "x", count: 201)]
        ]
        let data = try JSONSerialization.data(withJSONObject: ["data": rows])
        let names = try MARCAPIProvider.modelIDs(data)
        precondition(names == ["a", "b"])
        let geminiRows: [[String: Any]] = [
            ["name": "models/gemini-3.5-flash-lite", "supportedGenerationMethods": ["generateContent"]],
            ["name": "models/gemini-3.5-flash-lite", "supportedGenerationMethods": ["generateContent"]],
            ["name": "models/antigravity-preview-05-2026", "supportedGenerationMethods": ["generateContent"]],
            ["name": "models/gemini-embedding", "supportedGenerationMethods": ["embedContent"]],
            ["name": "models/gemini-flash-image", "supportedGenerationMethods": ["generateContent"]],
            ["name": "models/gemini-pro-tts", "supportedGenerationMethods": ["generateContent"]],
            ["name": "models/gemini-native-audio", "supportedGenerationMethods": ["generateContent"]]
        ]
        let geminiData = try JSONSerialization.data(withJSONObject: ["models": geminiRows])
        let geminiNames = try MARCAPIProvider.modelIDs(geminiData, provider: .gemini)
        precondition(geminiNames == ["gemini-3.5-flash-lite"])
        let normalized = try MARCAPIProvider.requestModel("models/gemini-3.5-flash-lite", endpoint: MARCAPIProvider.gemini.endpoint)
        precondition(normalized == "gemini-3.5-flash-lite")
        rejects { _ = try MARCAPIProvider.requestModel("models/antigravity-preview-05-2026", endpoint: MARCAPIProvider.gemini.endpoint) }
        var tokens = Set<String>()
        let page = try JSONSerialization.data(withJSONObject: ["nextPageToken": "abc&redirect=https://other.invalid"])
        let next = try MARCAPIProvider.nextCatalogueURL(endpoint: MARCAPIProvider.gemini.endpoint, data: page, seenTokens: &tokens)!
        precondition(next.host == "generativelanguage.googleapis.com" && next.path == "/v1beta/models")
        precondition(URLComponents(url: next, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "pageToken" })?.value == "abc&redirect=https://other.invalid")
        rejects { _ = try MARCAPIProvider.nextCatalogueURL(endpoint: MARCAPIProvider.gemini.endpoint, data: page, seenTokens: &tokens) }
        for bad in [Data("{}".utf8), Data("broken".utf8), Data(repeating: 32, count: 262145)] {
            rejects { _ = try MARCAPIProvider.modelIDs(bad) }
        }
        let tooMany = try JSONSerialization.data(withJSONObject: ["data": Array(repeating: ["id": "a"], count: 2001)])
        rejects { _ = try MARCAPIProvider.modelIDs(tooMany) }
        print("PASS: API provider presets, same-host catalogue routing and bounded/deduplicated model parsing")
        print("PASS: Gemini generation capabilities, resource-name normalization and exclusion of non-text catalogue entries")
        precondition(MARCAPIProvider.suggestedModel(in: ["gemini-2.5-flash-lite", "gemini-3.5-flash-lite"], endpoint: MARCAPIProvider.gemini.endpoint) == "gemini-3.5-flash-lite")
        precondition(MARCAPIProvider.suggestedModel(in: ["gemini-2.5-flash-lite"], endpoint: MARCAPIProvider.gemini.endpoint) == "gemini-2.5-flash-lite")
        precondition(MARCAPIProvider.suggestedModel(in: ["gemini-pro", "unknown-model"], endpoint: MARCAPIProvider.gemini.endpoint) == nil)
        precondition(MARCAPIProvider.suggestedModel(in: ["gemini-3.5-flash-lite"], endpoint: MARCAPIProvider.openAI.endpoint) == nil)
        precondition(MARCAPIProvider.suggestedModel(in: ["gpt-4.1-mini", "gpt-4o-mini"], endpoint: MARCAPIProvider.openAI.endpoint) == "gpt-4.1-mini")
        precondition(MARCAPIProvider.suggestedModel(in: ["gpt-4o-mini"], endpoint: MARCAPIProvider.openAI.endpoint) == "gpt-4o-mini")
        precondition(MARCAPIProvider.suggestedModel(in: ["openai/gpt-oss-20b", "openai/gpt-oss-120b"], endpoint: MARCAPIProvider.groq.endpoint) == "openai/gpt-oss-20b")
        precondition(MARCAPIProvider.suggestedModel(in: ["unrecognized"], endpoint: MARCAPIProvider.groq.endpoint) == nil)
        precondition(MARCAPIProvider.suggestedModel(in: ["gpt-4.1-mini"], endpoint: "https://custom.invalid/chat/completions") == nil)

        let queued = CatalogueHarness()
        queued.start()
        precondition(queued.catalogueConsent && queued.catalogueTask == nil && MARCAPIModelCatalogue.calls == 0)
        queued.cancel(); queued.approve()
        precondition(queued.catalogueTask == nil)
        queued.start(); queued.endpoint = MARCAPIProvider.gemini.endpoint; queued.approve()
        precondition(queued.catalogueTask == nil)
        queued.start(); queued.selectedAPIKey = UUID().uuidString; queued.approve()
        precondition(queued.catalogueTask == nil)
        queued.start(); queued.apiKeysRevision = UUID().uuidString; queued.approve()
        precondition(queued.catalogueTask == nil)
        queued.start(); queued.approve(); let queuedTask = queued.catalogueTask
        queued.cancel(); await queuedTask?.value
        precondition(MARCAPIModelCatalogue.calls == 0 && !queued.catalogueLoading)

        let gate = Gate(); let stale = CatalogueHarness()
        MARCAPIModelCatalogue.hook = { await gate.wait(); return ["old-model"] }
        stale.start(); stale.approve(); let staleTask = stale.catalogueTask
        await waitFor { gate.entered }
        stale.start(); stale.approve() // duplicate taps cannot replace a busy task
        precondition(MARCAPIModelCatalogue.calls == 1)
        stale.endpoint = MARCAPIProvider.groq.endpoint
        gate.open(); await staleTask?.value
        precondition(stale.catalogueModels.isEmpty && !stale.showingModelPicker && stale.failure == nil)

        let oldGate = Gate(), newGate = Gate(); let owner = CatalogueHarness()
        MARCAPIModelCatalogue.hook = { await oldGate.wait(); return ["old"] }
        owner.start(); owner.approve(); let oldTask = owner.catalogueTask
        await waitFor { oldGate.entered }; owner.cancel()
        MARCAPIModelCatalogue.hook = { await newGate.wait(); return ["new"] }
        owner.start(); owner.approve(); let newTask = owner.catalogueTask
        await waitFor { newGate.entered }
        oldGate.open(); await oldTask?.value
        precondition(owner.catalogueLoading && owner.catalogueModels.isEmpty)
        newGate.open(); await newTask?.value
        precondition(owner.catalogueModels == ["new"] && owner.showingModelPicker && !owner.catalogueLoading)
        MARCAPIModelCatalogue.hook = { throw MARCAIError.message("fixture failure") }
        let failed = CatalogueHarness(); failed.start(); failed.approve(); await failed.catalogueTask?.value
        precondition(failed.failure != nil && !failed.catalogueLoading && !failed.showingModelPicker)
        print("PASS: model-list consent, queued cancellation, duplicate taps, stale endpoints/keys and task ownership")
        MARCAPIModelCatalogue.hook = { ["gemini-3.5-flash-lite", "gemini-other"] }
        let automatic = CatalogueHarness(); automatic.endpoint = MARCAPIProvider.gemini.endpoint
        automatic.start(); automatic.approve(); await automatic.catalogueTask?.value
        precondition(automatic.apiModel == "gemini-3.5-flash-lite" && !automatic.showingModelPicker)
        let manual = CatalogueHarness(); manual.endpoint = MARCAPIProvider.gemini.endpoint
        manual.apiModel = "gemini-user-choice"
        manual.start(); manual.approve(); await manual.catalogueTask?.value
        precondition(manual.apiModel == "gemini-user-choice" && manual.showingModelPicker)
        MARCAPIModelCatalogue.hook = { ["gemini-pro"] }
        let unknown = CatalogueHarness(); unknown.endpoint = MARCAPIProvider.gemini.endpoint
        unknown.start(); unknown.approve(); await unknown.catalogueTask?.value
        precondition(unknown.apiModel.isEmpty && unknown.showingModelPicker)
        print("PASS: first-load Gemini suggestion uses available Flash-Lite candidates and preserves existing model choices")
        MARCAPIModelCatalogue.hook = { ["gpt-4.1-mini"] }
        let openAI = CatalogueHarness(); openAI.start(); openAI.approve(); await openAI.catalogueTask?.value
        precondition(openAI.apiModel == "gpt-4.1-mini" && !openAI.showingModelPicker)
        MARCAPIModelCatalogue.hook = { ["openai/gpt-oss-20b"] }
        let groq = CatalogueHarness(); groq.endpoint = MARCAPIProvider.groq.endpoint
        groq.start(); groq.approve(); await groq.catalogueTask?.value
        precondition(groq.apiModel == "openai/gpt-oss-20b" && !groq.showingModelPicker)
        print("PASS: provider-specific suggestions use the current catalogue for OpenAI and Groq; custom providers remain manual")
    }
}
'''

def fixture_source():
    return support + identity + methods + '\n}\n' + provider + checks

def main():
    compiler = shutil.which('swiftc')
    if not compiler:
        raise SystemExit('Swift is required. Run API provider checks on your Mac.')
    with tempfile.TemporaryDirectory(prefix='marc-api-provider-') as folder:
        folder = Path(folder)
        source = folder / 'ProviderChecks.swift'
        source.write_text(fixture_source())
        binary = folder / 'checks'
        subprocess.run([compiler, '-swift-version', '5', '-parse-as-library', str(source), '-o', str(binary)], check=True)
        subprocess.run([str(binary)], check=True, timeout=30)

if __name__ == '__main__':
    main()

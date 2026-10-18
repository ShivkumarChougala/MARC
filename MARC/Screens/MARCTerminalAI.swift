import Foundation
import SwiftUI
import UIKit

struct MARCTerminalAI: View {
    let session: MARCTerminalSession
    var focusChanged: (Bool) -> Void = { _ in }
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @AppStorage("marc.ai.provider") private var provider = "off"
    @AppStorage("marc.ai.localModel") private var localModel = ""
    @AppStorage("marc.ai.apiModel") private var apiModel = ""
    @AppStorage("marc.ai.endpoint") private var endpoint = ""
    @AppStorage("marc.ai.localServer") private var localServer = ""

    @State private var prompt = ""
    @State private var command = ""
    @State private var historyPrompt: String?
    @State private var commandConnection: UUID?
    @State private var commandConfiguration: [String]?
    @State private var failure: String?
    @State private var busy = false
    @State private var requestTask: Task<Void, Never>?
    @State private var requestID = UUID()
    @FocusState private var promptFocused: Bool

    private let credentialID =
        UUID(uuidString: "8769682D-2807-4706-81D8-28512948AB21")!

    private var configuration: [String] {
        if provider == "local" {
            return [provider, localModel.trimmingCharacters(in: .whitespacesAndNewlines), localServer]
        }
        return [provider, apiModel.trimmingCharacters(in: .whitespacesAndNewlines),
                endpoint.trimmingCharacters(in: .whitespacesAndNewlines)]
    }

    private var canRequest: Bool {
        guard session.ready, !busy,
              !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return false }
        if provider == "local" {
            return !localModel.isEmpty &&
                localServer == session.aiServerID?.uuidString
        }
        return provider == "api" &&
            !apiModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var insertable: Bool {
        let value = command.trimmingCharacters(in: .whitespacesAndNewlines)
        return session.ready && !busy && !value.isEmpty &&
            commandConnection == session.aiConnectionID &&
            commandConfiguration == configuration &&
            !value.unicodeScalars.contains {
                $0.value < 32 || $0.value == 127 ||
                (0x80...0x9f).contains($0.value) ||
                $0.value == 0x2028 || $0.value == 0x2029
            }
    }

    private var modelLabel: String {
        if provider == "local" {
            if localServer != session.aiServerID?.uuidString {
                return "Select this Mac’s model in Settings"
            }
            return localModel.isEmpty ? "Choose a model in Settings" : localModel
        }
        if provider == "api" {
            return apiModel.isEmpty ? "Configure API in Settings" : apiModel
        }
        return "Enable in Settings"
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(alignment: .leading, spacing: 7) {
            if promptFocused {
                ScrollView(.horizontal) {
                    HStack(spacing: 7) {
                        Text("Recent")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(p.muted)
                        if session.aiHistory.isEmpty {
                            Text("Commands you run with AI appear here")
                                .font(.system(size: 11)).foregroundStyle(p.muted)
                                .padding(.vertical, 10)
                        }
                        ForEach(session.aiHistory) { previous in
                            Button {
                                command = previous.command
                                historyPrompt = previous.prompt
                                commandConnection = session.aiConnectionID
                                commandConfiguration = configuration
                                failure = nil
                            } label: {
                                HStack(spacing: 7) {
                                    Image(systemName: "sparkles").foregroundStyle(p.accent)
                                    Text(previous.prompt.isEmpty ? previous.command : previous.prompt)
                                        .font(.system(size: 11)).lineLimit(1)
                                    Text(previous.command)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(p.muted).lineLimit(1)
                                }
                                .frame(maxWidth: 300, alignment: .leading)
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(p.surface, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Review recent command: \(previous.command)")
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(height: 44)
                .disabled(busy)
            }

            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundStyle(p.accent)

                TextField(
                    provider == "off" ? "Enable AI in Settings" : "Ask AI for a command…",
                    text: $prompt, axis: .vertical
                )
                .font(.system(size: 13))
                .lineLimit(1...2)
                .focused($promptFocused)
                .onChange(of: prompt) { old, new in
                    if old != new && !busy {
                        clearSuggestion()
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(busy || provider == "off")

                Button {
                    if busy { cancelRequest() }
                    else { generate() }
                } label: {
                    Group {
                        if busy {
                            ProgressView()
                                .controlSize(.small)
                                .tint(p.accent)
                        } else {
                            Text("AI")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .foregroundStyle(p.accent)
                    .frame(width: 36, height: 36)
                    .background(p.accent.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!busy && !canRequest)
                .accessibilityLabel(busy ? "Cancel generation" : "Generate command")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(p.border, lineWidth: 1)
            )

            if !command.isEmpty {
                HStack(spacing: 8) {
                    ScrollView(.horizontal) {
                        Text(command)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(p.text)
                            .textSelection(.enabled)
                            .padding(.vertical, 11)
                            .padding(.horizontal, 12)
                    }
                    .scrollIndicators(.hidden)

                    Button(action: runCommand) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(p.accent)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .disabled(!insertable)
                    .accessibilityLabel("Run generated command")

                    Button { clearSuggestion() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                            .frame(width: 32, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss generated command")
                }
                .background(p.raised, in: RoundedRectangle(cornerRadius: 12))

                if !insertable {
                    Text("Reconnect the shell, or generate a single-line command.")
                        .font(.system(size: 10))
                        .foregroundStyle(p.muted)
                }
            }

            if let failure {
                Text(failure)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .onChange(of: promptFocused) { _, focused in focusChanged(focused) }
        .onChange(of: session.aiConnectionID) { _, _ in
            cancelRequest()
            clearSuggestion()
        }
        .onChange(of: configuration) { _, _ in
            cancelRequest()
            clearSuggestion()
        }
        .onDisappear { cancelRequest(); focusChanged(false) }
    }

    private func runCommand() {
        guard insertable else { return }
        let value = command.trimmingCharacters(in: .whitespacesAndNewlines)
        promptFocused = false
        session.view?.resignFirstResponder()
        session.rememberAI(prompt: historyPrompt ?? prompt, command: value)
        session.send(Array((value + "\r").utf8))
        clearSuggestion()
        prompt = ""
    }

    private func clearSuggestion() {
        command = ""
        historyPrompt = nil
        commandConnection = nil
        commandConfiguration = nil
        failure = nil
    }

    private func cancelRequest() {
        requestID = UUID()
        requestTask?.cancel()
        requestTask = nil
        busy = false
    }

    private func generate() {
        guard canRequest else { return }
        let connection = session.aiConnectionID
        let chosenProvider = provider
        let chosenConfiguration = configuration
        let model = (provider == "local" ? localModel : apiModel)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let requestPrompt = prompt
        let key = MARCCredentials.read(credentialID)?.password ?? ""
        let urlText = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = UUID()
        requestID = id
        busy = true
        clearSuggestion()

        requestTask = Task { @MainActor in
            defer {
                if requestID == id { busy = false; requestTask = nil }
            }
            do {
                try Task.checkCancellation()
                guard requestID == id, configuration == chosenConfiguration,
                      session.aiConnectionID == connection, session.ready else {
                    throw CancellationError()
                }
                guard !model.isEmpty else {
                    throw MARCAIError.message("Enter a model name.")
                }
                let messages: [[String: String]] = [
                    [
                        "role": "system",
                        "content":
                            "Suggest exactly one single-line macOS shell command for the user's request. Output only the command, without markdown or explanations. Use macOS command syntax. Prefer non-destructive operations. If the request is unclear, return an empty response."
                    ],
                    ["role": "user", "content": requestPrompt]
                ]
                let body = try JSONSerialization.data(withJSONObject: [
                    "model": model,
                    "messages": messages,
                    "stream": false
                ])

                let data: Data
                if chosenProvider == "local" {
                    data = try await session.localAI(body: body)
                } else {
                    guard let url = URL(string: urlText),
                          url.scheme?.lowercased() == "https",
                          url.host != nil,
                          url.user == nil, url.password == nil else {
                        throw MARCAIError.message(
                            "Enter a valid HTTPS chat completions endpoint."
                        )
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.timeoutInterval = 120
                    request.httpBody = body
                    request.setValue(
                        "application/json", forHTTPHeaderField: "Content-Type"
                    )
                    if !key.isEmpty {
                        request.setValue(
                            "Bearer \(key)", forHTTPHeaderField: "Authorization"
                        )
                    }

                    let (bytes, response) =
                        try await URLSession.shared.bytes(for: request)
                    data = try await MARCAIResponseReader.read(bytes, response: response) {
                        bytes.task.cancel()
                    }
                }

                try Task.checkCancellation()
                guard requestID == id, configuration == chosenConfiguration,
                      session.aiConnectionID == connection, session.ready else { return }

                guard let json = try JSONSerialization.jsonObject(
                    with: data
                ) as? [String: Any] else {
                    throw MARCAIError.message("Invalid AI response.")
                }
                if let error = json["error"] as? String {
                    throw MARCAIError.message(error)
                }

                let result: String?
                if chosenProvider == "local" {
                    result = (json["message"] as? [String: Any])?["content"] as? String
                } else {
                    let choices = json["choices"] as? [[String: Any]]
                    result = (choices?.first?["message"] as? [String: Any])?["content"] as? String
                }

                var cleaned = (result ?? "").trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                if cleaned.hasPrefix("```") {
                    var lines = cleaned.components(separatedBy: "\n")
                    lines.removeFirst()
                    if lines.last?.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) == "```" {
                        lines.removeLast()
                    }
                    cleaned = lines.joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                guard !cleaned.isEmpty else {
                    throw MARCAIError.message(
                        "No command returned. Try a more specific request."
                    )
                }
                command = cleaned
                historyPrompt = requestPrompt
                commandConnection = connection
                commandConfiguration = chosenConfiguration
            } catch is CancellationError {
                // Cancellation is a state transition, not an AI failure.
            } catch {
                guard requestID == id, !Task.isCancelled,
                      configuration == chosenConfiguration,
                      session.aiConnectionID == connection, session.ready else { return }
                failure = error.localizedDescription
            }
        }
    }
}

struct MARCTerminalAISettings: View {
    let monitor: SSHMonitor
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @Environment(\.dismiss) private var dismiss

    @AppStorage("marc.ai.provider") private var provider = "off"
    @AppStorage("marc.ai.localModel") private var localModel = ""
    @AppStorage("marc.ai.localServer") private var localServer = ""
    @AppStorage("marc.ai.apiModel") private var apiModel = ""
    @AppStorage("marc.ai.endpoint") private var endpoint = ""

    @State private var models: [String] = []
    @State private var apiKey = ""
    @State private var loading = false
    @State private var failure: String?
    @State private var notice: String?
    @State private var reload = 0

    private let credentialID =
        UUID(uuidString: "8769682D-2807-4706-81D8-28512948AB21")!

    private var discoveryID: String {
        "\(provider)-\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)-\(reload)"
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 40, height: 40)
                        .background(p.raised, in: Circle())
                }
                .foregroundStyle(p.accent)
                .accessibilityLabel("Back")
                Text("Terminal & AI")
                    .font(.system(size: 19, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Provider")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(p.muted)
                        Picker("Provider", selection: $provider) {
                            Text("Off").tag("off")
                            Text("Local").tag("local")
                            Text("API").tag("api")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    .background(
                        p.surface, in: RoundedRectangle(cornerRadius: 16)
                    )

                    if provider == "local" {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Installed models")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(monitor.connected
                                         ? (monitor.server?.name ?? "Connected Mac")
                                         : "Connect a Mac in Settings")
                                        .font(.system(size: 11))
                                        .foregroundStyle(p.muted)
                                }
                                Spacer()
                                if loading {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Button { reload += 1 } label: {
                                        Image(systemName: "arrow.clockwise")
                                            .frame(width: 40, height: 40)
                                    }
                                    .foregroundStyle(p.accent)
                                    .disabled(!monitor.connected)
                                    .accessibilityLabel("Refresh installed models")
                                }
                            }
                            .padding(14)

                            ForEach(models, id: \.self) { model in
                                Divider().padding(.horizontal, 14)
                                Button {
                                    select(model)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "cube")
                                            .foregroundStyle(p.muted)
                                        Text(model)
                                            .font(.system(size: 13))
                                            .lineLimit(2)
                                        Spacer()
                                        if localModel == model &&
                                            localServer == monitor.server?.id.uuidString {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(p.accent)
                                        }
                                    }
                                    .foregroundStyle(p.text)
                                    .padding(.horizontal, 16)
                                    .frame(minHeight: 54)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            if !loading && models.isEmpty && monitor.connected &&
                                failure == nil {
                                Text("No installed models found.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(p.muted)
                                    .padding(16)
                            }
                        }
                        .background(
                            p.surface, in: RoundedRectangle(cornerRadius: 16)
                        )

                        Text("Uses Ollama on this Mac through SSH. The model choice is remembered separately for each Mac.")
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 4)
                    }

                    if provider == "api" {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("API connection")
                                .font(.system(size: 14, weight: .semibold))
                            fieldTitle("Chat completions endpoint", palette: p)
                            TextField(
                                "https://…/v1/chat/completions",
                                text: $endpoint
                            )
                            .keyboardType(.URL)
                            .font(.system(size: 12))
                            Divider()
                            fieldTitle("Model", palette: p)
                            TextField("Model name", text: $apiModel)
                                .font(.system(size: 13))
                            Divider()
                            fieldTitle("API key", palette: p)
                            SecureField("Optional for keyless providers", text: $apiKey)
                                .font(.system(size: 13))

                            Button(action: saveKey) {
                                HStack {
                                    Text("Save API key")
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(p.accent)
                                .padding(12)
                                .background(
                                    p.raised,
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .background(
                            p.surface, in: RoundedRectangle(cornerRadius: 16)
                        )

                        Text("Use a compatible HTTPS chat completions endpoint. The API key is stored in Keychain; provider, endpoint and model choices save automatically.")
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 4)
                    }

                    if provider == "off" {
                        Text("Choose Local or API to enable Ask AI in the terminal.")
                            .font(.system(size: 12))
                            .foregroundStyle(p.muted)
                            .padding(.horizontal, 4)
                    }

                    if let notice {
                        Text(notice)
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                    }
                    if let failure {
                        Text(failure)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(p.text)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .marcCanvas()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            apiKey = MARCCredentials.read(credentialID)?.password ?? ""
        }
        .onDisappear { apiKey = "" }
        .task(id: discoveryID) {
            await discoverModels()
        }
    }

    private func fieldTitle(
        _ title: String, palette: MARCPalette
    ) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(palette.muted)
    }

    private func select(_ model: String) {
        guard monitor.connected, let id = monitor.server?.id else { return }
        localModel = model
        localServer = id.uuidString
        UserDefaults.standard.set(
            model, forKey: "marc.ai.model.\(id.uuidString)"
        )
    }

    @MainActor
    private func discoverModels() async {
        guard !Task.isCancelled else { return }
        models = []
        failure = nil
        notice = nil
        guard provider == "local", monitor.connected,
              let serverID = monitor.server?.id else {
            loading = false
            return
        }

        let discovery = discoveryID
        loading = true
        defer {
            if discoveryID == discovery, !Task.isCancelled { loading = false }
        }

        do {
            let names = try await monitor.marcInstalledAIModels()
            try Task.checkCancellation()
            guard discoveryID == discovery,
                  monitor.server?.id == serverID else { return }
            models = names

            let remembered = UserDefaults.standard.string(
                forKey: "marc.ai.model.\(serverID.uuidString)"
            ) ?? (localServer == serverID.uuidString ? localModel : "")

            localServer = serverID.uuidString
            localModel = names.contains(remembered) ? remembered : ""
            if names.count == 1, let only = names.first {
                select(only)
            }
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled, discoveryID == discovery,
                  monitor.connected, monitor.server?.id == serverID else { return }
            failure = error.localizedDescription
        }
    }

    private func saveKey() {
        do {
            try MARCCredentials.save(
                credentialID, password: apiKey, hostKey: ""
            )
            notice = apiKey.isEmpty ? "API key cleared." : "API key saved."
            failure = nil
        } catch {
            failure = "Could not save the API key."
        }
    }
}

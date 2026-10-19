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
    @AppStorage("marc.ai.apiKeyID") private var selectedAPIKey = ""
    @AppStorage("marc.ai.keysRevision") private var apiKeysRevision = ""
    @AppStorage("marc.ai.localServer") private var localServer = ""

    @State private var prompt = ""
    @State private var command = ""
    @State private var commandConnection: UUID?
    @State private var commandConfiguration: [String]?
    @State private var failure: String?
    @State private var busy = false
    @State private var requestTask: Task<Void, Never>?
    @State private var requestID = UUID()
    @State private var showAPIConsent = false
    @State private var pendingAPIConsent: [String]?
    @State private var approvedAPIEndpoint: String?
    @FocusState private var promptFocused: Bool

    private var configuration: [String] {
        if provider == "local" {
            return [provider, localModel.trimmingCharacters(in: .whitespacesAndNewlines), localServer]
        }
        return [provider, apiModel.trimmingCharacters(in: .whitespacesAndNewlines),
                endpoint.trimmingCharacters(in: .whitespacesAndNewlines), selectedAPIKey, apiKeysRevision]
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

    private var statusLabel: String {
        if provider == "local" { return "Local · \(modelLabel)" }
        if provider == "api" {
            if apiModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "API · Choose a model" }
            let selected = MARCAPIProvider.identify(endpoint)
            let name = selected == .custom ? (URL(string: endpoint)?.host ?? "Custom provider") : selected.name
            return "API · \(name)"
        }
        return "AI Off"
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: provider == "local" ? "laptopcomputer" : provider == "api" ? "cloud" : "sparkles")
                    .foregroundStyle(provider == "off" ? p.muted : p.accent)
                Text(statusLabel).foregroundStyle(p.muted).lineLimit(1)
            }
            .font(.system(size: 11))
            .padding(.horizontal, 3)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(provider == "off" ? "AI off" : "\(statusLabel). Model: \(modelLabel)")

            HStack(alignment: .center, spacing: 8) {
                if provider == "off" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose Local or API to enable AI")
                            .font(.system(size: 12))
                        Text("Settings → Terminal & AI")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(p.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField(
                        "Ask AI for a command…",
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
                    .disabled(busy)
                }

                Button {
                    if busy { cancelRequest() }
                    else { generate() }
                } label: {
                    Group {
                        if busy {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.black)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundStyle(provider == "off" ? p.muted : Color.black)
                    .frame(width: 36, height: 36)
                    .background(provider == "off" ? p.raised : p.accent, in: Circle())
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
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!insertable)
                    .accessibilityLabel("Run generated command")

                    Button { clearSuggestion() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundStyle(p.muted)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
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
                    .lineLimit(4)
            }
        }
        .alert("Send prompt to AI service?", isPresented: $showAPIConsent) {
            Button("Cancel", role: .cancel) { pendingAPIConsent = nil }
            Button("Allow and Send") { approveAPIRequest() }
        } message: {
            Text("Destination: \(URL(string: endpoint.trimmingCharacters(in: .whitespacesAndNewlines))?.host ?? endpoint)\n\nMARC sends your prompt, selected model and command-generation instructions. Your API key is included if configured. This service also receives your IP address and may retain your request under its own privacy policy. Terminal output and files are not automatically attached.\n\nAllow this endpoint for this Terminal session? You can keep using Terminal without AI.")
        }
        .onChange(of: promptFocused) { _, focused in focusChanged(focused) }
        .onChange(of: session.aiConnectionID) { _, _ in
            cancelRequest()
            approvedAPIEndpoint = nil
            clearSuggestion()
        }
        .onChange(of: configuration) { _, _ in
            cancelRequest()
            approvedAPIEndpoint = nil
            clearSuggestion()
        }
        .onDisappear { cancelRequest(); focusChanged(false) }
    }

    private func runCommand() {
        guard insertable else { return }
        let value = command.trimmingCharacters(in: .whitespacesAndNewlines)
        promptFocused = false
        _ = session.view?.resignFirstResponder()
        session.send(Array((value + "\r").utf8))
        clearSuggestion()
        prompt = ""
    }

    private func clearSuggestion() {
        command = ""
        commandConnection = nil
        commandConfiguration = nil
        failure = nil
    }

    private func cancelRequest() {
        showAPIConsent = false
        pendingAPIConsent = nil
        requestID = UUID()
        requestTask?.cancel()
        requestTask = nil
        busy = false
    }

    private func generate() {
        guard canRequest else { return }
        if provider != "local" {
            let destination = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: destination), url.scheme?.lowercased() == "https",
                  url.host != nil, url.user == nil, url.password == nil else {
                failure = "Enter a valid HTTPS chat completions endpoint."
                return
            }
            guard approvedAPIEndpoint == destination else {
                pendingAPIConsent = configuration + [session.aiConnectionID.uuidString, prompt]
                showAPIConsent = true
                return
            }
        }
        let connection = session.aiConnectionID
        let chosenProvider = provider
        let chosenConfiguration = configuration
        let model = (provider == "local" ? localModel : apiModel)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let requestPrompt = prompt
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
                let requestModel: String
                if chosenProvider == "local" { requestModel = model }
                else { requestModel = try MARCAPIProvider.requestModel(model, endpoint: urlText) }
                let body = try JSONSerialization.data(withJSONObject: [
                    "model": requestModel,
                    "messages": messages,
                    "stream": false
                ])

                let data: Data
                if chosenProvider == "local" {
                    data = try await session.localAI(body: body)
                } else {
                    let key = try MARCAPIKeyStore.secret(selection: selectedAPIKey, endpoint: urlText)
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

                    let transport = MARCAINoRedirect.session(timeout: 120)
                    defer { transport.invalidateAndCancel() }
                    let (bytes, response) =
                        try await transport.bytes(for: request)
                    data = try await MARCAIResponseReader.read(bytes, response: response, redacting: [key, requestPrompt]) {
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
    private func approveAPIRequest() {
        guard let pending = pendingAPIConsent,
              pending == configuration + [session.aiConnectionID.uuidString, prompt],
              canRequest, provider != "local" else {
            pendingAPIConsent = nil
            showAPIConsent = false
            return
        }
        approvedAPIEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingAPIConsent = nil
        showAPIConsent = false
        generate()
    }
}

struct MARCTerminalAISettings: View {
    let monitor: SSHMonitor
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    @AppStorage("marc.ai.provider") private var provider = "off"
    @AppStorage("marc.ai.localModel") private var localModel = ""
    @AppStorage("marc.ai.localServer") private var localServer = ""
    @AppStorage("marc.ai.apiModel") private var apiModel = ""
    @AppStorage("marc.ai.endpoint") private var endpoint = ""
    @AppStorage("marc.ai.apiKeyID") private var selectedAPIKey = ""
    @AppStorage("marc.ai.keysRevision") private var apiKeysRevision = ""

    @State private var models: [String] = []
    @State private var apiKeys: [MARCAPIKeyStore.Info] = []
    @State private var catalogueModels: [String] = []
    @State private var catalogueLoading = false
    @State private var catalogueTask: Task<Void, Never>?
    @State private var catalogueTaskID = UUID()
    @State private var catalogueConsent = false
    @State private var pendingCatalogue: [String]?
    @State private var showingModelPicker = false
    @State private var reloadModelsAfterDismiss = false
    @State private var loading = false
    @State private var failure: String?
    @State private var notice: String?
    @State private var reload = 0

    private var discoveryID: String {
        "\(provider)-\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)-\(reload)"
    }

    private var catalogueIdentity: [String] {
        [provider, endpoint.trimmingCharacters(in: .whitespacesAndNewlines), selectedAPIKey, apiKeysRevision]
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI mode")
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
                        VStack(alignment: .leading, spacing: 12) {
                            Text("API connection").font(.system(size: 14, weight: .semibold))
                            HStack {
                                Label("Provider", systemImage: "network").font(.system(size: 13)).foregroundStyle(p.muted)
                                Spacer()
                                Menu {
                                    ForEach(MARCAPIProvider.allCases) { choice in
                                        Button(choice.name) {
                                            guard choice != MARCAPIProvider.identify(endpoint) else { return }
                                            endpoint = choice.endpoint
                                            selectedAPIKey = ""
                                            apiModel = ""
                                            notice = nil
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(MARCAPIProvider.identify(endpoint).name)
                                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 9))
                                    }.font(.system(size: 13)).foregroundStyle(p.text).frame(minHeight: 44)
                                }
                            }
                            Divider()
                            Menu {
                                ForEach(apiKeys) { key in
                                    Button { selectAPIKey(key) } label: {
                                        if selectedAPIKey == key.id.uuidString {
                                            Label(key.name, systemImage: "checkmark")
                                        } else { Text(key.name) }
                                    }
                                }
                                Divider()
                                Button("No key · custom endpoint") {
                                    selectedAPIKey = ""
                                    notice = nil
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "key.horizontal").foregroundStyle(p.accent)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(selectedKeyName).font(.system(size: 13, weight: .medium)).foregroundStyle(p.text)
                                        Text("Saved securely in Keychain")
                                            .font(.system(size: 11)).foregroundStyle(p.muted)
                                    }
                                    Spacer(minLength: 4)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10, weight: .semibold)).foregroundStyle(p.muted)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .padding(10).background(p.raised, in: RoundedRectangle(cornerRadius: 10))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Saved API key: \(selectedKeyName)")
                            Divider()
                            HStack(spacing: 8) {
                                Label("Model", systemImage: "cube").font(.system(size: 13)).foregroundStyle(p.muted)
                                Spacer(minLength: 4)
                                if catalogueLoading {
                                    ProgressView().controlSize(.small)
                                    Button("Cancel") { cancelCatalogue() }.font(.system(size: 12)).frame(minHeight: 44)
                                } else {
                                    Button {
                                        if catalogueModels.isEmpty && MARCAPIProvider.identify(endpoint) != .custom {
                                            requestCatalogue()
                                        } else { showingModelPicker = true }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(apiModel.isEmpty ? "Choose model" : apiModel).lineLimit(1)
                                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 9))
                                        }.font(.system(size: 13)).frame(minHeight: 44)
                                    }.tint(p.accent)
                                }
                            }
                            if MARCAPIProvider.identify(endpoint) == .custom {
                                fieldTitle("Chat completions endpoint", palette: p)
                                TextField("https://…/v1/chat/completions", text: $endpoint)
                                    .keyboardType(.URL).font(.system(size: 12)).frame(minHeight: 36)
                            } else {
                                DisclosureGroup("Endpoint") {
                                    Text(endpoint).font(.system(size: 11)).foregroundStyle(p.muted).textSelection(.enabled)
                                }.font(.system(size: 12)).tint(p.muted)
                                DisclosureGroup("Advanced") {
                                    Button("Enter a custom model ID") { showingModelPicker = true }
                                        .font(.system(size: 12)).frame(minHeight: 44)
                                }.font(.system(size: 12)).tint(p.muted)
                            }
                        }
                        .padding(16)
                        .background(
                            p.surface, in: RoundedRectangle(cornerRadius: 16)
                        )

                        Text("Add and manage API keys in Settings → Keychain → API Keys. Select a saved key here; supported providers fill their endpoint automatically.")
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
        .marcNavigationTitle("Terminal & AI")
        .onAppear(perform: loadAPIKeys)
        .onChange(of: apiKeysRevision) { _, _ in loadAPIKeys() }
        .onChange(of: catalogueIdentity) { _, _ in
            cancelCatalogue()
            catalogueModels = []
            showingModelPicker = false
            reloadModelsAfterDismiss = false
        }
        .onChange(of: endpoint) { _, _ in
            validateAPISelection()
        }
        .sheet(isPresented: $showingModelPicker, onDismiss: {
            if reloadModelsAfterDismiss {
                reloadModelsAfterDismiss = false
                requestCatalogue()
            }
        }) {
            MARCAPIModelPicker(models: catalogueModels, selected: apiModel,
                reload: MARCAPIProvider.identify(endpoint) == .custom ? nil : { reloadModelsAfterDismiss = true },
                choose: { apiModel = $0 })
        }
        .alert("Load provider models?", isPresented: $catalogueConsent) {
            Button("Cancel", role: .cancel) { pendingCatalogue = nil }
            Button("Allow and Load") { loadCatalogue() }
        } message: {
            Text("MARC will contact \(URL(string: endpoint)?.host ?? "this provider") to list models. Your API key is included if selected, and the provider receives your IP address. Your prompt, terminal output and files are not sent.")
        }
        .onDisappear { reloadModelsAfterDismiss = false; cancelCatalogue() }
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

    private var selectedKeyName: String {
        if selectedAPIKey.isEmpty { return apiKeys.isEmpty ? "Add a key in Keychain" : "Select API key" }
        return apiKeys.first(where: { $0.id.uuidString == selectedAPIKey })?.name ?? "Key unavailable · select another"
    }

    private func selectAPIKey(_ key: MARCAPIKeyStore.Info) {
        let changedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines) != key.endpoint
        if changedEndpoint { apiModel = "" }
        endpoint = key.endpoint
        selectedAPIKey = key.id.uuidString
        notice = changedEndpoint || apiModel.isEmpty
            ? "\(key.name) selected. Choose a model below."
            : "\(key.name) selected."
    }

    private func validateAPISelection() {
        guard !selectedAPIKey.isEmpty else { return }
        if !apiKeys.contains(where: {
            $0.id.uuidString == selectedAPIKey &&
                $0.endpoint == endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        }) {
            selectedAPIKey = ""
            notice = "Endpoint changed. Select a matching key or continue without a key."
        }
    }

    private func loadAPIKeys() {
        do {
            if let migrated = try MARCAPIKeyStore.migrateLegacy(endpoint: endpoint),
               selectedAPIKey.isEmpty, migrated.endpoint == endpoint.trimmingCharacters(in: .whitespacesAndNewlines) {
                selectedAPIKey = migrated.id.uuidString
                notice = "Your previous API key is now saved by name."
            }
            apiKeys = try MARCAPIKeyStore.entries()
            if MARCAPIProvider.identify(endpoint) == .gemini && !apiModel.isEmpty {
                if let normalized = MARCAPIProvider.chatModelID(apiModel, provider: .gemini) {
                    apiModel = normalized
                } else {
                    apiModel = ""
                    notice = "Choose a Gemini text model. The previous catalogue entry was not suitable for command generation."
                }
            }
            failure = nil
        } catch {
            failure = error.localizedDescription
        }
    }

    private func requestCatalogue() {
        guard !catalogueLoading else { return }
        pendingCatalogue = catalogueIdentity
        catalogueConsent = true
    }

    private func cancelCatalogue() {
        catalogueTaskID = UUID()
        catalogueTask?.cancel()
        catalogueTask = nil
        catalogueLoading = false
        catalogueConsent = false
        pendingCatalogue = nil
    }

    private func loadCatalogue() {
        guard let identity = pendingCatalogue, identity == catalogueIdentity,
              provider == "api", !catalogueLoading else { pendingCatalogue = nil; return }
        pendingCatalogue = nil
        catalogueConsent = false
        let id = UUID()
        catalogueTaskID = id
        catalogueLoading = true
        failure = nil
        catalogueTask = Task { @MainActor in
            defer {
                if catalogueTaskID == id { catalogueLoading = false; catalogueTask = nil }
            }
            do {
                try Task.checkCancellation()
                guard catalogueTaskID == id, catalogueIdentity == identity else { return }
                let names = try await MARCAPIModelCatalogue.load(endpoint: identity[1], selection: identity[2])
                try Task.checkCancellation()
                guard catalogueTaskID == id, catalogueIdentity == identity else { return }
                catalogueModels = names
                if apiModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let suggested = MARCAPIProvider.suggestedModel(in: names, endpoint: identity[1]) {
                    apiModel = suggested
                    showingModelPicker = false
                    notice = "Selected \(suggested). Tap Model to change it."
                } else {
                    showingModelPicker = true
                    notice = names.isEmpty ? "No models returned. Use Advanced to enter a model ID." : nil
                }
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled, catalogueTaskID == id, catalogueIdentity == identity else { return }
                failure = error.localizedDescription
            }
        }
    }
}

import SwiftUI
import Observation

private enum MARCDeveloperTab: String, CaseIterable, Identifiable {
    case services, docker
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

@MainActor @Observable private final class MARCDeveloperFeed {
    var services: [MARCListeningService] = []
    var containers: [MARCDeveloperContainer] = []
    var managed: [MARCManagedService] = []
    var portsMessage: String?
    var managedMessage: String?
    var message: String?
    var loading = false
    var truncated = false
    private var owner = UUID()
    var connection: UUID?
    var action = ""

    func poll(monitor: SSHMonitor, tab: String, connection: UUID) async {
        guard !Task.isCancelled, monitor.connected, monitor.statisticsConnectionID == connection else { return }
        let token = UUID(); owner = token
        self.connection = connection; action = tab
        if let cached = monitor.marcDeveloperCachedRead(tab) {
            services = cached.reply.services ?? []; containers = cached.reply.containers ?? []
            managed = cached.reply.managed ?? []; portsMessage = cached.reply.portsMessage
            managedMessage = cached.reply.managedMessage; truncated = cached.reply.truncated == true
            message = nil; loading = false
            let remaining = 8 - max(0, ProcessInfo.processInfo.systemUptime - cached.uptime)
            if remaining > 0 {
                do { try await Task.sleep(for: .seconds(remaining)) } catch { return }
            }
        } else {
            services = []; containers = []; managed = []; message = nil; managedMessage = nil
            portsMessage = nil; truncated = false; loading = true
        }
        defer { if owner == token { loading = false } }
        while !Task.isCancelled && monitor.connected && monitor.statisticsConnectionID == connection {
            do {
                let reply = try await monitor.marcDeveloperRequest(action: tab, expectedConnection: connection)
                try Task.checkCancellation()
                guard owner == token, monitor.connected, monitor.statisticsConnectionID == connection else { return }
                services = reply.services ?? []; containers = reply.containers ?? []; managed = reply.managed ?? []
                message = reply.message; managedMessage = reply.managedMessage; portsMessage = reply.portsMessage
                truncated = reply.truncated == true; loading = false
            } catch {
                guard !Task.isCancelled, owner == token, monitor.connected,
                      monitor.statisticsConnectionID == connection else { return }
                message = "Could not update \(tab). Try again."; loading = false
            }
            do { try await Task.sleep(for: .seconds(8)) } catch { return }
        }
    }
}

struct MARCDeveloperToolsView: View {
    let monitor: SSHMonitor
    let enabled: Bool
    @State private var feed = MARCDeveloperFeed()
    @State private var tab = MARCDeveloperTab.services
    @Namespace private var tabSelection
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var active: Bool { enabled && scenePhase == .active && monitor.connected }
    private var taskID: String { "\(monitor.statisticsConnectionID)|\(tab.rawValue)|\(active)" }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        let cached = monitor.marcDeveloperCachedRead(tab.rawValue)
        let reply = cached?.reply
        let services = compactServices(reply?.services ?? [])
        let shownServices = Array(services.prefix(3))
        let containers = reply?.containers ?? []
        let shownContainers = Array(containers.prefix(3))
        let ownFeed = feed.connection == monitor.statisticsConnectionID && feed.action == tab.rawValue
        VStack(alignment: .leading, spacing: 0) {
            // Keep the title compact; the trailing action retains its 44-point
            // target in the empty trailing space beside the tabs below.
            Text("Services & Docker").font(.system(size: 14, weight: .semibold))
                .foregroundStyle(p.text).accessibilityAddTraits(.isHeader)
                .lineLimit(1).minimumScaleFactor(0.85)
                .padding(.trailing, 116)
                .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                .overlay(alignment: .trailing) {
                NavigationLink {
                    MARCDeveloperList(monitor: monitor, kind: tab.rawValue, connection: monitor.statisticsConnectionID)
                } label: {
                    HStack(spacing: 4) {
                        Text(tab == .services ? "All services" : "All containers")
                        Image(systemName: "chevron.right").font(.system(size: 10))
                    }.font(.system(size: 12)).foregroundStyle(p.accent).frame(minHeight: 44)
                }.buttonStyle(.plain).disabled(!monitor.connected)
                }
            HStack(spacing: 18) {
                ForEach(MARCDeveloperTab.allCases) { item in
                    Button { tab = item } label: {
                        Text(item.title).font(.system(size: 13, weight: tab == item ? .semibold : .regular))
                            .foregroundStyle(tab == item ? p.accent : p.muted)
                            .frame(minWidth: 56, minHeight: 44)
                            .overlay(alignment: .bottom) {
                                if tab == item {
                                    Capsule().fill(p.accent).frame(height: 2)
                                        .matchedGeometryEffect(id: "developerSelection", in: tabSelection)
                                }
                            }.contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityAddTraits(tab == item ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity, alignment: .leading)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: tab)
            if let cached, ProcessInfo.processInfo.systemUptime - cached.uptime >= 16 {
                HStack(spacing: 3) {
                    Text("Last checked")
                    Text(cached.receivedAt, style: .relative)
                    Text("ago")
                }.font(.system(size: 10)).foregroundStyle(p.muted)
            }
            Group {
                if !monitor.connected { note("Connect to your Mac.", p) }
                else if cached == nil && (!ownFeed || feed.loading) {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 55)
                } else {
                    if ownFeed, let message = feed.message { note(message, p) }
                    if tab == .services {
                        if let message = reply?.portsMessage { note(message, p) }
                        else if services.isEmpty && (!ownFeed || feed.message == nil) { note("No listening ports found.", p) }
                        VStack(spacing: 0) {
                            ForEach(shownServices) { service in
                                NavigationLink {
                                    MARCServiceDetails(service: service, monitor: monitor, connection: monitor.statisticsConnectionID)
                                } label: { MARCServiceRow(service: service, fullAddress: false) }.buttonStyle(MARCDeveloperRowPressStyle()).padding(.vertical, 2)
                                if service.id != shownServices.last?.id { previewSeparator(p) }
                            }
                        }
                    } else {
                        if containers.isEmpty && (!ownFeed || feed.message == nil) { note("No containers found.", p) }
                        VStack(spacing: 0) {
                            ForEach(shownContainers) { container in
                                NavigationLink {
                                    MARCManagedDetails(monitor: monitor, kind: "docker", identifier: container.id,
                                                       name: container.name, connection: monitor.statisticsConnectionID)
                                } label: { MARCContainerRow(container: container) }.buttonStyle(MARCDeveloperRowPressStyle()).padding(.vertical, 2)
                                if container.id != shownContainers.last?.id { previewSeparator(p) }
                            }
                        }
                    }
                }
            }.id(tab).transition(.opacity)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: tab)
        }.frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: monitor.server?.id, initial: true) { _, id in
            guard let id else { return }
            tab = MARCDeveloperTab(rawValue: UserDefaults.standard.string(forKey: MARCDeveloperPreferences.tabKey(id)) ?? "") ?? .services
        }
        .onChange(of: tab) { _, selected in
            if let id = monitor.server?.id { UserDefaults.standard.set(selected.rawValue, forKey: MARCDeveloperPreferences.tabKey(id)) }
        }
        .task(id: taskID) {
            guard active else { return }
            await feed.poll(monitor: monitor, tab: tab.rawValue, connection: monitor.statisticsConnectionID)
        }
    }
    private func previewSeparator(_ p: MARCPalette) -> some View {
        Rectangle().fill(p.muted.opacity(0.12)).frame(height: 0.5)
            .padding(.leading, 38).accessibilityHidden(true)
    }
    private func compactServices(_ services: [MARCListeningService]) -> [MARCListeningService] {
        var seen = Set<String>()
        return services.filter { seen.insert($0.previewID).inserted }
    }
    private func note(_ text: String, _ p: MARCPalette) -> some View {
        Text(text).font(.system(size: 12)).foregroundStyle(p.muted).fixedSize(horizontal: false, vertical: true).padding(.vertical, 8)
    }
}

private struct MARCDeveloperRowIcon: View {
    let symbol: String
    let palette: MARCPalette
    var body: some View {
        Image(systemName: symbol).font(.system(size: 16, weight: .regular))
            .foregroundStyle(palette.muted).frame(width: 28, height: 28)
            .background(palette.raised, in: RoundedRectangle(cornerRadius: 7))
            .accessibilityHidden(true)
    }
}

private struct MARCDeveloperRowPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.65 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct MARCServiceRow: View {
    let service: MARCListeningService
    var fullAddress = true
    @Environment(\.colorScheme) private var scheme
    // Decorative hints only; process identity and action eligibility come from the backend.
    private var symbol: String {
        switch service.name.lowercased() {
        case "controlcenter": return "slider.horizontal.3"
        case "postgres", "postgresql", "mysqld", "mariadbd", "redis-server", "mongod": return "cylinder"
        default: return "terminal"
        }
    }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        HStack(spacing: 10) {
            MARCDeveloperRowIcon(symbol: symbol, palette: p)
            VStack(alignment: .leading, spacing: 3) {
                Text(service.name).font(.system(size: 13, weight: .medium)).foregroundStyle(p.text).lineLimit(1)
                Text("PID \(String(service.pid))").font(.system(size: 10)).foregroundStyle(p.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Text(fullAddress ? service.endpoint : ":\(service.port)")
                .font(.system(size: 11, design: .monospaced)).foregroundStyle(p.text).lineLimit(1).truncationMode(.middle)
                .frame(width: fullAddress ? nil : 52, alignment: .trailing)
            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(p.muted.opacity(0.7)).accessibilityHidden(true)
        }.frame(minHeight: 44).contentShape(Rectangle()).accessibilityElement(children: .combine)
            .accessibilityLabel("\(service.name), PID \(service.pid), listening on \(service.endpoint)")
    }
}
private func marcServiceState(_ state: String) -> String {
    switch state {
    case "started", "running": return "Running"
    case "none", "stopped", "exited": return "Stopped"
    case "error": return "Error"
    default: return state.capitalized
    }
}
private struct MARCContainerRow: View {
    let container: MARCDeveloperContainer
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        HStack(spacing: 10) {
            MARCDeveloperRowIcon(symbol: "shippingbox", palette: p)
            VStack(alignment: .leading, spacing: 3) {
                Text(container.name).font(.system(size: 13, weight: .medium)).foregroundStyle(p.text).lineLimit(1)
                Text(container.image).font(.system(size: 10)).foregroundStyle(p.muted).lineLimit(1)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Text(marcServiceState(container.state)).font(.system(size: 11)).foregroundStyle(p.muted)
            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(p.muted.opacity(0.7)).accessibilityHidden(true)
        }.frame(minHeight: 44).contentShape(Rectangle())
    }
}

private struct MARCDeveloperList: View {
    let monitor: SSHMonitor
    let kind: String
    let connection: UUID
    @State private var feed = MARCDeveloperFeed()
    @State private var search = ""
    @State private var visible = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    private var active: Bool { visible && scenePhase == .active && monitor.connected && monitor.statisticsConnectionID == connection }
    private var services: [MARCListeningService] {
        feed.services.filter { search.isEmpty || "\($0.name) \($0.pid) \($0.endpoint)".localizedCaseInsensitiveContains(search) }
    }
    private var containers: [MARCDeveloperContainer] {
        feed.containers.filter { search.isEmpty || "\($0.name) \($0.image) \($0.state)".localizedCaseInsensitiveContains(search) }
    }
    private var managed: [MARCManagedService] {
        feed.managed.filter { search.isEmpty || "\($0.name) \(marcServiceState($0.state))".localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text(monitor.server?.name ?? "Mac").font(.system(size: 12)).foregroundStyle(p.muted)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.bottom, 16)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(p.muted)
                    TextField(kind == "services" ? "Search process or port" : "Search containers", text: $search)
                        .font(.system(size: 13)).textInputAutocapitalization(.never).autocorrectionDisabled()
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(p.muted) }
                            .accessibilityLabel("Clear search").frame(minWidth: 44, minHeight: 44)
                    }
                }.padding(.horizontal, 12).frame(minHeight: 44).background(p.raised, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 20)
                if feed.loading { ProgressView().frame(maxWidth: .infinity).padding(20) }
                else if let message = feed.message { statusText(message, p) }
                else if kind == "services" {
                    heading("Listening ports · \(services.count)", p)
                    ForEach(services) { service in
                        NavigationLink { MARCServiceDetails(service: service, monitor: monitor, connection: connection) } label: { MARCServiceRow(service: service) }
                            .buttonStyle(.plain).padding(.vertical, 5)
                        rule(p)
                    }
                    if let message = feed.portsMessage { statusText(message, p) }
                    else if services.isEmpty { statusText(search.isEmpty ? "No listening ports found." : "No matches.", p) }
                    heading("Background services", p).padding(.top, 24)
                    if let message = feed.managedMessage { statusText(message, p) }
                    else if managed.isEmpty { statusText(search.isEmpty ? "No Homebrew services found." : "No matches.", p) }
                    ForEach(managed) { service in
                        NavigationLink {
                            MARCManagedDetails(monitor: monitor, kind: "services", identifier: service.name,
                                               name: service.name, connection: connection)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "gearshape").foregroundStyle(p.muted).accessibilityHidden(true)
                                Text(service.name).font(.system(size: 13)).foregroundStyle(p.text)
                                Spacer()
                                Text(marcServiceState(service.state)).font(.system(size: 11)).foregroundStyle(p.muted)
                                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(p.muted)
                            }.frame(minHeight: 44).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                        rule(p)
                    }
                } else {
                    heading("Containers · \(containers.count)", p)
                    ForEach(containers) { container in
                        NavigationLink {
                            MARCManagedDetails(monitor: monitor, kind: "docker", identifier: container.id,
                                               name: container.name, connection: connection)
                        } label: { MARCContainerRow(container: container) }.buttonStyle(.plain).padding(.vertical, 5)
                        rule(p)
                    }
                    if containers.isEmpty { statusText(search.isEmpty ? "No containers found." : "No matches.", p) }
                }
                if feed.truncated { statusText("List shortened. Some entries are not shown.", p) }
            }.padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
        }.scrollIndicators(.hidden).marcCanvas().marcNavigationTitle(kind == "services" ? "Services" : "Docker")
            .onAppear { visible = true }.onDisappear { visible = false }
            .task(id: active) {
                guard active else { return }
                await feed.poll(monitor: monitor, tab: kind, connection: connection)
            }
            .onChange(of: monitor.statisticsConnectionID) { _, _ in dismiss() }
            .onChange(of: monitor.connected) { _, connected in if !connected { dismiss() } }
    }
    private func heading(_ text: String, _ p: MARCPalette) -> some View {
        Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(p.muted).padding(.bottom, 8)
    }
    private func statusText(_ text: String, _ p: MARCPalette) -> some View {
        Text(text).font(.system(size: 12)).foregroundStyle(p.muted).padding(.vertical, 12)
    }
    private func rule(_ p: MARCPalette) -> some View { Rectangle().fill(p.muted.opacity(0.13)).frame(height: 0.5) }
}

private struct MARCServiceDetails: View {
    let service: MARCListeningService
    let monitor: SSHMonitor
    let connection: UUID
    @State private var visible = false
    @State private var busy = false
    @State private var requested = false
    @State private var confirming = false
    @State private var work: Task<Void, Never>?
    @State private var feedback: String?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var active: Bool { visible && scenePhase == .active && monitor.connected && monitor.statisticsConnectionID == connection }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Listening port").font(.system(size: 12)).foregroundStyle(p.muted)
                VStack(spacing: 0) {
                    MARCDeveloperDetailRow(label: "Process", value: service.name)
                    MARCDeveloperDetailRow(label: "PID", value: String(service.pid))
                    MARCDeveloperDetailRow(label: "Protocol", value: "TCP")
                    MARCDeveloperDetailRow(label: "Address", value: service.address)
                    MARCDeveloperDetailRow(label: "Port", value: String(service.port), last: true)
                }.padding(.horizontal, 16).background(p.surface, in: RoundedRectangle(cornerRadius: 14))
                Text(service.addressExplanation).font(.system(size: 12)).foregroundStyle(p.muted)
                if service.canStop {
                    Button { confirming = true } label: {
                        HStack {
                            if busy { ProgressView() }
                            Text(busy ? "Stopping…" : "Stop process")
                        }.font(.system(size: 14, weight: .medium)).frame(maxWidth: .infinity, minHeight: 46)
                            .foregroundStyle(.red).background(p.surface, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain).disabled(!active || busy || requested)
                    Text("Stops this process and closes all its ports. A background service may restart it.")
                        .font(.system(size: 12)).foregroundStyle(p.muted)
                } else {
                    Text("Stop is unavailable for this process.").font(.system(size: 12)).foregroundStyle(p.muted)
                }
                if let feedback { Text(feedback).font(.system(size: 12)).foregroundStyle(p.text) }
            }.padding(16)
        }.marcCanvas().marcNavigationTitle(service.name).textSelection(.enabled)
            .confirmationDialog("Stop \(service.name)?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Stop process", role: .destructive, action: stop)
                Button("Cancel", role: .cancel) {}
            } message: { Text("On \(monitor.server?.name ?? "this Mac"). This closes every port owned by this process.") }
            .onChange(of: scenePhase) { _, phase in if phase != .active { confirming = false; cancel() } }
            .onChange(of: monitor.statisticsConnectionID) { _, _ in cancel(); dismiss() }
            .onChange(of: monitor.connected) { _, connected in if !connected { cancel(); dismiss() } }
            .onAppear { visible = true }
            .onDisappear { visible = false; confirming = false; cancel() }
    }
    private func stop() {
        guard active, !busy, !requested, service.canStop, let identity = service.identity else { return }
        busy = true; feedback = nil
        work = Task {
            do {
                try Task.checkCancellation()
                guard active else { throw CancellationError() }
                let reply = try await monitor.marcDeveloperRequest(action: "portStop", target: String(service.port),
                    expectedState: service.address, identity: identity, expectedConnection: connection)
                try Task.checkCancellation()
                guard active else { return }
                feedback = reply.message ?? reply.feedback ?? "Check the port list for the current state."
                requested = reply.message == nil
            } catch {
                guard !Task.isCancelled, active else { return }
                feedback = "Could not confirm the result. Check the port list."
            }
            guard !Task.isCancelled else { return }
            busy = false; work = nil
        }
    }
    private func cancel() {
        work?.cancel(); work = nil
        if busy { requested = true; feedback = "Check the port list for the current state." }
        busy = false
    }
}
private struct MARCDeveloperDetailRow: View {
    let label: String
    let value: String
    var last = false
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(label).foregroundStyle(p.muted)
                Spacer(minLength: 4)
                Text(value).foregroundStyle(p.text).multilineTextAlignment(.trailing)
            }.font(.system(size: 13)).padding(.vertical, 15)
            if !last { Rectangle().fill(p.muted.opacity(0.13)).frame(height: 0.5) }
        }
    }
}

private struct MARCDeveloperOperation {
    let action: String
    let target: String
    let state: String
    let host: String?
}
private struct MARCManagedDetails: View {
    let monitor: SSHMonitor
    let kind: String
    let identifier: String
    let name: String
    let connection: UUID
    @State private var feed = MARCDeveloperFeed()
    @State private var visible = false
    @State private var busy = false
    @State private var work: Task<Void, Never>?
    @State private var pending: MARCDeveloperOperation?
    @State private var feedback: String?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    private var active: Bool { visible && scenePhase == .active && monitor.connected && monitor.statisticsConnectionID == connection }
    private var container: MARCDeveloperContainer? { feed.containers.first { $0.id == identifier } }
    private var service: MARCManagedService? { feed.managed.first { $0.id == identifier } }
    private var state: String? { kind == "docker" ? container?.state : service?.state }
    private var canStart: Bool { kind == "docker" ? ["created", "exited"].contains(state ?? "") : ["none", "stopped"].contains(state ?? "") }
    private var canStop: Bool { kind == "docker" ? state == "running" : state == "started" }
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(kind == "docker" ? "Container" : "Homebrew service").font(.system(size: 12)).foregroundStyle(p.muted)
                if feed.loading { ProgressView().frame(maxWidth: .infinity).padding() }
                else if let message = feed.message ?? feed.managedMessage { Text(message).font(.system(size: 12)).foregroundStyle(p.muted) }
                else if let state {
                    VStack(spacing: 0) {
                        MARCDeveloperDetailRow(label: "Name", value: name)
                        MARCDeveloperDetailRow(label: "State", value: marcServiceState(state), last: kind != "docker")
                        if let container {
                            MARCDeveloperDetailRow(label: "Image", value: container.image)
                            MARCDeveloperDetailRow(label: "Status", value: container.status, last: true)
                        }
                    }.padding(.horizontal, 16).background(p.surface, in: RoundedRectangle(cornerRadius: 14))
                    if canStart || canStop {
                        Button {
                            guard active, !busy else { return }
                            let operation = MARCDeveloperOperation(action: (kind == "docker" ? "docker" : "service") + (canStop ? "Stop" : "Start"),
                                target: identifier, state: state, host: container?.host)
                            if canStop { pending = operation } else { perform(operation) }
                        } label: {
                            HStack {
                                if busy { ProgressView() }
                                Text(busy ? "Please wait…" : (canStop ? "Stop" : "Start"))
                            }.font(.system(size: 14, weight: .medium)).frame(maxWidth: .infinity, minHeight: 46)
                                .foregroundStyle(canStop ? Color.red : p.accent)
                                .background(p.surface, in: RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain).disabled(busy || !active || feed.loading)
                    }
                } else { Text("Not found. Go back and try again.").font(.system(size: 12)).foregroundStyle(p.muted) }
                if let feedback { Text(feedback).font(.system(size: 12)).foregroundStyle(p.text) }
            }.padding(16)
        }.marcCanvas().marcNavigationTitle(name)
            .confirmationDialog("Stop \(name)?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }), titleVisibility: .visible) {
                if let operation = pending {
                    Button("Stop", role: .destructive) { pending = nil; perform(operation) }
                }
                Button("Cancel", role: .cancel) { pending = nil }
            } message: { Text("On \(monitor.server?.name ?? "this Mac"). Active work may be interrupted.") }
            .onAppear { visible = true }
            .onDisappear { visible = false; cancelAction() }
            .task(id: "\(active)|\(busy)") {
                guard active, !busy else { return }
                await feed.poll(monitor: monitor, tab: kind, connection: connection)
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active { pending = nil; cancelAction() } }
            .onChange(of: monitor.statisticsConnectionID) { _, _ in cancelAction(); dismiss() }
            .onChange(of: monitor.connected) { _, connected in if !connected { cancelAction(); dismiss() } }
    }
    private func perform(_ operation: MARCDeveloperOperation) {
        guard active, !busy else { return }
        guard state == operation.state else { feedback = "State changed. Check the current state."; return }
        busy = true; feedback = nil
        work = Task {
            do {
                try Task.checkCancellation()
                guard active else { throw CancellationError() }
                let reply = try await monitor.marcDeveloperRequest(action: operation.action, target: operation.target,
                    expectedState: operation.state, expectedHost: operation.host, expectedConnection: connection)
                try Task.checkCancellation()
                guard active else { return }
                feedback = reply.message ?? reply.feedback ?? "Refresh to check the current state."
            } catch {
                guard !Task.isCancelled, active else { return }
                feedback = "Could not confirm the result. Refresh to check the current state."
            }
            guard !Task.isCancelled else { return }
            busy = false; work = nil
        }
    }
    private func cancelAction() {
        work?.cancel(); work = nil
        if busy { feedback = "Refresh to check the current state." }
        busy = false
    }
}

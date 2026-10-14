import Foundation
import Observation

@MainActor
@Observable
final class BonjourDiscoveryService: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private(set) var devices: [NearbyMac] = []
    private(set) var isSearching = false
    private(set) var failure: String?

    @ObservationIgnored private var scanTimeout: Task<Void, Never>?
    @ObservationIgnored private var browser: NetServiceBrowser?
    @ObservationIgnored private var services: [String: NetService] = [:]
    @ObservationIgnored private var index = NearbyMacIndex()

    func start() {
        guard browser == nil else { return }
        failure = nil
        index.removeAll()
        devices.removeAll()
        let next = NetServiceBrowser()
        browser = next
        next.delegate = self
        isSearching = true
        next.searchForServices(ofType: "_ssh._tcp.", inDomain: "local.")
        scanTimeout = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(10)) } catch { return }
            self?.stop()
        }
    }

    func stop(clearResults: Bool = false) {
        scanTimeout?.cancel()
        scanTimeout = nil
        // Detach before stopping: late callbacks from a previous scan are ignored.
        let previous = browser
        browser = nil
        previous?.delegate = nil
        previous?.stop()
        for service in services.values {
            service.delegate = nil
            service.stop()
        }
        services.removeAll()
        if clearResults {
            index.removeAll()
            devices.removeAll()
        }
        isSearching = false
    }

    private func key(_ service: NetService) -> String {
        // Length-prefix fields to avoid delimiter collisions in service names.
        [service.name, service.domain.lowercased(), service.type.lowercased()]
            .map { "\($0.utf8.count):\($0)" }.joined()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard browser === self.browser else { return }
        let id = key(service)
        guard services[id] == nil else { return }
        services[id] = service
        service.delegate = self
        service.resolve(withTimeout: 5)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        let id = key(sender)
        guard isSearching, services[id] === sender, let host = sender.hostName else { return }
        index.resolve(serviceID: id, name: sender.name, host: host, port: sender.port)
        devices = index.devices
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        let id = key(sender)
        guard services[id] === sender else { return }
        sender.delegate = nil
        sender.stop()
        services.removeValue(forKey: id)
        index.remove(serviceID: id)
        devices = index.devices
        failure = "A nearby SSH service could not be resolved. Try scanning again."
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        guard browser === self.browser else { return }
        let id = key(service)
        let removed = services.removeValue(forKey: id)
        removed?.delegate = nil
        removed?.stop()
        index.remove(serviceID: id)
        devices = index.devices
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        guard browser === self.browser else { return }
        stop()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        guard browser === self.browser else { return }
        stop()
        failure = "Nearby discovery is unavailable. Check Local Network permission and Wi-Fi, then scan again. You can also enter a host manually."
    }
}

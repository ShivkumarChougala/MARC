import Foundation

struct NearbyMac: Identifiable, Equatable {
    let id: String
    let name: String
    let host: String
    let port: Int
}

/// Keep each advertisement so removing an alias cannot hide a live endpoint.
struct NearbyMacIndex {
    private var advertisements: [String: NearbyMac] = [:]

    mutating func resolve(serviceID: String, name: String, host: String, port: Int) {
        let host = host.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()
        guard !host.isEmpty, (1...65535).contains(port) else { return }
        advertisements[serviceID] = NearbyMac(
            id: "\(host):\(port)", name: name, host: host, port: port
        )
    }

    mutating func remove(serviceID: String) {
        advertisements.removeValue(forKey: serviceID)
    }

    mutating func removeAll() { advertisements.removeAll() }

    var devices: [NearbyMac] {
        var endpoints: [String: NearbyMac] = [:]
        for key in advertisements.keys.sorted() {
            guard let device = advertisements[key] else { continue }
            if endpoints[device.id] == nil { endpoints[device.id] = device }
        }
        return endpoints.values.sorted {
            let comparison = $0.name.localizedCaseInsensitiveCompare($1.name)
            return comparison == .orderedSame ? $0.id < $1.id : comparison == .orderedAscending
        }
    }
}

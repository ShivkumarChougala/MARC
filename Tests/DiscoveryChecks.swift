import Foundation

@main
struct DiscoveryChecks {
    static func main() throws {
        var index = NearbyMacIndex()
        index.resolve(serviceID: "a", name: "Mac", host: "MAC.local.", port: 22)
        index.resolve(serviceID: "a", name: "Mac", host: "mac.local", port: 22)
        precondition(index.devices.count == 1, "Repeated callbacks must not duplicate rows")
        index.resolve(serviceID: "b", name: "Mac alias", host: "mac.LOCAL.", port: 22)
        precondition(index.devices.count == 1, "Advertisements for one endpoint must merge")
        let stableID = index.devices[0].id
        index.remove(serviceID: "a")
        precondition(index.devices.count == 1 && index.devices[0].id == stableID,
                     "Removing one alias must preserve the live endpoint and stable row ID")
        index.resolve(serviceID: "c", name: "Other port", host: "mac.local", port: 2222)
        precondition(index.devices.count == 2, "Different SSH ports must remain distinct")
        index.remove(serviceID: "b")
        precondition(index.devices.count == 1 && index.devices[0].port == 2222)
        index.remove(serviceID: "c")
        precondition(index.devices.isEmpty, "Last removal must remove the endpoint")
        index.resolve(serviceID: "bad", name: "Invalid", host: "", port: 22)
        index.resolve(serviceID: "bad2", name: "Invalid", host: "mac.local", port: 65536)
        precondition(index.devices.isEmpty, "Invalid endpoints must not appear")
        index.resolve(serviceID: "a", name: "Mac", host: "mac.local", port: 22)
        index.resolve(serviceID: "a", name: "Mac", host: "new.local", port: 22)
        precondition(index.devices.count == 1 && index.devices[0].host == "new.local")
        index.removeAll()
        precondition(index.devices.isEmpty, "Stopping must clear stale devices")

        let legacy = Data("""
        {"id":"00112233-4455-6677-8899-AABBCCDDEEFF","name":"Saved Mac","host":"mac.local","port":22,"username":"user"}
        """.utf8)
        let decoder = JSONDecoder()
        var profile = try decoder.decode(ServerProfile.self, from: legacy)
        precondition(profile.requiresHostKey == nil, "Legacy profiles must still decode")
        let originalID = profile.id
        profile.requiresHostKey = true
        let restored = try decoder.decode(ServerProfile.self, from: JSONEncoder().encode(profile))
        precondition(restored.requiresHostKey == true && restored.id == originalID,
                     "Discovery trust requirement and identity must survive persistence")
        precondition(HostKeyIdentity.endpoint(host: " Mac.LOCAL. ", port: 22) == "mac.local:22")
        precondition(HostKeyIdentity.endpoint(host: "Mac.local", port: 2222) != "mac.local:22")
        let fingerprint = try HostKeyIdentity.fingerprint(publicKey: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
        precondition(fingerprint == "SHA256:kmYcvdi2GkPeWxB6XLjrZB8JHsy2Hm8luHMFp9GMvqk", "Fingerprint must hash the full SSH wire key blob")
        do {
            _ = try HostKeyIdentity.fingerprint(publicKey: "invalid")
            preconditionFailure("Malformed keys must not have a fingerprint")
        } catch { }
        precondition(HostKeyIdentity.matches(output: "256 \(fingerprint) Mac (ED25519)", fingerprint: fingerprint))
        precondition(HostKeyIdentity.matches(output: "  \(fingerprint)\n", fingerprint: fingerprint))
        precondition(!HostKeyIdentity.matches(output: fingerprint + "wrong", fingerprint: fingerprint))
        precondition(!HostKeyIdentity.matches(output: "", fingerprint: fingerprint))
        print("PASS: endpoint identity and OpenSSH SHA256 fingerprint fixtures")
        print("PASS: discovery deduplication, alias removal, ports, invalid endpoints, updates, clearing, and profile compatibility")
    }
}

import Foundation

struct ServerProfile: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var host: String
    var port: Int
    var username: String
    // Optional so existing saved profiles continue to decode unchanged.
    var requiresHostKey: Bool? = nil
}

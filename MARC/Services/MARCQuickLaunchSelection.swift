import Foundation

enum MARCQuickLaunchSelection {
    // Match the bounded discovery catalogue without restricting the row to six apps.
    static let maximumCount = 200
    static let defaults = [
        MARCLaunchApplication(id: "com.apple.Safari", title: "Safari"),
        MARCLaunchApplication(id: "com.apple.Terminal", title: "Terminal"),
        MARCLaunchApplication(id: "com.apple.Music", title: "Music")
    ]
    static func cleaned(_ apps: [MARCLaunchApplication]) -> [MARCLaunchApplication] {
        var seen = Set<String>()
        var result: [MARCLaunchApplication] = []
        for app in apps {
            guard MARCLaunchApplication.validID(app.id), !app.title.isEmpty,
                  app.title.count <= 96, seen.insert(app.id).inserted else { continue }
            result.append(app)
            if result.count == maximumCount { break }
        }
        return result
    }
    static func read(_ storage: String, mac: String) -> [MARCLaunchApplication] {
        guard let data = storage.data(using: .utf8),
              let saved = try? JSONDecoder().decode([String: [MARCLaunchApplication]].self, from: data),
              let apps = saved[mac] else { return defaults }
        return cleaned(apps)
    }
    static func write(_ apps: [MARCLaunchApplication], mac: String, storage: String) -> String {
        guard !mac.isEmpty else { return storage }
        var saved = storage.data(using: .utf8).flatMap {
            try? JSONDecoder().decode([String: [MARCLaunchApplication]].self, from: $0)
        } ?? [:]
        saved[mac] = cleaned(apps)
        guard let data = try? JSONEncoder().encode(saved), let result = String(data: data, encoding: .utf8)
        else { return storage }
        return result
    }
}

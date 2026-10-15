import Foundation

struct MARCProcessTarget: Identifiable {
    let id = UUID()
    let process: MARCProcess
    let connection: UUID
}

enum MARCProcessRows {
    static func visible(_ rows: [MARCProcess], query: String, sorting: String,
                        frozenOrder: [String] = []) -> [MARCProcess] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen = Set<String>()
        let candidates = rows.filter {
            guard $0.pid > 0, $0.cpu.isFinite, $0.memory.isFinite,
                  $0.cpu >= 0, $0.memory >= 0, seen.insert($0.id).inserted else { return false }
            return search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) ||
                $0.user.localizedCaseInsensitiveContains(search) || String($0.pid).contains(search)
        }
        let sorted = candidates.sorted {
            switch sorting {
            case "Memory":
                if $0.memory != $1.memory { return $0.memory > $1.memory }
            case "Name":
                let order = $0.name.localizedCaseInsensitiveCompare($1.name)
                if order != .orderedSame { return order == .orderedAscending }
            default:
                if $0.cpu != $1.cpu { return $0.cpu > $1.cpu }
            }
            return $0.pid == $1.pid ? $0.id < $1.id : $0.pid < $1.pid
        }
        let limit = search.isEmpty ? 50 : sorted.count
        guard !frozenOrder.isEmpty else { return Array(sorted.prefix(limit)) }
        let indexed = Dictionary(uniqueKeysWithValues: sorted.map { ($0.id, $0) })
        var used = Set<String>()
        let stable = frozenOrder.compactMap { id -> MARCProcess? in
            guard used.insert(id).inserted else { return nil }
            return indexed[id]
        }
        return Array((stable + sorted.filter { !used.contains($0.id) }).prefix(limit))
    }

    static func memoryBytes(_ value: Double) -> Int64 {
        guard value.isFinite, value > 0 else { return 0 }
        if value >= Double(Int64.max) { return Int64.max }
        return Int64(value)
    }
}

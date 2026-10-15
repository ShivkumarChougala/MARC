import Foundation

enum MARCFileFormatting {
    static func permissions(_ mode: UInt32?) -> String {
        guard let mode else { return "Permissions unavailable" }
        let kind: String
        switch mode & 0xF000 {
        case 0x4000: kind = "d"
        case 0xA000: kind = "l"
        case 0x8000: kind = "-"
        default: kind = "?"
        }
        var characters = Array(kind)
        for shift in [6, 3, 0] {
            characters.append(mode & (UInt32(4) << shift) != 0 ? "r" : "-")
            characters.append(mode & (UInt32(2) << shift) != 0 ? "w" : "-")
            characters.append(mode & (UInt32(1) << shift) != 0 ? "x" : "-")
        }
        if mode & 0o4000 != 0 { characters[3] = mode & 0o100 != 0 ? "s" : "S" }
        if mode & 0o2000 != 0 { characters[6] = mode & 0o010 != 0 ? "s" : "S" }
        if mode & 0o1000 != 0 { characters[9] = mode & 0o001 != 0 ? "t" : "T" }
        return String(characters)
    }

    static func shellDirectoryCommand(_ path: String) -> String? {
        guard path.hasPrefix("/"), !path.unicodeScalars.contains(where: {
            $0.value < 32 || $0.value == 127 || (0x80...0x9f).contains($0.value) ||
            $0.value == 0x2028 || $0.value == 0x2029
        }) else { return nil }
        return "cd -- '" + path.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}

enum MARCTerminalInput {
    static func modified(_ bytes: [UInt8], control: Bool, alt: Bool) -> [UInt8] {
        guard !bytes.isEmpty else { return [] }
        var output = bytes
        if control, bytes.count == 1, let byte = bytes.first, (32...126).contains(byte) {
            output = [byte & 0x1f]
        }
        if alt { output.insert(27, at: 0) }
        return output
    }
}

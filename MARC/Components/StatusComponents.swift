import SwiftUI

enum StatusFormat {
    static func speed(_ bytes: Double?) -> String {
        guard let bytes else { return "—" }
        if bytes >= 1_048_576 { return String(format: "%.2f MB/s", bytes / 1_048_576) }
        return String(format: "%.0f KB/s", bytes / 1024)
    }
}

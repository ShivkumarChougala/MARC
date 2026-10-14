import SwiftUI

struct MARCConnectionNotice: View {
    let message: String
    @Environment(\.colorScheme) private var scheme

    private var parts: [Substring] {
        message.split(separator: "\n", maxSplits: 1)
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 8) {
            Text(parts.count > 1
                 ? String(parts[0]) : "Connection needs attention")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(p.text)
            Text(parts.count > 1 ? String(parts[1]) : message)
                .font(.system(size: 12)).foregroundStyle(p.muted)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

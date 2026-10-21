import SwiftUI

struct MARCSettingsSupportRow: View {
    let title: String
    let icon: String
    var external = true
    var detail: String? = nil
    var enabled = true
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        HStack(spacing: 12) {
            MARCSettingsRowIcon(symbol: icon, enabled: enabled)
            Text(title).font(.subheadline)
                .foregroundStyle(enabled ? p.text : p.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            if let detail {
                Text(detail).font(.caption).foregroundStyle(p.muted)
            } else {
                Image(systemName: external ? "arrow.up.right" : "chevron.right")
                    .font(.system(size: 11)).foregroundStyle(p.muted)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 50)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct MARCSettingsRowIcon: View {
    let symbol: String
    var enabled = true
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        let selected = MARCAccentColor(rawValue: accent) ?? .defaultColor
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(enabled ? selected.color(dark: scheme == .dark) : p.muted)
            .frame(width: 22)
            .accessibilityHidden(true)
    }
}

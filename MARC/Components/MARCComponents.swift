import SwiftUI
struct MARCSettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(p.muted).padding(.horizontal, 14)
            VStack(spacing: 0) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(p.surface, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
struct MARCSettingsDivider: View {
    var body: some View { Divider().padding(.horizontal, 14) }
}

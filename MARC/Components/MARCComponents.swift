import SwiftUI
struct MARCCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 18) {
            if !title.isEmpty { Text(title).font(.system(size: 15, weight: .semibold)) }
            content
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(p.border, lineWidth: 1))
    }
}
struct MARCSettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
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
struct MARCSettingsAction: View {
    let title: String
    var symbol = "chevron.right"
    var body: some View {
        HStack {
            Text(title).font(.system(size: 15))
            Spacer()
            Image(systemName: symbol).font(.system(size: 12)).foregroundStyle(.secondary)
        }.padding(.horizontal, 14).frame(minHeight: 50).contentShape(Rectangle())
    }
}

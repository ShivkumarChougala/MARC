import SwiftUI

/// A small local hint, retained only until the user dismisses it.
struct MARCFirstUseTip: View {
    let message: String
    @AppStorage private var dismissed: Bool
    @Environment(\.marcGuidedTour) private var tour
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue

    init(key: String, message: String) {
        self.message = message
        _dismissed = AppStorage(wrappedValue: false, "marc.tip.v1." + key)
    }

    var body: some View {
        if !dismissed && tour?.active != true {
            let p = MARCPalette(dark: scheme == .dark)
            HStack(alignment: .top, spacing: 10) {
                Text(message).font(.caption).foregroundStyle(p.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Got it") { dismissed = true }.font(.caption.weight(.medium))
                    .frame(minWidth: 44, minHeight: 44).tint(p.accent)
            }.padding(10)
                .background(p.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

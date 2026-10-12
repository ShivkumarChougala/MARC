import SwiftUI
extension Color {
    init(marcHex: UInt32) {
        self.init(.sRGB, red: Double((marcHex >> 16) & 255)/255,
                  green: Double((marcHex >> 8) & 255)/255, blue: Double(marcHex & 255)/255, opacity: 1)
    }
}
struct MARCPalette {
    let dark: Bool
    var background: Color { Color(marcHex: dark ? 0x111113 : 0xf5f5f7) }
    var surface: Color { Color(marcHex: dark ? 0x1c1c1f : 0xffffff) }
    var raised: Color { Color(marcHex: dark ? 0x28282c : 0xf0f0f4) }
    var border: Color { Color(marcHex: dark ? 0x343438 : 0xe6e6eb) }
    var text: Color { Color(marcHex: dark ? 0xeeeef1 : 0x202124) }
    var muted: Color { Color(marcHex: dark ? 0xa0a0aa : 0x898a92) }
    var accent: Color {
        let choice = UserDefaults.standard.string(forKey: "marc.accent") ?? "coral"
        return (MARCAccentColor(rawValue: choice) ?? .coral).color(dark: dark)
    }
}
extension View {
    func marcCanvas() -> some View {
        modifier(MARCCanvas())
    }
}
private struct MARCCanvas: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    func body(content: Content) -> some View {
        let p = MARCPalette(dark: scheme == .dark)
        content.foregroundStyle(p.text).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(p.background.ignoresSafeArea()).tint(p.accent)
    }
}


enum MARCAccentColor: String, CaseIterable, Identifiable {
    case coral, blue, purple, green, amber

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    func color(dark: Bool) -> Color {
        let hex: UInt32
        switch self {
        case .coral:
            hex = dark ? 0xff7379 : 0xc94350
        case .blue:
            hex = dark ? 0x60a5fa : 0x2563eb
        case .purple:
            hex = dark ? 0xa78bfa : 0x7c3aed
        case .green:
            hex = dark ? 0x4ade80 : 0x15803d
        case .amber:
            hex = dark ? 0xfbbf24 : 0xb45309
        }
        return Color(marcHex: hex)
    }
}

struct MARCAccentPicker: View {
    @AppStorage("marc.accent") private var selection = "coral"
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    var body: some View {
        let dark = scheme == .dark
        let p = MARCPalette(dark: dark)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accent colour")
                    .font(.system(size: 15))
                Spacer()
                Text((MARCAccentColor(rawValue: selection) ?? .coral).title)
                    .font(.system(size: 12))
                    .foregroundStyle(p.muted)
            }

            HStack(spacing: 0) {
                ForEach(MARCAccentColor.allCases) { colour in
                    Button {
                        selection = colour.rawValue
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(colour.color(dark: dark))
                                    .frame(width: 28, height: 28)

                                if selection == colour.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(dark ? Color.black : Color.white)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .overlay {
                                Circle()
                                    .stroke(
                                        selection == colour.rawValue
                                            ? colour.color(dark: dark)
                                            : Color.clear,
                                        lineWidth: 1.5
                                    )
                            }

                            Text(colour.title)
                                .font(.system(size: 9))
                                .foregroundStyle(p.muted)
                        }
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(colour.title + " accent")
                    .accessibilityAddTraits(
                        selection == colour.rawValue ? .isSelected : []
                    )
                }
            }
        }
        .foregroundStyle(p.text)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

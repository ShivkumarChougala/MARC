import SwiftUI
import UIKit
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
        let choice = UserDefaults.standard.string(forKey: "marc.accent") ?? MARCAccentColor.defaultColor.rawValue
        return (MARCAccentColor(rawValue: choice) ?? .defaultColor).color(dark: dark)
    }
}
extension View {
    func marcCanvas() -> some View {
        modifier(MARCCanvas())
    }
}
private struct MARCCanvas: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = MARCAccentColor.defaultColor.rawValue
    func body(content: Content) -> some View {
        let p = MARCPalette(dark: scheme == .dark)
        let selected = MARCAccentColor(rawValue: marcAccentPreference) ?? .defaultColor
        content.foregroundStyle(p.text).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(p.background.ignoresSafeArea()).tint(selected.color(dark: scheme == .dark))
    }
}


enum MARCAccentColor: String, CaseIterable, Identifiable {
    case coral, blue, purple, green, amber
    static let defaultColor: Self = .green

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
    @AppStorage("marc.accent") private var selection = MARCAccentColor.defaultColor.rawValue
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        let p = MARCPalette(dark: dark)

        let selected = MARCAccentColor(rawValue: selection) ?? .defaultColor
        Menu {
            Picker("Accent colour", selection: $selection) {
                ForEach(MARCAccentColor.allCases) { colour in
                    Label {
                        Text(colour.title)
                    } icon: {
                        menuSwatch(colour, dark: dark)
                    }
                    .tag(colour.rawValue)
                }
            }
        } label: {
            HStack(spacing: 12) {
                MARCSettingsRowIcon(symbol: "paintpalette")
                Text("Accent colour").foregroundStyle(p.text)
                Spacer(minLength: 8)
                Circle().fill(selected.color(dark: dark)).frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(selected.title).foregroundStyle(p.muted)
                Image(systemName: "chevron.right").font(.system(size: 11))
                    .foregroundStyle(p.muted).accessibilityHidden(true)
            }
            .font(.system(size: 15))
            .padding(.horizontal, 14).frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Accent colour")
        .accessibilityValue(selected.title)
        .accessibilityHint("Choose a colour for MARC")
    }

    // Native menus accept image icons. Original rendering preserves each swatch
    // instead of tinting every option with the currently selected accent.
    private func menuSwatch(_ colour: MARCAccentColor, dark: Bool) -> Image {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16)).image { context in
            UIColor(colour.color(dark: dark)).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 2, y: 2, width: 12, height: 12))
        }
        return Image(uiImage: image.withRenderingMode(.alwaysOriginal))
    }
}

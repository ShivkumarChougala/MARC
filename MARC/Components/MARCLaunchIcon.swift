import SwiftUI

// Clear local symbols/initials; these are not downloaded Mac application artwork.
struct MARCLaunchIcon: View {
    let app: MARCLaunchApplication
    var size: CGFloat = 42

    private var color: Color {
        switch app.id {
        case "com.apple.Safari", "com.apple.finder", "com.apple.mail": return .blue
        case "com.apple.Terminal": return Color(white: 0.22)
        case "com.apple.Music": return .pink
        case "com.brave.Browser", "com.brave.Browser.beta", "com.brave.Browser.nightly": return .orange
        case "com.apple.Dictionary": return .brown
        case "com.apple.Notes": return .yellow.opacity(0.85)
        default: return .indigo
        }
    }

    var body: some View {
        Group {
            if app.symbol == "app" {
                Text(app.title.first(where: { !$0.isWhitespace }).map { String($0).uppercased() } ?? "?")
                    .font(.system(size: size * 0.50, weight: .semibold))
                    .lineLimit(1).minimumScaleFactor(0.6)
            } else {
                Image(systemName: app.symbol)
                    .font(.system(size: size * 0.48, weight: .medium))
            }
        }
        .foregroundStyle(.white)
        .frame(width: size, height: size)
        .background(color, in: RoundedRectangle(cornerRadius: size * 0.30, style: .continuous))
        .accessibilityHidden(true)
    }
}

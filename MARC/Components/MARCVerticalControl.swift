import SwiftUI

struct MARCVerticalControl: View {
    @Binding var value: Double
    let title: String
    let symbol: String
    let available: Bool
    let enabled: Bool
    let palette: MARCPalette
    let editing: (Bool) -> Void
    @State private var dragging = false

    var body: some View {
        VStack(spacing: 10) {
            MARCLiveNumberText(text: available ? "\(Int(value.rounded()))%" : "—",
                               value: available ? value : nil)
                .font(.system(size: 20, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(palette.text)

            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(palette.accent.opacity(0.08))

                    Rectangle()
                        .fill(palette.accent.opacity(0.8))
                        .frame(height: geometry.size.height *
                            (available ? min(100, max(0, value)) / 100 : 0))
                        .modifier(MARCLiveValueMotion(value: value, allowsMotion: !dragging))

                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(palette.text)
                        .padding(.bottom, 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .contentShape(RoundedRectangle(cornerRadius: 25))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            guard available && enabled else { return }
                            if !dragging {
                                dragging = true
                                editing(true)
                            }
                            value = min(100, max(0,
                                (1 - gesture.location.y /
                                 max(1, geometry.size.height)) * 100
                            )).rounded()
                        }
                        .onEnded { _ in
                            guard dragging else { return }
                            dragging = false
                            editing(false)
                        }
                )
            }
            .frame(width: 64, height: 112)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(
                available ? "\(Int(value.rounded())) percent" : "Unavailable"
            )
            .accessibilityAdjustableAction { direction in
                guard available && enabled else { return }
                editing(true)
                switch direction {
                case .increment: value = min(100, value + 5)
                case .decrement: value = max(0, value - 5)
                @unknown default: break
                }
                editing(false)
            }
            .opacity(available ? 1 : 0.4)
        }
        .frame(maxWidth: .infinity)
    }
}

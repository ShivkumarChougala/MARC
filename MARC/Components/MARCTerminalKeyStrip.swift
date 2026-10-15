import SwiftUI
import UIKit
@preconcurrency import SwiftTerm

struct MARCTerminalKeyStrip: View {
    let session: MARCTerminalSession
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var accent = "coral"

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        HStack(spacing: 6) {
            ScrollView(.horizontal) {
                HStack(spacing: 5) {
                    key("esc", accessibility: "Escape", bytes: [27], palette: p)
                    key("⇥", accessibility: "Tab", bytes: [9], palette: p)
                    Button {
                        session.controlArmed.toggle()
                        session.view?.becomeFirstResponder()
                    } label: {
                        Text("ctrl").font(.system(size: 13, weight: .medium))
                            .frame(minWidth: 44, minHeight: 44)
                            .background(session.controlArmed ? p.accent.opacity(0.2) : .clear,
                                        in: RoundedRectangle(cornerRadius: 10))
                    }.accessibilityLabel("Control modifier for next key")
                        .accessibilityValue(session.controlArmed ? "Selected" : "Off")
                    Button {
                        session.altArmed.toggle()
                        session.view?.becomeFirstResponder()
                    } label: {
                        Text("alt").font(.system(size: 13, weight: .medium))
                            .frame(minWidth: 44, minHeight: 44)
                            .background(session.altArmed ? p.accent.opacity(0.2) : .clear,
                                        in: RoundedRectangle(cornerRadius: 10))
                    }.accessibilityLabel("Alt modifier for next key")
                        .accessibilityValue(session.altArmed ? "Selected" : "Off")
                    key("^C", accessibility: "Control C, interrupt", bytes: [3], palette: p)
                    key("←", accessibility: "Left arrow", bytes: [27, 91, 68], palette: p)
                    key("↑", accessibility: "Up arrow", bytes: [27, 91, 65], palette: p)
                    key("↓", accessibility: "Down arrow", bytes: [27, 91, 66], palette: p)
                    key("→", accessibility: "Right arrow", bytes: [27, 91, 67], palette: p)
                    key("^D", accessibility: "Control D, end of input", bytes: [4], palette: p)
                    key("^Z", accessibility: "Control Z, suspend", bytes: [26], palette: p)
                }
            }
            .scrollIndicators(.hidden)
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipped()
            .disabled(!session.ready)
            Button {
                guard let view = session.view else { return }
                if view.isFirstResponder { view.resignFirstResponder() }
                else { view.becomeFirstResponder() }
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 20)).frame(width: 44, height: 44)
                    .background(p.raised, in: RoundedRectangle(cornerRadius: 12))
            }
            .fixedSize()
            .accessibilityLabel("Show or hide terminal keyboard")
        }
        .buttonStyle(.plain)
        .foregroundStyle(p.accent)
    }

    private func key(_ title: String, accessibility: String, bytes: [UInt8], palette p: MARCPalette) -> some View {
        Button {
            // Fixed escape/control sequences do not consume the armed modifiers.
            session.controlArmed = false
            session.altArmed = false
            session.send(bytes)
            session.view?.becomeFirstResponder()
        } label: {
            Text(title).font(.system(size: 15, weight: .medium, design: .monospaced))
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel(accessibility)
    }
}

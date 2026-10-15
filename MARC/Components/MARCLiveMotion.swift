import SwiftUI

// Scope animation to individual readings and shapes, keeping cards and rows still.
private struct MARCLiveMotionKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var marcLiveMotionEnabled: Bool {
        get { self[MARCLiveMotionKey.self] }
        set { self[MARCLiveMotionKey.self] = newValue }
    }
}

struct MARCLiveValueMotion<Value: Equatable>: ViewModifier {
    let value: Value
    var allowsMotion = true
    @Environment(\.marcLiveMotionEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var animate: Bool { allowsMotion && enabled && !reduceMotion && scenePhase == .active }

    func body(content: Content) -> some View {
        content
            .animation(animate ? .easeInOut(duration: 0.25) : nil, value: value)
            .transaction { transaction in
                if animate {
                    transaction.disablesAnimations = false
                } else {
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
            }
    }
}

struct MARCLiveNumberText: View {
    let text: String
    let value: Double?
    @Environment(\.marcLiveMotionEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var numericValue: Double? {
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }

    var body: some View {
        Text(text)
            .contentTransition(enabled && !reduceMotion && scenePhase == .active && numericValue != nil
                ? .numericText(value: numericValue ?? 0) : .identity)
            // Animate only when the displayed text changes, not for hidden decimals.
            .modifier(MARCLiveValueMotion(value: text, allowsMotion: numericValue != nil))
    }
}


private struct MARCLiveMotionScope: ViewModifier {
    let enabled: Bool
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .environment(\.marcLiveMotionEnabled, enabled && visible)
            .onAppear { visible = true }
            .onDisappear { visible = false }
    }
}

extension View {
    func marcLiveReadings(enabled: Bool) -> some View {
        modifier(MARCLiveMotionScope(enabled: enabled))
    }
}

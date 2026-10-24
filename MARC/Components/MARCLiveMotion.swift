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

    var body: some View {
        MARCRollingNumberText(text: text, value: value, enabled: enabled)
    }
}

// Roll changed digits using frame time while keeping rows and units still.
struct MARCRollingNumberText: View {
    let text: String
    let value: Double?
    let enabled: Bool
    @State private var shown: String
    @State private var outgoing: String
    @State private var previousValue: Double?
    @State private var startedAt: Date?
    @State private var revision = 0
    @State private var increasing = true
    @Environment(\.scenePhase) private var scenePhase

    init(text: String, value: Double?, enabled: Bool = true) {
        self.text = text
        self.value = value
        self.enabled = enabled
        _shown = State(initialValue: text)
        _outgoing = State(initialValue: text)
        _previousValue = State(initialValue: Self.valid(value))
    }

    private static func valid(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }

    // Keep the small digit roll available with Reduce Motion, as requested.
    // Larger chart and layout animations retain their accessibility policy.
    private var motion: Bool { enabled && scenePhase == .active }

    var body: some View {
        // Keep string tokenization outside the per-frame clock closure.
        let oldCharacters = Array(outgoing)
        let newCharacters = Array(shown)
        TimelineView(.animation(minimumInterval: 1.0 / 60.0,
                                paused: startedAt == nil || !motion)) { clock in
            let progress = startedAt.map {
                min(1, max(0, clock.date.timeIntervalSince($0) / 0.36))
            } ?? 1
            // Smoothstep eases the digit positions between readings.
            let eased = progress * progress * (3 - 2 * progress)
            MARCDigitRollFrame(oldCharacters: oldCharacters, newCharacters: newCharacters, phase: eased,
                               increasing: increasing, moving: motion)
                .transaction { transaction in
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
        }
            .monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .onChange(of: text) { _, nextText in
                let next = Self.valid(value)
                let animate = motion && previousValue != nil && next != nil
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) {
                    outgoing = shown
                    shown = nextText
                    increasing = (next ?? 0) >= (previousValue ?? 0)
                    previousValue = next
                    startedAt = animate ? .now : nil
                    revision &+= 1
                }
            }
            .task(id: revision) { @MainActor in
                guard startedAt != nil else { return }
                do { try await Task.sleep(for: .milliseconds(360)) }
                catch { return }
                guard !Task.isCancelled else { return }
                // Stop the display schedule at rest. A newer reading cancels
                // this task and replaces the target rather than queuing it.
                startedAt = nil
            }
    }
}

private struct MARCDigitRollFrame: View {
    let oldCharacters: [Character]
    let newCharacters: [Character]
    let phase: Double
    let increasing: Bool
    let moving: Bool

    var body: some View {
        let progress = moving ? min(1, max(0, phase)) : 1
        HStack(spacing: 0) {
            ForEach(newCharacters.indices, id: \.self) { index in
                let character = newCharacters[index]
                let oldIndex = index + oldCharacters.count - newCharacters.count
                let prior = oldCharacters.indices.contains(oldIndex) ? oldCharacters[oldIndex] : character
                if character.isNumber && prior.isNumber && character != prior {
                    Text(String(character)).hidden()
                        .overlay {
                            GeometryReader { geometry in
                                let direction: CGFloat = increasing ? 1 : -1
                                ZStack {
                                    Text(String(prior))
                                        .offset(y: -direction * geometry.size.height * progress)
                                        .opacity(1 - progress)
                                    Text(String(character))
                                        .offset(y: direction * geometry.size.height * (1 - progress))
                                        .opacity(progress)
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                        .clipped()
                } else {
                    Text(String(character))
                }
            }
        }
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

import SwiftUI
import UIKit

struct MARCCompactControl: View {
    @Binding var value: Double
    let title: String
    let available: Bool
    let enabled: Bool
    let palette: MARCPalette
    let editing: (Bool) -> Void
    let commit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title).font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.text)
                Spacer(minLength: 4)
                MARCLiveNumberText(text: available ? "\(Int(value.rounded()))%" : "—",
                                   value: available ? value : nil)
                    .font(.caption2.monospacedDigit().weight(.medium))
                    .foregroundStyle(available ? palette.accent : palette.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(palette.accent.opacity(available ? 0.08 : 0), in: Capsule())
                    .fixedSize()
            }
            MARCTrackingSlider(value: $value, enabled: available && enabled,
                               title: title, tint: UIColor(palette.accent),
                               editing: editing, commit: commit)
                .frame(height: 44)
                .opacity(available ? 1 : 0.35)
        }
    }
}

// Keep native touch tracking separate from animated readings and SwiftUI updates.
private struct MARCTrackingSlider: UIViewRepresentable {
    @Binding var value: Double
    let enabled: Bool
    let title: String
    let tint: UIColor
    let editing: (Bool) -> Void
    let commit: () -> Void

    func makeUIView(context: Context) -> MARCTouchSlider {
        let slider = MARCTouchSlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        let thumb = UIImage(systemName: "circle.fill",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular))?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        slider.setThumbImage(thumb, for: .normal)
        slider.setThumbImage(thumb, for: .highlighted)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        slider.started = { context.coordinator.parent.editing(true) }
        slider.finished = { committed in
            context.coordinator.parent.editing(false)
            if committed { context.coordinator.parent.commit() }
        }
        return slider
    }

    func updateUIView(_ slider: MARCTouchSlider, context: Context) {
        context.coordinator.parent = self
        slider.isEnabled = enabled
        slider.tintColor = tint
        slider.accessibilityLabel = title
        slider.accessibilityValue = enabled ? "\(Int(value.rounded())) percent" : "Unavailable"
        if !slider.isTracking { slider.setValue(Float(value), animated: false) }
    }

    static func dismantleUIView(_ slider: MARCTouchSlider, coordinator: Coordinator) {
        // The screen clears its editing flags on exit; teardown must never send a command.
        slider.started = nil
        slider.finished = nil
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject {
        var parent: MARCTrackingSlider
        init(_ parent: MARCTrackingSlider) { self.parent = parent }
        @objc func changed(_ slider: UISlider) {
            parent.value = Double(slider.value.rounded())
        }
    }
}

private final class MARCTouchSlider: UISlider {
    var started: (() -> Void)?
    var finished: ((Bool) -> Void)?
    private var editingTouch = false

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let accepted = super.beginTracking(touch, with: event)
        if accepted { editingTouch = true; started?() }
        return accepted
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        finish(committed: true)
    }

    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        finish(committed: false)
    }

    private func finish(committed: Bool) {
        guard editingTouch else { return }
        editingTouch = false
        finished?(committed)
    }

    override func accessibilityIncrement() { adjust(by: 5) }
    override func accessibilityDecrement() { adjust(by: -5) }
    private func adjust(by delta: Float) {
        guard isEnabled else { return }
        started?()
        value = min(maximumValue, max(minimumValue, value + delta))
        sendActions(for: .valueChanged)
        finished?(true)
    }
}

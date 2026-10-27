import Foundation
import CoreGraphics

/// Bounds the coach independently of the highlighted control.
struct MARCGuidePlacement {
    let card: CGRect
    let focus: CGRect?

    /// Hide guidance when it cannot fit without covering the target or nearby list.
    /// Unlike contextual feature hints, this never shrinks a caption's text.
    static func setupCaption(size: CGSize, target: CGRect, avoid: CGRect? = nil,
                             preferredHeight: CGFloat, accessibility: Bool = false, protected: [CGRect] = []) -> CGRect? {
        guard size.width.isFinite, size.height.isFinite, size.width > 32, size.height > 32,
              !target.isNull, !target.isInfinite, target.width > 0, target.height > 0,
              target.minX.isFinite, target.minY.isFinite,
              preferredHeight.isFinite, preferredHeight > 0 else { return nil }
        let viewport = CGRect(origin: .zero, size: size)
        guard viewport.contains(target) else { return nil }
        let width = min(accessibility ? 380 : 360, size.width - 32)
        let height = preferredHeight
        let x = min(max(16, target.midX - width / 2), size.width - width - 16)
        var positions = [target.maxY + 16, target.minY - height - 16]
        if let avoid, !avoid.isNull, !avoid.isInfinite {
            positions += [avoid.maxY + 16, avoid.minY - height - 16]
        }
        let protected = protected.filter { !$0.isNull && !$0.isInfinite }
        for region in protected { positions += [region.maxY + 16, region.minY - height - 16] }
        return positions.lazy.map { CGRect(x: x, y: $0, width: width, height: height) }.first { card in
            guard viewport.insetBy(dx: 8, dy: 8).contains(card),
                  !card.intersects(target.insetBy(dx: -8, dy: -8)) else { return false }
            if let avoid, card.intersects(avoid.insetBy(dx: -8, dy: -8)) { return false }
            return !protected.contains { card.intersects($0.insetBy(dx: -8, dy: -8)) }
        }
    }

    static func resolve(size: CGSize, target: CGRect?, preferredHeight: CGFloat) -> Self {
        let width = max(1, size.width.isFinite ? size.width : 1)
        let height = max(1, size.height.isFinite ? size.height : 1)
        let margin: CGFloat = min(16, min(width, height) / 8)
        let insetWidth: CGFloat = max(1, width - margin * 2)
        let insetHeight: CGFloat = max(1, height - margin * 2)
        let inset = CGRect(x: margin, y: margin, width: insetWidth, height: insetHeight)
        let cardWidth = min(380, inset.width)
        let desired = min(max(1, preferredHeight.isFinite ? preferredHeight : 244), inset.height)
        let cardX = (width - cardWidth) / 2
        guard let target, !target.isNull, !target.isInfinite,
              target.minX.isFinite, target.minY.isFinite, target.width.isFinite, target.height.isFinite else {
            return Self(card: CGRect(x: cardX, y: (height - desired) / 2, width: cardWidth, height: desired), focus: nil)
        }
        let visible = target.intersection(inset)
        guard !visible.isNull, visible.width > 1, visible.height > 1 else {
            return resolve(size: size, target: nil, preferredHeight: preferredHeight)
        }
        // A large panel needs a focus window, not a ring around the whole screen.
        let focusHeight = min(visible.height, min(140, max(24, inset.height - desired - 40)))
        let top = CGRect(x: visible.minX, y: visible.minY, width: visible.width, height: focusHeight)
        let bottom = CGRect(x: visible.minX, y: visible.maxY - focusHeight, width: visible.width, height: focusHeight)
        let gap: CGFloat = 32
        func room(_ rect: CGRect) -> CGFloat { max(rect.minY - inset.minY - gap, inset.maxY - rect.maxY - gap) }
        let focus = room(top) >= room(bottom) ? top : bottom
        let above = max(0, focus.minY - inset.minY - gap)
        let below = max(0, inset.maxY - focus.maxY - gap)
        let putBelow = below >= desired || (above < desired && below >= above)
        let cardHeight = max(1, min(desired, putBelow ? below : above))
        let cardY = putBelow ? focus.maxY + gap : focus.minY - gap - cardHeight
        let boundedY = min(max(inset.minY, cardY), inset.maxY - cardHeight)
        let card = CGRect(x: cardX, y: boundedY, width: cardWidth, height: cardHeight)
        return Self(card: card, focus: focus)
    }
}

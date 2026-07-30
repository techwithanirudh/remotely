import CoreGraphics

/// Turns fractional movement into whole pixels without losing the difference.
///
/// Scroll wheels take integers and the glide opens below one pixel per frame, so
/// truncating each frame discarded the movement instead of accumulating it.
public struct PixelAccumulator: Sendable {
    private var remainder = CGVector(dx: 0, dy: 0)

    public init() {}

    /// The whole pixels to send now, or nil when the step has not yet reached one.
    public mutating func take(_ step: CGVector) -> CGVector? {
        let wanted = CGVector(dx: remainder.dx + step.dx, dy: remainder.dy + step.dy)
        let whole = CGVector(
            dx: wanted.dx.rounded(.towardZero),
            dy: wanted.dy.rounded(.towardZero)
        )
        remainder = CGVector(dx: wanted.dx - whole.dx, dy: wanted.dy - whole.dy)
        return whole.dx == 0 && whole.dy == 0 ? nil : whole
    }

    public mutating func reset() {
        remainder = CGVector(dx: 0, dy: 0)
    }
}

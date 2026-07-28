import CoreGraphics
import Foundation

/// Speed curve for a held direction.
///
/// TV virtual-mouse implementations converge on this shape: start slow enough
/// that a tap nudges a few points, then ramp while the key stays down. A fixed
/// step per press cannot serve both — small enough to hit a menu item means
/// crawling across the screen.
public struct Glide: Sendable {
    public static let tick: TimeInterval = 1 / 60

    public var initialSpeed: Double
    public var acceleration: Double
    public var maximumSpeed: Double

    public private(set) var speed: Double

    public init(initialSpeed: Double = 95, acceleration: Double = 1500, maximumSpeed: Double = 2700) {
        self.initialSpeed = initialSpeed
        self.acceleration = acceleration
        self.maximumSpeed = maximumSpeed
        self.speed = initialSpeed
    }

    /// Scales the whole curve, so one slider changes feel without reshaping it.
    public static func pointer(sensitivity: Double) -> Glide {
        Glide(
            initialSpeed: 95 * sensitivity,
            acceleration: 1500 * sensitivity,
            maximumSpeed: 2700 * sensitivity
        )
    }

    /// Scrolling wants the same shape at a calmer pace.
    public static func scroll(sensitivity: Double) -> Glide {
        Glide(
            initialSpeed: 95 * sensitivity * 0.35,
            acceleration: 525 * sensitivity,
            maximumSpeed: 945 * sensitivity
        )
    }

    /// Distance for this frame, advancing the curve.
    public mutating func advance() -> Double {
        let distance = speed * Self.tick
        speed = min(speed + acceleration * Self.tick, maximumSpeed)
        return distance
    }

    public mutating func reset() {
        speed = initialSpeed
    }
}

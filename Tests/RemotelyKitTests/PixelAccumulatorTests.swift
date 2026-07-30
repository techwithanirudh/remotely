import CoreGraphics
import RemotelyKit

func pixelAccumulatorTests() {
    Expect.suite("Pixel accumulator") {
        var accumulator = PixelAccumulator()

        Expect.that(accumulator.take(CGVector(dx: 0, dy: 0.665)) == nil,
                    "a step under one pixel sends nothing yet")

        // The glide opens at 0.665px per frame. Truncating each frame sent zero
        // forever; carrying the remainder must lose none of it.
        var sent = 0.0
        accumulator = PixelAccumulator()
        for _ in 0 ..< 60 {
            if let whole = accumulator.take(CGVector(dx: 0, dy: 0.665)) {
                sent += whole.dy
            }
        }
        Expect.that(sent >= 39 && sent <= 41,
                    "sixty frames of 0.665px move about forty pixels, not zero")

        accumulator = PixelAccumulator()
        _ = accumulator.take(CGVector(dx: 0, dy: 0.9))
        accumulator.reset()
        Expect.that(accumulator.take(CGVector(dx: 0, dy: 0.9)) == nil,
                    "a reset drops the carried fraction")

        accumulator = PixelAccumulator()
        Expect.equal(accumulator.take(CGVector(dx: -2.4, dy: 0))?.dx, -2,
                     "negative movement truncates toward zero, not downward")
    }
}

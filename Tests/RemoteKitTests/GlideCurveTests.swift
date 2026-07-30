import CoreGraphics
import Foundation
import RemoteKit

func glideCurveTests() {
    Expect.suite("Glide curve") {
        do {
            var glide = Glide.pointer(sensitivity: 1)
            let travelled = (0 ..< 7).reduce(0.0) { total, _ in total + glide.advance() }
            Expect.that(travelled < 20, "a tap moves only a few points (\(Int(travelled)))")
        }

        do {
            var glide = Glide.pointer(sensitivity: 1)
            let first = glide.advance()
            for _ in 0 ..< 60 { _ = glide.advance() }
            Expect.that(glide.advance() > first * 5, "holding ramps the speed up")
        }

        do {
            var glide = Glide.pointer(sensitivity: 1)
            for _ in 0 ..< 1000 { _ = glide.advance() }
            Expect.that(glide.speed <= glide.maximumSpeed, "speed never exceeds its ceiling")
        }

        do {
            var slow = Glide.pointer(sensitivity: 0.5)
            var fast = Glide.pointer(sensitivity: 2)
            Expect.that(fast.advance() > slow.advance() * 3, "sensitivity scales the whole curve")
        }

        do {
            var pointer = Glide.pointer(sensitivity: 1)
            var scroll = Glide.scroll(sensitivity: 1)
            Expect.that(
                scroll.advance() < pointer.advance(),
                "scrolling is calmer than pointer motion"
            )
        }
    }
}

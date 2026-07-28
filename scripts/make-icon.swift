#!/usr/bin/env swift
import AppKit

// Generates the app icon.
//
// Built the way Alcove's is: a dark bezel wrapped around an inner panel that
// carries a vertical gradient, lit from the bottom so the panel reads as
// glowing rather than painted. The remote glyph sits on top in white.

let side: CGFloat = 1024
let outerInset: CGFloat = 92        // macOS icons float inside their canvas
let bezelRadius: CGFloat = 232
let bezelWidth: CGFloat = 58

func squircle(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else { exit(1) }
context.setAllowsAntialiasing(true)
// Without this the canvas comes out opaque black instead of transparent.
context.clear(CGRect(x: 0, y: 0, width: side, height: side))

let outerRect = NSRect(x: outerInset, y: outerInset,
                       width: side - outerInset * 2,
                       height: side - outerInset * 2)

// Bezel, with the drop shadow macOS icons carry.
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -14), blur: 34,
                  color: NSColor.black.withAlphaComponent(0.34).cgColor)
NSColor(calibratedWhite: 0.09, alpha: 1).setFill()
squircle(outerRect, bezelRadius).fill()
context.restoreGState()

// Inner panel.
let innerRect = outerRect.insetBy(dx: bezelWidth, dy: bezelWidth)
let innerRadius = bezelRadius - bezelWidth * 0.72
let panel = squircle(innerRect, innerRadius)

context.saveGState()
panel.addClip()
let gradient = NSGradient(colors: [
    NSColor(srgbRed: 0.09, green: 0.10, blue: 0.13, alpha: 1),   // near-black
    NSColor(srgbRed: 0.13, green: 0.15, blue: 0.20, alpha: 1),
    NSColor(srgbRed: 0.20, green: 0.24, blue: 0.32, alpha: 1),
    NSColor(srgbRed: 0.34, green: 0.41, blue: 0.53, alpha: 1),   // lifted slate
])
gradient?.draw(in: innerRect, angle: -90)

// Bloom along the bottom edge, which is what sells the glow.
let bloom = NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.0),
    NSColor.white.withAlphaComponent(0.16),
])
bloom?.draw(in: NSRect(x: innerRect.minX, y: innerRect.minY,
                       width: innerRect.width, height: innerRect.height * 0.34),
            angle: -90)
context.restoreGState()

// Inner rim highlight.
context.saveGState()
NSColor.white.withAlphaComponent(0.16).setStroke()
panel.lineWidth = 3
panel.stroke()
context.restoreGState()

// Remote glyph in white, centred in the panel.
let config = NSImage.SymbolConfiguration(pointSize: 300, weight: .medium)
if let symbol = NSImage(systemSymbolName: "av.remote.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let white = NSImage(size: symbol.size)
    white.lockFocus()
    NSColor.white.set()
    NSRect(origin: .zero, size: symbol.size).fill(using: .sourceOver)
    symbol.draw(at: .zero, from: .zero, operation: .destinationIn, fraction: 1)
    white.unlockFocus()

    let target = NSRect(
        x: innerRect.midX - symbol.size.width / 2,
        y: innerRect.midY - symbol.size.height / 2,
        width: symbol.size.width,
        height: symbol.size.height
    )

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -6), blur: 22,
                      color: NSColor.black.withAlphaComponent(0.5).cgColor)
    white.draw(in: target, from: .zero, operation: .sourceOver, fraction: 1)
    context.restoreGState()
}

image.unlockFocus()

// Write every size the iconset needs.
let iconset = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

let variants: [(Int, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]

for (pixels, name) in variants {
    let target = NSImage(size: NSSize(width: pixels, height: pixels))
    target.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    target.unlockFocus()

    guard let tiff = target.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { continue }
    try? png.write(to: URL(fileURLWithPath: "\(iconset)/\(name).png"))
}

print("wrote \(iconset)")

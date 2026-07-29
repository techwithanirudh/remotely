#!/usr/bin/env swift
import AppKit

// Generates the app icon.
//
// Shaped like every other macOS app icon: one squircle filling the tile, with a
// ~100pt margin for the shadow, and a glyph large enough to read at dock size.
// An earlier version wrapped the panel in a thick bezel the way Alcove's does,
// which shrank the artwork so far that it looked tiny next to Finder and
// Settings in the dock.

let side: CGFloat = 1024
let margin: CGFloat = 100
let cornerRadius: CGFloat = 185     // macOS squircle is ~0.2237 of the tile
let glyphSize: CGFloat = 505
let tilt: CGFloat = CommandLine.arguments.count > 2 ? CGFloat(Double(CommandLine.arguments[2]) ?? 45) : 45
let glyphInset: CGFloat = CommandLine.arguments.count > 3 ? CGFloat(Double(CommandLine.arguments[3]) ?? 170) : 170

let tile = NSRect(x: margin, y: margin,
                  width: side - margin * 2,
                  height: side - margin * 2)

func squircle(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else { exit(1) }
context.setAllowsAntialiasing(true)
// Without this the canvas comes out opaque black instead of transparent.
context.clear(CGRect(x: 0, y: 0, width: side, height: side))

let shape = squircle(tile, cornerRadius)

// Tile, with the drop shadow macOS icons carry.
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -12), blur: 30,
                  color: NSColor.black.withAlphaComponent(0.30).cgColor)
NSColor(srgbRed: 0.30, green: 0.18, blue: 0.66, alpha: 1).setFill()
shape.fill()
context.restoreGState()

// Violet ramp, lighter at the top so it catches light like a real object.
// Graphite read as another dark square in a dock full of colour.
context.saveGState()
shape.addClip()
NSGradient(colors: [
    NSColor(srgbRed: 0.60, green: 0.46, blue: 0.98, alpha: 1),
    NSColor(srgbRed: 0.44, green: 0.29, blue: 0.87, alpha: 1),
    NSColor(srgbRed: 0.25, green: 0.13, blue: 0.55, alpha: 1),
])?.draw(in: tile, angle: -90)

// Highlight across the top edge.
NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.16),
    NSColor.white.withAlphaComponent(0.0),
])?.draw(in: NSRect(x: tile.minX, y: tile.maxY - tile.height * 0.42,
                    width: tile.width, height: tile.height * 0.42),
         angle: -90)
context.restoreGState()

// Rim.
context.saveGState()
NSColor.white.withAlphaComponent(0.14).setStroke()
shape.lineWidth = 2.5
shape.stroke()
context.restoreGState()

// Remote glyph, centred and large enough to carry the tile. `av.remote.fill`
// was tried first and its grid of buttons turned to mush at dock size; the
// Apple TV remote is two shapes and survives being small.
let config = NSImage.SymbolConfiguration(pointSize: glyphSize, weight: .regular)
if let symbol = NSImage(systemSymbolName: "appletvremote.gen4.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let white = NSImage(size: symbol.size)
    white.lockFocus()
    NSColor.white.set()
    NSRect(origin: .zero, size: symbol.size).fill(using: .sourceOver)
    symbol.draw(at: .zero, from: .zero, operation: .destinationIn, fraction: 1)
    white.unlockFocus()

    // Sized off the glyph's ink rather than its image box, which carries
    // padding, and scaled so the tilted remote runs corner to corner.
    let ink = inkBounds(of: white)
    let angle = tilt * .pi / 180
    let available = tile.width - glyphInset * 2
    let spread = CGSize(
        width: ink.width * cos(angle) + ink.height * sin(angle),
        height: ink.width * sin(angle) + ink.height * cos(angle)
    )
    let scale = min(available / spread.width, available / spread.height)

    context.saveGState()
    context.translateBy(x: tile.midX, y: tile.midY)
    context.rotate(by: -angle)
    context.setShadow(offset: CGSize(width: 0, height: -6), blur: 24,
                      color: NSColor.black.withAlphaComponent(0.45).cgColor)
    white.draw(
        in: NSRect(
            x: -ink.midX * scale,
            y: -ink.midY * scale,
            width: white.size.width * scale,
            height: white.size.height * scale
        ),
        from: .zero,
        operation: .sourceOver,
        fraction: 1
    )
    context.restoreGState()
}

/// The drawn extent of an image, in its own coordinates.
func inkBounds(of image: NSImage) -> NSRect {
    guard let data = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: data)
    else { return NSRect(origin: .zero, size: image.size) }

    var minX = rep.pixelsWide, maxX = 0
    var minY = rep.pixelsHigh, maxY = 0

    for y in 0..<rep.pixelsHigh {
        for x in 0..<rep.pixelsWide where (rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.05 {
            minX = min(minX, x); maxX = max(maxX, x)
            minY = min(minY, y); maxY = max(maxY, y)
        }
    }
    guard maxX >= minX else { return NSRect(origin: .zero, size: image.size) }

    // Bitmap rows run top down; the image's own coordinates run bottom up.
    let unit = image.size.width / CGFloat(rep.pixelsWide)
    return NSRect(
        x: CGFloat(minX) * unit,
        y: CGFloat(rep.pixelsHigh - 1 - maxY) * unit,
        width: CGFloat(maxX - minX + 1) * unit,
        height: CGFloat(maxY - minY + 1) * unit
    )
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

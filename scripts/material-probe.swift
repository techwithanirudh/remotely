#!/usr/bin/env swift
import AppKit

// Opens one window per NSVisualEffectView material, tiled, so they can be
// compared over whatever is actually on the desktop. A capture of a lone window
// reports a material's tint and nothing about how much passes through it, which
// is only visible against real content.
//
//   swift scripts/material-probe.swift

let materials: [(String, NSVisualEffectView.Material)] = [
    ("titlebar", .titlebar), ("selection", .selection), ("menu", .menu),
    ("popover", .popover), ("sidebar", .sidebar), ("headerView", .headerView),
    ("sheet", .sheet), ("windowBackground", .windowBackground),
    ("hudWindow", .hudWindow), ("fullScreenUI", .fullScreenUI),
    ("toolTip", .toolTip), ("contentBackground", .contentBackground),
    ("underWindowBackground", .underWindowBackground),
    ("underPageBackground", .underPageBackground),
]

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let size = NSSize(width: 230, height: 150)
let columns = 5
var windows: [NSWindow] = []

for (index, entry) in materials.enumerated() {
    let column = index % columns, row = index / columns
    let frame = NSRect(
        x: 120 + CGFloat(column) * (size.width + 16),
        y: 700 - CGFloat(row) * (size.height + 16),
        width: size.width,
        height: size.height
    )

    let window = NSWindow(
        contentRect: frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.isOpaque = false
    window.backgroundColor = .clear
    window.isMovableByWindowBackground = true

    let effect = NSVisualEffectView()
    effect.material = entry.1
    effect.blendingMode = .behindWindow
    effect.state = .active
    effect.wantsLayer = true
    effect.layer?.cornerRadius = 16
    effect.layer?.cornerCurve = .continuous
    effect.layer?.masksToBounds = true

    let label = NSTextField(labelWithString: entry.0)
    label.font = .systemFont(ofSize: 13, weight: .semibold)
    label.translatesAutoresizingMaskIntoConstraints = false
    effect.addSubview(label)
    NSLayoutConstraint.activate([
        label.centerXAnchor.constraint(equalTo: effect.centerXAnchor),
        label.centerYAnchor.constraint(equalTo: effect.centerYAnchor),
    ])

    window.contentView = effect
    window.orderFrontRegardless()
    windows.append(window)
}

app.activate(ignoringOtherApps: true)
app.run()

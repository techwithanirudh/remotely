import AppKit
import RemoteKit

/// The menu bar item and its menu.
@MainActor
final class StatusItemController {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let header = MenuHeader()
    private let lastPress = NSMenuItem(title: "Last button: None", action: nil, keyEquivalent: "")
    private let toggle: NSMenuItem

    /// Named actions rather than a target/selector dance.
    init(
        onToggle: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onCopyLog: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        toggle = NSMenuItem(title: "Enable", action: nil, keyEquivalent: "")

        item.button?.image = NSImage(systemSymbolName: "appletvremote.gen4.fill", accessibilityDescription: "Remote Bridge")
        item.button?.image?.isTemplate = true

        let menu = NSMenu()
        menu.minimumWidth = 272

        let headerItem = NSMenuItem()
        headerItem.view = header
        menu.addItem(headerItem)

        lastPress.isEnabled = false
        lastPress.image = Self.icon("button.programmable")
        menu.addItem(lastPress)
        menu.addItem(.separator())

        // The header already names the app, so items do not repeat it.
        menu.addItem(Self.item(toggle, symbol: "power", action: onToggle))
        menu.addItem(Self.item(
            NSMenuItem(title: "Settings…", action: nil, keyEquivalent: ","),
            symbol: "gearshape",
            action: onSettings
        ))
        menu.addItem(.separator())
        menu.addItem(Self.item(
            NSMenuItem(title: "Copy Diagnostic Log", action: nil, keyEquivalent: ""),
            symbol: "doc.on.doc",
            action: onCopyLog
        ))
        menu.addItem(.separator())
        menu.addItem(Self.item(
            NSMenuItem(title: "Quit", action: nil, keyEquivalent: "q"),
            symbol: "xmark.circle",
            action: onQuit
        ))

        item.menu = menu
    }

    func update(status: BridgeStatus, lastKey: RemoteKey?, isEnabled: Bool) {
        header.update(status: status)
        item.button?.toolTip = "Remote Bridge: \(status.title)"
        lastPress.title = "Last button: \(lastKey?.title ?? "None")"
        toggle.state = isEnabled ? .on : .off
    }

    private static func item(_ item: NSMenuItem, symbol: String, action: @escaping () -> Void) -> NSMenuItem {
        let handler = ActionHandler(action)
        item.representedObject = handler
        item.target = handler
        item.action = #selector(ActionHandler.run)
        item.image = icon(symbol)
        return item
    }

    private static func icon(_ symbol: String) -> NSImage? {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        image?.size = NSSize(width: 15, height: 15)
        return image
    }
}

/// Lets menu items carry closures instead of selectors on the delegate.
private final class ActionHandler: NSObject {
    private let action: () -> Void

    init(_ action: @escaping () -> Void) { self.action = action }

    @objc func run() { action() }
}

@MainActor
private final class MenuHeader: NSView {
    private let title = NSTextField(labelWithString: "Remote Bridge")
    private let subtitle = NSTextField(labelWithString: "Starting…")
    private let dot = NSView()

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 272, height: 59))

        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "appletvremote.gen4.fill", accessibilityDescription: nil)
        icon.symbolConfiguration = .init(pointSize: 19, weight: .medium)
        icon.contentTintColor = .labelColor

        title.font = .systemFont(ofSize: 13, weight: .semibold)
        subtitle.font = .systemFont(ofSize: 11, weight: .medium)
        subtitle.textColor = .secondaryLabelColor
        subtitle.lineBreakMode = .byTruncatingTail

        dot.wantsLayer = true
        dot.layer?.cornerRadius = 3

        for view in [icon, title, subtitle, dot] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 272),
            heightAnchor.constraint(equalToConstant: 59),

            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),

            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            title.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -14),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 11),

            dot.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            dot.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),

            subtitle.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 6),
            subtitle.centerYAnchor.constraint(equalTo: dot.centerYAnchor),
            subtitle.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -14),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    func update(status: BridgeStatus) {
        subtitle.stringValue = status.title
        dot.layer?.backgroundColor = color(for: status).cgColor
    }

    private func color(for status: BridgeStatus) -> NSColor {
        switch status {
        case .ready: .systemGreen
        case .waitingForRemote, .needsPermission: .systemOrange
        case .unsupported, .failed: .systemRed
        case .paused: .secondaryLabelColor
        }
    }
}

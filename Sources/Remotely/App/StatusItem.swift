import AppKit
import RemotelyKit

@MainActor
final class StatusItemController {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let header = MenuHeader()
    private let toggle: NSMenuItem

    init(
        onToggle: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onCopyLog: @escaping () -> Void,
        onCheckForUpdates: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        toggle = NSMenuItem(title: "Enable", action: nil, keyEquivalent: "")

        item.button?.image = NSImage(
            systemSymbolName: "appletvremote.gen4.fill",
            accessibilityDescription: "Remotely"
        )
        item.button?.image?.isTemplate = true

        let menu = NSMenu()
        menu.minimumWidth = 272

        let headerItem = NSMenuItem()
        headerItem.view = header
        menu.addItem(headerItem)
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
            NSMenuItem(title: "Check for Updates…", action: nil, keyEquivalent: ""),
            symbol: "arrow.triangle.2.circlepath",
            action: onCheckForUpdates
        ))
        menu.addItem(Self.item(
            NSMenuItem(title: "Copy Diagnostics", action: nil, keyEquivalent: ""),
            symbol: "waveform.path.ecg",
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

    var isVisible: Bool {
        get { item.isVisible }
        set { item.isVisible = newValue }
    }

    func update(status: RemoteStatus, isEnabled: Bool) {
        header.update(status: status)
        item.button?.toolTip = "Remotely: \(status.title)"
        toggle.state = isEnabled ? .on : .off
    }

    private static func item(_ item: NSMenuItem, symbol: String,
                             action: @escaping () -> Void) -> NSMenuItem {
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

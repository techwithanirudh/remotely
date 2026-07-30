import AppKit
import RemotelyKit

@MainActor
final class MenuHeader: NSView {
    private let title = NSTextField(labelWithString: "Remotely")
    private let subtitle = NSTextField(labelWithString: "Starting…")
    private let dot = NSView()

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 272, height: 50))

        let icon = NSImageView()
        icon.image = NSImage(
            systemSymbolName: "appletvremote.gen4.fill",
            accessibilityDescription: nil
        )
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

            // Derived rather than hard-coded, so the padding stays even and the
            // height cannot drift when a font size changes.
            dot.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not supported")
    }

    func update(status: RemoteStatus) {
        subtitle.stringValue = status.title
        dot.layer?.backgroundColor = status.nsTint.cgColor
    }
}

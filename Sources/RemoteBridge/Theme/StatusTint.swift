import AppKit
import RemoteKit
import SwiftUI

extension BridgeStatus {
    var tint: Color {
        switch self {
        case .ready: .green
        case .waitingForRemote, .needsPermission: .orange
        case .unsupported, .failed: .red
        case .paused: .secondary
        }
    }

    /// The menu bar draws in AppKit, and a second switch there drifted from
    /// this one every time a status was added.
    var nsTint: NSColor { NSColor(tint) }
}

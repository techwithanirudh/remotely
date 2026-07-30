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

    var nsTint: NSColor { NSColor(tint) }
}

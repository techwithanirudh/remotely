import AppKit
import RemotelyKit
import SwiftUI

extension RemoteStatus {
    var tint: Color {
        switch self {
        case .ready: .green
        case .waitingForRemote, .needsPermission, .noDisplay: .orange
        case .unsupported, .failed: .red
        case .paused: .secondary
        }
    }

    var nsTint: NSColor { NSColor(tint) }
}

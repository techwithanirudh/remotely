import AppKit
import RemotelyKit
import SwiftUI

extension RemoteStatus {
    var tint: Color {
        switch self {
        case .ready: .green
        case .needsPermission, .noDisplay: .orange
        case .unsupported, .failed: .red
        // Nothing is wrong yet, so it does not get a warning colour.
        case .waitingForRemote, .paused: .secondary
        }
    }

    var nsTint: NSColor { NSColor(tint) }
}

import SwiftUI

enum SettingsPage: String, CaseIterable, Equatable, Identifiable, Sendable {
    case general, connection, controls, diagnostics, about

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "General"
        case .connection: "Connection"
        case .controls: "Controls"
        case .diagnostics: "Diagnostics"
        case .about: "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .connection: "cable.connector"
        case .controls: "dpad.fill"
        case .diagnostics: "waveform.path.ecg"
        case .about: "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .general: .gray
        case .connection: .cyan
        case .controls: .purple
        case .diagnostics: .orange
        case .about: .gray
        }
    }
}

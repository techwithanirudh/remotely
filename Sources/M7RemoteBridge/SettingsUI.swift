import SwiftUI
import M7RemoteCore

enum SettingsPage: String, CaseIterable, Identifiable {
    case general
    case connection
    case controls
    case diagnostics
    case about

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

struct SettingsRootView: View {
    @ObservedObject var model: BridgeModel
    @State private var selection: SettingsPage = .general

    var body: some View {
        ZStack {
            VisualEffectBackground(material: .underWindowBackground)

            HStack(spacing: 0) {
                SettingsSidebar(selection: $selection, model: model)
                    .frame(width: 228)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.11), .black.opacity(0.13)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)

                ZStack {
                    VisualEffectBackground(material: .contentBackground)

                    LinearGradient(
                        colors: [
                            Color.indigo.opacity(0.025),
                            .clear,
                            Color.cyan.opacity(0.018),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Group {
                        switch selection {
                        case .general:
                            GeneralSettingsView(model: model)
                        case .connection:
                            ConnectionSettingsView(model: model)
                        case .controls:
                            ControlsSettingsView(model: model)
                        case .diagnostics:
                            DiagnosticsSettingsView(model: model)
                        case .about:
                            AboutSettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 740, minHeight: 620)
        .ignoresSafeArea()
    }
}

private struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

private struct SettingsSidebar: View {
    @Binding var selection: SettingsPage
    @ObservedObject var model: BridgeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusPill(state: model.connectionState)
                .padding(.horizontal, 16)
                .padding(.top, 48)
                .padding(.bottom, 15)

            SidebarButton(page: .general, selection: $selection)

            SidebarSection(title: "Remote") {
                SidebarButton(page: .connection, selection: $selection)
                SidebarButton(page: .controls, selection: $selection)
            }

            SidebarSection(title: "Support") {
                SidebarButton(page: .diagnostics, selection: $selection)
            }

            Spacer()

            SidebarSection(title: "M7 Remote") {
                SidebarButton(page: .about, selection: $selection)
            }
            .padding(.bottom, 14)
        }
        .background {
            ZStack {
                VisualEffectBackground(material: .sidebar)
                LinearGradient(
                    colors: [.white.opacity(0.045), .clear, .black.opacity(0.025)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

private struct StatusPill: View {
    let state: CECClient.State

    private var tint: Color {
        switch state {
        case .running: .green
        case .waitingForHDMI: .orange
        case .unsupported, .failed: .red
        case .stopped: .secondary
        }
    }

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 17, height: 17)

                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                    .shadow(color: tint.opacity(0.55), radius: 3)
            }

            Text(state.displayName)
                .font(.system(size: 11.5, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .layoutPriority(1)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 31)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.16), .white.opacity(0.035)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

private struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 19)
                .padding(.top, 16)
                .padding(.bottom, 2)
            content
        }
    }
}

private struct SidebarButton: View {
    let page: SettingsPage
    @Binding var selection: SettingsPage

    var body: some View {
        Button {
            selection = page
        } label: {
            HStack(spacing: 10) {
                SymbolTile(symbol: page.symbol, tint: page.tint, size: 22)

                Text(page.title)
                    .font(.system(size: 13, weight: selection == page ? .semibold : .medium))

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 10)
            .frame(height: 39)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selection == page ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(.clear))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        selection == page ? Color.white.opacity(0.09) : .clear,
                        lineWidth: 1
                    )
            }
            .shadow(
                color: selection == page ? .black.opacity(0.09) : .clear,
                radius: 4,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 11)
    }
}

private struct SymbolTile: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(tint.gradient)
            Image(systemName: symbol)
                .font(.system(size: size * 0.53, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .strokeBorder(.white.opacity(0.17), lineWidth: 0.7)
        }
        .shadow(color: tint.opacity(0.18), radius: 2, y: 1)
    }
}

private struct PageShell<Content: View>: View {
    let page: SettingsPage
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                SymbolTile(symbol: page.symbol, tint: page.tint, size: 23)
                Text(page.title)
                    .font(.system(size: 15, weight: .bold))
            }
            .padding(.horizontal, 30)
            .padding(.top, 15)
            .padding(.bottom, 14)

            ScrollView {
                content
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
            }
            .scrollIndicators(.visible)
        }
    }
}

private struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 9)
            .padding(.top, 18)
            .padding(.bottom, 7)
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.14),
                            .white.opacity(0.045),
                            .black.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.11), radius: 7, y: 3)
    }
}

private struct SettingRow<Control: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)
            control
        }
        .padding(.horizontal, 14)
        .frame(minHeight: subtitle == nil ? 42 : 50)
        .contentShape(Rectangle())
    }
}

private struct CardDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.white.opacity(0.045), .primary.opacity(0.11), .white.opacity(0.025)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.7)
            .padding(.leading, 14)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        PageShell(page: .general) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsCard {
                    SettingRow(title: "Enable remote bridge") {
                        Toggle("", isOn: $model.bridgeEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    CardDivider()
                    SettingRow(title: "Launch at login") {
                        Toggle("", isOn: Binding(
                            get: { model.launchAtLoginEnabled },
                            set: { model.setLaunchAtLogin($0) }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }
                }

                SectionLabel(title: "Permissions")

                SettingsCard {
                    SettingRow(
                        title: "Accessibility",
                        subtitle: model.accessibilityGranted
                            ? "Pointer and keyboard control is allowed."
                            : "Required to move the pointer and send media keys."
                    ) {
                        if model.accessibilityGranted {
                            Label("Granted", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.green)
                        } else {
                            Button("Grant Access") {
                                model.requestAccessibility()
                            }
                            .controlSize(.small)
                        }
                    }
                }

                SectionLabel(title: "Pointer")

                SettingsCard {
                    SettingRow(
                        title: "D-pad movement",
                        subtitle: "Distance moved for each remote press."
                    ) {
                        HStack(spacing: 9) {
                            Slider(value: $model.cursorStep, in: 18...90, step: 2)
                                .frame(width: 118)
                            Text("\(Int(model.cursorStep)) px")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 42, alignment: .trailing)
                        }
                    }
                    CardDivider()
                    SettingRow(title: "Test pointer movement") {
                        Button {
                            model.test(.moveRight)
                        } label: {
                            Label("Move Right", systemImage: "arrow.right")
                        }
                        .controlSize(.small)
                    }
                }
            }
        }
    }
}

struct ConnectionSettingsView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        PageShell(page: .connection) {
            VStack(alignment: .leading, spacing: 0) {
                ConnectionHero(model: model)

                SectionLabel(title: "Signal Path")

                SettingsCard {
                    TopologyRow(
                        number: 1,
                        symbol: "av.remote.fill",
                        title: "Samsung SolarCell Remote",
                        detail: "Paired normally with the M70D"
                    )
                    CardDivider()
                    TopologyRow(
                        number: 2,
                        symbol: "display",
                        title: "M70D HDMI 1",
                        detail: "Anynet+ forwards supported buttons"
                    )
                    CardDivider()
                    TopologyRow(
                        number: 3,
                        symbol: "macmini",
                        title: "M4 Mac mini",
                        detail: "Native CoreRC HDMI-CEC receiver"
                    )
                }

                SectionLabel(title: "Checklist")

                SettingsCard {
                    ChecklistRow(
                        title: "Use the Mac mini’s built-in HDMI port",
                        complete: model.connectionState == .running
                    )
                    CardDivider()
                    ChecklistRow(
                        title: "Select HDMI 1 on the M7",
                        complete: model.connectionState == .running
                    )
                    CardDivider()
                    ChecklistRow(
                        title: "Enable Anynet+ (HDMI-CEC)",
                        complete: model.connectionState == .running
                    )
                }
            }
        }
    }
}

private struct ConnectionHero: View {
    @ObservedObject var model: BridgeModel

    private var tint: Color {
        switch model.connectionState {
        case .running: .green
        case .waitingForHDMI: .orange
        case .stopped: .gray
        case .unsupported, .failed: .red
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(.white.opacity(0.14))
                Image(systemName: model.connectionState.symbol)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(model.connectionState.displayName)
                    .font(.system(size: 16, weight: .bold))
                Text(model.connectionState.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button("Reconnect") {
                model.reconnect()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.18))
            .controlSize(.small)
        }
        .padding(16)
        .foregroundStyle(.white)
        .background {
            LinearGradient(
                colors: [tint.opacity(0.92), tint.opacity(0.52), .blue.opacity(0.68)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.28), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: tint.opacity(0.16), radius: 12, y: 5)
    }
}

private struct TopologyRow: View {
    let number: Int
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 11) {
            Text("\(number)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(Color.primary.opacity(0.08), in: Circle())

            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.cyan)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 52)
    }
}

private struct ChecklistRow: View {
    let title: String
    let complete: Bool

    var body: some View {
        HStack {
            Image(systemName: complete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(complete ? .green : .secondary)
            Text(title).font(.system(size: 13))
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
    }
}

struct ControlsSettingsView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        PageShell(page: .controls) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Make the remote yours")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Assign any macOS action to each remote button.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Reset Defaults") {
                        model.resetMappings()
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 11)

                SectionLabel(title: "Pointer")
                    .padding(.top, 0)

                SettingsCard {
                    MappingEditorRow(button: .up, model: model)
                    CardDivider()
                    MappingEditorRow(button: .down, model: model)
                    CardDivider()
                    MappingEditorRow(button: .left, model: model)
                    CardDivider()
                    MappingEditorRow(button: .right, model: model)
                    CardDivider()
                    MappingEditorRow(button: .center, model: model)
                }

                SectionLabel(title: "Navigation")

                SettingsCard {
                    MappingEditorRow(button: .back, model: model)
                    CardDivider()
                    MappingEditorRow(button: .doubleBack, model: model)
                }

                SectionLabel(title: "Media")

                SettingsCard {
                    MappingEditorRow(button: .playPause, model: model)
                    CardDivider()
                    MappingEditorRow(button: .rewind, model: model)
                    CardDivider()
                    MappingEditorRow(button: .fastForward, model: model)
                }

                SectionLabel(title: "Audio")

                SettingsCard {
                    MappingEditorRow(button: .volumeUp, model: model)
                    CardDivider()
                    MappingEditorRow(button: .volumeDown, model: model)
                    CardDivider()
                    MappingEditorRow(button: .mute, model: model)
                }

                Label(
                    "Samsung normally keeps Home for the monitor, so it is intentionally omitted.",
                    systemImage: "info.circle"
                )
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.top, 10)
            }
        }
    }
}

private struct MappingEditorRow: View {
    let button: RemoteButton
    @ObservedObject var model: BridgeModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: button.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.purple)
                .frame(width: 22)

            Text(button.title)
                .font(.system(size: 13))

            Spacer()

            Picker("", selection: Binding(
                get: { model.action(for: button) },
                set: { model.setAction($0, for: button) }
            )) {
                ForEach(MacAction.allCases) { action in
                    Label(action.title, systemImage: action.symbol)
                        .tag(action)
                }
            }
            .labelsHidden()
            .controlSize(.small)
            .frame(width: 178)
        }
        .padding(.horizontal, 12)
        .frame(height: 43)
    }
}

struct DiagnosticsSettingsView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        PageShell(page: .diagnostics) {
            VStack(alignment: .leading, spacing: 0) {
                RemoteVisualizerCard(model: model)

                SectionLabel(title: "System Status")

                SettingsCard {
                    SettingRow(title: "HDMI-CEC Service") {
                        StatusBadge(
                            text: model.connectionState == .unsupported ? "Unavailable" : "Ready",
                            color: model.connectionState == .unsupported ? .red : .green
                        )
                    }
                    CardDivider()
                    SettingRow(title: "Accessibility") {
                        StatusBadge(
                            text: model.accessibilityGranted ? "Granted" : "Required",
                            color: model.accessibilityGranted ? .green : .orange
                        )
                    }
                }

                SectionLabel(title: "Remote Event Log")

                VStack(spacing: 0) {
                    HStack {
                        Text("\(model.logs.count) events")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear") { model.clearLogs() }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .semibold))
                        Button("Copy") { model.copyLogs() }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 34)

                    Divider()

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            if model.logs.isEmpty {
                                Text("CEC events will appear here.")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 44)
                            } else {
                                ForEach(model.logs.suffix(100)) { entry in
                                    HStack(alignment: .firstTextBaseline, spacing: 9) {
                                        Text(entry.timestamp)
                                            .foregroundStyle(.tertiary)
                                            .frame(width: 72, alignment: .leading)
                                        Text(entry.message)
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                    }
                                    .font(.system(size: 10, design: .monospaced))
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 190)
                }
                .background(.ultraThinMaterial)
                .background(Color.black.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.13), .white.opacity(0.035)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .shadow(color: .black.opacity(0.12), radius: 7, y: 3)

                SectionLabel(title: "Action Tests")

                HStack(spacing: 8) {
                    TestButton(title: "Move", symbol: "arrow.right") { model.test(.moveRight) }
                    TestButton(title: "Click", symbol: "cursorarrow.click") { model.test(.leftClick) }
                    TestButton(title: "Play", symbol: "playpause.fill") { model.test(.playPause) }
                    TestButton(title: "Desktop", symbol: "macwindow") { model.test(.showDesktop) }
                }
            }
        }
    }
}

private struct RemoteVisualizerCard: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        HStack(spacing: 22) {
            MiniRemoteView(model: model)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.03), .white.opacity(0.13), .white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(model.highlightedButton == nil ? Color.secondary : Color.purple)
                        .frame(width: 7, height: 7)
                        .shadow(
                            color: model.highlightedButton == nil
                                ? .clear
                                : Color.purple.opacity(0.75),
                            radius: 5
                        )

                    Text(model.highlightedButton == nil ? "Listening for input" : "Button received")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(model.buttonEventCount) events")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Text(model.lastButton?.title ?? "Press a remote button")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                if let action = model.lastMappedAction {
                    Label(action.title, systemImage: action.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.purple)
                        .padding(.top, 6)
                } else {
                    Text("The matching control will glow here.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.top, 5)
                }

                Spacer()

                Text("Click the preview remote to test the visualizer without HDMI.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    model.previewButton(.doubleBack)
                } label: {
                    Label("Preview Double Back", systemImage: "arrow.uturn.backward.circle")
                }
                .controlSize(.small)
                .padding(.top, 10)
            }
            .padding(.vertical, 22)
        }
        .padding(.horizontal, 20)
        .frame(height: 350)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.16))
        .background {
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.06),
                    Color.indigo.opacity(0.02),
                    .clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.17), .white.opacity(0.035)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .shadow(color: .black.opacity(0.13), radius: 9, y: 4)
    }
}

private struct MiniRemoteView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                RemoteDecorativeKey(symbol: "power")
                Spacer()
                RemoteDecorativeKey(symbol: "123.rectangle")
                RemoteDecorativeKey(symbol: "mic.fill")
            }

            DPadPreview(model: model)

            HStack(spacing: 12) {
                RemotePreviewKey(
                    button: .back,
                    symbol: "arrow.uturn.backward",
                    model: model,
                    compact: true
                )
                RemoteDecorativeKey(symbol: "house.fill", compact: true)
                RemotePreviewKey(
                    button: .playPause,
                    symbol: "playpause.fill",
                    model: model,
                    compact: true
                )
            }

            HStack(alignment: .top, spacing: 24) {
                VolumeRockerPreview(model: model)
                ChannelRockerPreview()
            }

            HStack(spacing: 5) {
                RemoteShortcutKey(label: "N", tint: .red)
                RemoteShortcutKey(label: "TV+", tint: .blue)
                RemoteShortcutKey(label: "D+", tint: .green)
                RemoteShortcutKey(label: "prime", tint: .cyan)
            }

            Text("SAMSUNG")
                .font(.system(size: 7, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(width: 146, height: 324)
        .background(Color.black.opacity(0.76))
        .background {
            LinearGradient(
                colors: [.white.opacity(0.12), .clear, .black.opacity(0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.28), .white.opacity(0.045)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.38), radius: 16, y: 9)
    }
}

private struct RemoteShortcutKey: View {
    let label: String
    let tint: Color

    var body: some View {
        Text(label)
            .font(.system(size: label == "prime" ? 5.8 : 7, weight: .bold, design: .rounded))
            .foregroundStyle(tint.opacity(0.92))
            .frame(width: 25, height: 16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.09), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 0.7)
            }
            .help("App shortcut handled by the Samsung monitor")
    }
}

private struct DPadPreview: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.22))
                .background(.thinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.07), .clear, .black.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 0.8))

            RemotePreviewKey(button: .up, symbol: "chevron.up", model: model, compact: true)
                .offset(y: -36)
            RemotePreviewKey(button: .down, symbol: "chevron.down", model: model, compact: true)
                .offset(y: 36)
            RemotePreviewKey(button: .left, symbol: "chevron.left", model: model, compact: true)
                .offset(x: -36)
            RemotePreviewKey(button: .right, symbol: "chevron.right", model: model, compact: true)
                .offset(x: 36)
            RemotePreviewKey(button: .center, symbol: "circle.fill", model: model, compact: true)
        }
        .frame(width: 108, height: 108)
    }
}

private struct RemoteDecorativeKey: View {
    let symbol: String
    var compact = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: compact ? 10 : 10.5, weight: .semibold))
            .foregroundStyle(.white.opacity(0.62))
            .frame(width: compact ? 31 : 28, height: compact ? 27 : 24)
            .background(.thinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.09), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 0.7))
            .help("Handled by the Samsung monitor")
    }
}

private struct VolumeRockerPreview: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        VStack(spacing: 0) {
            RockerButton(button: .volumeUp, symbol: "plus", model: model)
            RockerButton(button: .mute, symbol: "speaker.slash.fill", model: model)
            RockerButton(button: .volumeDown, symbol: "minus", model: model)
        }
        .frame(width: 42, height: 68)
        .background(.thinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.08), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 0.8))
    }
}

private struct RockerButton: View {
    let button: RemoteButton
    let symbol: String
    @ObservedObject var model: BridgeModel

    private var isHighlighted: Bool {
        model.highlightedButton == button
    }

    var body: some View {
        Button {
            model.previewButton(button)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(isHighlighted ? .white : .white.opacity(0.58))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isHighlighted ? Color.purple : .clear)
                .shadow(
                    color: isHighlighted ? Color.purple.opacity(0.8) : .clear,
                    radius: 7
                )
        }
        .buttonStyle(.plain)
        .help("Preview \(button.title)")
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isHighlighted)
    }
}

private struct ChannelRockerPreview: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "chevron.up")
            Text("CH")
                .font(.system(size: 6.5, weight: .bold, design: .rounded))
            Image(systemName: "chevron.down")
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.white.opacity(0.46))
        .frame(width: 42, height: 68)
        .background(.thinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.08), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .overlay(Capsule().strokeBorder(.white.opacity(0.17), lineWidth: 0.8))
        .help("Channel control stays with the Samsung monitor")
    }
}

private struct RemotePreviewKey: View {
    let button: RemoteButton
    let symbol: String
    @ObservedObject var model: BridgeModel
    var compact = false

    private var isHighlighted: Bool {
        model.highlightedButton == button ||
            (button == .back && model.highlightedButton == .doubleBack)
    }

    var body: some View {
        Button {
            model.previewButton(button)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: compact ? 10 : 11, weight: .bold))
                .foregroundStyle(isHighlighted ? .white : .white.opacity(0.72))
                .frame(
                    width: compact ? 32 : (button == .mute ? 28 : 38),
                    height: compact ? 29 : 27
                )
                .background(
                    isHighlighted
                        ? AnyShapeStyle(Color.purple.gradient)
                        : AnyShapeStyle(.thinMaterial),
                    in: Capsule()
                )
                .background(Color.white.opacity(isHighlighted ? 0 : 0.02), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isHighlighted ? Color.white.opacity(0.38) : Color.white.opacity(0.16),
                            lineWidth: 0.8
                        )
                }
                .shadow(
                    color: isHighlighted ? Color.purple.opacity(0.8) : .clear,
                    radius: 8
                )
                .scaleEffect(isHighlighted ? 0.9 : 1)
        }
        .buttonStyle(.plain)
        .help("Preview \(button.title)")
        .animation(.spring(response: 0.2, dampingFraction: 0.62), value: isHighlighted)
    }
}

private struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .frame(height: 23)
        .background(color.opacity(0.12), in: Capsule())
    }
}

private struct TestButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.14), .white.opacity(0.035)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .shadow(color: .black.opacity(0.09), radius: 4, y: 2)
    }
}

struct AboutSettingsView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.3"
    }

    var body: some View {
        PageShell(page: .about) {
            VStack(alignment: .leading, spacing: 0) {
                RemoteHeroArtwork()

                SettingsCard {
                    SettingRow(title: "M7 Remote Bridge") {
                        Text("Version \(version)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    CardDivider()
                    SettingRow(
                        title: "Built for your setup",
                        subtitle: "Samsung Smart M70D + M4 Mac mini"
                    ) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                    }
                }
                .padding(.top, 14)

                SectionLabel(title: "How it works")

                SettingsCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A tiny native bridge between Samsung Anynet+ and macOS.")
                            .font(.system(size: 13, weight: .semibold))
                        Text("It listens through the M4 Mac mini’s built-in HDMI-CEC service and translates remote buttons into pointer, browser, and media actions—without extra hardware.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("CoreRC is a private macOS framework and may change in future system updates.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.top, 10)
            }
        }
    }
}

private struct RemoteHeroArtwork: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo, .blue.opacity(0.88), .cyan.opacity(0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.11))
                .frame(width: 210)
                .blur(radius: 1)
                .offset(x: 155, y: -60)

            HStack(spacing: 28) {
                stylizedRemote

                VStack(alignment: .leading, spacing: 6) {
                    Text("One remote.\nYour whole Mac.")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Native HDMI-CEC • Zero extra hardware")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .frame(height: 152)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.28), .white.opacity(0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .shadow(color: .blue.opacity(0.18), radius: 14, y: 6)
    }

    private var stylizedRemote: some View {
        VStack(spacing: 9) {
            Circle()
                .strokeBorder(.white.opacity(0.8), lineWidth: 3)
                .frame(width: 42, height: 42)
                .overlay(Circle().fill(.white.opacity(0.16)).frame(width: 16, height: 16))
            Capsule()
                .fill(.white.opacity(0.75))
                .frame(width: 28, height: 5)
            Image(systemName: "playpause.fill")
                .font(.system(size: 12, weight: .bold))
        }
        .frame(width: 66, height: 118)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.2))
        }
        .shadow(color: .black.opacity(0.28), radius: 12, y: 8)
        .foregroundStyle(.white)
        .rotationEffect(.degrees(-7))
    }
}

import SwiftUI
import RemoteCore

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
                    .frame(width: Theme.sidebarWidth)

                Rectangle()
                    .fill(Theme.divider)
                    .frame(width: 1)

                ZStack {
                    VisualEffectBackground(material: .contentBackground)

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
                            AboutSettingsView(model: model)
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
            // Clears the traffic lights, which sit in the transparent titlebar.
            StatusPill(status: model.status)
                .padding(.horizontal, Theme.sidebarInset)
                .padding(.top, 46)
                .padding(.bottom, 12)

            SidebarButton(page: .general, selection: $selection)

            SidebarSection(title: "Remote") {
                SidebarButton(page: .connection, selection: $selection)
                SidebarButton(page: .controls, selection: $selection)
            }

            SidebarSection(title: "Support") {
                SidebarButton(page: .diagnostics, selection: $selection)
            }

            Spacer()

            SidebarSection(title: "Remote Bridge") {
                SidebarButton(page: .about, selection: $selection)
            }
            .padding(.bottom, 14)
        }
        .background(VisualEffectBackground(material: .sidebar))
    }
}

private struct StatusPill: View {
    let status: BridgeStatus

    private var tint: Color {
        switch status {
        case .ready: .green
        case .waitingForRemote, .needsPermission: .orange
        case .unsupported, .failed: .red
        case .paused: .secondary
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

            Text(status.title)
                .font(.system(size: 11.5, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .layoutPriority(1)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 30)
        .background(Theme.cardFill, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.cardStroke, lineWidth: 1)
        }
    }
}

private struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.sidebarInset + 8)
                .padding(.top, 14)
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
            .padding(.horizontal, 8)
            .frame(height: 34)
            .background {
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(selection == page ? Theme.selectionFill : .clear)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.sidebarInset)
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
        .cardSurface()
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
            .fill(Theme.divider)
            .frame(height: 1)
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
                            Slider(value: $model.pointerSensitivity, in: 0.4...2.0, step: 0.1)
                                .frame(width: 118)
                            Text(String(format: "%.1f×", model.pointerSensitivity))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 42, alignment: .trailing)
                        }
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

                SectionLabel(title: "Setup")

                SettingsCard {
                    ChecklistRow(
                        title: "Connect this Mac to your TV with an HDMI cable",
                        complete: model.connectionState == .running
                    )
                    CardDivider()
                    ChecklistRow(
                        title: "Switch the TV to that HDMI input",
                        complete: model.connectionState == .running
                    )
                    CardDivider()
                    ChecklistRow(
                        title: "Turn on HDMI-CEC in the TV's settings",
                        complete: model.connectionState == .running
                    )
                }

                Label(
                    "TV makers rename HDMI-CEC: Samsung calls it Anynet+, LG SimpLink, "
                        + "Sony Bravia Sync, Philips EasyLink.",
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

private struct ConnectionHero: View {
    @ObservedObject var model: BridgeModel

    private var tint: Color {
        switch model.status {
        case .ready: .green
        case .waitingForRemote, .needsPermission: .orange
        case .paused: .gray
        case .unsupported, .failed: .red
        }
    }

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: model.status.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(model.status.title)
                    .font(.system(size: 14, weight: .semibold))
                Text(model.status.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if model.status == .needsPermission {
                Button("Allow…") { model.requestAccessibility() }
                    .controlSize(.small)
            } else {
                Button("Reconnect") { model.reconnect() }
                    .controlSize(.small)
            }
        }
        .padding(14)
        .cardSurface()
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
                }

                SectionLabel(title: "Center")

                SettingsCard {
                    MappingEditorRow(button: .center, model: model)
                    CardDivider()
                    MappingEditorRow(button: .centerDouble, model: model)
                    CardDivider()
                    MappingEditorRow(button: .centerHold, model: model)
                }

                SectionLabel(title: "Back")

                SettingsCard {
                    MappingEditorRow(button: .back, model: model)
                    CardDivider()
                    MappingEditorRow(button: .doubleBack, model: model)
                }

                Label(
                    "Volume, media and Home never reach the Mac — displays handle those "
                        + "themselves and never put them on the CEC bus.",
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

            Button {
                model.resetAction(for: button)
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Reset to default")
            .opacity(model.isDefaultAction(for: button) ? 0 : 1)
            .disabled(model.isDefaultAction(for: button))
            .frame(width: 16)
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
                LiveActivityCard(model: model)

                SectionLabel(title: "System Status")

                SettingsCard {
                    SettingRow(title: "Remote signal") {
                        StatusBadge(
                            text: model.connectionState == .running ? "Receiving" : "None yet",
                            color: model.connectionState == .running ? .green : .orange
                        )
                    }
                    CardDivider()
                    SettingRow(title: "Accessibility") {
                        StatusBadge(
                            text: model.accessibilityGranted ? "Allowed" : "Required",
                            color: model.accessibilityGranted ? .green : .orange
                        )
                    }
                }

                SectionLabel(title: "Events")

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
                .background(Theme.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(Theme.cardStroke)
                }
            }
        }
    }
}

/// Shows the most recent button and what it did. Replaces the old mock remote —
/// any CEC display can be paired here, so we cannot draw a specific handset.
private struct LiveActivityCard: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        SettingsCard {
            HStack(spacing: 14) {
                SymbolTile(
                    symbol: model.lastButton?.symbol ?? "dot.radiowaves.left.and.right",
                    tint: model.lastButton == nil ? .gray : .accentColor,
                    size: 38
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.lastButton?.title ?? "Waiting for a button")
                        .font(.system(size: 14, weight: .semibold))

                    if let button = model.lastButton {
                        Text(model.action(for: button).title)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Press any button on your TV remote.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(model.buttonEventCount)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("events")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .animation(.snappy(duration: 0.22), value: model.buttonEventCount)
        }
        .padding(.top, 14)
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


struct AboutSettingsView: View {
    @ObservedObject var model: BridgeModel

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.3"
    }

    var body: some View {
        PageShell(page: .about) {
            VStack(alignment: .leading, spacing: 0) {


                SettingsCard {
                    SettingRow(title: "Remote Bridge") {
                        Text("Version \(version)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    CardDivider()
                    SettingRow(
                        title: "Connected display",
                        subtitle: model.displayName ?? "No CEC display detected yet"
                    ) {
                        Image(systemName: "display")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 14)

                SectionLabel(title: "How it works")

                SettingsCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A tiny native bridge between HDMI-CEC and macOS.")
                            .font(.system(size: 13, weight: .semibold))
                        Text("It listens through the Mac’s built-in HDMI-CEC service and translates TV remote buttons into pointer, browser, and media actions—without extra hardware.")
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


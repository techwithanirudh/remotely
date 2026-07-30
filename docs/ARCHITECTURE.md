# Architecture

## The shape

Two targets. `RemoteKit` is the whole behaviour of the app and imports no UI
framework; `RemoteBridge` is the window, the menu bar item and the guide. The
split is not tidiness. It is what makes the rules testable, because every
interesting decision happens in a type that can be driven from a test without
a screen, a remote, or a TV.

Folders group by feature rather than by type. A screen's pane, its model and
its primitives sit together, so a file's path says what it belongs to instead
of what kind of thing it is.

```
Sources/RemoteKit          the core
  CEC/                     transport and parsing
  Input/                   synthesis, gesture timing, the glide curve
  Model/                   buttons, actions, bindings, key combinations
Sources/RemoteBridge       the app
  App/                     lifecycle, windows, menu bar
  Settings/
    Models/                 settings state and persistence models
    SettingsPanes/          one settings pane per file
  UI/                      reusable presentation code
    RemoteBridgeUI/         product-specific UI primitives
    Modifiers/              reusable SwiftUI modifiers
    Utilities/              UI-only styling helpers
    Views/                  composed and transient views
  Utilities/               small reusable non-UI helpers
  Onboarding/              first run
Tests/RemoteKitTests       one file per behaviour
```

`UI/RemoteBridgeUI` holds this app's own primitives. Add `UI/Shapes` only when
the app owns a real reusable `Shape`. Empty folders and wrapper-only abstractions do not improve the
architecture. Root `Utilities` is not a miscellaneous core folder. It must not
own app state, input synthesis, gesture timing, or CEC work.

## How a button press becomes a click

```
remote -> TV -> HDMI-CEC -> corercd -> CECLink -> GestureReader -> RemoteBridge -> InputSynthesizer -> CGEvent
```

**`CECLink`** owns the transport. macOS keeps the CEC bus inside the `corercd`
daemon, and its private CoreRC XPC service refuses bus enumeration to
third-party clients. `queryBusesAsync:` answers `NSOSStatusErrorDomain -6773`,
so no HID events are ever routed to this process. What the daemon does do is
log every frame, so the link runs `log stream` against it and reads the output.
This is the single most important fact about the codebase: the framework path
is a dead end, and a previous rewrite that "fixed" it by going back to CoreRC
broke remote detection completely.

**`CECLogParser`** turns a line into an event. It is a plain struct with one
pure function, which is why it is the best-tested thing here.

These boundaries hold through any reorganization:

- `RemoteKit/CEC/CECLink.swift` owns process launch, unified-log streaming, and
  transport lifecycle.
- `RemoteKit/CEC/CECLogParser.swift` owns pure line parsing and CEC event
  decoding.
- Neither file moves to `Utilities`, `RemoteBridge`, settings code, or UI.
- UI and settings consume decoded state. They never read `corercd`, parse log
  lines, or construct transport commands.

**`GestureReader`** turns events into buttons. CEC has no concept of a double
tap or a hold: a key repeats while held and ends with a single release that
carries no key code, so taps, double taps, holds and dropped releases all have
to come out of timing. It is a pure struct driven by `press`, `release` and
`elapse`, holding no timers and making no system calls, so a whole gesture can
be played out in a test in microseconds.

Two consequences worth knowing:

- A single Back is withheld until the double-tap window closes, because
  Back-twice has to win. That wait is paid on every Back press.
- Arrows glide only actions that have a direction. Anything else bound to an
  arrow fires once on key down, or binding Show Desktop to an arrow would do
  nothing at all.

**`RemoteBridge`** owns the clock, the bindings and the log, and is the only
`@MainActor` `ObservableObject` the UI observes.

**`InputSynthesizer`** posts the events. Everything it posts carries
`EventSignature.value` in `kCGEventSourceUserData`, which is how onboarding's
practice steps can tell a remote press from the user's own mouse. Correlating
by timestamp would only ever be a guess.

## Things that look wrong and are not

**Timers are added to `RunLoop.main` in `.common` mode.** An open menu spins a
nested tracking run loop, and a timer scheduled the ordinary way stops firing
while it is up, which froze the pointer mid-glide. A custom lint rule now bans
`Timer.scheduledTimer` so this cannot come back.

**Show Desktop and Mission Control go through the window server.** They are
symbolic hot keys, not key presses, and both of the system's bindings carry the
fn bit. Posting F11 or control-Up alone matches nothing and is swallowed.
`SymbolicHotKey` reads the live binding out of SkyLight before posting, so a
user who rebinds them still gets what they asked for.

**Back and Forward dispatch per app.** There is no single method that works
everywhere; see `NavigationMethod`, which is derived from Mac Mouse Fix and
carries their licence rather than this repository's.

## The design values are measured

Nothing in `Theme` is chosen by eye. Reference windows are captured with
`screencapture -o -l <window-id>` and sampled pixel by pixel, and the numbers
in the comments are the readings. When something looks wrong, measure it again
rather than nudging the constant.

Two SwiftUI traps are already paid for and recorded in `AGENTS.md`: the page
title has to be a `safeAreaBar` rather than a `safeAreaInset`, and an overlay
applied after `.ignoresSafeArea()` is laid out inside the safe area.

## Testing

The suite is a plain executable rather than XCTest, because Command Line Tools
ships neither XCTest nor swift-testing, and swift-testing conflicts with
Defaults over swift-syntax. `Expect` is forty lines. One file per behaviour,
called in order from `main.swift`.

What is tested is the part that can be: gesture timing, binding resolution and
round-tripping, the glide curve's shape, key-combination encoding, status
precedence, the CEC parser, the per-app navigation table. The AppKit and
SwiftUI layers are deliberately untested. The same split alt-tab-macos calls
the Humble Object pattern.

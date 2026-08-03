# Architecture

## The shape

Two targets. `RemotelyKit` is the UI-free CEC, input, and domain core;
`Remotely` is the TCA feature layer, windows, menu bar item, and guide. The
split is not tidiness. It is what makes the rules testable, because every
interesting decision can be driven from a reducer or a pure type without a
screen, a remote, or a TV.

Folders group by feature rather than by type. A screen's pane, its model and
its primitives sit together, so a file's path says what it belongs to instead
of what kind of thing it is.

```
Sources/RemotelyKit          the core
  CEC/                     transport and parsing
  Input/                   synthesis, gesture timing, the glide curve
  Model/                   buttons, actions, bindings, key combinations
Sources/Remotely             the app
  App/                       lifecycle, windows, menu bar
  Clients/                  live AppKit/CEC dependency adapters
  Features/
    App/                    root composition
    Remote/                 remote state, actions, effects
    Settings/               settings state and settings views
    Onboarding/             first-run state and onboarding views
  Models/                   app-facing models
  Utilities/                small non-UI helpers and measured styling
  Views/                    shared presentation and product UI primitives
Tests/RemotelyKitTests       one file per behaviour
```

`Features` follows Void's shape: each feature owns its reducer, state, actions,
and views. `Clients` owns side effects and translates the proven runtime into
dependency values. `Views/RemotelyUI` holds this app's own reusable primitives.
Empty folders and wrapper-only abstractions do not improve the architecture.
`Utilities` must not own app state, input synthesis, gesture timing, or CEC
work.

## How a button press becomes a click

```
remote -> TV -> HDMI-CEC -> corercd -> CECLink -> GestureReader -> RemoteClient -> RemoteFeature -> InputSynthesizer -> CGEvent
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

- `RemotelyKit/CEC/CECLink.swift` owns process launch, unified-log streaming, and
  transport lifecycle.
- `RemotelyKit/CEC/CECLogParser.swift` owns pure line parsing and CEC event
  decoding.
- Neither file moves to `Utilities`, `Remotely`, settings code, or UI.
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

**`RemoteFeature`** owns the app-facing state, bindings, log, lifecycle actions,
and effects. **`RemoteClient`** is the dependency boundary around the existing
remote runtime, so the reducer does not own processes, timers, or AppKit
objects. This is the same State/Action/Reducer/Store shape used by Void.

The dependency surface lives in `Clients/RemoteClient.swift` and its live
runtime in `Clients/RemoteClientLive.swift`, but their CEC and
input algorithm boundaries remain deliberately intact. Those are the parts
that have been proven against macOS's `corercd` path; replacing them is a
separate hardware-risky change, not a folder reorganization.

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

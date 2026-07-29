# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
swift build                                   # library + app
swift run RemoteKitTests                      # the whole suite
zsh scripts/build-app.sh [release|debug]      # writes build/Remote Bridge.app
swift scripts/make-icon.swift <iconset> [tilt] [inset]
iconutil -c icns build/AppIcon.iconset -o resources/AppIcon.icns
```

Tests are a plain executable, not XCTest: Command Line Tools ships neither
XCTest nor swift-testing, and swift-testing conflicts with Defaults over
swift-syntax. There is no single-test runner — `Expect.suite` blocks in
`Sources/RemoteKitTests/main.swift` run top to bottom. Comment out suites to
narrow a run.

Installing means replacing `/Applications/Remote Bridge.app`. The build is
ad-hoc signed, so its signature changes every time and macOS revokes
Accessibility; the app detects a new build and re-asks. Do not write to the
app's live `Defaults` to shortcut into a UI state — it destroys real user
state.

## Architecture

`RemoteKit` is the core and has no UI. `RemoteBridge` is the app. The split is
what makes the rules testable, so keep timing, bindings and event synthesis out
of the views.

**CEC transport — do not "fix" this.** macOS owns the CEC bus inside `corercd`.
Its private CoreRC XPC service refuses bus enumeration to third parties
(`queryBusesAsync:` → `NSOSStatusErrorDomain -6773`), and without a bus object
the daemon routes no HID events here. The only path that works is parsing the
unified log (`CECLink` + `CECLogParser`). A previous rewrite reinstated the
framework approach and broke remote detection entirely.

**Event flow.** `CECLink` → `GestureReader` → `RemoteBridge` → `InputSynthesizer`.
`GestureReader` is a pure struct driven by `press`/`release`/`elapse`, with no
timers or system calls, which is why the gesture rules can be tested directly.
`RemoteBridge` owns the clock and the bindings.

- CEC repeats a key while it is held and sends one release carrying no key
  code, so taps, double taps and holds all come out of timing.
- A single Back is withheld until the double-tap window closes, because
  Back-twice has to win. That wait is paid on every Back press.
- Arrow buttons only glide actions that have a direction; anything else bound
  to an arrow fires once on key down (`beginHold`), or it would do nothing.

**Posted events** carry `EventSignature.value` in `kCGEventSourceUserData`.
That is how onboarding's practice steps tell a remote press from the user's own
mouse; correlating by timestamp would only ever be a guess.

**Show Desktop and Mission Control** are window-server symbolic hot keys, not
plain key presses. Both of the system's bindings carry the fn bit, so posting
F11 or control-Up alone matches nothing. `SymbolicHotKey` reads the live
binding out of SkyLight before posting.

**Timers** must be added to `RunLoop.main` in `.common` mode. An open menu
spins a nested tracking loop and starves anything scheduled the ordinary way,
which freezes the pointer mid-glide.

## UI

The design target is Alcove.app, and its numbers are measured rather than
guessed — capture a window with `screencapture -o -l <id>` and sample pixels.
Established values: material `.titlebar` (233,235,235 light / 86,88,88 dark
against Alcove's 232,235,236 and 85,87,88), card fill white at 52% light,
card edge black at 16%, sidebar rows 38pt, window radius 26. The glass stays
`.active` when the window loses focus and the content dims instead, which is
what Alcove does.

Two SwiftUI traps already hit here:

- The page title must be a `safeAreaBar`, not a `safeAreaInset`. Only the bar
  extends the scroll edge effect into itself; as an inset the blur sits at the
  top of the content and cuts across the page.
- An overlay applied after `.ignoresSafeArea()` is laid out *inside* the safe
  area. That put the window's lit top edge 32pt down as a bar across the whole
  window.

Action pickers stay on `Picker`. A grouped `Menu` was tried and half its items
did not register.

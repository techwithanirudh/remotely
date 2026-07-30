# Working in this repo

## The one rule

Every task goes in `TODO.md` before it is started, however small, and is
deleted from `TODO.md` when it is done. If it is not written down it is not
being worked on.

## Before committing

```sh
zsh scripts/lint.sh     # formats, then lints
swift build
swift run RemoteKitTests
```

`scripts/lint.sh --check` is the read-only version CI runs.

## Comments

The linter and the formatter enforce style, so comments do not have to.
Write one only for something the code cannot say: why a value was measured
rather than chosen, why an obvious approach was rejected, what a private API
does. Never restate what the next line does.

## Commits

Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.

## Commands

```sh
swift build
swift run RemoteKitTests                 # the whole suite; there is no single-test runner
zsh scripts/build-app.sh                 # writes build/Remote Bridge.app
zsh scripts/capture-cec.sh 20            # records a CEC session for a fixture
swift scripts/make-icon.swift <iconset> [tilt] [inset]
```

Tests are a plain executable, not XCTest: Command Line Tools ships neither
XCTest nor swift-testing, and swift-testing conflicts with Defaults over
swift-syntax.

Installing means replacing `/Applications/Remote Bridge.app`. The build is
ad-hoc signed, so macOS revokes Accessibility every time. Never write to the
app's live `Defaults` to shortcut into a UI state.

## Architecture

`RemoteKit` is the core and has no UI. `RemoteBridge` is the app. Keep timing,
bindings and event synthesis out of the views — that split is what makes the
rules testable.

**CEC transport — do not "fix" this.** macOS owns the CEC bus inside `corercd`,
and its private CoreRC XPC service refuses bus enumeration to third parties
(`queryBusesAsync:` → `NSOSStatusErrorDomain -6773`). Parsing the unified log
is the only path that works. A previous rewrite reinstated the framework
approach and broke remote detection entirely.

`CECLink` → `GestureReader` → `RemoteBridge` → `InputSynthesizer`.
`GestureReader` is a pure struct driven by `press`/`release`/`elapse`.

- CEC repeats a key while held and sends one release with no key code, so taps,
  double taps and holds all come out of timing.
- A single Back waits out the double-tap window, on every press.
- Arrows glide only actions with a direction; the rest fire on key down.
- Posted events carry `EventSignature.value` in `kCGEventSourceUserData`, which
  is how onboarding tells a remote press from the user's own mouse.
- Show Desktop and Mission Control are window-server symbolic hot keys whose
  bindings carry the fn bit; `SymbolicHotKey` reads them live before posting.
- Timers go on `RunLoop.main` in `.common` mode, or an open menu starves them.

## UI

Values are measured off Alcove and Klack, not chosen: capture a window with
`screencapture -o -l <id>` and sample pixels. Window material is
`.underWindowBackground` in front and `.contentBackground` behind; cards lift
the ground 5% with a 16% edge; sidebar rows are 38pt; window radius 26.

- The page title must be a `safeAreaBar`, not a `safeAreaInset` — only the bar
  extends the scroll edge effect into itself.
- An overlay applied after `.ignoresSafeArea()` lays out inside the safe area.
- Action pickers stay on `Picker`; a grouped `Menu` dropped half its items.

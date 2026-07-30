# Working in this repo

## The one rule

Every task goes in `TODO.md` before it is started, however small, and is
deleted from `TODO.md` when it is done. If it is not written down it is not
being worked on.

## Before committing

```sh
swiftformat .
swiftlint
swift build
swift run RemoteKitTests
```

The pre-commit hook runs the first two on staged files, so this is only for
checking before you get there. CI pins SwiftLint 0.65.0 and SwiftFormat 0.62.1
from their release binaries; match those with
`brew install swiftlint swiftformat`.

Without a full Xcode, SwiftLint cannot find `sourcekitd` and dies on startup.
Point it at the Command Line Tools copy once, in your shell profile:

```sh
export TOOLCHAIN_DIR=$(xcode-select -p)
```

## Comments

The linter and the formatter enforce style, so comments do not have to.
Write one only for something the code cannot say: why a value was measured
rather than chosen, why an obvious approach was rejected, what a private API
does. Never restate what the next line does.

## Borrowed research

`NavigationMethod` and `NavigationSwipe` follow Mac Mouse Fix's per-app Back
and Forward table and its gesture event. Their source is Objective-C wired into
five of their own classes, so this is a port rather than a copy, and the MMF
License attaches its conditions to publishing. Re-read it before this app ever
ships.

Keep their compatibility strategy intact: non-Apple apps default to mouse
buttons 4 and 5 at the session event tap, Apple apps default to navigation
swipes, and named exceptions use their menu shortcuts. Finder is a measured
exception on this Mac and uses Command-bracket. Do not collapse the table to a
single shortcut without repeating the live Aside, Finder, and System Settings
tests.

## Commits

Conventional Commits, enforced by a hook: `feat:`, `fix:`, `refactor:`,
`docs:`, `chore:`, `ci:`, `perf:`, `style:`, `test:`, `build:`, `revert:`.
Subject lowercase, 80 characters or less.

Hooks live in `.githooks` rather than a package manager, so there is nothing
to install beyond one line per clone:

```sh
git config core.hooksPath .githooks
```

## Commands

```sh
swift build
swift run RemoteKitTests                 # the whole suite; there is no single-test runner
zsh scripts/build-app.sh                 # writes build/Remote Bridge.app
zsh scripts/capture-cec.sh 20            # records a CEC session for a fixture
zsh scripts/analyze.sh                   # SwiftLint's analyzer rules, needs a clean build
```

Tests are a plain executable, not XCTest: Command Line Tools ships neither
XCTest nor swift-testing, and swift-testing conflicts with Defaults over
swift-syntax.

Installing means replacing `/Applications/Remote Bridge.app`. The build is
ad-hoc signed, so macOS revokes Accessibility every time. Never write to the
app's live `Defaults` to shortcut into a UI state.

## Architecture

`RemoteKit` is the core and has no UI. `RemoteBridge` is the app. Keep timing,
bindings and event synthesis out of the views. That split is what makes the
rules testable.

Use [thaw-app/Thaw](https://github.com/thaw-app/Thaw) at commit
`97f3afd4c1a251bc79a131c0afc68f3dc402b14c` as the canonical organization
reference. Thaw is the maintained fork of Ice. Adapt its names to Remote Bridge
instead of copying product-specific names:

- `Settings/Models` contains settings state and persistence models.
- `Settings/SettingsPanes` contains one settings pane per file.
- `UI` contains reusable presentation code.
- `UI/RemoteBridgeUI` contains Remote Bridge-specific UI primitives, matching
  Thaw's `UI/IceUI` role.
- `UI/Modifiers`, `UI/Utilities`, and `UI/Views` match Thaw's reusable UI
  boundaries. Add `UI/Shapes` only for an actual reusable `Shape`.
- `Utilities` contains small, reusable non-UI helpers that do not own app state,
  input synthesis, gesture timing, or CEC.

Folder cleanup must not blur the core boundary. `CECLink` and `CECLogParser`
stay in `RemoteKit/CEC`. Transport process ownership, unified-log streaming,
line parsing, and CEC event decoding must not move into `Utilities`, app
lifecycle code, settings models, or UI.

**CEC transport: do not "fix" this.** macOS owns the CEC bus inside `corercd`,
and its private CoreRC XPC service refuses bus enumeration to third parties
(`queryBusesAsync:` returns `NSOSStatusErrorDomain -6773`). Parsing the unified log
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

- The page title must be a `safeAreaBar`, not a `safeAreaInset`. Only the bar
  extends the scroll edge effect into itself.
- An overlay applied after `.ignoresSafeArea()` lays out inside the safe area.
- Action pickers stay on `Picker`; a grouped `Menu` dropped half its items.

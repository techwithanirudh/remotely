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
swift run RemotelyKitTests
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
swift run RemotelyKitTests                 # the whole suite; there is no single-test runner
zsh scripts/build-app.sh                 # writes build/Remotely.app
zsh scripts/capture-cec.sh 20            # records a CEC session for a fixture
zsh scripts/analyze.sh                   # SwiftLint's analyzer rules, needs a clean build
```

Tests are a plain executable, not XCTest: Command Line Tools ships neither
XCTest nor swift-testing, and swift-testing conflicts with Defaults over
swift-syntax.

Sparkle is linked by SwiftPM but not embedded by it, so `build-app.sh` copies
`Sparkle.framework` into `Contents/Frameworks`, and the app target carries an
`@executable_path/../Frameworks` rpath. Nested code is signed before its
container.

Sign with a stable identity, not ad-hoc. Accessibility is granted against the
designated requirement, and the two differ:

- ad-hoc puts the binary hash in it, measured changing from
  `cdhash H"eed024..."` to `cdhash H"e5f28c..."` across one version bump, so
  macOS treats every build as a new app and drops the grant
- a self-signed certificate puts the certificate in it,
  `identifier "com.anirudh.remotely" and certificate root = H"13f1de..."`,
  unchanged across the same bump

`build-app.sh` uses `CODESIGN_IDENTITY`, defaulting to `Remotely Self Signed`,
and warns then falls back to ad-hoc when that identity is missing. Notarization
is unrelated: it silences Gatekeeper on first launch and needs a paid account.

Every workflow action is pinned to a 40-character commit SHA with the tag in a
trailing comment, so a moved tag cannot change what runs.

Releases are documented in `docs/RELEASING.md`, verification in
`docs/VERIFYING_RELEASES.md`. Signing material lives in the login keychain
and in repo secrets, never in the working copy.

Installing means replacing `/Applications/Remotely.app`. The build is
ad-hoc signed, so macOS revokes Accessibility every time. Never write to the
app's live `Defaults` to shortcut into a UI state.

## Architecture

`RemotelyKit` is the UI-free core and `Remotely` is the app. `Remotely` follows
Void's TCA shape: `Features` own state/actions/reducers and `Clients` own live
side effects. Keep timing, bindings, persistence, and event synthesis out of
the views. That split is what makes the rules testable.

Folders group by feature, not by type, so everything a screen needs sits
together and a file's path says what it belongs to rather than what it is:

- `Features/Settings/Views` holds one settings pane per file.
- `Features/Onboarding/Views` holds the onboarding steps and primitives.
- `Views/RemotelyUI` holds this app's own primitives; `Views/Modifiers` holds
  reusable SwiftUI modifiers.
- `Clients` holds dependency clients such as the CEC/runtime and Sparkle
  updates.
- `Models` holds app-facing models; `Utilities` holds small non-UI helpers.

Folder cleanup must not blur the core boundary. `CECLink` and `CECLogParser`
stay in `RemotelyKit/CEC`. Transport process ownership, unified-log streaming,
line parsing, and CEC event decoding must not move into `Utilities`, app
lifecycle code, settings models, or UI.

**CEC transport: do not "fix" this.** macOS owns the CEC bus inside `corercd`,
and its private CoreRC XPC service refuses bus enumeration to third parties
(`queryBusesAsync:` returns `NSOSStatusErrorDomain -6773`). Parsing the unified log
is the only path that works. A previous rewrite reinstated the framework
approach and broke remote detection entirely.

`CECLink` → `GestureReader` → `RemoteClient` → `RemoteFeature` →
`InputSynthesizer`.
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

Values in `Theme` are measured, not chosen: capture a window with
`screencapture -o -l <id>` and sample pixels. Window material is
`.underWindowBackground` in front and `.contentBackground` behind; cards lift
the ground 5% with a 16% edge; sidebar rows are 38pt; window radius 26.

- The page title must be a `safeAreaBar`, not a `safeAreaInset`. Only the bar
  extends the scroll edge effect into itself.
- An overlay applied after `.ignoresSafeArea()` lays out inside the safe area.
- Action pickers stay on `Picker`; a grouped `Menu` dropped half its items.

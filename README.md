<h1 align="center">Remote Bridge</h1>

<p align="center">
  <img alt="Requirements" src="https://img.shields.io/badge/macOS-15%2B-555555?style=flat-square" />
  <a href="https://github.com/techwithanirudh/remote-bridge/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/techwithanirudh/remote-bridge/ci.yml?style=flat-square&label=CI" /></a>
  <img alt="Tests" src="https://img.shields.io/badge/checks-80-555555?style=flat-square" />
</p>

<p align="center">
  <b>Your TV remote becomes a pointer for your Mac, over the HDMI cable you already have.<br />
  No dongle, no extra hardware, nothing to plug in.</b>
</p>

<p align="center">
  <a href="#what-the-buttons-do">Buttons</a> ·
  <a href="#setup">Setup</a> ·
  <a href="#build">Build</a> ·
  <a href="docs/ARCHITECTURE.md">Architecture</a>
</p>

<p align="center">
  <img alt="Remote Bridge settings" src=".github/cover.png" width="800" />
</p>

## Why Remote Bridge

- **Nothing to buy.** It uses the HDMI cable already carrying your picture, and the remote already in your hand.
- **Every button is yours.** Point, scroll, click, right click, Escape, Show Desktop, Mission Control, Back, Forward, or a keyboard shortcut you record.
- **Nothing leaves your Mac.** No account, no network, no analytics.

## Features

- **Move the pointer with the D-pad**: tap to nudge, hold to glide, accelerating the longer you hold
- **Click without a mouse**: press Center to click, twice to double click, hold for a right click
- **Scroll with the same arrows**: press Back twice to switch modes, with a chip beside the pointer showing which you are in
- **Rebind anything**: twenty actions grouped by kind, including recorded keyboard shortcuts

## What the buttons do

| Button | Default |
| --- | --- |
| D-pad, tapped | Nudges the pointer a few pixels |
| D-pad, held | Glides, accelerating the longer you hold |
| Center | Left click |
| Center, twice | Double click |
| Center, held | Right click |
| Back | Back |
| Back, twice | Switches the arrows between moving and scrolling |
| Back, held | Forward |

Volume, media and Home never reach the Mac. Displays handle those themselves
and keep them off the CEC bus.

## Setup

1. Connect the Mac to the display over HDMI and switch to that input.
2. Turn on HDMI-CEC in the display's settings. Every maker renames it: Anynet+
   on Samsung, SimpLink on LG, Bravia Sync on Sony. **Connection** has the menu
   path for eight brands.
3. Grant Accessibility under System Settings, Privacy & Security.

The first run walks through all of it and has you practise each gesture, so you
find out the remote works before you rely on it.

## Build

```sh
swift build
swift run RemoteKitTests     # 80 checks
swiftformat . && swiftlint   # needs TOOLCHAIN_DIR, see AGENTS.md
zsh scripts/build-app.sh     # writes build/Remote Bridge.app
```

| Path | What lives there |
| --- | --- |
| `Sources/RemoteKit` | The core, with no UI: CEC transport and parsing, gesture rules, the glide curve, input synthesis, bindings |
| `Sources/RemoteBridge` | The app: menu bar item, settings window, onboarding |
| `Tests/RemoteKitTests` | A plain executable, since Command Line Tools ships neither XCTest nor swift-testing |

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the architecture.

## License

MIT. See [LICENSE](LICENSE).

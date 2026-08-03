<h1 align="center">Remotely</h1>

<p align="center">
  <img alt="Requirements" src="https://img.shields.io/badge/macOS-15%2B-555555?style=flat-square" />
  <a href="https://github.com/techwithanirudh/remotely/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/techwithanirudh/remotely/ci.yml?style=flat-square&label=CI" /></a>
  <img alt="Tests" src="https://img.shields.io/badge/checks-89-555555?style=flat-square" />
</p>

<p align="center">
  <b>Turns your display's remote into a mouse.</b>
</p>

<p align="center">
  <a href="#features">Features</a> ·
  <a href="#buttons">Buttons</a> ·
  <a href="#setup">Setup</a> ·
  <a href="#build">Build</a> ·
  <a href="#resources">Resources</a> ·
  <a href="#license">License</a>
</p>

<p align="center">
  <img alt="Remotely settings" src=".github/cover.png" width="800" />
</p>

## Features

- **Scroll with the same arrows**, with a chip beside the pointer showing the mode
- **Rebind anything**: twenty actions grouped by kind, including recorded keyboard shortcuts
- **Nothing leaves your Mac**: no account, no network, no analytics

## Buttons

| Button | Default |
| --- | --- |
| D-pad, tapped | Nudges the pointer a few pixels |
| D-pad, held | Glides, accelerating the longer you hold |
| Center | Left click |
| Center, twice | Double click |
| Center, held | Right click |
| Back | Back |
| Back, twice | Switches the arrows between moving and scrolling |
| Back, held | Yours to bind |

## Setup

1. Connect the Mac to the display over HDMI and switch to that input.
2. Turn on HDMI-CEC in the display's settings.
3. Grant Accessibility under System Settings, Privacy & Security.

The first run walks through all of it and has you practise each gesture, so you
find out the remote works.

## Build

```sh
swift build
swift run RemotelyKitTests     # 89 checks
swiftformat . && swiftlint   # needs TOOLCHAIN_DIR, see AGENTS.md
zsh scripts/build-app.sh     # writes build/Remotely.app
```

| Path | What lives there |
| --- | --- |
| `Sources/RemotelyKit` | The core, with no UI: CEC transport and parsing, gesture rules, the glide curve, input synthesis, bindings |
| `Sources/Remotely` | The app: menu bar item, settings window, onboarding |
| `Tests/RemotelyKitTests` | A plain executable, since Command Line Tools ships neither XCTest nor swift-testing |

## Resources

- [Architecture](docs/ARCHITECTURE.md)
- [Releasing](docs/RELEASING.md)
- [Contributing](CONTRIBUTING.md)
- [What is next](TODO.md)

## License

MIT. See [LICENSE](LICENSE).

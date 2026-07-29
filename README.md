# Remote Bridge

A macOS menu bar app that turns your TV remote into a pointer for your Mac,
over the HDMI cable you already have. Press the D-pad and the pointer moves;
press Center and it clicks. No dongle, no extra hardware.

Requires macOS 15 or later, a Mac with an HDMI port, and a display that
forwards remote buttons over HDMI-CEC.

## How it works

macOS owns the CEC bus inside the `corercd` daemon. Its private CoreRC XPC
service refuses bus enumeration to third-party clients — `queryBusesAsync:`
answers `NSOSStatusErrorDomain -6773` — so the daemon routes no HID events to
this app. What it does do is log every button on the bus, so Remote Bridge
reads the unified log:

```
log stream --predicate 'process == "corercd"' --debug --style compact
```

Lines carrying `<User Control Pressed> XX` give the CEC wire code; the app maps
those to buttons and posts the corresponding `CGEvent`. Every event it posts is
stamped with a signature in `kCGEventSourceUserData`, which is how the practice
steps in onboarding can tell a remote press from your own mouse.

This is an experimental use of existing system components rather than a public
API. A macOS update could change it.

```
TV remote  →  TV (HDMI-CEC)  →  HDMI cable  →  Mac  →  corercd  →  Remote Bridge  →  pointer
```

## What the buttons do

| Button | Default action |
|---|---|
| D-pad, tapped | Nudges the pointer a few pixels |
| D-pad, held | Glides, accelerating the longer you hold |
| Center | Left click |
| Center, twice | Double click |
| Center, held | Right click |
| Back | Whatever you bind it to |
| Back, twice | Switches the arrows between moving and scrolling |

Every button can be reassigned from **Controls**, including to a keyboard
shortcut you record, Escape, Show Desktop or Mission Control. Volume, media and
Home never reach the Mac — displays handle those themselves and keep them off
the CEC bus.

## Setup

1. Connect the Mac to the display over HDMI and switch the display to that
   input.
2. Turn on HDMI-CEC in the display's settings. Every maker names it something
   else: Anynet+ on Samsung, SimpLink on LG, Bravia Sync on Sony. The app's
   **Connection** page has the menu path for each.
3. Grant Accessibility under System Settings → Privacy & Security.

The first run walks through all of it and has you practise each gesture, so you
find out the remote is working before you rely on it.

## Build

```sh
zsh scripts/build-app.sh          # builds build/Remote Bridge.app
swift run RemoteKitTests          # 55 checks
swift scripts/make-icon.swift build/AppIcon.iconset [tilt] [inset]
```

The build is ad-hoc signed, so macOS revokes Accessibility every time the
bundle is replaced. The app notices and asks for it again.

## Layout

- `Sources/RemoteKit` — the core, with no UI. CEC transport and log parsing,
  the gesture rules, the glide curve, input synthesis, and the binding model.
- `Sources/RemoteBridge` — the app: menu bar item, settings window, onboarding.
- `Sources/RemoteKitTests` — a plain executable rather than XCTest, because
  Command Line Tools ships neither XCTest nor swift-testing.

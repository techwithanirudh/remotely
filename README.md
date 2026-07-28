# M7 Remote Bridge

A polished native macOS menu-bar app that turns Samsung Smart Remote
HDMI-CEC button events into macOS pointer, click, browser, media, and volume
actions. It uses the M4 Mac mini's built-in HDMI-CEC hardware and macOS's
private CoreRC service. No USB-CEC adapter or paid software is required.

Version 0.6.1 adds a complete SwiftUI settings experience modeled after the
compact native design language used by Alcove and Klack: a vibrant glass
sidebar, inset grouped controls, colored SF Symbol tiles, translucent borders,
native switches and sliders, and a hidden-titlebar AppKit window.

The latest update adds a properly proportioned M70D SolarCell remote
visualizer with restrained glass controls and the four physical shortcut keys,
persistent per-button action pickers, normal macOS media keys, tighter layouts,
and a structured menu-bar menu with a live status header.

## Settings

Open **Settings…** from the menu-bar remote icon. The app includes:

- **General** — enable/disable the bridge, launch at login, Accessibility
  permission, pointer speed, and a pointer test.
- **Connection** — live native CEC status, reconnect, signal-path diagram, and
  HDMI/Anynet+ checklist.
- **Controls** — persistent action pickers for every useful remote button,
  including the double-Back gesture.
- **Diagnostics** — an interactive remote visualizer with live button glow,
  mapped-action readout, event count, offline previews, event log,
  permission/framework status, and action tests.
- **About** — setup-specific architecture and version information.

## What is proven on this Mac

- This is an **M4 Mac mini (Mac16,10)** connected to a Samsung **Smart M70D**.
- The current connection is **USB-C DisplayPort**, not HDMI.
- The remote is not visible to macOS as Bluetooth or USB HID while paired with
  the monitor.
- Apple officially lists the M4 Mac mini's built-in HDMI port as HDMI-CEC
  compatible.
- macOS 26 on this Mac includes and loads `IOCECFamily`, and its private CoreRC
  framework exposes CEC remote commands including Cursor Up/Down/Left/Right,
  Select, Back, Root Menu, Play/Pause, and volume.
- The app compiles and can connect to CoreRC. End-to-end button receipt cannot
  be verified until the M70D is physically connected to the Mac's HDMI port.

Apple's public documentation guarantees CEC display wake/sleep. Incoming remote
buttons through private CoreRC are an experimental use of existing system
components, not a public Apple API. A macOS update could change it.

## Zero-cost architecture

```text
Samsung SolarCell remote
          |
          v
Samsung M70D / Anynet+
          |
          v
ordinary HDMI cable
          |
          v
M4 Mac mini built-in HDMI CEC
          |
          v
macOS CoreRC -> M7 Remote Bridge -> pointer/keys
```

The M70D originally shipped with an HDMI cable in regions where Samsung lists
it as an included accessory. Any existing HDMI cable that carries your 4K/60
picture is enough; there is no special "CEC cable."

## Required physical test

1. Leave the USB-C cable connected if it carries the M7 USB hub or peripherals.
2. Connect the Mac mini's built-in HDMI port to **M70D HDMI 1**.
3. Switch the M70D picture source to HDMI 1.
4. On the M70D enable:

   **Home -> Settings -> All Settings -> Connection -> External Device Manager
   -> Anynet+ (HDMI-CEC)**

5. Open **M7 Remote Bridge**.
6. Grant Accessibility permission under:

   **System Settings -> Privacy & Security -> Accessibility**

7. The menu-bar status should change from “Waiting for HDMI” to “Connected.”
8. Press D-pad and Center. If Samsung forwards the commands, the pointer moves
   and clicks.

If both HDMI and USB-C appear as separate M70D displays in macOS, mirror the
USB-C display to the HDMI display. HDMI must remain the visible M70D input for
CEC; USB-C can stay connected for data.

To inspect the native CEC bus without granting Accessibility permission:

```sh
"M7 Remote Bridge.app/Contents/MacOS/M7RemoteBridge" --diagnose-cec
```

It listens for eight seconds and prints every native CEC device/button event.

## Button map

| Samsung remote | Default macOS action |
|---|---|
| Each D-pad direction | Move pointer, accelerating on repeats |
| Center | Left click |
| Back | Browser Back (`Command-[`) |
| Back twice | Show Desktop |
| Play/Pause | Normal macOS Play/Pause media key |
| Rewind / Fast-forward | Normal macOS media keys |
| Volume / Mute | macOS media keys if forwarded |

Every row can be reassigned to any available action or **Do Nothing**. Samsung
normally reserves Home for the monitor, so Home is intentionally omitted and
double-Back is the default Desktop gesture. Volume may also be handled directly
by the M70D rather than forwarded over CEC.

## Build

```sh
./scripts/test-parser.sh
./scripts/build-app.sh release
open "build/M7 Remote Bridge.app"
```

The app is locally/ad-hoc signed rather than Developer-ID notarized. If macOS
blocks the copied build, right-click the app and select **Open**.

## What if native HDMI receives no buttons?

First copy the recent CEC log from the menu-bar app. The likely failure points
are:

1. The M70D recognizes the Mac only for CEC wake/sleep and does not forward
   navigation keys.
2. Samsung reserves a particular button, especially Home or volume.
3. Apple's private CoreRC service enumerates the HDMI bus but restricts raw
   remote-event observation to Apple-signed clients.

If the bus appears but no button events arrive, there is no supported
software-only interface on either side that can recover those physical presses:

- The Tizen API receives keys only inside the active monitor app.
- Samsung network APIs send virtual keys *to* the monitor; they do not provide
  a physical-key event stream.
- Direct Bluetooth would require unpairing the remote from the M70D, and Samsung
  does not advertise the TM2360E SolarCell remote as a general-purpose macOS HID
  controller.

Direct Bluetooth pairing can still be tried as a second free experiment after
the HDMI test, but it may leave the remote temporarily disconnected from the
monitor and is less promising than native CEC.

## References

- Apple HDMI/CEC compatibility:
  <https://support.apple.com/en-ie/108928>
- Samsung M70D HDMI-CEC specification:
  <https://www.samsung.com/us/computing/monitors/smart-monitors/43-smart-monitor-m7-m70d-4k-uhd-with-streaming-tv-speakers-and-usb-c-white-ls43dm703unxza/>
- Samsung Anynet+ external-device control:
  <https://www.samsung.com/us/support/answer/ANS10006946/>
- Samsung Tizen remote input API:
  <https://developer.samsung.com/smarttv/develop/guides/user-interaction/remote-control.html>
- Apple Core Graphics event injection:
  <https://developer.apple.com/documentation/coregraphics/cgevent>

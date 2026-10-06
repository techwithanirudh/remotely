# Loop as a reference

[MrKai77/Loop](https://github.com/MrKai77/Loop) is a menu bar window manager
whose settings window is the closest thing to what Remotely wants: a sidebar of
tinted icon tabs, one pane per tab, cards of toggles and pickers. This page is
what was found comparing it to Remotely at Loop commit `995b1bd` (2026-10-05),
so nobody has to clone it again to answer "how did Loop do X".

## Licence first

Loop is **GPL-3.0**. Remotely is MIT. Pasting Loop source into this repo makes
the shipped app a GPL derivative, so "copy it directly" is off the table unless
the whole app goes GPL. Read it, learn the layout, write our own.

Luminare, the UI kit Loop's settings are built from
([MrKai77/Luminare](https://github.com/MrKai77/Luminare)), is **BSD-3-Clause**.
That one could be depended on or borrowed from with attribution. It is still a
`branch = main` dependency in Loop, with no tagged releases to pin to.

## Architecture side by side

| | Loop | Remotely |
| --- | --- | --- |
| Build | Xcode project, multiple targets (app, dock tile, privileged helper) | SwiftPM, `RemotelyKit` core + `Remotely` app |
| State | `ObservableObject` singletons (`SettingsWindowManager.shared`, `LoopManager.shared`, `Updater.shared`, about a dozen) | TCA `Feature`s with `@ObservableState` |
| Settings storage | Views read and write `@Default(.key)` directly | `SettingsFeature` / `RemoteFeature` state, pushed through `RemoteSettingsClient` |
| Side effects | Methods on the singletons, called from views and `AppDelegate` | `@DependencyClient` structs with live and test values |
| App entry | SwiftUI `App` with `MenuBarExtra` + `@NSApplicationDelegateAdaptor` | `AppCoordinator` translating delegate callbacks into `AppFeature` actions |
| Settings window | `LuminareWindow` inside an `NSWindowController`, created lazily, thrown away on close | Hand-built `NSWindow` in `SettingsWindowController`, kept alive |
| Settings UI | Luminare components (`LuminareSidebar`, `LuminarePane`, `LuminareSection`, `LuminareToggle`, `LuminareSliderPicker`, `LuminarePickerMenu`, `luminareModal`) | Our own `Card`, `Row`, `SectionLabel`, `SettingsPane`, stock `Toggle`/`Slider`/`Picker` |
| Tabs | `SettingsTab: LuminareTabItem`, each case owns title, SF symbol, tint colour, `view()` and an update badge | `SettingsPage` owns title, symbol, tint; `SettingsView.page(for:)` switches to the pane |
| Tests | swift-testing, 7 files, all on core logic (keybind resolution, cycles, gesture filter, screen order) | Plain executable, `RemotelyKitTests`, core only |
| Logging | Scribe `@Loggable` macro | None in the app yet |
| Updates | Its own updater (checker, downloader, privileged installer, changelog view) | Sparkle |
| Localisation | String catalogs, 10+ languages | English only |

### What that means

Loop is the classic "managers plus `@Default` in views" shape. It is quick to
write and each pane is self-contained: `BehaviorConfigurationView` declares the
fifteen `@Default` keys it touches and binds Luminare controls straight to
them. Nothing between the view and `UserDefaults`, so nothing to test either.

Remotely deliberately went the other way: the reducer owns the value and a
client applies it to `RemoteRuntime`. That costs more files per setting, but it
is why `RemoteFeature` can be tested and why the rules in AGENTS.md hold. Do
not regress to `@Default` in panes just because Loop does it. The one place we
already match Loop is `GeneralSettingsPane`'s `@Default(.showsMenuBarIcon)`,
which is pure UI preference with no runtime effect. That is the line: UI-only
preferences may bind to `Defaults` directly, anything the runtime reads goes
through a feature.

Loop's core is not a reducer either. `LoopManager` is a 700-line `@MainActor`
singleton with lock-mirrored flags (`OSAllocatedUnfairLock`) so event-tap
threads can read state without hopping actors. Our `GestureReader` being a pure
struct is the cleaner design; nothing to take from there except the event tap
threading in `Utilities/Event Monitoring`, if we ever move the tap off the
main thread.

## Borrowed, and where it landed

Every one of these is our own code written after reading Loop's, not a copy.

| Loop | Remotely |
| --- | --- |
| `SettingsTab.view()`, the tab enum owning its pane | `SettingsPage.pane(settings:remote:)` in `Features/Settings/SettingsPage.swift`. Our panes need stores, so they come in as arguments |
| Sidebar sections with headers | Already had it: `SidebarGroup`, "Remote" and "Support" |
| `SettingsTab.showIndicator` on About | `SidebarItem(badge:)`, fed by `SettingsFeature.State.availableVersion`. `Updater` learns the version from Sparkle's `didFindValidUpdate` and probes silently when Settings opens, if automatic checks are on. The About row reads "Update…" with the version |
| Dependent rows shown only under their parent | "Automatically install updates" appears only while "Automatically check" is on, since Sparkle only installs what a scheduled check found |
| `luminareModal` for Padding | `SettingsSheet` in `Views/RemotelyUI`. The display brand guide moved off the Connection page into one. Per-app bindings will want the same |
| `KeybindItemView.hasDuplicateKeybinds` | `Bindings.clashes(with:)` in RemotelyKit, tested, and an orange triangle in `BindingRow` naming the other buttons. Do Nothing and unrecorded shortcuts never clash |
| `AppDelegate.launchedAsLoginItem` | `AppCoordinator.launchedAtLogin` passes `didFinishLaunching(atLogin:)`. A login launch opens no window unless onboarding is unfinished |
| Terminate broadcast to older instances | `InstanceClient`: the newest launch posts a distributed notification, older copies quit, stragglers are killed after 3s, and only then does the remote start reading the CEC log |

Still to check on a real Mac: that a login launch really carries
`keyAELaunchedAsLogInItem` under `SMAppService` (Loop relies on it with the same
API), and that installing over a running build hands over cleanly.

## Not worth borrowing

- The custom updater. Sparkle already does this, and Loop needed a privileged
  helper target to make theirs work.
- `SkyLightToolBelt` private window blur. Our window material is measured and
  done with public API.
- The 44 rotating "no updates" jokes. Tempting. No.

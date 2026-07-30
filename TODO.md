# TODO

Everything agreed but not yet done. One line each, ticked and deleted when it
lands. See AGENTS.md — nothing gets worked on that is not written here first.

## Next

- [ ] Find out whether volume, mute, media and Home reach the Mac over CEC.
      `RemoteKey` documents that they never do, but that claim has never been
      tested and 0x2C already proved one documented assumption wrong. The codes
      are 0x41 up, 0x42 down, 0x43 mute. A 40s capture recorded nothing at all,
      so it stays untested rather than disproved.
- [ ] Confirm 0x2C is Back-held and not a separate button, by holding other
      buttons and checking no other long-duration code appears.
- [ ] Capture arrows too. This remote sends no repeats at all, so check whether
      the glide is driven by press-to-release only, and fix the `CECLogParser`
      comment and AGENTS.md, both of which claim repeats drive it.
- [ ] Test light, dark, and a red backdrop, focused and unfocused, for the
      window background.
- [ ] Test on the Shal Mac Neo and with the Samsung TV remote.
- [ ] Test the MacBook Air with two displays, the monitor plus the TV. Work out
      how to test two remotes on two HDMI inputs at once, and which display
      owns each press.
- [ ] Confirm the unfocused window background by eye. It is a solid fill under
      the material now, not `windowBackgroundColor` alone, which was white on
      Tahoe. Klack's grey measures rgb(232,235,237).
- [ ] Diagnose the live Samsung CEC pipeline from `corercd` through the
      installed app, repair the regression, and verify a fresh physical press.
- [ ] Separate macOS display discovery from CEC input discovery, then test one
      display, multiple displays, reconnects, and which display owns each press.
- [ ] Capture a real CEC session as a test fixture and replay it in the suite
      (`zsh scripts/capture-cec.sh 20 > Sources/RemotelyKitTests/Fixtures/session.txt`).
      Debug-level log lines are never archived, so this has to be recorded live.
- [ ] Collapse the font scale to 11/12/13/15 and add font tokens to `Theme`,
      then enable the `hardcoded_font_size` custom lint rule (64 hits today).
- [ ] `Row` absorbs the hand-rolled rows; one badge component; `IconTile`
      styles instead of three hand-drawn tinted squares.
- [ ] Merge WelcomeStep and FinishStep into one BookendStep.

## Actions worth adding

- [ ] A virtual keyboard the remote drives. `keyboardSetUnicodeString` on a
      keycode-0 event types arbitrary characters with no keycode or layout
      mapping, verified with an accent and an emoji, so the typing half is
      solved. The panel must be `.nonactivatingPanel` like `ScrollModeOverlay`
      or it takes focus and the keystrokes land in the keyboard itself. Before
      building one, check whether pointing the remote at the system
      Accessibility Keyboard is already good enough.
- [ ] An on-screen command menu the remote drives, the way Pieoneer's pie menu
      and Remote Buddy's Menu tab work: a configurable list of actions per app,
      arrowed through with the D-pad and confirmed with Center. Reuses the
      `ScrollModeOverlay` panel approach, which already floats over everything
      without taking focus.
- [ ] Per-app bindings, layered the way Remote Buddy does it: a global "All
      apps" table plus per-app overrides keyed on bundle ID, resolving
      app-specific then global then default. Copy their conflict rule too: a
      button claimed globally is removed from the per-app tables.
- [ ] App Exposé, Launchpad, Move a Space left/right.

## Later

- [ ] Delta updates. `generate_appcast` writes them automatically when the
      archives directory holds more than one version, but the enclosure URL it
      writes is derived from the archive's filename under one
      `--download-url-prefix`. Per-tag release URLs therefore cannot host old
      versions, so this needs one permanent archive location that every zip is
      uploaded to and the prefix points at, which is why Thaw keeps a separate
      `updates` repo. Do that before bolting deltas on, or the regenerated
      appcast points old entries at URLs that 404.

- [ ] Sparkle: generate the EdDSA keypair (only you can hold the private half)
      and have `.github/workflows/release.yml` sign the zip and publish an
      appcast. Until the app is notarized, every update replaces an ad-hoc
      signature and macOS revokes Accessibility, so automatic install stays off.
- [ ] Apple Developer cert so releases can be notarized instead of ad-hoc
      signed, which currently forces right-click-Open on first launch.
- [ ] Progressive blur at the scroll edge on macOS 15, where there is no
      system effect.

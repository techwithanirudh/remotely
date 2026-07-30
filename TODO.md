# TODO

Everything agreed but not yet done. One line each, ticked and deleted when it
lands. See AGENTS.md — nothing gets worked on that is not written here first.

## Next

- [ ] Back-held never fires on the M70D. Two "Pressed Back" lines land inside
      one second while repeats arrive every 0.2-0.3s, well inside the 0.6s
      repeat timeout, so a `<User Control Released>` must be interleaved between
      repeats and clearing `heldKey`. Capture the raw log holding Back to
      confirm, then make a release provisional for non-directional keys so an
      immediate repeat resumes the same hold.
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
      (`zsh scripts/capture-cec.sh 20 > Sources/RemoteKitTests/Fixtures/session.txt`).
      Debug-level log lines are never archived, so this has to be recorded live.
- [ ] Collapse the font scale to 11/12/13/15 and add font tokens to `Theme`,
      then enable the `hardcoded_font_size` custom lint rule (64 hits today).
- [ ] `Row` absorbs the hand-rolled rows; one badge component; `IconTile`
      styles instead of three hand-drawn tinted squares.
- [ ] Merge WelcomeStep and FinishStep into one BookendStep.
- [ ] Rename the app? RemoteControl / CECControl are the candidates.

## Actions worth adding

- [ ] App Exposé, Launchpad, Move a Space left/right.
- [ ] Per-app bindings.

## Later

- [ ] Sparkle: embed the framework, generate an EdDSA keypair, and have
      `.github/workflows/release.yml` sign the zip and publish an appcast.
- [ ] Apple Developer cert so releases can be notarized instead of ad-hoc
      signed, which currently forces right-click-Open on first launch.
- [ ] Progressive blur at the scroll edge on macOS 15, where there is no
      system effect.

# TODO

Everything agreed but not yet done. One line each, ticked and deleted when it
lands. See AGENTS.md — nothing gets worked on that is not written here first.

## Next

- [ ] Diagnose the live Samsung CEC pipeline from `corercd` through the
      installed app, repair the regression, and verify a fresh physical press.
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

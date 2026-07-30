# TODO

Everything agreed but not yet done. One line each, ticked and deleted when it
lands. See AGENTS.md — nothing gets worked on that is not written here first.

## Next

- [ ] Capture a real CEC session as a test fixture and replay it in the suite
      (`zsh scripts/capture-cec.sh 20 > Sources/RemoteKitTests/Fixtures/session.txt`).
      Debug-level log lines are never archived, so this has to be recorded live.
- [ ] Keyboard Shortcut binding is broken — recording no longer takes.
- [ ] Reorganise sources by feature, one component per file, one casing scheme.
- [ ] README: screenshot at the top, architecture diagram, badges.
- [ ] Commit-message enforcement (Conventional Commits) without a package.json.
- [ ] Apply the rest of the magic-number audit: font scale, `Row` absorbing the
      hand-rolled rows, one badge component, `IconTile` styles.
- [ ] Rename the app? RemoteControl / CECControl are the candidates.

## Actions worth adding

- [ ] Back and Forward, the way Mac Mouse Fix posts them.
- [ ] Middle click, App Exposé, Launchpad, Move a Space left/right.
- [ ] Per-app bindings.

## Later

- [ ] Sparkle updates: embed the framework in the bundle, generate an EdDSA
      keypair, host `appcast.xml`. Needs the repo public or a token.
- [ ] Progressive blur at the scroll edge on macOS 15, where there is no
      system effect.

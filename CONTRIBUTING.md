# Contributing to Remotely

Guidelines for contributing to Remotely on GitHub. Propose changes to this
document freely.

## Ways to contribute

- Bug reports
- Documentation improvements
- Code

## Developer Certificate of Origin (DCO)

Contributors certify they have the right to submit their work under this
project's licence, using the
[Developer Certificate of Origin v1.1](https://developercertificate.org/).

Sign off each commit with your real name:

```bash
git commit -s -m "fix: explain the change"
```

which appends:

```text
Signed-off-by: Your Name <your.email@example.com>
```

This is not a CLA and transfers no copyright. It attests that you can contribute
the change under the MIT licence.

### AI-assisted contributions

AI-assisted work is welcome when the result is high quality and follows this
guide. The DCO applies to the human who signs off: by adding `Signed-off-by` you
certify you have the right to contribute the change, including any
AI-generated portions. The tool is not a party to the DCO, you are.

In practice:

- Prefer tools whose terms allow contributing output to an MIT-licensed project.
- Do not feed proprietary or third-party-restricted code into an assistant and
  commit the result as your own.
- You must understand the change well enough to explain it in review.

Pull requests will be closed for observable quality failures: generated content
pasted without review, failing CI left unaddressed, missing tests for new
behaviour, or drive-by refactors with no issue. Using AI does not lower the bar.

## Reporting bugs

Search the [issue tracker](https://github.com/techwithanirudh/remotely/issues)
first. A bug cannot be fixed before it can be reproduced, so include what you
did, what happened, and what you expected.

For anything involving the remote itself, the **Diagnostics** pane has a live
event log with a Copy button. Include it. It distinguishes the three failure
modes that look identical from outside:

- no event line at all, meaning the press never reached the Mac
- `Ignored, no Accessibility permission yet`
- an event line but no visible effect

A raw CEC capture is even better:

```bash
zsh scripts/capture-cec.sh 20 > /tmp/cec.txt
```

Displays differ more than they should. The `0x2C` code for a held Back was found
this way and exists in no CEC specification.

## Getting started

Prerequisites: macOS 15+ and the Command Line Tools. A full Xcode is not
required, but without one SwiftLint cannot find `sourcekitd`, so put this in your
shell profile:

```bash
export TOOLCHAIN_DIR=$(xcode-select -p)
```

Then:

```bash
git clone https://github.com/techwithanirudh/remotely.git
cd remotely
git config core.hooksPath .githooks
swift build && swift run RemotelyKitTests
```

`.githooks` holds the commit-message and pre-commit hooks. That one `git config`
line is the whole setup.

## Code style

SwiftLint and SwiftFormat enforce style, configured in
[`.swiftlint.yml`](.swiftlint.yml) and [`.swiftformat`](.swiftformat). Before
opening a pull request:

```bash
swiftformat .
swiftlint lint --strict
swift build
swift run RemotelyKitTests
```

Because the linter and formatter enforce style, comments do not have to. Write
one only for something the code cannot say: why a value was measured rather than
chosen, why an obvious approach was rejected, what a private API does. Never
restate the next line.

## Tests

Tests are a plain executable rather than XCTest, because the Command Line Tools
ship neither XCTest nor swift-testing, and swift-testing conflicts with Defaults
over swift-syntax. Run them with `swift run RemotelyKitTests`.

New behaviour in `RemotelyKit` needs a test. Prefer a recorded fixture over a
hand-written sequence for anything touching CEC: a hand-written sequence tests
what you believe the hardware does, and
`Tests/RemotelyKitTests/Fixtures/back-tap-and-hold.txt` exists because that
belief was wrong twice.

## Conventions

- **Commits:** Conventional Commits, enforced by a hook. Subject lowercase, 80
  characters or fewer.
- **Sign-off:** every commit needs `git commit -s`.
- **Scope:** keep pull requests small. Say why if one has to be large.
- **Sensitive areas:** expect deeper review on the CEC transport, gesture
  timing, event synthesis, signing and the release workflow.

The CEC transport in particular is not to be "fixed". macOS owns the bus inside
`corercd`, whose private XPC service refuses bus enumeration to third parties,
so parsing the unified log is the only path that works. A previous rewrite
reinstated the framework approach and broke remote detection entirely.

## Project docs

- [Architecture](docs/ARCHITECTURE.md)
- [Releasing](docs/RELEASING.md)
- [Agent and contributor conventions](AGENTS.md)
- [What is next](TODO.md)

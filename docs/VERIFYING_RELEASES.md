# Verifying a release

Everything here can be checked from a downloaded release without trusting this
repository's word for it.

## What is signed

| Artefact | Signature | Verifies |
| --- | --- | --- |
| `Remotely.zip` | EdDSA, in the appcast's `sparkle:edSignature` | the archive Sparkle installs |
| `Remotely.zip.sigstore.json` | Sigstore, keyless | that the archive came from this repo's workflow |
| `Remotely.app` | `Remotely Self Signed` | the bundle has not been altered since it was built |

There is no Apple notarization, so Gatekeeper will warn on first launch. That is
expected, not a sign of tampering.

## The public Sparkle key

`SUPublicEDKey` in `Resources/Info.plist`:

```
jJP59+JLsgZWqKDiRqa+ljhjSVfbHrmCOgNNBvS7Uho=
```

An update is only installed when its `sparkle:edSignature` verifies against
this. A feed served over a hijacked domain still cannot ship a build without the
private half.

## Check the appcast

```bash
curl -s https://remotely.techwithanirudh.com/appcast.xml
```

The `enclosure` URL must point at `github.com/techwithanirudh/remotely/releases`
and carry a `sparkle:edSignature`. An enclosure on the Pages host is the bug
described in [RELEASING.md](RELEASING.md) and will 404.

## Check the archive with Sigstore

```bash
gh release download 0.6.1 --repo techwithanirudh/remotely
cosign verify-blob \
  --bundle Remotely.zip.sigstore.json \
  --certificate-identity-regexp 'github.com/techwithanirudh/remotely' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  Remotely.zip
```

## Check the app bundle

```bash
codesign -v --deep --strict Remotely.app
codesign -d --requirements - Remotely.app
```

The designated requirement must read:

```
identifier "com.anirudh.remotely" and certificate root = H"13f1de9d0e9d39afb5988272ebaebd98b56e08ac"
```

A `cdhash` requirement instead means the build was ad-hoc signed. It will run,
but installing it drops the Accessibility grant.

## Check the tag

```bash
git fetch --tags
git rev-list -n 1 0.6.1
```

Compare that to the commit shown on the release page.

## Related

- [RELEASING.md](RELEASING.md)

# Local signing material

Nothing here is committed: the patterns are in `.gitignore` and this note is the
only tracked file.

| File | What it is | How to get it |
| --- | --- | --- |
| `sparkle-private.key` | Sparkle EdDSA private key, the half that signs an appcast | already in your login keychain; export with `generate_keys -x` |
| `codesign.p12` | The `Remotely Self Signed` code-signing identity | already in your login keychain; export from Keychain Access |

Both live in the keychain, so these files are only for moving them to another
machine or to a CI secret. Delete them once transferred.

The public halves are not secret and are committed: `SUPublicEDKey` in
`Resources/Info.plist`, and the certificate hash appears in the app's designated
requirement.

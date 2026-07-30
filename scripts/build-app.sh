#!/bin/zsh
set -euo pipefail

repo_dir=${0:A:h:h}
configuration=${1:-release}
app_dir="$repo_dir/build/Remotely.app"
module_cache="$repo_dir/.build/swiftpm-cache"
clang_cache="$repo_dir/.build/clang-module-cache"

cd "$repo_dir"
mkdir -p "$module_cache" "$clang_cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$module_cache"
export CLANG_MODULE_CACHE_PATH="$clang_cache"
swift build --disable-sandbox -c "$configuration"
binary_dir=$(swift build --disable-sandbox -c "$configuration" --show-bin-path)

mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources" "$app_dir/Contents/Frameworks"
cp "$binary_dir/Remotely" "$app_dir/Contents/MacOS/Remotely"
cp "$repo_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"
cp "$repo_dir/Resources/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
cp "$repo_dir/Resources/Click.wav" "$app_dir/Contents/Resources/Click.wav"

# SwiftPM links Sparkle but will not embed it, and the updater cannot run from
# the build directory once the app is installed elsewhere.
rm -rf "$app_dir/Contents/Frameworks/Sparkle.framework"
ditto "$binary_dir/Sparkle.framework" "$app_dir/Contents/Frameworks/Sparkle.framework"

xattr -cr "$app_dir"

# Accessibility is granted against the designated requirement. Ad-hoc signing
# puts the binary's cdhash in it, so every build looks like a different app and
# macOS drops the grant. A stable identity puts the certificate there instead,
# measured as `identifier "com.anirudh.remotely" and certificate root = H"..."`
# and unchanged across a version bump. Notarization is a separate matter: it
# only silences Gatekeeper on first launch.
identity=${CODESIGN_IDENTITY:-Remotely Self Signed}
if ! security find-identity -v 2>/dev/null | grep -qF "$identity"; then
    print -u2 "No '$identity' identity; falling back to ad-hoc, which resets Accessibility on every install."
    identity="-"
fi

# Nested code is signed before its container, which --deep does not guarantee.
codesign --force --sign "$identity" "$app_dir/Contents/Frameworks/Sparkle.framework"
codesign --force --sign "$identity" "$app_dir"

echo "$app_dir"

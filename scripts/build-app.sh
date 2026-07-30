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

mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$binary_dir/Remotely" "$app_dir/Contents/MacOS/Remotely"
cp "$repo_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"
cp "$repo_dir/Resources/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
xattr -cr "$app_dir"
codesign --force --deep --sign - "$app_dir"

echo "$app_dir"

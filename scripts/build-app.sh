#!/bin/zsh
set -euo pipefail

repo_dir=${0:A:h:h}
configuration=${1:-release}
app_dir="$repo_dir/build/Remote Bridge.app"
module_cache="$repo_dir/.build/swiftpm-cache"
clang_cache="$repo_dir/.build/clang-module-cache"

cd "$repo_dir"
mkdir -p "$module_cache" "$clang_cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$module_cache"
export CLANG_MODULE_CACHE_PATH="$clang_cache"
swift build --disable-sandbox -c "$configuration"
binary_dir=$(swift build --disable-sandbox -c "$configuration" --show-bin-path)

mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$binary_dir/RemoteBridge" "$app_dir/Contents/MacOS/RemoteBridge"
cp "$repo_dir/resources/Info.plist" "$app_dir/Contents/Info.plist"
xattr -cr "$app_dir"
codesign --force --deep --sign - "$app_dir"

echo "$app_dir"

#!/bin/zsh
set -euo pipefail

repo_dir=${0:A:h:h}
cd "$repo_dir"
mkdir -p "$repo_dir/.build/swiftpm-cache" "$repo_dir/.build/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$repo_dir/.build/swiftpm-cache"
export CLANG_MODULE_CACHE_PATH="$repo_dir/.build/clang-module-cache"

actual=$(printf '%s\n' \
  'DEBUG: key pressed: up (1, 0)' \
  'NOTICE: key pressed: select (0, 0)' \
  'key pressed: play/pause (0, 0)' \
  'key released: up (duration: 120)' \
  'TRAFFIC: [ 123] >> 01:44:04' \
  'TRAFFIC: [ 124] >> 01:44:46' \
  'TRAFFIC: [ 125] >> 01:45' \
  | swift run --disable-sandbox RemoteBridge --dry-run 2>/dev/null)

expected=$'up\nselect\nplayPause\nright\npause'
if [[ "$actual" != "$expected" ]]; then
  print -u2 "Parser test failed"
  print -u2 "Expected:\n$expected"
  print -u2 "Actual:\n$actual"
  exit 1
fi

echo "Parser test passed"

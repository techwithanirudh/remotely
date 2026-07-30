#!/bin/zsh
# Formats, then lints. Both tools come from `brew install swiftlint swiftformat`.
set -euo pipefail

repo_dir=${0:A:h:h}
cd "$repo_dir"

if (( ! $+commands[swiftformat] )) || (( ! $+commands[swiftlint] )); then
    echo "brew install swiftlint swiftformat" >&2
    exit 1
fi

# SwiftLint looks for sourcekitd inside Xcode. On a Command Line Tools only
# machine it lives here instead, and without this it dies on startup.
if [[ -d /Library/Developer/CommandLineTools/usr/lib/sourcekitdInProc.framework ]]; then
    export DYLD_FRAMEWORK_PATH=/Library/Developer/CommandLineTools/usr/lib
fi

[[ ${1-} == "--check" ]] && format_flag="--lint" || format_flag=""
swiftformat ${format_flag} .
swiftlint lint --quiet ${${1-}:+--strict}

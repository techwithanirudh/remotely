#!/bin/zsh
# Formats, then lints. Both tools come from `brew install swiftlint swiftformat`.
set -euo pipefail

repo_dir=${0:A:h:h}
cd "$repo_dir"

if (( ! $+commands[swiftformat] )) || (( ! $+commands[swiftlint] )); then
    echo "brew install swiftlint swiftformat" >&2
    exit 1
fi

[[ ${1-} == "--check" ]] && format_flag="--lint" || format_flag=""
swiftformat ${format_flag} .
swiftlint lint --quiet ${${1-}:+--strict}

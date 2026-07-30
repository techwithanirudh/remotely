#!/bin/zsh
# SwiftLint's analyzer rules, which need a real compiler log. Slow: a clean
# build plus the analysis is about a minute, so this is a CI job, never a hook.
set -euo pipefail

cd "${0:A:h:h}"
if [[ ! -d /Applications/Xcode.app ]]; then
    export TOOLCHAIN_DIR=${TOOLCHAIN_DIR:-$(xcode-select -p)}
fi

log=$(mktemp -t rb-build)
expanded=$(mktemp -t rb-build-expanded)

swift package clean
swift build -v > "$log" 2>&1

# SwiftPM hands the compiler its sources in a response file, which SwiftLint
# cannot expand; without this it silently analyzes nothing and exits 0.
perl -pe 's{\@(/\S+)}{ my $f=$1; if (-r $f) { local $/; open my $h,"<",$f; my $c=<$h>; close $h; $c =~ s/\s+/ /g; $c } else { "\@$f" } }ge' \
    "$log" > "$expanded"

# Explicit paths, canonical: a directory argument also yields zero files.
find "$PWD/Sources" "$PWD/Tests" -name '*.swift' \
    | xargs swiftlint analyze --quiet --compiler-log-path "$expanded"

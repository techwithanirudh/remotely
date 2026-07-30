#!/bin/zsh
# Checks every support link in TVBrand still resolves to the article itself.
#
# A retired article redirects to the maker's help-library index and answers 200
# from there, so the status code alone says nothing. The final URL has to match
# what was asked for.
set -euo pipefail

source="$(dirname "$0")/../Sources/RemoteKit/Model/TVBrand.swift"
failed=0

urls=($(grep -oE 'https://[^"]+' "$source" | grep -v duckduckgo))

for url in $urls; do
    final=$(curl -sS -o /dev/null -L --max-time 30 -w '%{url_effective}' "$url" || echo "unreachable")
    if [[ "$final" == "$url" ]]; then
        print "ok    $url"
    else
        print "moved $url\n   -> $final"
        failed=1
    fi
done

exit $failed

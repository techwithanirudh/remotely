#!/bin/zsh
# Records a real CEC session for use as a test fixture.
#
# The daemon's remote-button lines are debug level, which the unified log keeps
# in memory and never archives, so `log show` cannot recover a past session.
# The only way to get one is to stream while somebody presses buttons.
#
#   zsh scripts/capture-cec.sh 20 > Sources/RemoteKitTests/Fixtures/session.txt
set -euo pipefail

seconds=${1:-20}
print -u2 "Recording for ${seconds}s. Press buttons on the remote now."

/usr/bin/log stream --predicate 'process == "corercd"' --debug --style compact &
stream_pid=$!
sleep "$seconds"
kill "$stream_pid" 2>/dev/null || true

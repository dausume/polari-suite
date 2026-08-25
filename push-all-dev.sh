#!/bin/bash
# Thin wrapper — the ONE implementation lives in polari-cli/shells/.
exec "$(dirname "${BASH_SOURCE[0]}")/polari-cli/shells/push-all-dev.sh" "$@"

#!/bin/bash
# Configuration as Code reads secrets as ${name} from ONE flat directory
# ($SECRETS). The host keeps them ORGANIZED (secrets/<area>/<name>), so
# flatten at start into a private tmpfs-like dir: <name> only, 0600,
# examples/keep files skipped. A name that appears in two areas is a
# configuration error and is reported, not silently overwritten.
set -eu
FLAT=/tmp/polari-secrets; rm -rf "$FLAT"; mkdir -m 0700 "$FLAT"
if [ -d /run/secrets ]; then
    while IFS= read -r -d '' f; do
        n=$(basename "$f"); case "$n" in *.example|.gitkeep|README.md|ROTATION.log) continue ;; esac
        [ -e "$FLAT/$n" ] && { echo "[secrets] DUPLICATE name '$n' in two areas — fix secrets/ layout" >&2; exit 1; }
        cp "$f" "$FLAT/$n"; chmod 0600 "$FLAT/$n"
    done < <(find /run/secrets -mindepth 2 -type f -print0)
fi
echo "[secrets] $(ls "$FLAT" | wc -l) secret(s) available to Configuration as Code: $(ls "$FLAT" | tr '\n' ' ')"
export SECRETS="$FLAT"
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"

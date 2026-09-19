#!/bin/bash
# polari-jenkins/isle/app-debs.sh — build the APP debs a testing stage
# needs, into a directory the pipeline names.
#
#   app-debs.sh <outdir> <module>…
#
# THIN VERB, exactly like `isle apps build-debs` is. The ONE implementation
# of "turn a module into an installable deb" is polari-framework's
#   modules/appstore/custom/app_deb_builder.py
# (the pure-python deb writer with shared-payload factoring, the generation
# ledger and the TTL pool — dl-4). Nothing here writes a deb; it only
# locates that implementation, points its pool at <outdir> via
# POLARI_APP_DEBS_DIR, and invokes it with the module names.
#
# Locating it, in order: a framework checkout beside this file (the normal
# CI case — the job checks the superproject out recursively), then a
# running polari backend container. Same order the isle CLI uses.
#
# exit 0 = every named module has a deb in <outdir> · exit 5 = no builder
set -euo pipefail

OUT="${1:?usage: app-debs.sh <outdir> <module>…}"; shift
[ $# -gt 0 ] || { echo "[app-debs] no modules named — nothing to build (a 'core' stage builds no app debs)"; exit 0; }
mkdir -p "$OUT"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE="$(cd "$HERE/../.." && pwd)"

framework_dir() {
    local d
    for d in "${POLARI_FRAMEWORK_DIR:-}" "$SUITE/polari-rf-node/polari-framework" "$HOME/polari-framework"; do
        [ -n "$d" ] && [ -f "$d/modules/appstore/custom/app_deb_builder.py" ] && { echo "$d"; return 0; }
    done
    return 1
}
backend_container() {
    docker ps --format '{{.Names}}' 2>/dev/null | grep -m1 -E 'polari.*(backend|framework)|prf-backend' || true
}

echo "[app-debs] modules: $*"
echo "[app-debs] output:  $OUT"
if DIR=$(framework_dir); then
    echo "[app-debs] builder: $DIR/modules/appstore/custom/app_deb_builder.py (framework checkout)"
    ( cd "$DIR" && PYTHONPATH=.:modules POLARI_APP_DEBS_DIR="$OUT" \
        python3 -m appstore.custom.app_deb_builder "$@" )
elif CONT=$(backend_container) && [ -n "$CONT" ]; then
    echo "[app-debs] builder: the running backend container $CONT"
    docker exec -e PYTHONPATH=.:modules -e POLARI_APP_DEBS_DIR=/tmp/app-debs "$CONT" \
        python3 -m appstore.custom.app_deb_builder "$@"
    docker cp "$CONT:/tmp/app-debs/." "$OUT/"
else
    echo "[app-debs] REFUSED: no polari framework checkout and no backend container — set POLARI_FRAMEWORK_DIR" >&2
    exit 5
fi

MISSING=""
for m in "$@"; do
    ls "$OUT"/polari-app-"$m"_*.deb >/dev/null 2>&1 || MISSING="$MISSING $m"
done
if [ -n "$MISSING" ]; then
    echo "[app-debs] REFUSED: no deb was produced for:$MISSING" >&2
    exit 5
fi
ls -1 "$OUT"/*.deb

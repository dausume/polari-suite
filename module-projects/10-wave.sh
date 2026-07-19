#!/bin/bash
# mp-4 migration wave runner: move this wave's modules into modules/,
# update the register, commit on a wave branch, rebuild the staging
# backend, run every moved module's selftests in-container.
#
# Usage: ./10-wave.sh <wave-number> [--no-deploy]
#   --no-deploy: move + register + commit ONLY (no rebuild, no
#   selftests) — for ripping through several waves in one sitting,
#   then ONE rebuild + ./90-verify-all.sh at the end.
#   wave 1: nutrition tanks plant_morphology         (pure leaves)
#   wave 2: waxsupply supplychain dmvdata
#   wave 3: mathshapes electrodevice hwdigital hwfpga
#   wave 4: zones xr                                  (xr stays required_by_core)
#   wave 5: aquaponics grpcbridge resources           (resources stays required_by_core)
#   wave 6: waxprint scoring techtree polariapps testing
#           (deep polariServer coupling — mp-3 lazy imports make
#            this legal; runs LAST by design)
# The wave list is read from the register (wave fields), so this file
# never drifts from modules/polari-modules.json.
source "$(dirname "$0")/lib.sh"

WAVE=${1:?usage: $0 <wave-number 1..6> [--no-deploy]}
NO_DEPLOY=""
[ "${2:-}" = "--no-deploy" ] && NO_DEPLOY=1
MODULES=$(python3 -c "
import json
doc = json.load(open('$FW/modules/polari-modules.json'))
print(' '.join(sorted(n for n, e in doc['modules'].items()
                      if e.get('wave') == int('$WAVE'))))")
[ -n "$MODULES" ] || die "no modules registered for wave $WAVE"

say "mp-4 wave $WAVE: $MODULES"
need_clean_fw

BRANCH="dev-mp-4-wave-$WAVE"
confirm "create branch $BRANCH off the current framework HEAD ($(git -C "$FW" branch --show-current)) and move: $MODULES?"
run git -C "$FW" checkout -b "$BRANCH"

for m in $MODULES; do
    move_module "$m"
done

run git -C "$FW" add -A
run git -C "$FW" commit -m "mp-4 wave $WAVE: move $(echo $MODULES | tr ' ' ',') into modules/ (import seam keeps names; register paths updated)"

if [ -n "$NO_DEPLOY" ]; then
    say "wave $WAVE moved + committed (--no-deploy: rebuild + selftests deferred — run ./90-verify-all.sh after the last wave)"
else
    rebuild_backend

    say "selftests for the moved modules (in-container, new layout)"
    for m in $MODULES; do
        selftest_module "$m"
    done

    say "wave $WAVE deployed + selftest-green"
fi
pol modules registry | grep -E "wave $WAVE" || true
print_pointer_commits "mp-4 wave $WAVE: $(echo $MODULES | tr ' ' ',') into modules/"

cat <<EOF

${BOLD}Next:${NC} ./20-split-module.sh <module> for each of: $MODULES
(creates its PUBLIC repo + pushes the subtree; can also be done later
in one sitting — the register remembers what is split via its repo
field). Then the next wave.
EOF

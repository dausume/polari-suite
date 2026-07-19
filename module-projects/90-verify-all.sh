#!/bin/bash
# Full verification paint after any wave/split: register coherence,
# lazy-import drift guard, module selftests for everything moved,
# the /modules surface, and the mp-3 boots-without-downstream proof.
# Read-only apart from a temporary in-container module hide.
source "$(dirname "$0")/lib.sh"

say "register (sizes, waves, repos)"
pol modules registry

say "drift guard: every polariServer feature import is stubbable"
docker exec prf-backend python3 -m moduleService.selftest_lazy_imports | tail -1

say "register selftest"
docker exec prf-backend python3 -m moduleService.selftest_module_registry | tail -1

say "selftests for every module already under modules/"
# Reds are COLLECTED and reported at the end, not fatal mid-sweep —
# known pre-existing: aquaponics.system 12/13 (environmental-impact
# concept; predates module-projects, see NEXT_AGENT_HANDOFF.md).
RED_SUITES=""
for d in "$FW"/modules/*/; do
    m=$(basename "$d")
    case "$m" in polariAgroForestryModule|polariMaterialsScienceModule) continue ;; esac
    if ! selftest_module "$m"; then
        RED_SUITES="$RED_SUITES $m"
    fi
done
if [ -n "$RED_SUITES" ]; then
    echo "${RED}suites with reds:${NC}$RED_SUITES (aquaponics 12/13 is the known pre-existing red)"
else
    ok "every module suite green"
fi

say "/modules API lists honestly"
docker exec prf-backend python3 -c "
import json, urllib.request as u
doc = json.loads(u.urlopen('http://localhost:3000/modules', timeout=10).read())
mods = doc.get('modules', doc if isinstance(doc, list) else [])
print(f'{len(mods)} modules listed')
missing = [m for m in mods if m.get('notDownloaded')]
print('not-downloaded rows:', [m['id'] for m in missing] or 'none (all code present)')"

say "mp-3 proof: the core BOOTS (imports) without a feature module"
echo "  (hides modules/biomining inside the container, imports the"
echo "   server module, restores — the running process is untouched)"
docker exec prf-backend sh -c '
  mv /app/modules/biomining /tmp/_hide-biomining || exit 2
  python3 -c "import polariApiServer.polariServer" >/tmp/_lazyboot.log 2>&1
  status=$?
  mv /tmp/_hide-biomining /app/modules/biomining
  grep -m2 "ModuleLoading\|Traceback" /tmp/_lazyboot.log || true
  exit $status' \
    && ok "core imports cleanly without biomining" \
    || die "core import FAILED without biomining"

say "verification paint complete"

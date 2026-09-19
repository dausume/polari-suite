# shared by every route: DRY_RUN rendering + the honest refusal when a secret is absent.
#
# ci-7 (C), the automated half: DRY_RUN=auto (the default) means a route
# publishes FOR REAL only when BOTH are true —
#   · every secret it needs is present (the credential arrives non-empty), and
#   · the route is named in CI_ROUTES (device.env — the operator's list of
#     routes that may publish at all).
# Anything else renders. Each route prints which it is, and why, at the top:
#   ARMED · DRY (secret <name> absent) · DRY (not in CI_ROUTES)
# DRY_RUN=1/true and DRY_RUN=0/false still force the old behaviour.
set -eu
DRY_RUN="${DRY_RUN:-auto}"
CI_ROUTES="${CI_ROUTES:-github-release,ghcr,homebrew,apt-repo}"
: "${VERSION:?VERSION required}"; : "${POOL_DIR:?POOL_DIR required}"
ROUTE="$(basename "${BASH_SOURCE[1]:-$0}" .sh)"
run(){ if [ "$DRY_RUN" = 1 ]; then echo "[dry-run:$ROUTE] $*"; else echo "[$ROUTE] $*"; "$@"; fi; }
need(){ # need VAR secret-file-path — a real run REFUSES without it; a dry run renders anyway and says what would refuse
    if [ -z "${!1:-}" ]; then
        if [ "$DRY_RUN" = 1 ]; then echo "[dry-run:$ROUTE] secret '$1' is absent — a real run would REFUSE here (polari-jenkins/secrets/$2)"; export "$1=<absent:$1>"
        else echo "[$ROUTE] REFUSED: secret '$1' is empty — put it in polari-jenkins/secrets/$2 (see secrets/README.md)"; exit 3; fi
    fi
}
manifest(){ python3 -c "import json,sys;print(json.load(open('$POOL_DIR/release.json'))$1)"; }
record(){ # record <url> — write publishedTo[route] into release.json (dry-run: marks rendered)
    python3 - "$POOL_DIR/release.json" "$ROUTE" "$1" "$DRY_RUN" <<'PY'
import json, sys, datetime
p, route, url, dry = sys.argv[1:5]
m = json.load(open(p)); m.setdefault('publishedTo', {})[route] = {'url': url, 'at': datetime.datetime.now().isoformat(timespec='seconds'), 'dryRun': dry == '1'}
json.dump(m, open(p, 'w'), indent=1)
PY
}
route_in_ci_routes(){ case ",$(echo "$CI_ROUTES" | tr -d ' ')," in *",$ROUTE,"*) return 0 ;; esac; return 1; }

# ---------------------------------------------------------------------------
# THE RELEASE RULE (his ask 2026-09-19): "The pipeline should only generate
# artifact for things that are tested." The throwaway isle is what the
# pipeline analyses; polari-isle-test writes pool/<version>/isle-test/
# results.json; NOTHING is published that that file does not say passed.
#
#   no results.json at all   → every route is DRY and the tag is not pushed
#   core_ok false            → every route is DRY (the core itself is untested)
#   an app whose result is not 'pass' → its deb is left OUT of the assets and
#                                       named under "not released"
#
# It is a TESTING rule, not a security gate — and it is HARD: DRY_RUN=false
# does not override it. Forcing a publish of something untested is exactly
# the thing the rule exists to prevent.
RESULTS_JSON="${RESULTS_JSON:-$POOL_DIR/isle-test/results.json}"
tested_state(){ # → 'OK' or the reason this version may not be published
    [ -f "$RESULTS_JSON" ] || { echo "no isle-test results for $VERSION — the pipeline only releases what it tested"; return 1; }
    python3 - "$RESULTS_JSON" "$VERSION" <<'PY' || return 1
import json, sys
p, ver = sys.argv[1:3]
try: r = json.load(open(p))
except Exception as e:
    print('isle-test results unreadable (%s)' % e); sys.exit(1)
if not r.get('core_ok'):
    print('the isle test did not record core_ok for %s — the core itself is untested' % ver); sys.exit(1)
print('OK')
PY
}
tested_apps(){ # the app modules a stage recorded as pass — the only ones that may ship
    [ -f "$RESULTS_JSON" ] || return 0
    python3 -c 'import json,sys; print(" ".join(json.load(open(sys.argv[1])).get("passed", [])))' "$RESULTS_JSON" 2>/dev/null || true
}
release_assets(){ # release_assets <dir> — the files this route MAY publish
    local d="$1" f base app passed; passed=" $(tested_apps) "
    for f in "$d"/*; do
        [ -f "$f" ] || continue
        base="$(basename "$f")"
        case "$base" in
            polari-app-*_*.deb) app="${base#polari-app-}"; app="${app%%_*}"
                                case "$passed" in *" $app "*) echo "$f" ;; esac ;;
            *) echo "$f" ;;
        esac
    done
}
release_excluded(){ # release_excluded <dir> — what is held back, and why
    local d="$1" f base app passed; passed=" $(tested_apps) "
    for f in "$d"/*; do
        [ -f "$f" ] || continue
        base="$(basename "$f")"
        case "$base" in
            polari-app-*_*.deb) app="${base#polari-app-}"; app="${app%%_*}"
                                case "$passed" in *" $app "*) ;; *) echo "$base (untested or failed in the isle test)" ;; esac ;;
        esac
    done
}
arm(){ # arm VAR:area/name … — the FIRST line of every route: resolve DRY_RUN=auto and say why
    local spec var path missing="" state why excluded
    for spec in "$@"; do var="${spec%%:*}"; path="${spec#*:}"; [ -n "${!var:-}" ] || missing="$missing $path"; done
    case "$DRY_RUN" in
        0|false|no)  DRY_RUN=0; state="ARMED (DRY_RUN=false forced)" ;;
        1|true|yes)  DRY_RUN=1; state="DRY (DRY_RUN=true forced)" ;;
        auto)
            if ! route_in_ci_routes; then DRY_RUN=1; state="DRY (not in CI_ROUTES)"
            elif [ -n "$missing" ]; then DRY_RUN=1; state="DRY (secret$missing absent)"
            else DRY_RUN=0; state="ARMED"; fi ;;
        *) echo "[$ROUTE] REFUSED: DRY_RUN='$DRY_RUN' is not auto|true|false" >&2; exit 2 ;;
    esac
    # THE RELEASE RULE — hard, and it overrides even DRY_RUN=false.
    if ! why="$(tested_state)" || [ "$why" != OK ]; then
        DRY_RUN=1; state="DRY ($why)"
    fi
    echo "== route $ROUTE  version $VERSION  $state  pool $POOL_DIR"
    excluded="$(release_excluded "$POOL_DIR/debs" 2>/dev/null || true)"
    [ -n "$excluded" ] && { echo "[$ROUTE] not released: untested/failed —"; printf '%s\n' "$excluded" | sed 's/^/    /'; } || true
    for spec in "$@"; do need "${spec%%:*}" "${spec#*:}"; done
}

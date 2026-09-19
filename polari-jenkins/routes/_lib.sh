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
# THE RELEASE RULE — ci-12 SHAPE (his rulings 2026-09-19).
#
# "The pipeline should only generate artifact for things that are tested."
# The rule has not changed; WHERE the testing happens has. It used to be a
# polari-isle-test run fired from inside the release job. It is now the TEST
# BRANCH: a push to `test` wipes the device, builds, scans and tests, and
# records ONE verdict for that superproject sha. A push to `main` releases —
# and only a sha whose verdict says `passed` may be released.
#
#   pool/test/<sha>/verdict.json   verdict == 'passed'    -> routes may arm
#   verdict 'failed' | 'partial'                          -> every route DRY
#   no verdict.json for this sha                          -> every route DRY
#
# The sha is read from the release manifest this build wrote
# (release.json -> components.superproject.sha), so a route can enforce the rule
# on its own without being told: triggering polari-publish by hand on an
# untested build is safe, because every route re-reads this.
#
# It is a TESTING rule, not a security gate - and it is HARD: DRY_RUN=false does
# not override it. Forcing a publish of something untested is exactly the thing
# the rule exists to prevent. The ONE override is a person running
# `pol jenkins promote main --force-untested`, which is loud, is in that log,
# and still leaves this check to refuse the publish.
#
# ci-10's coupling is NOT lost: the verdict itself already required the isle
# stages' core_ok, which in turn requires a CLEAN hand-back from the product's
# own uninstall. The rule is enforced once, where it is computed, instead of
# twice in two places that could drift.
POLARI_POOL="${POLARI_POOL:-/var/polari-pool}"
release_sha(){ # the superproject sha this build is of
    [ -n "${RELEASE_SHA:-}" ] && { printf '%s' "$RELEASE_SHA"; return 0; }
    python3 -c 'import json,sys
try: print((json.load(open(sys.argv[1])).get("components") or {}).get("superproject", {}).get("sha", ""))
except Exception: print("")' "$POOL_DIR/release.json" 2>/dev/null || true
}
VERDICT_JSON="${VERDICT_JSON:-}"
verdict_path(){
    [ -n "$VERDICT_JSON" ] && { printf '%s' "$VERDICT_JSON"; return 0; }
    local sha; sha="$(release_sha)"
    [ -n "$sha" ] || return 1
    printf '%s/test/%s/verdict.json' "$POLARI_POOL" "$sha"
}
tested_state(){ # -> 'OK' or the reason this version may not be published
    local vp; vp="$(verdict_path)" || {
        echo "this build names no superproject sha (no release.json) - the test verdict cannot be found, so nothing is released"; return 1; }
    [ -f "$vp" ] || { echo "no passed test run for $(release_sha) - push to test first (pol jenkins promote test), let polari-test record a verdict, then promote main"; return 1; }
    python3 -c '
import json, sys
p, ver = sys.argv[1:3]
try:
    v = json.load(open(p))
except Exception as e:
    print("the test verdict is unreadable (%s)" % e); sys.exit(1)
verdict = v.get("verdict")
if verdict != "passed":
    print("the test verdict for %s is %r, not passed - %s"
          % (str(v.get("sha", "?"))[:12], verdict, v.get("why") or "no reason recorded")); sys.exit(1)
print("OK")
' "$vp" "$VERSION" || return 1
}
tested_apps(){ # the app modules the test run recorded as passing - the only ones that may ship
    local vp; vp="$(verdict_path)" || return 0
    [ -f "$vp" ] || return 0
    python3 -c 'import json,sys
try: print(" ".join((json.load(open(sys.argv[1])).get("isle") or {}).get("passed") or []))
except Exception: pass' "$vp" 2>/dev/null || true
}
# ---------------------------------------------------------------------------
# ci-9 — APP MODE (his addendum 2026-09-19: "some people will also be using this
# pipeline as a way to maintain their own Polari Apps and will only be testing
# the one app they are developing").
#
# A device in app mode releases ONE deb — the app it maintains — to the
# DEVELOPER'S own routes. Two hard rules, both enforced here rather than trusted
# to a Jenkinsfile:
#   · the core debs it pulled from an official release are NOT re-released.
#     Republishing somebody else's core under your name is not a release.
#   · CI_ROUTE_TARGET must be the developer's own owner/namespace. Aimed at the
#     upstream owner it is a REFUSAL: a fork is never republished under an
#     upstream name. This is the ci-8 rule, now with a key behind it.
CI_MODE="${CI_MODE:-suite}"
CI_APP_NAME="${CI_APP_NAME:-}"
CI_ROUTE_TARGET="${CI_ROUTE_TARGET:-}"
CI_UPSTREAM_OWNER="${CI_UPSTREAM_OWNER:-dausume}"
route_target_state(){ # → 'OK', or the reason this device may not publish
    [ "$CI_MODE" = app ] || { echo OK; return 0; }
    [ -n "$CI_APP_NAME" ] || { echo "app mode names no app (CI_APP_NAME) — there is nothing to release"; return 1; }
    [ -n "$CI_ROUTE_TARGET" ] || { echo "app mode publishes to YOUR routes but CI_ROUTE_TARGET is empty — set it to your own owner/namespace"; return 1; }
    case "$CI_ROUTE_TARGET" in
        "$CI_UPSTREAM_OWNER"|"$CI_UPSTREAM_OWNER"/*)
            echo "CI_ROUTE_TARGET is the UPSTREAM owner ($CI_UPSTREAM_OWNER) — a fork is never republished under an upstream name"; return 1 ;;
    esac
    echo OK
}
release_assets(){ # release_assets <dir> — the files this route MAY publish
    local d="$1" f base app passed; passed=" $(tested_apps) "
    for f in "$d"/*; do
        [ -f "$f" ] || continue
        base="$(basename "$f")"
        # app mode: the ONE app's deb, and nothing else — not the core it was
        # tested against, not another app a stage happened to test here.
        if [ "$CI_MODE" = app ]; then
            case "$base" in
                "polari-app-${CI_APP_NAME}_"*.deb)
                    case "$passed" in *" $CI_APP_NAME "*) echo "$f" ;; esac ;;
            esac
            continue
        fi
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
    # ci-9 — THE TARGET RULE, equally hard: an app-mode device that has not
    # named its OWN owner/namespace, or has named the upstream one, publishes
    # nothing. DRY_RUN=false does not override this either.
    local twhy
    if ! twhy="$(route_target_state)" || [ "$twhy" != OK ]; then
        DRY_RUN=1; state="DRY ($twhy)"
    fi
    echo "== route $ROUTE  version $VERSION  $state  pool $POOL_DIR"
    [ "$CI_MODE" = app ] && echo "[$ROUTE] app mode: releasing ONLY polari-app-$CI_APP_NAME to ${CI_ROUTE_TARGET:-(no target)} — the core it was tested against is NOT re-released" || true
    excluded="$(release_excluded "$POOL_DIR/debs" 2>/dev/null || true)"
    [ -n "$excluded" ] && { echo "[$ROUTE] not released: untested/failed —"; printf '%s\n' "$excluded" | sed 's/^/    /'; } || true
    for spec in "$@"; do need "${spec%%:*}" "${spec#*:}"; done
}

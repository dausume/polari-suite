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
arm(){ # arm VAR:area/name … — the FIRST line of every route: resolve DRY_RUN=auto and say why
    local spec var path missing="" state
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
    echo "== route $ROUTE  version $VERSION  $state  pool $POOL_DIR"
    for spec in "$@"; do need "${spec%%:*}" "${spec#*:}"; done
}

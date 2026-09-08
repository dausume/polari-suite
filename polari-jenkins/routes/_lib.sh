# shared by every route: DRY_RUN rendering + the honest refusal when a secret is absent
set -eu
DRY_RUN="${DRY_RUN:-1}"
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
echo "== route $ROUTE  version $VERSION  dry_run=$DRY_RUN  pool $POOL_DIR"

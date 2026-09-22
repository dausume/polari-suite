#!/bin/bash
# polari-jenkins/deploy/targets.sh — THE DEPLOYMENT TARGETS (dep-0, plan §11.2).
#
# One row per place Polari runs. The `cicd` app's DeployTarget rows are the
# source of truth; this file is their fallback on the device, exactly as
# device.env is for the device itself (cicd-sync.sh pull rewrites it).
#
#   deploy/targets.env      gitignored. NEVER an address or a hostname — an ssh
#                           ALIAS from the pipeline user's ~/.ssh/config, and a
#                           chosen name that may be rendered on a page.
#
# Sourced by conditions.sh / apply.sh / deploy.sh:
#   targets_list                     → the names, one per line
#   target_field <name> <FIELD> [dflt]
#   target_exists <name>
#   target_write <name> FIELD=value …   (add or change; keeps the rest)
#   target_remove <name>
[ -n "${_TARGETS_SH:-}" ] && return 0; _TARGETS_SH=1
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS_ENV="${CI_DEPLOY_TARGETS_ENV:-$DEPLOY_DIR/targets.env}"

# the fields, with their defaults — the ONE list (deploy.sh add asks these, the doctor reads these)
TARGET_FIELDS="SSH_ALIAS ROUTE PROFILE CHANNEL WINDOW HEALTH MIN_FREE_GB HOLD NEEDS SETTLE_S"
target_default() {
    case "$1" in
        ROUTE) echo swarm ;; PROFILE) echo lean ;; CHANNEL) echo release ;; WINDOW) echo any ;;
        HEALTH) echo '' ;; MIN_FREE_GB) echo 4 ;; HOLD) echo true ;;
        NEEDS) echo github-release,ghcr ;;   # the publish routes this target CONSUMES (debs, images)
        SETTLE_S) echo 60 ;; *) echo '' ;;
    esac
}
_tkey() { printf 'DEPLOY_%s_%s' "$(printf '%s' "$1" | tr '-' '_' | tr -c 'A-Za-z0-9_\n' '_')" "$2"; }

_targets_load() {
    [ -f "$TARGETS_ENV" ] || return 0
    # shellcheck disable=SC1090
    set -a; . "$TARGETS_ENV"; set +a
}
targets_list() { _targets_load; printf '%s\n' ${DEPLOY_TARGETS:-} | sed '/^$/d'; }
target_exists() { targets_list | grep -qx -- "$1"; }
target_field() {  # target_field <name> <FIELD> [default]
    _targets_load
    local k v; k="$(_tkey "$1" "$2")"; v="${!k:-}"
    [ -n "$v" ] && printf '%s' "$v" || printf '%s' "${3:-$(target_default "$2")}"
}
target_write() {  # target_write <name> FIELD=value …
    local name="$1"; shift
    python3 - "$TARGETS_ENV" "$name" "$@" <<'PY'
import re, sys, os, shlex
path, name = sys.argv[1:3]
key = 'DEPLOY_%s_' % re.sub(r'[^A-Za-z0-9_]', '_', name.replace('-', '_'))
lines = open(path).read().splitlines() if os.path.exists(path) else []
targets = []
for l in lines:
    if l.startswith('DEPLOY_TARGETS='):
        targets = l.split('=', 1)[1].strip().strip('"').split()
if name not in targets:
    targets.append(name)
new = {}
for kv in sys.argv[3:]:
    k, _, v = kv.partition('=')
    new[key + k] = shlex.quote(v)   # the file is SOURCED: a value with spaces (HEALTH urls) must be quoted
out = []
seen = set()
for l in lines:
    if l.startswith('DEPLOY_TARGETS='):
        out.append('DEPLOY_TARGETS="%s"' % ' '.join(targets)); seen.add('DEPLOY_TARGETS'); continue
    k = l.split('=', 1)[0]
    if k in new:
        out.append('%s=%s' % (k, new[k])); seen.add(k); continue
    out.append(l)
if 'DEPLOY_TARGETS' not in seen:
    out.insert(0, 'DEPLOY_TARGETS="%s"' % ' '.join(targets))
for k, v in new.items():
    if k not in seen:
        out.append('%s=%s' % (k, v))
os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
tmp = path + '.tmp'
open(tmp, 'w').write('\n'.join(out) + '\n'); os.chmod(tmp, 0o600); os.replace(tmp, path)
PY
}
target_remove() {
    python3 - "$TARGETS_ENV" "$1" <<'PY'
import re, sys, os
path, name = sys.argv[1:3]
if not os.path.exists(path): sys.exit(0)
key = 'DEPLOY_%s_' % re.sub(r'[^A-Za-z0-9_]', '_', name.replace('-', '_'))
out = []
for l in open(path).read().splitlines():
    if l.startswith('DEPLOY_TARGETS='):
        t = [x for x in l.split('=', 1)[1].strip().strip('"').split() if x != name]
        out.append('DEPLOY_TARGETS="%s"' % ' '.join(t)); continue
    if l.startswith(key): continue
    out.append(l)
open(path, 'w').write('\n'.join(out) + '\n')
PY
}
target_show() {  # target_show <name> → FIELD=value lines
    local f; for f in $TARGET_FIELDS; do printf '%s=%s\n' "$f" "$(target_field "$1" "$f")"; done
}

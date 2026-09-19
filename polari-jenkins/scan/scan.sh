#!/bin/bash
# polari-jenkins/scan/scan.sh — the ADVISORY scanning layer (scn-0,
# SCANNING_AND_RELEASE_AUTOMATION_PLAN.md §2; driven by the ci-12 test pipeline).
#
# THE RULE, AND IT IS THE FIRST LINE FOR A REASON: **every stage exits 0**.
# A finding is never a gate. Not here, not in the test verdict, not in the
# release rule. Scans are recorded so a person can read them; that is the whole
# of their authority (his standing rule 2026-09-19). A tool that is missing, a
# pull that fails, a report that will not parse — each is a LINE in the summary
# and an exit of 0. The only thing a scan can cost a build is time and disk,
# and `retention.sh guard` already bounds both.
#
#   scan.sh source  [--out DIR]           gitleaks + trivy fs (vuln, misconfig, secret, licence)
#   scan.sh deps    [--out DIR]           trivy fs (lockfiles) + pip-audit + npm audit
#   scan.sh images  [--out DIR] [ref…]    trivy image, per built image
#   scan.sh debs    [--out DIR] [dir]     trivy fs over each unpacked .deb
#   scan.sh all     [--out DIR]           all four, in that order
#   scan.sh summary [--out DIR]           (re)write SCAN_SUMMARY.md from what is there
#   scan.sh lock                          print the pinned tools
#   scan.sh lock-resolve                  pull each image and write its digest back into the lock
#
# --out defaults to $SCAN_OUT, else <pool>/scan.  Reports land as
# <out>/<tool>.json (+ <tool>-<target>.json for per-target runs), a
# <out>/SKIPPED.txt line per tool that could not run, and <out>/SCAN_SUMMARY.md.
set -uo pipefail          # deliberately NOT -e: a failing scanner must not end the run

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
J="$(cd "$HERE/.." && pwd)"
LOCK="${SCAN_LOCK:-$J/scan-tools.lock}"
WORK="${SCAN_WORKSPACE:-$PWD}"
POOL="${POLARI_POOL:-$J/pool}"
OUT="${SCAN_OUT:-$POOL/scan}"
TIMEOUT="${POLARI_SCAN_TIMEOUT:-600}"
DOCKER="${SCAN_DOCKER:-docker}"

say()  { printf '[scan] %s\n' "$*"; }
skip() { printf '[scan] SKIPPED: %s\n' "$*"; mkdir -p "$OUT"; printf '%s\n' "$*" >> "$OUT/SKIPPED.txt"; }

# ----------------------------------------------------------------- the lock
lock_image() {  # lock_image <tool> → image[@digest], or empty
    local tool="$1" image digest
    image="$(awk -F'|' -v t="$tool" '$1 ~ /^[a-z]/ { gsub(/ /,"",$1); if ($1==t) { gsub(/^ +| +$/,"",$2); print $2 } }' "$LOCK" 2>/dev/null | head -1)"
    digest="$(awk -F'|' -v t="$tool" '$1 ~ /^[a-z]/ { gsub(/ /,"",$1); if ($1==t) { gsub(/^ +| +$/,"",$3); print $3 } }' "$LOCK" 2>/dev/null | head -1)"
    [ -n "$image" ] || return 1
    case "$image" in host:*) printf '%s' "$image"; return 0 ;; esac
    case "$digest" in
        sha256:*) printf '%s@%s' "${image%%:*}" "$digest" ;;
        *)        printf '%s' "$image" ;;
    esac
}

lock_print() {
    printf 'tool      image                          digest        licence      what\n'
    awk -F'|' '$1 ~ /^[a-z]/ { gsub(/^ +| +$/,"",$1); gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$3);
               gsub(/^ +| +$/,"",$4); gsub(/^ +| +$/,"",$5);
               printf "%-9s %-30s %-13s %-12s %s\n", $1, $2, substr($3,1,13), $4, $5 }' "$LOCK"
    printf '\nevery tool above is ADVISORY — no finding of any of them gates anything\n'
}

lock_resolve() {
    local tool image d tmp; tmp="$(mktemp)"
    cp "$LOCK" "$tmp"
    while IFS='|' read -r tool image _rest; do
        tool="$(printf '%s' "$tool" | tr -d ' ')"; image="$(printf '%s' "$image" | xargs)"
        case "$tool" in ''|\#*) continue ;; esac
        case "$image" in host:*) continue ;; esac
        say "pulling $image to resolve its digest…"
        if ! "$DOCKER" pull "$image" >/dev/null 2>&1; then
            skip "$tool: $image could not be pulled — its pin stays unresolved and the tool still runs by tag"
            continue
        fi
        d="$("$DOCKER" image inspect --format '{{index .RepoDigests 0}}' "$image" 2>/dev/null | sed 's/.*@//')"
        [ -n "$d" ] || { skip "$tool: $image has no repo digest locally (built, not pulled?)"; continue; }
        python3 - "$tmp" "$tool" "$d" <<'PY'
import sys
path, tool, digest = sys.argv[1:4]
out = []
for line in open(path):
    parts = line.split('|')
    if len(parts) >= 5 and parts[0].strip() == tool:
        parts[2] = ' %s ' % digest
        line = '|'.join(parts)
    out.append(line)
open(path, 'w').writelines(out)
PY
        say "$tool → $d"
    done < "$LOCK"
    mv "$tmp" "$LOCK"
    lock_print
}

# --------------------------------------------------------------- the runners
# Every runner writes a report and returns 0. Always.
have_docker() { command -v "$DOCKER" >/dev/null 2>&1 && "$DOCKER" info >/dev/null 2>&1; }

run_trivy() {  # run_trivy <report-name> <trivy args…>
    local name="$1"; shift
    local img; img="$(lock_image trivy)" || { skip "trivy: not in $LOCK"; return 0; }
    have_docker || { skip "trivy: no usable docker daemon — $name not scanned"; return 0; }
    mkdir -p "$OUT" "$POOL/cache/scanners"
    say "trivy ($img) → $OUT/$name.json"
    timeout "$TIMEOUT" "$DOCKER" run --rm \
        -v "$WORK:/work:ro" -v "$POOL/cache/scanners:/root/.cache/trivy" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$OUT:/out" "$img" --quiet --format json --output "/out/$name.json" "$@" \
        2>&1 | tail -5
    [ -s "$OUT/$name.json" ] || { skip "trivy: $name produced no report (see the lines above)"; }
    return 0
}

scan_source() {
    mkdir -p "$OUT"
    # 1. secrets in the working tree
    local gl; gl="$(lock_image gitleaks)"
    if [ -n "$gl" ] && have_docker; then
        say "gitleaks ($gl) → $OUT/gitleaks.json"
        timeout "$TIMEOUT" "$DOCKER" run --rm -v "$WORK:/work:ro" -v "$OUT:/out" "$gl" \
            detect --source /work --no-git --report-format json --report-path /out/gitleaks.json \
            --exit-code 0 2>&1 | tail -5
        [ -f "$OUT/gitleaks.json" ] || skip "gitleaks: no report produced"
    else
        skip "gitleaks: no image in $LOCK or no docker daemon"
    fi
    # 2. the tree itself: misconfiguration, secrets, licences
    run_trivy trivy-source fs --scanners misconfig,secret --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL /work
    return 0
}

scan_deps() {
    mkdir -p "$OUT"
    run_trivy trivy-deps fs --scanners vuln --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL /work
    # pip-audit and npm audit are HOST tools: they run in the workspace image
    # when it carries them, and are skipped with a line when it does not. No
    # container is invented for them here — an unpinned one would be worse than
    # an honest skip.
    local fw="$WORK/polari-rf-node/polari-framework"
    if command -v pip-audit >/dev/null 2>&1 && [ -f "$fw/requirements.txt" ]; then
        say "pip-audit → $OUT/pip-audit.json"
        timeout "$TIMEOUT" pip-audit -r "$fw/requirements.txt" -f json -o "$OUT/pip-audit.json" 2>&1 | tail -5
    else
        skip "pip-audit: not in the workspace image (or no requirements.txt) — install it there to include Python advisories"
    fi
    local ng="$WORK/polari-rf-node/polari-platform-angular"
    if command -v npm >/dev/null 2>&1 && [ -f "$ng/package-lock.json" ]; then
        say "npm audit → $OUT/npm-audit.json"
        ( cd "$ng" && timeout "$TIMEOUT" npm audit --json --package-lock-only ) > "$OUT/npm-audit.json" 2>/dev/null
        [ -s "$OUT/npm-audit.json" ] || skip "npm audit: produced no report"
    else
        skip "npm audit: npm is not in the workspace image (or no package-lock.json)"
    fi
    return 0
}

scan_images() {
    local refs=("$@")
    [ ${#refs[@]} -gt 0 ] || refs=(prf-backend:staging prf-frontend:staging pol-reticulum:staging)
    have_docker || { skip "images: no usable docker daemon"; return 0; }
    local ref safe
    for ref in "${refs[@]}"; do
        if ! "$DOCKER" image inspect "$ref" >/dev/null 2>&1; then
            skip "image $ref is not on this daemon — nothing to scan (the build stage did not make it)"
            continue
        fi
        safe="$(printf '%s' "$ref" | tr '/:' '--')"
        run_trivy "trivy-image-$safe" image --scanners vuln --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL "$ref"
    done
    return 0
}

scan_debs() {
    local dir="${1:-$WORK/.generated/debs}"
    if [ ! -d "$dir" ]; then skip "debs: $dir does not exist — nothing was built here"; return 0; fi
    local n=0 f base tmp
    for f in "$dir"/*.deb; do
        [ -f "$f" ] || continue
        n=$((n+1)); base="$(basename "$f" .deb)"
        tmp="$(mktemp -d)"
        if dpkg-deb -x "$f" "$tmp" 2>/dev/null; then
            SCAN_WORKSPACE_SAVE="$WORK"; WORK="$tmp"
            run_trivy "trivy-deb-$base" fs --scanners vuln,secret --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL /work
            WORK="$SCAN_WORKSPACE_SAVE"
        else
            skip "deb $base: dpkg-deb could not unpack it here"
        fi
        rm -rf "$tmp"
    done
    [ "$n" -gt 0 ] || skip "debs: no .deb in $dir"
    return 0
}

do_summary() {
    mkdir -p "$OUT"
    python3 "$HERE/summarize.py" summary "$OUT" "$LOCK" || true
    [ -f "$OUT/SCAN_SUMMARY.md" ] && say "summary: $OUT/SCAN_SUMMARY.md"
    return 0
}

# ------------------------------------------------------------------ dispatch
VERB="${1:-all}"; shift || true
while [ $# -gt 0 ]; do
    case "$1" in --out) OUT="${2:-$OUT}"; shift ;; *) break ;; esac
    shift
done
mkdir -p "$OUT"

case "$VERB" in
    source)  scan_source ;;
    deps)    scan_deps ;;
    images)  scan_images "$@" ;;
    debs)    scan_debs "${1:-}" ;;
    all)     scan_source; scan_deps; scan_images; scan_debs; do_summary ;;
    summary) do_summary ;;
    lock)    lock_print ;;
    lock-resolve) lock_resolve ;;
    --help|-h) sed -n '2,30p' "$0" ;;
    *) printf '[scan] unknown verb %r — source|deps|images|debs|all|summary|lock|lock-resolve\n' "$VERB" >&2 ;;
esac
# ADVISORY: this script exits 0 whatever any scanner said.
exit 0

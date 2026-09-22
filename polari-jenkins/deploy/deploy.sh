#!/bin/bash
# polari-jenkins/deploy/deploy.sh — `pol jenkins deploy …` (dep-0/1, plan §11.5)
#
#   deploy list                          every target: name · alias · route · channel · hold · what it runs · last outcome
#   deploy add <name> [FIELD=value …]    write a target (asks what is not given; never an address — an ssh ALIAS)
#   deploy remove <name>
#   deploy show <name>
#   deploy authorize <name>              the PIPELINE user's key onto the target (isle/authorize.sh — fingerprint-verified)
#   deploy check <name> [<version>]      the conditions as a REPORT: GO/SKIP per condition with its evidence; nothing written
#   deploy <name> --now [<version>]      a PERSON's deploy: overrides hold + window + an earlier failure; still refuses on
#                                        newer/tested/published/healthy/disk/idle
#   deploy <name> --dry-run [<version>]  the exact ssh commands, rendered; nothing sent
#   deploy status [<name>]               what runs where, since when, from which release (pool/deploy/*)
# <version> defaults to the newest release in the pool.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; J="$(cd "$HERE/.." && pwd)"
. "$HERE/targets.sh"
POOL="${POLARI_POOL:-$J/pool}"
newest_version() { ls -1 "$POOL" 2>/dev/null | grep -E '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}(\.[0-9]+)?$' | sort -V | tail -1; }
last_outcome() {  # last_outcome <target> → 'applied 2026.09.22 at …' | 'failed …' | 'skipped …' | 'never'
    local d="$POOL/deploy/$1" f
    f="$(ls -t "$d"/*/applied.json "$d"/*/failed.json 2>/dev/null | head -1)"
    [ -n "$f" ] || { echo never; return; }
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("%s %s at %s" % (d.get("result"), d.get("release"), d.get("at","?")[:16]))' "$f"
}
cmd="${1:-list}"; shift || true
case "$cmd" in
    list)
        printf '%-14s %-12s %-6s %-8s %-5s %-24s %s\n' TARGET ALIAS ROUTE CHANNEL HOLD RUNS "LAST OUTCOME"
        for t in $(targets_list); do
            cur="$(ssh -o BatchMode=yes -o ConnectTimeout=6 "$(target_field "$t" SSH_ALIAS)" "pol prod agent current" 2>/dev/null | sed -n 's/^release=//p' | head -1)"
            printf '%-14s %-12s %-6s %-8s %-5s %-24s %s\n' "$t" "$(target_field "$t" SSH_ALIAS)" "$(target_field "$t" ROUTE)" "$(target_field "$t" CHANNEL)" \
                   "$(target_field "$t" HOLD)" "${cur:-(unreachable or none)}" "$(last_outcome "$t")"
        done
        [ -n "$(targets_list)" ] || echo "(no targets — pol jenkins deploy add <name>)"
        echo "targets file: $TARGETS_ENV (gitignored; the cicd app's DeployTarget rows are the source of truth when a core is set)" ;;
    add)
        name="${1:?deploy add <name> [FIELD=value …]}"; shift
        case "$name" in *[!a-zA-Z0-9_-]*) echo "a target NAME is chosen: letters, digits, - and _ (never a hostname)" >&2; exit 2 ;; esac
        args=("$@"); given=" ${args[*]} "
        for f in $TARGET_FIELDS; do
            case "$given" in *" $f="*) continue ;; esac
            if [ "$f" = SSH_ALIAS ]; then
                if [ -t 0 ]; then read -r -p "ssh alias (a Host entry in the pipeline user's ssh config, never an address): " v; else v=""; fi
                [ -n "$v" ] || { echo "SSH_ALIAS is required (deploy add $name SSH_ALIAS=<alias> …)" >&2; exit 2; }
                args+=("SSH_ALIAS=$v")
            elif [ -t 0 ]; then
                read -r -p "$f [$(target_default "$f")]: " v; args+=("$f=${v:-$(target_default "$f")}")
            fi
        done
        target_write "$name" "${args[@]}"
        echo "wrote $name → $TARGETS_ENV"; target_show "$name" | sed 's/^/  /'
        echo "next: pol jenkins deploy authorize $name   (the pipeline user's key onto it), then pol jenkins deploy check $name" ;;
    remove) target_remove "${1:?name}"; echo "removed ${1}" ;;
    show)   target_exists "${1:?name}" || { echo "no such target"; exit 2; }; target_show "$1" ;;
    authorize)
        t="${1:?deploy authorize <name>}"; target_exists "$t" || { echo "no such target '$t'" >&2; exit 2; }
        # the key is RESTRICTED to the target's deploy agent (his ruling: the pipeline's ssh cannot touch production secrets)
        exec bash "$J/isle/authorize.sh" "$(target_field "$t" SSH_ALIAS)" --forced-command auto ;;
    check)
        t="${1:?deploy check <name> [<version>]}"; v="${2:-$(newest_version)}"
        [ -n "$v" ] || { echo "no release in the pool to check against"; exit 2; }
        bash "$HERE/conditions.sh" "$t" "$v" --report ;;
    status)
        for t in $(targets_list); do
            [ -z "${1:-}" ] || [ "$1" = "$t" ] || continue
            echo "$t:"; for f in "$POOL/deploy/$t"/*/*.json; do
                [ -f "$f" ] || continue
                python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("  %-8s %-24s %s  %s" % (d.get("result") or d.get("verdict"), d.get("release") or ("polari-v"+d.get("version","?")), d.get("at","?")[:19], (d.get("first_false") or {}).get("evidence","") if d.get("verdict")=="skipped" else d.get("rollback","")))' "$f"
            done
        done ;;
    *)
        t="$cmd"; target_exists "$t" || { echo "no such target or verb '$t' — pol jenkins deploy help" >&2; exit 2; }
        mode="${1:-}"; v="${2:-$(newest_version)}"
        case "$mode" in
            --now)     bash "$HERE/apply.sh" "$t" "$v" --now ;;
            --dry-run) bash "$HERE/apply.sh" "$t" "$v" --dry-run ;;
            *) echo "pol jenkins deploy $t --now|--dry-run [<version>]   (an automatic deploy is the polari-deploy job's)" >&2; exit 2 ;;
        esac ;;
esac

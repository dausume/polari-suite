#!/bin/bash
# polari-jenkins/setup.sh — `pol jenkins setup`: ONE SHOT. His ask
# 2026-09-19: "Our setup command for the pol jenkins should walk us
# through our options and tell us how and what we should be setting up
# and where to get everything to work" … "this way pol jenkins setup is
# a one shot setup."
#
# So every step, in order:
#   1. EXPLAINS the option in plain words,
#   2. CHECKS the current state live — by running the doctor, the
#      preflight and secrets.sh, never by re-implementing their checks,
#   3. says WHAT to set up, HOW (the exact command or clicks) and WHERE
#      to get it (the URL or the package),
#   4. OFFERS to do the local part itself (yes/no, default yes) and then
#      DOES it — apt, usermod, nmcli, init-device, key generation,
#      device.env, ssh-copy-id, the sudoers drop-in, `pol jenkins up`,
#   5. ends with "done / still to do, in order", saved to SETUP_STATUS.md.
#
# What it can NEVER do for you: fetch a token from an outside site. Those
# steps print the exact URL and scopes and then take the value pasted in
# (hidden), storing it through `pol jenkins secrets put`.
#
#   setup.sh [--yes] [--non-interactive|--report] [--step <name>] [--help]
#     --yes              answer every SAFE local question yes (never invents a token)
#     --report           read-only: print the state and the to-do list, change nothing
#     --step <name>      re-run one step (role checkout network secrets isle stages controller)
#
#   THE MACHINE PROTOCOL (ci-11a) — one JSON document on stdout, logs on stderr:
#     --json                     the whole walkthrough as `polari-pipeline-setup/1`
#     --json --step <name>       recompute one step
#     --json --answer KEY=VALUE  write an answer to device.env (repeatable; NEVER a secret)
#     --json --run <action-id>   run ONE unprivileged action and return its step
#   --json never prompts and never runs anything privileged: a privileged
#   action is DESCRIBED, naming a verb from polari-jenkins/shell-verbs.json.
#   It works with no Polari core running and with no device.env at all.
#
# Never prints or logs a secret VALUE. Never writes a LAN address, a
# hostname or an e-mail anywhere — the isle device is an ssh ALIAS.
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE="$(cd "$J/.." && pwd)"
STATUS_FILE="$J/SETUP_STATUS.md"
CLI_JENKINS="$SUITE/polari-cli/scripts/jenkins.sh"

# shellcheck source=device.sh
source "$J/device.sh"
# shellcheck source=secrets.sh
source "$J/secrets.sh"
TUI_LIB="${POL_TUI_LIB:-$SUITE/polari-cli/scripts/lib/tui.sh}"
[ -r "$TUI_LIB" ] || { echo "setup: cannot find the dialog helpers ($TUI_LIB) — is the polari-cli submodule populated? (git submodule update --init)" >&2; exit 2; }
# shellcheck source=/dev/null
source "$TUI_LIB"

MODE=interactive; ASSUME_YES=0; ONE_STEP=""; JSON=0; RUN_ACTION=""; ANSWERS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --yes|-y) ASSUME_YES=1 ;;
        --report|--non-interactive) MODE=report ;;
        --step) shift; ONE_STEP="${1:-}" ;;
        --json) JSON=1; MODE=json ;;
        --answer) shift; ANSWERS+=("${1:-}") ;;
        --run) shift; RUN_ACTION="${1:-}" ;;
        --help|-h) sed -n '2,38p' "$0"; exit 0 ;;
        *) echo "setup.sh: unknown argument '$1' (--yes --report --step <name> --json --answer K=V --run <id> --help)" >&2; exit 2 ;;
    esac; shift
done
if [ "$JSON" = 0 ] && { [ -n "$RUN_ACTION" ] || [ ${#ANSWERS[@]} -gt 0 ]; }; then
    echo "setup.sh: --run and --answer belong to the machine protocol — use them with --json" >&2; exit 2
fi

SETUP_STEPS="role checkout network secrets isle stages controller summary"
SETUP_TOTAL=$(printf '%s\n' $SETUP_STEPS | wc -l | tr -d ' ')

# ------------------------------------------------------------- rendering
B=''; D=''; Y=''; G=''; R=''
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then B=$'\033[1m'; D=$'\033[0m'; Y=$'\033[1;33m'; G=$'\033[0;32m'; R=$'\033[0;31m'; fi
hdr()     { printf '\n%s══ step %s/%s — %s%s\n' "$B" "$1" "$SETUP_TOTAL" "$2" "$D"; }
explain() { printf '%s\n' "$1" | fold -s -w 74 | sed 's/^/   /'; }
check()   { case "$1" in
                OK)   printf '   %s[ok]%s   %s\n' "$G" "$D" "$2" ;;
                MISS) printf '   %s[--]%s   %s\n' "$Y" "$D" "$2" ;;
                BAD)  printf '   %s[!!]%s   %s\n' "$R" "$D" "$2" ;;
                *)    printf '   [..]   %s\n' "$2" ;;
            esac }
howto()   { printf '   %showto%s  %s\n' "$B" "$D" "$1"; }
where()   { printf '   %swhere%s  %s\n' "$B" "$D" "$1"; }

# ------------------------------------------------------------- the state
declare -A ST_STATE ST_NOTE
TODO_STEP=(); TODO_TEXT=(); TODO_HOW=()
CUR=""
state() { ST_STATE["$CUR"]="$1"; ST_NOTE["$CUR"]="${2:-}"; }
todo()  { TODO_STEP+=("$CUR"); TODO_TEXT+=("$1"); TODO_HOW+=("${2:-}"); }

# ------------------------------------------- the live checks, reused
# The doctor is the one place the host checks live (ci-7 (B)); the
# preflight is the one place the device-fitness checks live (ci-7 (A)).
# setup.sh runs them and READS their rows — it never re-implements one.
DOCTOR_OUT=""; DOCTOR_WARNS=-1
doctor_refresh() { DOCTOR_OUT=""; DOCTOR_WARNS=-1; }
doctor_ensure() {
    [ -n "$DOCTOR_OUT" ] && return 0
    DOCTOR_OUT="$(bash "$J/doctor.sh" 2>&1 || true)"
    DOCTOR_WARNS=$(printf '%s\n' "$DOCTOR_OUT" | sed -n 's/^doctor: \([0-9]*\) warning.*/\1/p' | tail -1)
    [ -n "$DOCTOR_WARNS" ] || DOCTOR_WARNS=0
}
doctor_row() {   # doctor_row <exact label> → "OK|WARN<TAB>message"; 1 when absent
    doctor_ensure
    local line st rest lbl
    while IFS= read -r line; do
        case "$line" in
            "OK    "*) st=OK ;;
            "WARN  "*) st=WARN ;;
            *) continue ;;
        esac
        rest="${line:6}"
        case "$rest" in *" — "*) ;; *) continue ;; esac
        lbl="${rest%% — *}"; lbl="${lbl%"${lbl##*[![:space:]]}"}"
        [ "$lbl" = "$1" ] || continue
        printf '%s\t%s\n' "$st" "${rest#* — }"; return 0
    done <<<"$DOCTOR_OUT"
    return 1
}
doctor_ok()  { local r; r="$(doctor_row "$1")" || return 2; [ "${r%%	*}" = OK ]; }
doctor_msg() { local r; r="$(doctor_row "$1")" || return 1; printf '%s' "${r#*	}"; }
# the doctor's WARN message is "<what is wrong> → <what to do>"
doctor_what() { local m; m="$(doctor_msg "$1")" || return 1; printf '%s' "${m%% → *}"; }
doctor_fix()  { local m; m="$(doctor_msg "$1")" || return 1; printf '%s' "${m##* → }"; }
# report a doctor row as one check line, and return its verdict
doctor_check() { # doctor_check <label> [prefix]
    # ci-11a: the doctor's WARN carries its own fix ("<what is wrong> → <what to
    # do>"), so the machine protocol's `fix` field is filled from the SAME row the
    # terminal prints. JSON_NEXT_FIX is consumed by the rebound `check` and is
    # inert in the interactive path.
    JSON_NEXT_FIX=""
    if doctor_ok "$1"; then check OK "${2:-$1}: $(doctor_msg "$1")"; return 0; fi
    if doctor_row "$1" >/dev/null 2>&1; then
        JSON_NEXT_FIX="$(doctor_fix "$1" 2>/dev/null || true)"
        check MISS "${2:-$1}: $(doctor_what "$1")"; JSON_NEXT_FIX=""; return 1
    fi
    check MISS "${2:-$1}: the doctor has no such row"; return 1
}

PREFLIGHT_JSON=""
preflight_json() {
    [ -n "$PREFLIGHT_JSON" ] && { printf '%s' "$PREFLIGHT_JSON"; return 0; }
    PREFLIGHT_JSON="$(bash "$J/isle/preflight.sh" --isle --json 2>/dev/null || true)"
    printf '%s' "$PREFLIGHT_JSON"
}
preflight_verdict() {
    local j; j="$(preflight_json)"
    printf '%s' "$j" | python3 -c 'import json,sys
try: print(json.load(sys.stdin)["verdict"])
except Exception: print("UNREADABLE")' 2>/dev/null || echo UNREADABLE
}

# ------------------------------------------------------------- the asks
ask() {   # ask <title> <question> [yes|no]  → 0 yes / 1 no
    [ "$MODE" = report ] && return 1
    if [ "$ASSUME_YES" = 1 ] && [ "${3:-yes}" = yes ]; then printf '   %s→ yes%s (--yes)\n' "$G" "$D"; return 0; fi
    tui_yesno "$1" "$2" "${3:-yes}"
}
ask_value() { [ "$MODE" = report ] && { printf ''; return 0; }; tui_input "$1" "$2" "${3:-}"; }
ask_secret() { [ "$MODE" = report ] && { printf ''; return 0; }; tui_password "$1" "$2"; }

act() {   # act <sentence> -- cmd…   : echo it, run it, say how it went
    local desc="$1"; shift; [ "${1:-}" = -- ] && shift
    printf '   %s$%s %s\n' "$B" "$D" "$*"
    if "$@"; then check OK "$desc"; doctor_refresh; return 0
    else check BAD "$desc — that command failed; the to-do list keeps it"; return 1; fi
}

# store one secret THROUGH the CLI (jd_secrets_put): it knows the posture,
# uses sudo when the system posture is in force, and never echoes a value.
setup_put_secret() {   # setup_put_secret <area/name>   — value on stdin
    [ -x "$CLI_JENKINS" ] || [ -r "$CLI_JENKINS" ] || { echo "   (polari-cli is not populated — cannot store $1)"; return 1; }
    bash "$CLI_JENKINS" secrets put "$1"
}

# ------------------------------------------------------------ the steps
for f in "$J"/setup/steps/*.sh; do
    # shellcheck source=/dev/null
    [ -r "$f" ] && source "$f"
done

step_title() { local v="STEP_TITLE_$1"; printf '%s' "${!v:-$1}"; }

run_checks() {   # every step's pure check, no prompts, no changes
    local visible="${1:-}" s n=1
    ST_STATE=(); ST_NOTE=(); TODO_STEP=(); TODO_TEXT=(); TODO_HOW=()
    for s in $SETUP_STEPS; do
        [ "$s" = summary ] && continue
        CUR="$s"; state todo
        if [ "$visible" = --visible ]; then
            hdr "$n" "$(step_title "$s")"
            "step_${s}_check" || true
        else
            "step_${s}_check" >/dev/null 2>&1 || true
        fi
        n=$((n+1))
    done
    CUR=""
}
step_index() { local s n=1; for s in $SETUP_STEPS; do [ "$s" = "$1" ] && { printf '%s' "$n"; return; }; n=$((n+1)); done; printf '?'; }

steps_done() {
    local s n=0
    for s in $SETUP_STEPS; do [ "${ST_STATE[$s]:-todo}" = done ] && n=$((n+1)); done
    printf '%s' "$n"
}

# --------------------------------------------------------------- summary
render_summary() {   # to stdout
    local s n=1
    printf '\n%s══ step %s/%s — summary%s\n' "$B" "$SETUP_TOTAL" "$SETUP_TOTAL" "$D"
    echo
    echo "   done:"
    for s in $SETUP_STEPS; do
        [ "$s" = summary ] && continue
        case "${ST_STATE[$s]:-todo}" in
            done) printf '     %s✓%s %s — %s\n' "$G" "$D" "$(step_title "$s")" "${ST_NOTE[$s]:-}" ;;
        esac
    done
    echo
    if [ ${#TODO_TEXT[@]} -eq 0 ]; then
        echo "   still to do: nothing."
    else
        echo "   still to do, in order:"
        local i
        for i in "${!TODO_TEXT[@]}"; do
            printf '     %2d. [%s] %s\n' "$n" "${TODO_STEP[$i]}" "${TODO_TEXT[$i]}"
            [ -n "${TODO_HOW[$i]}" ] && printf '         → %s\n' "${TODO_HOW[$i]}" || true
            n=$((n+1))
        done
    fi
    echo
    explain "THE RELEASE RULE — the pipeline only generates artifacts for things it TESTED in a throwaway isle. Stages now: $CI_ISLE_STAGES. Core debs and images publish only when the isle test recorded core_ok; an app's deb ships only when its stage result is pass; with no isle-test/results.json for a version NOTHING is published and the tag is not pushed."
    echo
    printf '   %s\n' "$VERDICT_LINE"
    printf '   steps: %s of %s complete   ·   full state: pol jenkins setup --report\n' "$(steps_done)" "$SETUP_TOTAL"
}

compute_verdict() {
    doctor_refresh; doctor_ensure
    local pv; pv="$(preflight_verdict)"
    if [ "$DOCTOR_WARNS" = 0 ] && [ "$pv" = PASS ]; then
        VERDICT_LINE="${G}READY${D} — the doctor has 0 warnings and the preflight passes. This device can run the pipeline."
        CUR=summary; ST_STATE[summary]=done; ST_NOTE[summary]="READY"
    else
        local one="${TODO_TEXT[0]:-}"
        [ -n "$one" ] || one="the doctor reports $DOCTOR_WARNS warning(s) and the preflight says $pv"
        VERDICT_LINE="${Y}NOT READY${D} — ${#TODO_TEXT[@]} thing(s) stand in the way; the first is: $one"
        ST_STATE[summary]=todo; ST_NOTE[summary]="$pv"
    fi
    VERDICT_SHORT="$([ "$DOCTOR_WARNS" = 0 ] && [ "$pv" = PASS ] && echo READY || echo 'NOT READY')"
    PRE_VERDICT="$pv"
}

write_status_file() {
    local s i n=1
    {
        echo "# polari-jenkins — setup status"
        echo
        echo "_Written by \`pol jenkins setup\` on $(date +%Y-%m-%d\ %H:%M). This file is gitignored;"
        echo "it names no address and no host — the isle device is an ssh alias._"
        echo
        echo "**verdict: $VERDICT_SHORT** · doctor warnings: $DOCTOR_WARNS · preflight --isle: $PRE_VERDICT"
        echo
        echo "steps: $(steps_done) of $SETUP_TOTAL complete"
        echo
        echo "| # | step | state | note |"
        echo "|---|---|---|---|"
        for s in $SETUP_STEPS; do
            printf '| %s | %s | %s | %s |\n' "$n" "$(step_title "$s")" "${ST_STATE[$s]:-todo}" "${ST_NOTE[$s]:-}"
            n=$((n+1))
        done
        echo
        echo "## still to do, in order"
        echo
        if [ ${#TODO_TEXT[@]} -eq 0 ]; then echo "Nothing."; else
            n=1
            for i in "${!TODO_TEXT[@]}"; do
                printf '%s. **[%s]** %s\n' "$n" "${TODO_STEP[$i]}" "${TODO_TEXT[$i]}"
                [ -n "${TODO_HOW[$i]}" ] && printf '   - `%s`\n' "${TODO_HOW[$i]}" || true
                n=$((n+1))
            done
        fi
        echo
        echo "## the release rule"
        echo
        echo "The pipeline only generates artifacts for things it TESTED in a throwaway"
        echo "isle. Stages: \`$CI_ISLE_STAGES\`. Core debs/images publish only when the"
        echo "isle test recorded \`core_ok\`; an app deb ships only when its stage result"
        echo "is \`pass\`; with no \`isle-test/results.json\` for a version **nothing** is"
        echo "published and the tag is not pushed."
        echo
        echo "Re-run: \`pol jenkins setup\` · one step: \`pol jenkins setup --step <name>\` · state only: \`pol jenkins setup --report\`"
    } > "$STATUS_FILE"
}

# ------------------------------------------------------------------ main
banner() {
    printf '%s\n' "$B┌──────────────────────────────────────────────────────────────────────────┐$D"
    printf '%s\n' "$B│ pol jenkins setup — the pipeline device, one step at a time              │$D"
    printf '%s\n' "$B└──────────────────────────────────────────────────────────────────────────┘$D"
    echo "   device: $(device_target_name)   secrets posture: $(secrets_mode)   mode: $MODE$([ "$ASSUME_YES" = 1 ] && echo ' (--yes)')"
    if [ "$MODE" = report ]; then
        echo "   READ-ONLY: this run changes nothing. It prints the state and the to-do list."
    else
        echo "   Every step asks before it does anything. Ctrl-C is always safe."
        tui_available && echo "   (whiptail dialogs)" || echo "   (plain prompts — whiptail is not installed or there is no terminal)"
    fi
}

if [ -n "$ONE_STEP" ]; then
    case " $SETUP_STEPS " in *" $ONE_STEP "*) ;; *) echo "setup: no such step '$ONE_STEP' (try: $SETUP_STEPS)" >&2; exit 2 ;; esac
fi

# ---------------------------------------------------------- the machine path
# ONE JSON document on stdout and NOTHING else. The step functions print as
# they always did — a raw `echo` in a step, `stages_print`, a tool's own
# chatter — so stdout is moved out of their reach for the whole computation
# (fd 3 holds the real one) and given back only to print the document. That
# is why "no stdout noise" is a property of this file rather than a promise
# every future step has to keep.
if [ "$JSON" = 1 ]; then
    # shellcheck source=setup/json.sh
    source "$J/setup/json.sh"
    exec 3>&1 1>&2
    printf 'setup --json: %s · device %s · secrets %s%s%s\n' \
        "${ONE_STEP:-the whole walkthrough}" "$(device_target_name)" "$(secrets_mode)" \
        "${RUN_ACTION:+ · run $RUN_ACTION}" "$([ ${#ANSWERS[@]} -gt 0 ] && echo " · ${#ANSWERS[@]} answer(s)")" >&2
    json_main "$ONE_STEP" "$RUN_ACTION" "${ANSWERS[@]:-}" || true
    exec 1>&3 3>&-
    if [ -s "${JSON_DOC_FILE:-}" ]; then
        cat "$JSON_DOC_FILE"; rm -f "$JSON_DOC_FILE"
        exit 0
    fi
    rm -f "${JSON_DOC_FILE:-/dev/null}" 2>/dev/null || true
    printf '{"protocol":"polari-pipeline-setup/1","error":"the setup protocol could not be produced — run `pol jenkins setup --report` at a terminal to see why"}\n'
    exit 1
fi

banner
if [ "$MODE" = report ]; then
    run_checks --visible
elif [ -n "$ONE_STEP" ] && [ "$ONE_STEP" != summary ]; then
    CUR="$ONE_STEP"; state todo
    hdr "$(step_index "$ONE_STEP")" "$(step_title "$ONE_STEP")"
    "step_${ONE_STEP}_do" || true
    run_checks
else
    STEP_N=1
    for s in $SETUP_STEPS; do
        [ "$s" = summary ] && continue
        CUR="$s"; state todo
        hdr "$STEP_N" "$(step_title "$s")"
        "step_${s}_do" || true
        STEP_N=$((STEP_N+1))
    done
    run_checks
fi

compute_verdict
render_summary
write_status_file
echo "   saved: $STATUS_FILE (gitignored)"
exit 0

#!/bin/bash
# polari-jenkins/setup/json.sh — `pol jenkins setup --json`: the machine
# half of the SAME walkthrough. ci-11a.
#
#   setup.sh --json                        the whole document (8 steps)
#   setup.sh --json --step <name>          one step, recomputed
#   setup.sh --json --answer KEY=VALUE …   write answers to device.env, then recompute
#   setup.sh --json --run <action-id>      run ONE unprivileged action, return its step
#
# ONE SOURCE OF TRUTH. The `checks` of every step come from running that
# step's own `step_<name>_check` — the very function the interactive path
# prints — with `check`/`explain`/`where` rebound to record instead of
# print. A check can therefore never drift between the terminal and a
# screen: there is only one of it. What the interactive path ASKS (the
# tui_menu / ask_value calls, which cannot run unattended) is declared
# beside it, in the same step file, by `step_<name>_json`.
#
# LAYER BOUNDARY (his rule 2026-09-19 — "keep different pieces logically
# separate, like CLI vs JavaFX"). This file knows nothing about any
# desktop application. It never mentions pkexec, never branches on who is
# calling, and emits no Java. It marks an action `privileged: true` and
# names a VERB; which verbs exist and how they are elevated is the
# separate, tracked allowlist `polari-jenkins/shell-verbs.json`, and how
# any of it is rendered is the separate `cicd` Polari module.
#
# NOTHING IS PROMPTED IN JSON MODE, and NOTHING PRIVILEGED IS RUN: a
# privileged action is DESCRIBED (its verb id + params) and nothing else.
# A secret VALUE never enters this file — a secret question carries only
# `present`/empty, and a secret is stored by the `secrets-put` verb, whose
# value travels on stdin.

JSON_US=$'\037'
JSON_RS=$'\036'
JSON_REC_FILE=""
JSON_NEXT_FIX=""
JSON_RUNLOG=""
JSON_CONSENT=0
#: where the finished document is left. setup.sh prints THAT file and nothing
#: else, so no amount of printing inside a step can reach stdout.
JSON_DOC_FILE=""

json_init() {
    JSON_REC_FILE="$(mktemp)"
    JSON_RUNLOG="$(mktemp)"
    JSON_DOC_FILE="$(mktemp)"
    : > "$JSON_REC_FILE"
    : > "$JSON_RUNLOG"
    : > "$JSON_DOC_FILE"
}
json_cleanup() { rm -f "$JSON_REC_FILE" "$JSON_RUNLOG" 2>/dev/null || true; }

json_rec() {   # json_rec <kind> [field…]
    local out="" a
    for a in "$@"; do out="$out$a$JSON_US"; done
    printf '%s%s' "$out" "$JSON_RS" >> "$JSON_REC_FILE"
}

json_meta() { json_rec meta "$1" "${2:-}"; }

# ------------------------------------------------------- the declarations
# Used by `step_<name>_json` in each step file, beside the interactive ask
# that means the same thing.
json_explain()  { json_rec explain "$1"; }
# A question declares WHAT is being asked; how it is written back is derived,
# not re-declared per step: protocol.py binds every non-secret question to the
# `setup-answer` verb with `"value": "{answer}"`, the placeholder the executor
# substitutes. A `secret` question binds to nothing — see protocol.py.
json_question() { # json_question <key> <label> <kind> <default> <answered> [options v=l|v=l]
    json_rec question "$1" "$2" "${3:-text}" "${4:-}" "${5:-}" "${6:-}"
}
json_action()   { # json_action <id> <label> <0|1 privileged> <verb> <0|1 done> <why> [params k=v|k=v]
    json_rec action "$1" "$2" "${3:-0}" "$4" "${5:-0}" "${6:-}" "${7:-}"
}
json_where()    { json_rec where "$1" "${2:-}" "${3:-}"; }
json_skip()     { json_rec skip "$1"; }

# ------------------------------------------------ the primitives, rebound
# `check` / `explain` / `howto` / `where` are the interactive renderer's
# four verbs. Rebinding them is what makes the JSON the same reading the
# terminal gives, rather than a second implementation of it.
check() {   # check <OK|MISS|BAD> <message>
    local verdict name value msg="${2:-}"
    case "${1:-}" in
        OK)   verdict=OK ;;
        BAD)  verdict=FAIL ;;
        MISS) verdict=WARN ;;
        *)    verdict=WARN ;;
    esac
    case "$msg" in
        *": "*) name="${msg%%: *}"; value="${msg#*: }" ;;
        *)      name="$msg"; value="" ;;
    esac
    json_rec check "$verdict" "$name" "$value" "$JSON_NEXT_FIX"
    JSON_NEXT_FIX=""
    # during --run the caller wants to SEE what the action reported; stdout is
    # the action's own log there, never the document (setup.sh holds fd 3).
    [ "$JSON_CONSENT" = 1 ] && printf '   [%s] %s\n' "$verdict" "$msg" || true
}
explain() { json_rec explain "$1"; }
howto()   { json_rec todo "$CUR" "$1" "$1"; }
where()   { json_rec where "$1" "$(json_url_in "$1")" ""; }

json_url_in() { printf '%s' "$1" | grep -oE 'https?://[^ )]+' | head -1 || true; }

# In JSON mode nothing is ever prompted: `ask` is NO unless the caller
# asked for this exact action by id (`--run`), which IS the consent.
ask()        { [ "${JSON_CONSENT:-0}" = 1 ]; }
ask_value()  { printf ''; }
ask_secret() { printf ''; }

# ------------------------------------------------------------- one step
json_step() {   # json_step <name> <index>
    local s="$1" n="$2"
    CUR="$s"; ST_STATE["$s"]=todo; ST_NOTE["$s"]=""
    json_rec step "$s" "$n" "$SETUP_TOTAL" "$(step_title "$s")"
    if declare -F "step_${s}_json" >/dev/null 2>&1; then "step_${s}_json" || true; fi
    if declare -F "step_${s}_check" >/dev/null 2>&1; then "step_${s}_check" || true; fi
    json_rec stepstate "${ST_STATE[$s]:-todo}" "${ST_NOTE[$s]:-}"
}

# the eighth step: the verdict. It has no checks of its own — it reads the
# doctor and the preflight, exactly as render_summary does.
step_summary_json() {
    json_explain "THE RELEASE RULE — the pipeline only generates artifacts for things it TESTED in a throwaway isle. Stages now: $CI_ISLE_STAGES. Core debs and images publish only when the isle test recorded core_ok; an app's deb ships only when its stage result is pass; with no isle-test/results.json for a version NOTHING is published and the tag is not pushed."
    json_action recheck "Re-run every check" 0 setup-step 0 \
        "reads the doctor and the preflight again; changes nothing" "step=summary"
}
step_summary_check() {
    compute_verdict
    check "$([ "$VERDICT_SHORT" = READY ] && echo OK || echo MISS)" \
          "verdict: $VERDICT_SHORT — the doctor reports $DOCTOR_WARNS warning(s) and the preflight says $PRE_VERDICT"
    check OK "steps complete: $(steps_done) of $SETUP_TOTAL"
    [ "$VERDICT_SHORT" = READY ] && state done READY || state todo "$PRE_VERDICT"
    [ "$VERDICT_SHORT" = READY ]
}

# ------------------------------------------------------------- the answers
# `--answer KEY=VALUE`. Only device.env keys; a secret is REFUSED here on
# purpose — its value would land in argv, in the process list and in this
# script's own error path. Secrets go through the `secrets-put` verb,
# whose value travels on stdin and nowhere else.
JSON_ANSWER_NOTES=()
json_apply_answer() {   # json_apply_answer KEY=VALUE
    local pair="$1" key val
    [ -n "$pair" ] || return 0
    case "$pair" in *=*) ;; *) JSON_ANSWER_NOTES+=("refused '$pair' — an answer is KEY=VALUE"); return 1 ;; esac
    key="${pair%%=*}"; val="${pair#*=}"
    case "$key" in
        */*) JSON_ANSWER_NOTES+=("refused $key — that is a SECRET name, and a secret value may not travel in an argument. Use the secrets-put verb (the value goes on stdin)."); return 1 ;;
    esac
    case " $DEVICE_KEYS " in
        *" $key "*) ;;
        *) JSON_ANSWER_NOTES+=("refused $key — not a device.env key. Known: $DEVICE_KEYS"); return 1 ;;
    esac
    if [ "$key" = CI_ISLE_STAGES ]; then val="$(json_stages_value "$val")"; fi
    device_env_set "$key" "$val" >/dev/null 2>&1 || true
    device_reload
    doctor_refresh; PREFLIGHT_JSON=""
    JSON_ANSWER_NOTES+=("$key=$val")
    return 0
}

# A checklist answer is a comma list of apps; a knob typed by hand keeps
# its ';' grouping verbatim. One stage per app, core first — the shape
# step 6 explains.
json_stages_value() {
    local v="$1"
    case "$v" in
        *';'*) printf '%s' "$v"; return 0 ;;
    esac
    local a out="core"
    for a in $(printf '%s' "$v" | tr ',' ' '); do
        [ -n "$a" ] || continue
        [ "$a" = core ] && continue
        out="$out; $a"
    done
    printf '%s' "$out"
}

# ------------------------------------------------------------- the actions
# Every id here is UNPRIVILEGED and is reached through the `setup-run`
# verb. Anything needing root is not here: it is DESCRIBED by a step and
# carries its own verb id.  json_action_step <id> → which step owns it.
json_action_step() {
    case "$1" in
        clone-app)                         printf role ;;
        install-cli|submodules)            printf checkout ;;
        generate-cosign|generate-gpg|generate-ssh-github|generate-ssh-apt) printf secrets ;;
        preflight)                         printf isle ;;
        write-env)                         printf stages ;;
        doctor|sync-push|cache-status)     printf summary ;;
        *) return 1 ;;
    esac
}

json_run_action() {   # json_run_action <id> → 0 ok / non-zero exit code
    local id="$1" rc=0
    JSON_CONSENT=1
    case "$id" in
        install-cli)
            bash "$SUITE/polari-cli/shells/install-cli.sh" >>"$JSON_RUNLOG" 2>&1 || rc=$? ;;
        submodules)
            git -C "$SUITE" submodule update --init --recursive >>"$JSON_RUNLOG" 2>&1 || rc=$? ;;
        clone-app)
            if [ "$CI_MODE" != app ] || [ -z "$CI_APP_NAME" ] || [ -z "$CI_APP_REPO" ]; then
                echo "clone-app needs app mode with CI_APP_NAME and CI_APP_REPO set" >>"$JSON_RUNLOG"; rc=2
            else
                ( setup_app_clone "$CI_APP_NAME" "$CI_APP_REPO" ) >>"$JSON_RUNLOG" 2>&1 || rc=$?
            fi ;;
        preflight)
            bash "$J/isle/preflight.sh" --isle >>"$JSON_RUNLOG" 2>&1 || rc=$?
            PREFLIGHT_JSON="" ;;
        doctor)
            bash "$J/doctor.sh" >>"$JSON_RUNLOG" 2>&1 || rc=$?
            doctor_refresh ;;
        sync-push)
            bash "$J/cicd-sync.sh" push >>"$JSON_RUNLOG" 2>&1 || rc=$? ;;
        cache-status)
            bash "$J/cache.sh" status >>"$JSON_RUNLOG" 2>&1 || rc=$? ;;
        write-env)
            echo "device.env written from the answers given with this call" >>"$JSON_RUNLOG" ;;
        generate-cosign|generate-gpg|generate-ssh-github|generate-ssh-apt)
            json_run_keygen "$id" >>"$JSON_RUNLOG" 2>&1 || rc=$? ;;
        *)
            echo "no such action '$id' — ids: clone-app install-cli submodules generate-cosign generate-gpg generate-ssh-github generate-ssh-apt preflight write-env doctor sync-push cache-status" >>"$JSON_RUNLOG"
            rc=2 ;;
    esac
    JSON_CONSENT=0
    doctor_refresh
    return "$rc"
}

# KEY GENERATION, and the one thing it refuses. Under the SYSTEM posture
# the store is root:polari-ci — writing to it means sudo, and sudo means a
# password prompt no unattended caller can answer. So generation here is
# allowed only while the system posture is ABSENT (the repo posture), and
# it SAYS SO instead of hanging on a prompt. Under the system posture the
# same material is generated by a person at the terminal.
json_run_keygen() {
    local id="$1"
    if [ "$(secrets_mode)" = system ]; then
        echo "REFUSED: the SYSTEM secrets posture is in force ($(secrets_dir), root:$CI_USER 0640)."
        echo "Writing there needs sudo, and an unattended call cannot answer a sudo prompt."
        echo "Generate this at a terminal instead:  sudo -i; pol jenkins setup --step secrets"
        echo "(Key generation from here writes into the REPO posture only — that is deliberate.)"
        return 3
    fi
    echo "posture: REPO ($(secrets_dir)) — generated material is written there, readable by every process of $(id -un). init-device moves it to the system posture."
    case "$id" in
        generate-cosign)     _secret_generate_cosign ;;
        generate-gpg)        _secret_generate_gpg ;;
        generate-ssh-github) _secret_generate_ssh github/github_ssh_key polari-ci ;;
        generate-ssh-apt)    _secret_generate_ssh ssh/distribution_host_key polari-ci-apt ;;
    esac
}

# --------------------------------------------------------------- the run
json_main() {   # json_main <one-step-or-empty> <action-or-empty> <answers…>
    local one="$1" action="$2"; shift 2
    local a rc=0

    json_init
    for a in "$@"; do json_apply_answer "$a" || true; done

    if [ -n "$action" ]; then
        json_run_action "$action" || rc=$?
        one="$(json_action_step "$action" 2>/dev/null || echo summary)"
    fi

    json_meta at "$(date -Is 2>/dev/null || date)"
    json_meta mode "$CI_MODE"
    json_meta device_name "$CI_DEVICE_NAME"
    json_meta target "$(device_target_name)"
    json_meta secrets_posture "$(secrets_mode)"
    json_meta total "$SETUP_TOTAL"
    for a in "${JSON_ANSWER_NOTES[@]:-}"; do [ -n "$a" ] && json_rec todo answers "$a" "" || true; done

    if [ -n "$one" ]; then
        json_meta partial 1
        json_step "$one" "$(step_index "$one")"
        compute_verdict >/dev/null 2>&1 || true
        json_meta ready "$([ "$VERDICT_SHORT" = READY ] && echo true || echo false)"
    else
        local s n=1
        for s in $SETUP_STEPS; do json_step "$s" "$n"; n=$((n+1)); done
        compute_verdict >/dev/null 2>&1 || true
        json_meta ready "$([ "$VERDICT_SHORT" = READY ] && echo true || echo false)"
        json_meta blocking "${TODO_TEXT[0]:-}"
        write_status_file 2>/dev/null || true
    fi
    # the to-do list the steps built while they checked — the SAME array
    # render_summary prints and write_status_file saves, no second copy.
    local i
    for i in "${!TODO_TEXT[@]}"; do
        json_rec todo "${TODO_STEP[$i]}" "${TODO_TEXT[$i]}" "${TODO_HOW[$i]}"
    done

    if [ -n "$action" ]; then
        python3 "$J/setup/protocol.py" "$JSON_REC_FILE" \
            --action "$action" --ok "$([ "$rc" = 0 ] && echo 1 || echo 0)" \
            --exit "$rc" --output "$JSON_RUNLOG" > "$JSON_DOC_FILE"
    else
        python3 "$J/setup/protocol.py" "$JSON_REC_FILE" > "$JSON_DOC_FILE"
    fi
    json_cleanup
}

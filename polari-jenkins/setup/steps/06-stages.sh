#!/bin/bash
# setup/steps/06-stages.sh — WHAT gets tested in a throwaway isle, and
# therefore WHAT may ever be released (his ask 2026-09-19: "the testing
# isle being what the pipeline is analyzing. The pipeline should only
# generate artifact for things that are tested. We should also be able to
# setup Isle Testing stages, for the case where we are space limited but
# still want to test as much as we can.")
#
# The knob is CI_ISLE_STAGES in device.env; device.sh owns the parsing and
# the validation, this step only explains it and writes it.

STEP_TITLE_stages="isle testing stages — what gets tested, and so what ships"

setup_stages_render() {   # stage lines on stdin (one stage per line) → the knob value
    local line out=""
    while IFS= read -r line; do
        line="$(printf '%s' "$line" | tr -s ' ' | sed 's/^ *//; s/ *$//')"
        [ -n "$line" ] || line=core
        out="$out${out:+; }$(printf '%s' "$line" | tr ' ' ',')"
    done
    printf '%s' "${out:-core}"
}

step_stages_check() {
    local okall=1
    stages_print
    check OK "CI_ISLE_STAGES=$CI_ISLE_STAGES — $(stages_count) stage(s), run one after another, each in its OWN throwaway isle"
    local unknown="" a
    for a in $(stages_all_apps); do stages_app_known "$a" || unknown="$unknown $a"; done
    if [ -n "$unknown" ]; then
        check BAD "not a module with a polari-app.json:$unknown"
        check MISS "known apps: $(stages_known_apps | tr '\n' ' ')"
        todo "fix the app names in CI_ISLE_STAGES:$unknown" "pol jenkins setup --step stages   (or: ls polari-rf-node/polari-framework/modules/*/polari-app.json)"
        okall=0
    else
        check OK "every app named is a real module (modules/<name>/polari-app.json)"
    fi
    doctor_row 'isle stages (twice)' >/dev/null 2>&1 && { check MISS "$(doctor_what 'isle stages (twice)')"; okall=0; } || true
    doctor_row 'isle stages (empty)' >/dev/null 2>&1 && { check MISS "$(doctor_what 'isle stages (empty)')"; okall=0; } || true
    check OK "THE RELEASE RULE: core publishes only when the isle test recorded core_ok; an app deb ships only when its stage result is pass; no results.json for a version = NOTHING published, tag not pushed"
    [ "$okall" = 1 ] && state done "$(stages_count) stage(s): $CI_ISLE_STAGES" || state todo "$CI_ISLE_STAGES"
    [ "$okall" = 1 ]
}

# ci-11a. The interactive path builds the stage list stage by stage; a machine
# answers ONE checklist. A comma list becomes one stage per app (core first);
# a value carrying ';' is taken verbatim, so the grouped form stays reachable.
step_stages_json() {
    json_explain "The throwaway isle is what the pipeline ANALYSES, and the pipeline only generates artifacts for things it tested. So this list is also the list of what can ever ship.

A stage is one throwaway isle: it comes up, the core debs go in, that stage's app debs go in, each app's selftest runs, the result is recorded, and the isle is destroyed. Stages run SEQUENTIALLY, so a space-limited device never needs room for more than one at a time.

COST per app: one more module deb build, one more install, one more selftest run inside the isle. 'core' alone is the honest default.

  core                            only the core (default)
  core; household                 two stages
  core; household; gears,motors   three, the last testing two apps together"
    local opts="" a
    for a in $(stages_known_apps); do opts="$opts${opts:+|}$a=module $a"; done
    json_question CI_ISLE_STAGES \
        'Which apps get their own testing stage? (stage 1 is always core. A comma list becomes one stage per app; type the knob with ";" to group apps into one stage.)' \
        checklist core "$(stages_all_apps | tr '\n' ',' | sed 's/,$//')" "$opts"
    json_action write-env 'Save the stage list' 0 setup-run 0 \
        'writes CI_ISLE_STAGES to device.env and revalidates it against the module catalogue' 'action=write-env'
}

step_stages_do() {
    explain "The throwaway isle is what the pipeline ANALYSES, and the pipeline only generates artifacts for things it tested. So this list is also the list of what can ever ship.

A stage is one throwaway isle: it comes up, the core debs go in, that stage's app debs go in, each app's 'pol modules selftest <app>' runs, the result is recorded, and the isle is destroyed. Stages run SEQUENTIALLY, so a space-limited device never needs room for more than one at a time — that is the whole point of staging rather than one big isle.

Every stage installs core first, so core is re-verified in each; the recorded core result is stage 1's.

COST per app: one more module deb build, one more install, one more selftest run inside the isle. 'core' alone is the honest default — add an app when you actually want to ship it.

  core                        only the core (default)
  core; household             two stages
  core; household; gears,motors   three, the last testing two apps together"
    echo
    step_stages_check || true
    echo
    [ "$MODE" = report ] && return 0

    ask "rebuild the testing stages?" "Current: $CI_ISLE_STAGES

Build the stage list again? (No keeps it as it is.)" no || { check OK "stages left as they are — already: OK"; return 0; }

    local known remaining lines="" n=1 picked
    known="$(stages_known_apps)"
    if [ -z "$known" ]; then
        check BAD "no module manifests found under $CI_MODULES_DIR — is polari-rf-node populated?"
        return 1
    fi
    remaining="$known"
    lines="core"            # stage 1 is always core
    check OK "stage 1 is core only, always — every later stage installs core first anyway"
    n=2
    while :; do
        ask "stage $n" "Add stage $n? Each extra stage is another full isle cycle: up, install, test, destroy.

Remaining apps: $(printf '%s' "$remaining" | tr '\n' ' ')" no || break
        local args=() a
        for a in $remaining; do args+=("$a" "module $a"); done
        picked="$(tui_checklist "stage $n — which apps?" "Pick the apps tested together in stage $n. Nothing picked ends the list." "${args[@]}")"
        picked="$(printf '%s' "$picked" | tr -s ' ' | sed 's/^ *//; s/ *$//')"
        [ -n "$picked" ] || { check OK "nothing picked — stage list ends at $((n-1))"; break; }
        lines="$lines
$picked"
        for a in $picked; do remaining="$(printf '%s\n' $remaining | grep -vx "$a" || true)"; done
        n=$((n+1))
        [ -n "$remaining" ] || { check OK "every app is assigned to a stage"; break; }
    done

    local value; value="$(printf '%s\n' "$lines" | setup_stages_render)"
    device_env_set CI_ISLE_STAGES "$value"
    check OK "device.env: CI_ISLE_STAGES=$value"
    doctor_refresh
    echo
    step_stages_check || true
}

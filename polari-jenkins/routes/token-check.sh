#!/bin/bash
# polari-jenkins/routes/token-check.sh — WHAT THE TWO GITHUB TOKENS CAN ACTUALLY DO.
#
# Found live 2026-09-22: github/release_token was a fine-grained PAT that READ the
# repo fine and could not push — GitHub's fine-grained UI does not show what a
# token holds, and there is no API to ask, so the first release (#337) died at
# `git push refs/tags/…` with "Permission … denied". This script asks the ONLY
# reliable way: it tries. Every probe is write-free —
#   · `git push --dry-run` authenticates and asks the remote whether the push
#     WOULD be accepted, and transfers nothing;
#   · the token's own response headers say its kind, its expiry and (classic) its
#     scopes;
#   · the tap repository is looked up, not written.
# It runs wherever the secrets are readable (the controller: /run/secrets; the host
# with sudo). It never prints a token. Output: one row per finding,
#   OK|WARN <TAB> <check> <TAB> <what is true / wrong> <TAB> <what to do>
# for the doctor to render; `--text` prints them readably.
set -uo pipefail
J="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$J/routes/destinations.sh"
SECRETS="${TOKEN_CHECK_SECRETS_DIR:-}"
for d in "$SECRETS" /run/secrets "$J/secrets" /etc/polari-jenkins/secrets; do
    [ -n "$d" ] && [ -d "$d/github" ] && { SECRETS="$d"; break; }
done
API="${GITHUB_API:-https://api.github.com}"
TEXT=0; [ "${1:-}" = --text ] && TEXT=1
row() {  # row OK|WARN <check> <msg> [fix]
    if [ "$TEXT" = 1 ]; then
        [ "$1" = OK ] && printf 'OK    %-28s — %s\n' "$2" "$3" || printf 'WARN  %-28s — %s → %s\n' "$2" "$3" "${4:-}"
    else printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${4:-}"; fi
}
readtok() {  # readtok <area/name> → the value, or ''
    local f="$SECRETS/$1"
    if [ -r "$f" ]; then tr -d '\n' < "$f"; elif sudo -n test -r "$f" 2>/dev/null; then sudo -n cat "$f" | tr -d '\n'; fi
}
kind_of() { case "$1" in github_pat_*) echo fine-grained ;; ghp_*) echo classic ;; gho_*|ghu_*) echo oauth ;; *) echo unknown ;; esac; }
headers() {  # headers <token> → the /user response headers (scopes, expiry) or ''
    curl -s -m 15 -o /dev/null -D - -H "Authorization: Bearer $1" "$API/user" 2>/dev/null | tr -d '\r'
}
can_push() {  # can_push <token> <owner/repo> → 0 can · 1 denied · 2 unreachable/other (message on stdout)
    local t="$1" repo="$2" d out rc
    d="$(mktemp -d)"; ( cd "$d" && git init -q . && git -c user.name=probe -c user.email=probe@noreply.invalid commit -q --allow-empty -m probe )
    out="$(cd "$d" && git push --dry-run "https://x-access-token:$t@github.com/$repo.git" HEAD:refs/tags/zz-token-check 2>&1 | sed "s#$t#****#g")"
    rc=$?; rm -rf "$d"
    case "$out" in
        *"[new tag]"*|*"up to date"*) return 0 ;;
        *denied*|*403*)  printf '%s' "$(printf '%s' "$out" | grep -i -E 'denied|403' | head -1)"; return 1 ;;
        *) printf '%s' "$(printf '%s' "$out" | tail -1)"; return 2 ;;
    esac
}
repo_exists() {  # repo_exists <token> <owner/repo> → HTTP code
    curl -s -m 15 -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $1" "$API/repos/$2"
}

# ------------------------------------------------------------ release token
REL="$(readtok github/release_token || true)"
[ -n "$REL" ] || REL="$(readtok github/github_token || true)"
RREPO="$(dest_release_repo)"; TAP="$(dest_homebrew_tap)"
if [ -z "$REL" ]; then
    row WARN "release token" "github/release_token is absent (or not readable from here) — the github-release + homebrew routes stay DRY and the tag is not pushed" \
        "printf '%s' '<token>' | sudo pol jenkins secrets put github/release_token   (a CLASSIC token with the 'repo' scope — see pol jenkins setup --step secrets)"
else
    K="$(kind_of "$REL")"; H="$(headers "$REL")"
    if [ -z "$H" ]; then
        row WARN "release token" "GitHub did not answer (no network from here?) — nothing proven" "run the doctor again when the device is online"
    else
        EXP="$(printf '%s' "$H" | sed -n 's/^github-authentication-token-expiration: //Ip' | head -1)"
        SCOPES="$(printf '%s' "$H" | sed -n 's/^x-oauth-scopes: //Ip' | head -1)"
        case "$K" in
            classic) row OK "release token kind" "classic, scopes: ${SCOPES:-none}${EXP:+, expires $EXP}" ;;
            fine-grained) row OK "release token kind" "fine-grained${EXP:+, expires $EXP} — GitHub shows a fine-grained token's grants NOWHERE; the push probe below is the only proof" ;;
            *) row OK "release token kind" "$K${EXP:+, expires $EXP}" ;;
        esac
        if [ "$K" = classic ] && [ -n "$SCOPES" ] && ! printf '%s' " $SCOPES," | grep -q -E '[ ,]repo,|[ ,]public_repo,'; then
            row WARN "release token scope" "a classic token WITHOUT the 'repo' scope (has: $SCOPES) — it cannot push the tag, create the release or upload assets" \
                "GitHub → Settings → Developer settings → Tokens (classic) → this token → tick 'repo' → Update; then sudo pol jenkins secrets put github/release_token"
        fi
        MSG="$(can_push "$REL" "$RREPO")"; RC=$?
        case "$RC" in
            0) row OK "release token → $RREPO" "can push (git push --dry-run accepted a tag; nothing was written) — the tag stage and the github-release route will work" ;;
            1) row WARN "release token → $RREPO" "CANNOT push: $MSG — the tag stage fails and no release is created" \
                   "the token lacks write on this repo. Classic: tick the 'repo' scope. Fine-grained: Repository access must include $RREPO AND Permissions → Contents = Read and write (the UI shows none of this afterwards — re-run pol jenkins doctor to prove it). Then sudo pol jenkins secrets put github/release_token" ;;
            *) row WARN "release token → $RREPO" "the push probe could not reach GitHub: $MSG" "run the doctor again when the device is online" ;;
        esac
        INLIST=0; case ",${CI_ROUTES:-github-release,ghcr,homebrew,apt-repo}," in *,homebrew,*) INLIST=1 ;; esac
        if [ "$INLIST" = 1 ]; then
            CODE="$(repo_exists "$REL" "$TAP")"
            if [ "$CODE" = 200 ]; then
                MSG="$(can_push "$REL" "$TAP")"; RC=$?
                case "$RC" in
                    0) row OK "release token → $TAP" "the tap exists and the token can push to it — the homebrew route will work" ;;
                    1) row WARN "release token → $TAP" "the tap exists but the token CANNOT push to it: $MSG" \
                           "the same token must be able to write the tap: classic 'repo' covers every repo you own; fine-grained must list $TAP under Repository access with Contents = Read and write" ;;
                    *) row WARN "release token → $TAP" "the push probe could not reach GitHub: $MSG" "run the doctor again when the device is online" ;;
                esac
            else
                row WARN "homebrew tap $TAP" "does not exist (HTTP $CODE) — the homebrew route is in CI_ROUTES and would fail at 'gh repo clone'" \
                    "create the repository $TAP on GitHub (empty is fine; the route writes Formula/pol.rb), or take homebrew out of CI_ROUTES until it exists"
            fi
        fi
    fi
fi

# ------------------------------------------------------------ registry token
REG="$(readtok github/registry_token || true)"
[ -n "$REG" ] || REG="$(readtok registries/ghcr_token || true)"
if [ -z "$REG" ]; then
    row WARN "registry token" "github/registry_token is absent (or not readable from here) — the ghcr route stays DRY" \
        "printf '%s' '<token>' | sudo pol jenkins secrets put github/registry_token   (a CLASSIC token: write:packages + read:packages)"
else
    K="$(kind_of "$REG")"; H="$(headers "$REG")"
    if [ -z "$H" ]; then
        row WARN "registry token" "GitHub did not answer (no network from here?) — nothing proven" "run the doctor again when the device is online"
    else
        EXP="$(printf '%s' "$H" | sed -n 's/^github-authentication-token-expiration: //Ip' | head -1)"
        SCOPES="$(printf '%s' "$H" | sed -n 's/^x-oauth-scopes: //Ip' | head -1)"
        if [ "$K" = fine-grained ]; then
            row WARN "registry token kind" "FINE-GRAINED — a fine-grained token cannot write container packages, so the ghcr push will be refused" \
                "mint a CLASSIC token (Tokens (classic) → scopes write:packages + read:packages) and sudo pol jenkins secrets put github/registry_token"
        elif ! printf '%s' " $SCOPES," | grep -q 'write:packages,'; then
            row WARN "registry token scope" "classic, but without write:packages (has: ${SCOPES:-none}) — the ghcr push will be refused" \
                "GitHub → Tokens (classic) → this token → tick write:packages (+ read:packages) → Update; then sudo pol jenkins secrets put github/registry_token"
        else
            EXTRA=""; printf '%s' " $SCOPES," | grep -q '[ ,]repo,' && EXTRA=" (it also carries 'repo' — more than the registry needs; harmless, but a narrower token is the documented shape)"
            row OK "registry token" "classic, scopes: $SCOPES${EXP:+, expires $EXP} — can write packages$EXTRA"
        fi
    fi
fi

#!/bin/bash
# polari-jenkins/isle/authorize.sh — THE PIPELINE USER'S OWN KEY reaches the
# isle target. (§76 addendum 2, defect 5.)
#
#   pol jenkins isle authorize [<alias>]      ← run by the INTERACTIVE user
#
# The gap it closes: after `sudo pol jenkins init-device` the controller runs
# as the `polari-ci` system user with HOME=/var/jenkins_home. The ssh alias,
# key and known_hosts that `pol jenkins setup --step isle` created live in the
# INTERACTIVE user's ~/.ssh, so `polari-isle-test` inside the controller could
# not reach the target at all — it refused at its preflight, correctly, with
# "target reachable … FAIL".
#
# So the pipeline user owns ITS OWN key (init-device makes it) and this verb
# gives that key an entry on the target:
#
#   1. read jenkins_home/.ssh/id_ed25519.pub  (root-owned; sudo when needed)
#   2. resolve the alias THE INTERACTIVE USER already uses — `ssh -G <alias>`
#      is the resolved truth, so the controller's entry cannot drift from the
#      one a person proved works
#   3. ssh-keyscan the resolved HostName and VERIFY every scanned fingerprint
#      against the interactive user's own known_hosts. A mismatch, or nothing
#      to compare against, REFUSES — a key copied to a machine that answered
#      at authorize time is exactly how a MITM would be made permanent
#   4. append the public key to the target's ~/.ssh/authorized_keys over the
#      user's OWN working alias (idempotent: a second run adds nothing)
#   5. write jenkins_home/.ssh/config + known_hosts for the alias, owned by
#      the pipeline user, 0600. Neither file is ever tracked (jenkins_home/
#      is gitignored) — the ADDRESS lives there and in ~/.ssh/config only.
#
# It never touches the interactive user's key: the CLI-from-a-shell path keeps
# working exactly as it did.
#
# exit 0 ok · 2 usage · 3 no pipeline key yet · 4 the target refused
#      · 5 the host key could not be verified (refused)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
J="$(cd "$HERE/.." && pwd)"
# shellcheck source=../device.sh
source "$J/device.sh"
# shellcheck source=../secrets.sh
source "$J/secrets.sh"

ALIAS=""; FORCED=""
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h) sed -n '2,31p' "$0"; exit 0 ;;
        # dep-1 (his ruling 2026-09-22): a DEPLOYMENT target gets the key RESTRICTED to one command —
        # the deploy agent — so the pipeline's key can run nothing else there: no shell, no forwarding,
        # no `pol prod apply`, no path to the vault. `--forced-command auto` asks the target where its
        # agent is (pol prod agent --path) and writes that absolute path.
        --forced-command) FORCED="${2:?--forced-command <absolute path|auto>}"; shift ;;
        -*) echo "authorize.sh: unknown argument '$1' (--help)" >&2; exit 2 ;;
        *)  [ -z "$ALIAS" ] || { echo "authorize.sh: one alias, not two" >&2; exit 2; }
            ALIAS="$1" ;;
    esac; shift
done
[ -n "$ALIAS" ] || ALIAS="$CI_ISLE_SSH_HOST"
if [ -z "$ALIAS" ]; then
    echo "pol jenkins isle authorize <alias> — the ssh ALIAS of the isle device (never an address)." >&2
    echo "  This device has no CI_ISLE_SSH_HOST either: pol jenkins target ssh <alias> first." >&2
    exit 2
fi
case "$ALIAS" in
    *[!A-Za-z0-9._-]*) echo "authorize.sh: '$ALIAS' is not an ssh alias (letters, digits, . _ -)" >&2; exit 2 ;;
esac

say()  { printf '[authorize] %s\n' "$*"; }
fail() { printf '[authorize] REFUSED: %s\n' "$*" >&2; }

# `init-device` needs sudo, and this verb is the next line of its own advice —
# so it will be typed with sudo. It must not be. Root's ~/.ssh is a different
# file: the alias, the key and the known_hosts this copies THROUGH are the
# person's, and under sudo none of them is in scope.
if [ "$(id -u)" = 0 ] && [ -n "${SUDO_USER:-}" ]; then
    fail "run this as yourself, NOT with sudo — it copies through the alias in YOUR ~/.ssh/config, and root's is a different file."
    echo "    pol jenkins isle authorize $ALIAS        (it will ask for your password if it needs root)" >&2
    exit 2
fi

JH="${JENKINS_HOME:-$J/jenkins_home}"
CI_SSH_DIR="$JH/.ssh"
CI_KEY="$CI_SSH_DIR/id_ed25519"

# Everything under jenkins_home belongs to the pipeline user (0750), so this
# shell usually cannot read the key or write the config. Elevate only when
# that is actually true — in a sandbox (and as root) it is not.
if [ -r "$CI_SSH_DIR" ] && [ -w "$CI_SSH_DIR" ]; then
    PRIV=""                               # ours already (a sandbox, or root)
elif [ -r "$JH" ] && [ ! -e "$CI_SSH_DIR" ]; then
    PRIV=""                               # visibly absent: no root needed to know there is no key
else
    PRIV="sudo"
fi
priv() { if [ -z "$PRIV" ]; then "$@"; else sudo "$@"; fi; }

# …and if it cannot elevate, SAY THAT. Without this check a sudo that simply
# refuses looks exactly like a key that was never created, and the verb would
# send a person to `init-device` for a key they already have.
if [ -n "$PRIV" ] && ! sudo -n true 2>/dev/null && [ ! -t 0 ]; then
    fail "$CI_SSH_DIR belongs to $CI_USER; reading the pipeline user's key needs root, this shell has no passwordless sudo, and there is no terminal to ask on."
    echo "  Run it at a terminal on that device (it asks for YOUR password once):" >&2
    echo "    pol jenkins isle authorize $ALIAS" >&2
    exit 2
fi

# ---------------------------------------------------- 1. the pipeline's key
if ! priv test -s "$CI_KEY.pub" 2>/dev/null; then
    fail "the pipeline user has no key yet ($CI_KEY.pub is absent)."
    echo "  init-device is what creates it (it needs root: it owns the user and the key):" >&2
    echo "    sudo pol jenkins init-device" >&2
    echo "    pol jenkins isle authorize $ALIAS" >&2
    exit 3
fi
PUB="$(priv cat "$CI_KEY.pub")"
case "$PUB" in
    ssh-ed25519\ *|ssh-rsa\ *|ecdsa-*) ;;
    *) fail "$CI_KEY.pub does not look like a public key"; exit 3 ;;
esac
case "$PUB" in *\'*|*\"*|*'`'*|*'$'*) fail "the public key carries a quoting character — refusing to send it through a shell"; exit 3 ;; esac
say "the pipeline user's key: $(printf '%s' "$PUB" | awk '{print $1, $3}')"

# ------------------------------------------- 2. the alias, as ssh resolves it
G="$(ssh -G "$ALIAS" 2>/dev/null || true)"
g() { printf '%s\n' "$G" | awk -v k="$1" '$1==k {print $2; exit}'; }
HOSTNAME_="$(g hostname)"; USER_="$(g user)"; PORT_="$(g port)"
# `ssh -G` falls back to the alias itself when no Host block declares a
# HostName — which is legitimate (a name DNS resolves), but is also exactly
# what an alias nobody ever configured looks like. The config decides.
_alias_declared() {
    grep -qiE "^[[:space:]]*Host([[:space:]]+[^[:space:]]+)*[[:space:]]+${ALIAS}([[:space:]]|$)" \
        "$HOME/.ssh/config" 2>/dev/null
}
if [ -z "$HOSTNAME_" ] || { [ "$HOSTNAME_" = "$ALIAS" ] && ! _alias_declared; }; then
    fail "'$ALIAS' has no Host entry in your own ~/.ssh/config — there is nothing to copy."
    echo "  Add the Host block (HostName/User/IdentityFile), prove it with: ssh $ALIAS true" >&2
    exit 2
fi
[ -n "$PORT_" ] || PORT_=22
say "alias '$ALIAS' resolves to user $USER_, port $PORT_ (the address stays out of this output and out of every tracked file)"

# --------------------------------------- 3. the host key, VERIFIED not trusted
# ssh-keyscan answers whoever is at that address RIGHT NOW. On its own that is
# no better than StrictHostKeyChecking=no. The interactive user has already
# accepted this device's key, so their known_hosts is the reference: every type
# the scan and the reference share must agree, and at least one must.
fps() { ssh-keygen -lf - 2>/dev/null | awk '{t=$NF; gsub(/[()]/,"",t); print toupper(t) " " $2}'; }

KH_FILES="$(printf '%s\n' "$G" | awk '$1=="userknownhostsfile" {$1=""; print}')"
[ -n "$KH_FILES" ] || KH_FILES="$HOME/.ssh/known_hosts"
REF=""
for khf in $KH_FILES; do
    case "$khf" in "~/"*) khf="$HOME/${khf#\~/}" ;; none) continue ;; esac
    [ -r "$khf" ] || continue
    for name in "$HOSTNAME_" "$ALIAS" "[$HOSTNAME_]:$PORT_"; do
        [ -n "$name" ] || continue
        REF="$REF$(ssh-keygen -F "$name" -f "$khf" 2>/dev/null | grep -v '^#' || true)
"
    done
done
REF_FP="$(printf '%s' "$REF" | sed '/^$/d' | fps | sort -u || true)"
SCAN="$(ssh-keyscan -T 8 -p "$PORT_" "$HOSTNAME_" 2>/dev/null | grep -v '^#' || true)"
SCAN_FP="$(printf '%s' "$SCAN" | sed '/^$/d' | fps | sort -u || true)"

if [ -z "$SCAN" ]; then
    fail "ssh-keyscan got no host key from the device behind '$ALIAS' (port $PORT_)."
    echo "  Is it up? Try: ssh $ALIAS true" >&2
    exit 5
fi
if [ -z "$REF_FP" ]; then
    fail "you have no known_hosts entry for '$ALIAS' to check the scan against."
    echo "  Connect once yourself first — you are the person who can judge the fingerprint:" >&2
    echo "    ssh $ALIAS true" >&2
    echo "  then: pol jenkins isle authorize $ALIAS" >&2
    exit 5
fi
SHARED=0
while read -r t fp; do
    [ -n "$t" ] || continue
    ref="$(printf '%s\n' "$REF_FP" | awk -v t="$t" '$1==t {print $2; exit}')"
    [ -n "$ref" ] || continue
    if [ "$ref" = "$fp" ]; then SHARED=$((SHARED+1))
    else
        fail "the $t host key the device is offering NOW is not the one you already trust."
        echo "  yours: $ref" >&2
        echo "  now:   $fp" >&2
        echo "  Nothing was copied and nothing was written. Either that device was rebuilt" >&2
        echo "  (then remove the stale line: ssh-keygen -R $ALIAS) or something is answering" >&2
        echo "  in its place." >&2
        exit 5
    fi
done <<<"$SCAN_FP"
if [ "$SHARED" = 0 ]; then
    fail "none of the host key types the scan returned is one your known_hosts has — nothing could be verified."
    echo "  Connect once yourself (ssh $ALIAS true), then run this again." >&2
    exit 5
fi
say "host key verified against your own known_hosts ($SHARED key type(s) agree) — not blindly accepted"

# --------------------------------- 4. the key onto the target, idempotently
if [ "$FORCED" = auto ]; then
    FORCED="$(ssh -o BatchMode=yes -o ConnectTimeout="$CI_SSH_TIMEOUT" "$ALIAS" "bash -lc 'pol prod agent --path'" 2>/dev/null | tail -1)"
    case "$FORCED" in /*prod-agent.sh) say "the target's deploy agent is $FORCED" ;;
        *) fail "the target did not name its deploy agent (pol prod agent --path over '$ALIAS' answered: '${FORCED:-nothing}') — is pol installed there?"; exit 4 ;; esac
fi
if [ -n "$FORCED" ]; then
    # `restrict` (OpenSSH ≥ 7.2) = no pty, no port/agent/X11 forwarding, no user rc; command= is the ONLY thing run.
    LINE="restrict,command=\"$FORCED\" $PUB"
    say "the key will be RESTRICTED on $ALIAS to: $FORCED  (no shell, no forwarding — the deploy agent and nothing else)"
else LINE="$PUB"; fi
say "copying the pipeline user's PUBLIC key to $ALIAS over your own working alias…"
RES="$(ssh -o BatchMode=yes -o ConnectTimeout="$CI_SSH_TIMEOUT" "$ALIAS" "
    umask 077
    mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys
    if grep -qxF '$LINE' ~/.ssh/authorized_keys; then echo already
    else
        # one line per key: an UNRESTRICTED copy of this same key is replaced, never kept beside the restricted one
        grep -vF '$PUB' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.new || true
        printf '%s\n' '$LINE' >> ~/.ssh/authorized_keys.new; mv ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys; chmod 0600 ~/.ssh/authorized_keys; echo added
    fi
    id -un" 2>&1)" || {
    fail "your own alias '$ALIAS' did not answer a BatchMode ssh: ${RES//$'\n'/ }"
    echo "  This verb copies THROUGH the path you already have. Fix that one first:" >&2
    echo "    ssh $ALIAS true" >&2
    exit 4
}
TARGET_LOGIN="$(printf '%s\n' "$RES" | tail -1)"
case "$RES" in
    *already*) say "authorized_keys on $ALIAS: the key was already there (nothing added)" ;;
    *added*)   say "authorized_keys on $ALIAS: the key was added for login '$TARGET_LOGIN'" ;;
    *) fail "unexpected answer from $ALIAS: ${RES//$'\n'/ }"; exit 4 ;;
esac

# ------------------------- 5. the controller's own config + known_hosts
# Rendered from `ssh -G` above, so the controller's entry is the SAME
# destination the interactive user proved, not a second description of it.
BEGIN="# >>> polari-ci authorize $ALIAS"
END="# <<< polari-ci authorize $ALIAS"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
CFG="$TMP/config"
if priv test -f "$CI_SSH_DIR/config"; then
    priv cat "$CI_SSH_DIR/config" | awk -v b="$BEGIN" -v e="$END" '
        $0==b {skip=1} !skip {print} $0==e {skip=0}' > "$CFG"
else
    : > "$CFG"
fi
{
    printf '%s\n' "$BEGIN"
    printf 'Host %s\n' "$ALIAS"
    printf '    HostName %s\n' "$HOSTNAME_"
    printf '    User %s\n' "$USER_"
    [ "$PORT_" = 22 ] || printf '    Port %s\n' "$PORT_"
    printf '    IdentityFile ~/.ssh/id_ed25519\n'
    printf '    IdentitiesOnly yes\n'
    printf '    StrictHostKeyChecking yes\n'
    printf '    UserKnownHostsFile ~/.ssh/known_hosts\n'
    printf '    BatchMode yes\n'
    printf '%s\n' "$END"
} >> "$CFG"

KH="$TMP/known_hosts"
if priv test -f "$CI_SSH_DIR/known_hosts"; then priv cat "$CI_SSH_DIR/known_hosts" > "$KH"; else : > "$KH"; fi
ADDED=0
while IFS= read -r line; do
    [ -n "$line" ] || continue
    grep -qxF "$line" "$KH" || { printf '%s\n' "$line" >> "$KH"; ADDED=$((ADDED+1)); }
done <<<"$SCAN"
# the alias the controller connects BY must resolve too: ssh looks the entry up
# under the HostName it dials, which is what the scan lines already carry.

CI_OWNER="$CI_USER"
id -u "$CI_USER" >/dev/null 2>&1 || CI_OWNER=""      # before init-device there is no such user
priv install -d ${CI_OWNER:+-o "$CI_OWNER" -g "$CI_OWNER"} -m 0700 "$CI_SSH_DIR"
priv install ${CI_OWNER:+-o "$CI_OWNER" -g "$CI_OWNER"} -m 0600 "$CFG" "$CI_SSH_DIR/config"
priv install ${CI_OWNER:+-o "$CI_OWNER" -g "$CI_OWNER"} -m 0600 "$KH" "$CI_SSH_DIR/known_hosts"
say "$CI_SSH_DIR/config: the '$ALIAS' entry written (HostName/User/IdentityFile/IdentitiesOnly), owner ${CI_OWNER:-this user}, 0600 — never tracked"
say "$CI_SSH_DIR/known_hosts: $ADDED line(s) added ($(wc -l < "$KH" | tr -d ' ') total)"

# --------------------------------------------------- 6. prove it, through the controller
CTR="${CI_CONTROLLER_CONTAINER:-polari-jenkins}"
if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CTR"; then
    if out=$(docker exec "$CTR" ssh -o BatchMode=yes -o ConnectTimeout="$CI_SSH_TIMEOUT" "$ALIAS" true 2>&1); then
        say "PROVEN: the controller reaches $ALIAS as the pipeline user, with no prompt"
        if docker exec "$CTR" ssh -o BatchMode=yes -o ConnectTimeout="$CI_SSH_TIMEOUT" "$ALIAS" 'sudo -n true' >/dev/null 2>&1; then
            say "…and that login has passwordless sudo on the target (the isle stages need it)"
        else
            say "WARNING: login '$TARGET_LOGIN' on $ALIAS has no passwordless sudo — the isle stages will refuse."
            say "         grant it there: pol jenkins setup --step isle writes the drop-in"
        fi
    else
        fail "the controller still cannot reach $ALIAS: ${out//$'\n'/ }"
        case "$out" in
            *"No user exists for uid"*)
                echo "  That is not about the key at all: the image has no passwd entry for the uid" >&2
                echo "  compose starts it as, and ssh dies on getpwuid() before reading an argument." >&2
                echo "    pol jenkins up      (it rebuilds with JENKINS_UID from .env)" >&2 ;;
            *)  echo "  If the controller was started before this ran, it may hold an older mount:" >&2
                echo "    pol jenkins up      (then: pol jenkins doctor)" >&2 ;;
        esac
        exit 4
    fi
else
    say "the controller is not running — bring it up and check: pol jenkins up && pol jenkins doctor"
fi
say "done. pol jenkins preflight --isle should now read 'target reachable … PASS'."

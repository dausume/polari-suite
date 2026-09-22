#!/bin/bash
# setup/steps/04-secrets.sh — (C) of ci-7: the posture, and then every
# secret: WHAT it is for, WHERE to get it, HOW. Two kinds:
#   · outside authority (a GitHub token) — no script can fetch it. The
#     step prints the URL and the exact scopes, then takes the value
#     pasted in (hidden) and stores it through `pol jenkins secrets put`.
#   · generated here (cosign, gpg, ssh) — the step offers to generate it
#     and store both halves itself.
# No value is ever printed, echoed or logged. Which routes are ARMED is
# the doctor's reading (secrets.sh's route table), not a second copy.

STEP_TITLE_secrets="the secrets posture, and the secrets"

# ci-12: the where-to-get-it entries below name the ACTUAL destination — which
# release pool, which registry — and those come from the ONE catalogue
# (secrets.sh → routes/destinations.sh). A step file can be sourced on its own
# (the selftest does), so make sure the catalogue is there rather than printing
# an entry with a hole where the destination should be.
if ! command -v secrets_destination >/dev/null 2>&1; then
    _S04="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    # shellcheck source=../../secrets.sh
    [ -f "$_S04/secrets.sh" ] && . "$_S04/secrets.sh"
fi

# ------------------------------------------------------- where to get it
# kind | blocked | what it is for | where | how
# kind: paste (outside authority) · cosign · gpg · ssh · auto
setup_secret_info() {
    case "$1" in
    github/release_token) printf '%s\t%s\t%s\t%s\t%s\n' paste 0 \
        "the RELEASE token — $(secrets_destination github/release_token). It creates the release, uploads its assets and pushes the version tag." \
        "https://github.com/settings/tokens/new" \
        "RECOMMENDED — a CLASSIC token: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token. Scopes: 'repo' and NOTHING else (it is a SECOND token — keep it apart from the registry one). Set an expiry and note it. THE TIGHTER OPTION — a fine-grained token (Fine-grained tokens → Generate new token): Repository access = ONLY $(dest_release_repo) and $(dest_homebrew_tap); Permissions → Repository → Contents = Read and write (Metadata: Read is added by itself); NO account permissions. ⚠ GitHub's fine-grained UI shows a token's grants NOWHERE afterwards and there is no API to ask — the first real release (2026-09-22) died on one that could read the repo and not push. Whichever kind: after 'secrets put', run pol jenkins doctor — it PROVES the token can push with a write-free 'git push --dry-run' and says exactly what is missing. EXAMPLES, documentation only — the routes are GitHub today: GitLab → User Settings → Access Tokens, scopes api + write_registry; Gitea → Settings → Applications → Generate token, scopes write:repository + write:package." ;;
    github/registry_token) printf '%s\t%s\t%s\t%s\t%s\n' paste 0 \
        "the REGISTRY token — $(secrets_destination github/registry_token)." \
        "https://github.com/settings/tokens/new" \
        "GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token. It MUST be classic: a fine-grained token cannot write packages. Scopes: write:packages and read:packages. Add delete:packages only if you ever need to remove a bad tag. EXAMPLES, documentation only — the routes are GitHub today: GitLab → User Settings → Access Tokens, scope write_registry; Gitea → Settings → Applications → Generate token, scope write:package." ;;
    signing/cosign_key) printf '%s\t%s\t%s\t%s\t%s\n' cosign 0 \
        "signs the release images and the checksums so a downloader can verify them" \
        "nothing to fetch — generated here; cosign is in the controller image, standalone binaries at https://github.com/sigstore/cosign/releases" \
        "cosign generate-key-pair   (no cosign on the host: docker run --rm -v \"\$PWD\":/w -w /w ghcr.io/sigstore/cosign/cosign generate-key-pair). cosign.key is the secret; cosign.pub is PUBLIC and is committed as polari-jenkins/cosign.pub." ;;
    signing/cosign_password) printf '%s\t%s\t%s\t%s\t%s\n' cosign 0 \
        "the passphrase of the cosign private key (generated with it)" \
        "nothing to fetch — generated here alongside cosign_key" \
        "generated as a random 24-character string when the key pair is made; cosign generate-key-pair reads it from COSIGN_PASSWORD" ;;
    signing/apt_signing_gpg) printf '%s\t%s\t%s\t%s\t%s\n' gpg 1 \
        "signs the apt repository's Release file so apt will trust the downloads host" \
        "nothing to fetch — generated here" \
        "gpg --quick-generate-key \"Polari apt signing <apt@polari.invalid>\" ed25519 sign 2y   then   gpg --armor --export-secret-keys <keyid>   (an .invalid address on purpose — never a real one)" ;;
    signing/apt_signing_keyid) printf '%s\t%s\t%s\t%s\t%s\n' gpg 1 \
        "the fingerprint of that apt signing key (what apt pins)" \
        "nothing to fetch — printed by gpg when the key is made" \
        "gpg --list-secret-keys --with-colons apt@polari.invalid | awk -F: '/^fpr/{print \$10; exit}'" ;;
    ssh/distribution_host_key) printf '%s\t%s\t%s\t%s\t%s\n' ssh 1 \
        "the rsync key the apt route uses to push the repository to the downloads host" \
        "generated here; its PUBLIC half goes into that host's ~/.ssh/authorized_keys" \
        "ssh-keygen -t ed25519 -C polari-ci-apt -f ./polari-apt -N \"\"  — the private half is the secret, the .pub goes on the distribution host" ;;
    github/github_ssh_key) printf '%s\t%s\t%s\t%s\t%s\n' ssh 0 \
        "OPTIONAL alternative to the RELEASE token, for the tag push only (a deploy key)" \
        "https://github.com/$(dest_release_repo)/settings/keys → Add deploy key → Allow write access" \
        "ssh-keygen -t ed25519 -C polari-ci -f ./polari-ci-deploy -N \"\"  — the private half is the secret, the .pub is the deploy key" ;;
    admin/jenkins_admin_password) printf '%s\t%s\t%s\t%s\t%s\n' auto 0 \
        "the local Jenkins admin login" \
        "nothing to fetch — pol jenkins up generates it and prints it once" \
        "pol jenkins up" ;;
    *) return 1 ;;
    esac
}
_si() { setup_secret_info "$1" | cut -f"$2"; }

SETUP_BLOCKED_NOTE="BLOCKED until the Keycloak rotation (CICD_PIPELINE_PLAN §5.4): the apt/downloads route may not be armed before it. Generate the material if you like — the route stays DRY."

# Not required by any ACTIVE route today: signing is strongly recommended
# but nothing refuses without it, and the deploy key is an alternative to
# the token. They are offered, never counted as missing.
_secret_optional() {
    case "$1" in signing/cosign_key|signing/cosign_password|github/github_ssh_key) return 0 ;; esac
    return 1
}

# every secret any ACTIVE route wants, in a stable order, plus the optional one
setup_all_secrets() {
    local r s out=""
    for r in $SECRETS_ACTIVE_ROUTES; do
        for s in $(secrets_route_requires "$r"); do case " $out " in *" $s "*) ;; *) out="$out $s" ;; esac; done
    done
    out="$out signing/cosign_key signing/cosign_password github/github_ssh_key"
    printf '%s\n' $out
}

step_secrets_check() {
    local mode; mode="$(secrets_mode)"
    if [ "$mode" = system ]; then
        check OK "posture: SYSTEM — $(secrets_dir) (root:$CI_USER 0750, files 0640). Readable by sudo and by the pipeline process, by nobody else."
    else
        check MISS "posture: REPO — $(secrets_dir), readable by EVERY process of $(id -un)"
        todo "move the secrets out of the checkout (the posture (C) asks for)" "sudo pol jenkins init-device"
    fi
    local s missing=0 how
    for s in $(setup_all_secrets); do
        if secrets_have "$s"; then check OK "$s — present"
        else
            local blocked; blocked="$(_si "$s" 2)"
            if [ "$blocked" = 1 ]; then check MISS "$s — absent ($SETUP_BLOCKED_NOTE)"
            elif _secret_optional "$s"; then check OK "$s — absent (optional: $(_si "$s" 3))"
            else
                check MISS "$s — absent: $(_si "$s" 3)"; missing=$((missing+1))
                case "$(_si "$s" 1)" in
                    paste) how="$(_si "$s" 4)" ;;
                    *)     how="pol jenkins setup --step secrets — it generates and stores it for you" ;;
                esac
                todo "put $s in place" "$how"
            fi
        fi
    done
    check OK "parked routes: $SECRETS_PARKED_ROUTES — each needs an outside account; parked by his rule, nothing is asked for them"
    if [ "$mode" = system ] && [ "$missing" = 0 ]; then state done "system posture; every unblocked route has its secret"
    elif [ "$missing" = 0 ]; then state todo "every unblocked route has its secret, but the posture is still REPO"
    else state todo "$missing secret(s) missing"; fi
    [ "$mode" = system ] && [ "$missing" = 0 ]
}

# ---------------------------------------------------------------- actions
_secret_offer_paste() {   # <area/name>
    local rel="$1" v
    where "$(_si "$rel" 4)"
    howto "$(_si "$rel" 5)"
    ask "$rel" "$(_si "$rel" 3)

WHERE: $(_si "$rel" 4)
HOW:   $(_si "$rel" 5)

Paste the value now? (Choose No to skip — the route stays DRY and it lands on the to-do list.)" || { check MISS "$rel skipped"; return 1; }
    v="$(ask_secret "$rel" "Paste the value. It is not echoed, not logged and never printed back.")"
    [ -n "$v" ] || { check MISS "$rel — nothing pasted, skipped"; return 1; }
    printf '%s' "$v" | setup_put_secret "$rel" && { doctor_refresh; return 0; }
    return 1
}

_cosign_cmd() {   # echo how cosign can be run here, or nothing
    if command -v cosign >/dev/null 2>&1; then echo host
    elif command -v docker >/dev/null 2>&1; then echo docker
    else echo none; fi
}

_secret_generate_cosign() {
    local how tmp pw rc=0
    how="$(_cosign_cmd)"
    where "$(_si signing/cosign_key 4)"
    howto "$(_si signing/cosign_key 5)"
    [ "$how" = none ] && { check MISS "neither cosign nor docker is here — install one, then: pol jenkins setup --step secrets"; return 1; }
    ask "cosign key pair" "Generate a cosign key pair locally and store both halves?

The private key goes to signing/cosign_key, a random 24-character passphrase to signing/cosign_password, and the PUBLIC half is written to polari-jenkins/cosign.pub — that one is committed, it is meant to be public.

Method: $([ "$how" = host ] && echo 'the cosign on this host' || echo 'docker run ghcr.io/sigstore/cosign/cosign')" || { check MISS "cosign key skipped"; return 1; }
    tmp="$(mktemp -d)"; chmod 700 "$tmp"
    pw="$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)"
    if [ "$how" = host ]; then
        ( cd "$tmp" && COSIGN_PASSWORD="$pw" cosign generate-key-pair >/dev/null ) || rc=1
    else
        ( cd "$tmp" && docker run --rm -e COSIGN_PASSWORD="$pw" -v "$tmp":/w -w /w \
            ghcr.io/sigstore/cosign/cosign generate-key-pair >/dev/null ) || rc=1
    fi
    if [ "$rc" = 0 ] && [ -s "$tmp/cosign.key" ]; then
        setup_put_secret signing/cosign_key < "$tmp/cosign.key" || rc=1
        printf '%s' "$pw" | setup_put_secret signing/cosign_password || rc=1
        install -m 0644 "$tmp/cosign.pub" "$J/cosign.pub" && check OK "public half written to polari-jenkins/cosign.pub (tracked — it is public on purpose)"
    else
        check BAD "cosign generate-key-pair failed"; rc=1
    fi
    find "$tmp" -type f -exec shred -u {} + 2>/dev/null || true; rm -rf "$tmp"
    unset pw
    doctor_refresh; return "$rc"
}

_secret_generate_gpg() {
    local keyid rc=0
    where "$(_si signing/apt_signing_gpg 4)"
    howto "$(_si signing/apt_signing_gpg 5)"
    check MISS "$SETUP_BLOCKED_NOTE"
    command -v gpg >/dev/null 2>&1 || { check MISS "gpg is not installed — sudo apt-get install -y gnupg"; return 1; }
    ask "apt signing key" "Generate the apt repository signing key now?

  gpg --quick-generate-key \"Polari apt signing <apt@polari.invalid>\" ed25519 sign 2y

The address is deliberately .invalid — no real e-mail ever goes into this material. The armored private key goes to signing/apt_signing_gpg and its fingerprint to signing/apt_signing_keyid.

⚠ $SETUP_BLOCKED_NOTE" no || { check MISS "apt signing key skipped (the route is blocked anyway)"; return 1; }
    gpg --batch --passphrase '' --quick-generate-key "Polari apt signing <apt@polari.invalid>" ed25519 sign 2y >/dev/null 2>&1 || rc=1
    keyid="$(gpg --list-secret-keys --with-colons apt@polari.invalid 2>/dev/null | awk -F: '/^fpr/{print $10; exit}')"
    if [ "$rc" = 0 ] && [ -n "$keyid" ]; then
        gpg --armor --export-secret-keys "$keyid" | setup_put_secret signing/apt_signing_gpg || rc=1
        printf '%s' "$keyid" | setup_put_secret signing/apt_signing_keyid || rc=1
        check OK "apt signing key $keyid stored (the apt route stays DRY until the rotation)"
    else
        check BAD "gpg key generation failed"; rc=1
    fi
    doctor_refresh; return "$rc"
}

_secret_generate_ssh() {   # <area/name> <comment>
    local rel="$1" cmt="$2" tmp rc=0 blocked
    blocked="$(_si "$rel" 2)"
    where "$(_si "$rel" 4)"
    howto "$(_si "$rel" 5)"
    [ "$blocked" = 1 ] && check MISS "$SETUP_BLOCKED_NOTE"
    ask "$rel" "Generate an ed25519 key pair and store the PRIVATE half as $rel?

The public half is printed here so you can paste it where it belongs:
  $(_si "$rel" 4)

Nothing on GitHub or on any host is touched by this — only the key is made." no || { check MISS "$rel skipped"; return 1; }
    tmp="$(mktemp -d)"; chmod 700 "$tmp"
    ssh-keygen -t ed25519 -C "$cmt" -f "$tmp/key" -N "" -q || rc=1
    if [ "$rc" = 0 ]; then
        setup_put_secret "$rel" < "$tmp/key" || rc=1
        echo; echo "   the PUBLIC half — paste this where the 'where' line above says:"
        sed 's/^/     /' "$tmp/key.pub"; echo
    fi
    find "$tmp" -type f -exec shred -u {} + 2>/dev/null || true; rm -rf "$tmp"
    doctor_refresh; return "$rc"
}

# ci-11a — the secrets, declared. THE ONE RULE OF THIS FUNCTION: no value.
# A secret question carries `present` or nothing as its `answered`; its VALUE
# reaches the store only through the `secrets-put` verb, whose value travels
# on stdin and never in an argument, a URL or a page.
step_secrets_json() {
    json_explain "Two postures, and the doctor is loud about which one is in force.

SYSTEM  $CI_SECRETS_SYSTEM, root:$CI_USER 0750 and every file 0640. Readable by root (a person who elevated) and by the pipeline process — not by your shell, not by anything your shell runs. This is what the posture asks for.

REPO    polari-jenkins/secrets, 0600 and owned by you. Git never sees it, but every process you run can read it: a browser extension, an npm postinstall, any script. It is a fallback, not a posture.

init-device makes the system posture: it creates the polari-ci system user the controller runs as, creates the directory, and MOVES anything already sitting in the checkout there.

A route publishes for real only when BOTH its secret is present AND it is named in CI_ROUTES — a secret alone never arms anything."
    json_action init-device 'Create the system secrets posture' 1 init-device \
        "$([ "$(secrets_mode)" = system ] && echo 1 || echo 0)" \
        "it creates the $CI_USER system user and $CI_SECRETS_SYSTEM, and moves any secret already in the checkout there. It installs nothing, opens no port and touches no deployment; re-running it is safe." ''

    local s kind area name
    for s in $(setup_all_secrets); do
        area="${s%%/*}"; name="${s#*/}"
        kind="$(_si "$s" 1)"
        json_where "$s — $(_si "$s" 3)" "$(_si "$s" 4)" "$(_si "$s" 5)"
        case "$kind" in
            paste)
                json_question "$s" "$(_si "$s" 3)" secret '' \
                    "$(secrets_have "$s" && echo present || echo '')" ''
                json_action "secret-$area-$name" "Store $s" 1 secrets-put \
                    "$(secrets_have "$s" && echo 1 || echo 0)" \
                    'the value is read on stdin by the elevated command and never appears in an argument, a log or this document' \
                    "area=$area|name=$name" ;;
            cosign)
                [ "$s" = signing/cosign_key ] || continue
                json_action generate-cosign 'Generate the cosign key pair' 0 setup-run \
                    "$(secrets_have "$s" && echo 1 || echo 0)" \
                    'made locally; the PUBLIC half is written to polari-jenkins/cosign.pub. Refused while the SYSTEM posture is in force — writing there needs an elevation an unattended call cannot answer.' \
                    'action=generate-cosign' ;;
            gpg)
                [ "$s" = signing/apt_signing_gpg ] || continue
                json_action generate-gpg 'Generate the apt signing key' 0 setup-run \
                    "$(secrets_have "$s" && echo 1 || echo 0)" \
                    "$SETUP_BLOCKED_NOTE Refused while the SYSTEM posture is in force." \
                    'action=generate-gpg' ;;
            ssh)
                case "$s" in
                    github/github_ssh_key)
                        json_action generate-ssh-github 'Generate the github deploy key' 0 setup-run \
                            "$(secrets_have "$s" && echo 1 || echo 0)" \
                            'the PRIVATE half is stored; the public half is printed for you to paste. Refused while the SYSTEM posture is in force.' \
                            'action=generate-ssh-github' ;;
                    ssh/distribution_host_key)
                        json_action generate-ssh-apt 'Generate the apt distribution key' 0 setup-run \
                            "$(secrets_have "$s" && echo 1 || echo 0)" \
                            "$SETUP_BLOCKED_NOTE Refused while the SYSTEM posture is in force." \
                            'action=generate-ssh-apt' ;;
                esac ;;
        esac
    done
}

step_secrets_do() {
    explain "Two postures, and the doctor is loud about which one is in force.

SYSTEM  $CI_SECRETS_SYSTEM, root:$CI_USER 0750 and every file 0640. Readable by root (a person who typed sudo) and by the pipeline process — not by your shell, not by anything your shell runs. This is what (C) asks for.

REPO    polari-jenkins/secrets, 0600 and owned by you. Git never sees it, but every process you run can read it: a browser extension, an npm postinstall, any script. It is a fallback, not a posture.

sudo pol jenkins init-device makes the system posture: it creates the polari-ci system user the controller runs as, creates the directory, and MOVES anything already sitting in the checkout there."
    echo
    step_secrets_check || true
    echo

    if [ "$(secrets_mode)" != system ]; then
        howto "sudo pol jenkins init-device   (it asks for your sudo password itself)"
        if ask "run init-device now?" "Create the polari-ci system user and $CI_SECRETS_SYSTEM, and move any secret already in the checkout there?

It installs nothing, opens no port, and touches no deployment. Re-running it is safe."; then
            act "the system secrets posture is in force" -- sudo bash "$J/init-device.sh" || true
            source "$J/secrets.sh"
        fi
        echo
    fi

    explain "Now the secrets themselves. A route publishes for real only when BOTH its secret is present AND it is named in CI_ROUTES — a secret alone never arms anything. Skipping any of these is fine: the route stays DRY and it lands on the to-do list."
    echo

    local s kind
    for s in $(setup_all_secrets); do
        secrets_have "$s" && { check OK "$s — already: OK"; continue; }
        kind="$(_si "$s" 1)"
        echo; printf '   %s%s%s — %s\n' "$B" "$s" "$D" "$(_si "$s" 3)"
        case "$kind" in
            paste)  _secret_offer_paste "$s" || true ;;
            cosign) [ "$s" = signing/cosign_key ] && { _secret_generate_cosign || true; } || check OK "(made with the key pair above)" ;;
            gpg)    [ "$s" = signing/apt_signing_gpg ] && { _secret_generate_gpg || true; } || check OK "(made with the key above)" ;;
            ssh)    case "$s" in
                        github/github_ssh_key)      _secret_generate_ssh "$s" polari-ci || true ;;
                        ssh/distribution_host_key)  _secret_generate_ssh "$s" polari-ci-apt || true ;;
                    esac ;;
            auto)   check OK "generated by pol jenkins up and printed once" ;;
        esac
    done
    echo
    check OK "parked routes — $SECRETS_PARKED_ROUTES — need an outside account; parked by his rule, nothing is asked here (routes/later/)"
    echo
    step_secrets_check || true
}

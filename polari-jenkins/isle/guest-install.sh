#!/bin/bash
# polari-jenkins/isle/guest-install.sh — ci-3, LAYER 1: THE PRODUCT INSTALLED.
#
# His ask, 2026-09-20: *"make sure the overall functionality including getting
# the actual tests to run and the reports built … so we can be confident when
# doing a deployment from test to main and in the end-result artifacts from
# that."*
#
# This is the half that was the marked TODO in Jenkinsfile.isle-test. Inside the
# throwaway guest, exactly as a person with the deb would do it:
#
#   1. the prerequisites polari-complete does NOT depend on. Its control file
#      Depends on curl/jq/nodejs/openssl/socat/zenity and nothing else — no
#      docker, no libvirt, no dnsmasq — yet `isle create` hard-exits without
#      docker, and without libvirt it asks a QUESTION on a tty and exits 1
#      without one (Isle-Mesh/isle-cli/scripts/create.sh; ISLE_ASSUME_YES is not
#      consulted there). A pipeline that let that happen would be recording a
#      product failure that is really a missing apt line. They go in first, and
#      the fact that they are NOT dependencies is a finding, not a workaround.
#   2. the IMAGES THIS RUN BUILT, loaded from the tarball payload.sh made, and
#      re-tagged under `localhost/` so the isle's own compose can name them.
#   3. `apt-get install ./polari-complete_*.deb` — the one merged package. The
#      four member debs beside it in the pool are NOT installed: polari-complete
#      Provides/Conflicts/Replaces all four, and polari-complete-offline
#      conflicts with polari-complete.
#   4. the .env override, written into the SEED at
#      /usr/share/isle-mesh/polari-isle/.env, between the deb and core-install.
#      isle-polari-deploy.sh copies that seed into ~<user>/polari-isle on first
#      run ONLY — so the seed is the one place an override always takes, and
#      pre-creating the user directory would SKIP the seed of the compose file
#      itself.
#   5. `sudo ISLE_ASSUME_YES=1 isle core-install --skip-security` — the
#      canonical unattended line (Isle-Mesh/NOTES-FROM-POL-CORE.md).
#   6. the wait for the isle to ANSWER, from inside the guest, on the guest's own
#      DNS. core-install ends on an `echo` and therefore exits 0 whatever
#      happened, so its exit code is recorded but never believed: `install.ok`
#      is the two HTTP 200s.
#
# Verdicts: install.ok is true only when the isle answered. Everything else —
# a prereq that would not install, a deb that would not unpack, core-install
# exiting non-zero — is recorded with its reason and the log tail, and
# `core_ok` stays false.

# ---------------------------------------------------------------- the guest half
# $1 = the directory the payload was copied to, inside the guest
# $2 = the modules core-install should load
_install_guest_script() {
cat <<GUEST
# pipefail, deliberately: every rc below is read after a \`| tail -N\`, and
# without it \$? would be tail's (always 0) rather than apt's or docker's — a
# silent "everything installed" for an install that did not.
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
PAY="$1"
MODULES="$2"
CORE_TMO="${CI_ISLE_CORE_INSTALL_TMO_S:-2400}"
ONLINE_TMO="${CI_ISLE_ONLINE_WAIT_S:-600}"
IMAGE_TAG="${CI_ISLE_IMAGE_TAG:-ci}"
GUEST
cat <<'GUEST'
echo "###POLARI-INSTALL-BEGIN"

# ---- 1. what the deb does not depend on, and the isle cannot run without
echo "###STEP prereqs"
T0=$(date +%s)
sudo apt-get update -qq 2>&1 | tail -5
sudo apt-get install -y -qq \
    qemu-kvm qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients \
    bridge-utils dnsmasq acl net-tools wget jq python3 \
    docker.io docker-compose-v2 2>&1 | tail -20
RC=$?
echo "###FIELD rc_prereqs=$RC"
sudo systemctl enable --now libvirtd 2>&1 | tail -3 || true
sudo mkdir -p /etc/dnsmasq.d
echo "###FIELD kvm=$([ -e /dev/kvm ] && echo present || echo ABSENT)"
echo "###FIELD docker=$(docker --version 2>/dev/null || echo absent)"
echo "###FIELD compose=$(docker compose version 2>/dev/null | head -1 || echo absent)"
echo "###FIELD secs_prereqs=$(( $(date +%s) - T0 ))"

# ---- 2. the images THIS RUN built
echo "###STEP images"
T0=$(date +%s)
if [ -s "$PAY/images.tar.gz" ]; then
    gzip -dc "$PAY/images.tar.gz" | sudo docker load 2>&1 | tail -20
    RC=$?
    while IFS="	" read -r ref id; do
        [ -n "$ref" ] || continue
        sudo docker tag "$ref" "localhost/${ref%%:*}:$IMAGE_TAG" || RC=1
        echo "###IMAGE ${ref}|${id}|localhost/${ref%%:*}:$IMAGE_TAG"
    done < "$PAY/images.txt"
else
    echo "no images.tar.gz in the payload — the isle would pull a PUBLISHED image, which is not what this run built"
    RC=1
fi
echo "###FIELD rc_images=$RC"
echo "###FIELD secs_images=$(( $(date +%s) - T0 ))"

# ---- 3. the one merged package
echo "###STEP deb"
T0=$(date +%s)
DEB=$(ls "$PAY"/debs/polari-complete_*.deb 2>/dev/null | head -1)
if [ -n "$DEB" ]; then
    sudo apt-get install -y -qq "$DEB" 2>&1 | tail -20
    RC=$?
    echo "###FIELD deb=$(basename "$DEB")"
    echo "###FIELD deb_sha256=$(sha256sum "$DEB" | cut -d' ' -f1)"
    echo "###FIELD deb_version=$(dpkg-query -W -f='${Version}' polari-complete 2>/dev/null || echo '')"
else
    echo "no polari-complete_*.deb in the payload"
    RC=1
fi
echo "###FIELD rc_deb=$RC"
echo "###FIELD secs_deb=$(( $(date +%s) - T0 ))"

# ---- 4. the images the isle's own compose will name
echo "###STEP env"
SEED=/usr/share/isle-mesh/polari-isle/.env
if [ -d /usr/share/isle-mesh/polari-isle ]; then
    printf 'POLARI_IMAGE_REPO=localhost/\nPOLARI_IMAGE_TAG=%s\n' "$IMAGE_TAG" | sudo tee "$SEED" >/dev/null
    echo "###FIELD env_seed=$(sudo cat "$SEED" | tr '\n' ' ')"
else
    echo "###FIELD env_seed=MISSING — /usr/share/isle-mesh/polari-isle is not there, so the deb did not lay its compose seed down"
fi

# ---- 5. the guided install, unattended
echo "###STEP core-install"
T0=$(date +%s)
sudo timeout "$CORE_TMO" env ISLE_ASSUME_YES=1 isle core-install --skip-security --modules "$MODULES" 2>&1
RC=$?
echo "###FIELD rc_core=$RC"
echo "###FIELD secs_core=$(( $(date +%s) - T0 ))"

# ---- 6. does the isle ANSWER? core-install ends on an echo, so its exit code
#         proves nothing. These two curls are what `install.ok` means.
echo "###STEP online"
T0=$(date +%s)
HEALTH=""; HUB=""
while [ $(( $(date +%s) - T0 )) -lt "$ONLINE_TMO" ]; do
    HEALTH=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 8 \
             --resolve api.polari.isle:443:127.0.0.1 https://api.polari.isle/api/health 2>/dev/null || true)
    HUB=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 8 \
          --resolve polari.isle:443:127.0.0.1 https://polari.isle/isle 2>/dev/null || true)
    [ "$HEALTH" = 200 ] && [ "$HUB" = 200 ] && break
    sleep 10
done
SECS=$(( $(date +%s) - T0 ))
echo "###FIELD health_code=$HEALTH"
echo "###FIELD hub_code=$HUB"
echo "###FIELD secs_online=$SECS"
[ "$HEALTH" = 200 ] && [ "$HUB" = 200 ] && echo "###FIELD online=yes" || echo "###FIELD online=no"
echo "###FIELD containers=$(sudo docker ps --format '{{.Names}}' 2>/dev/null | tr '\n' ',' )"
echo "###POLARI-INSTALL-END"
GUEST
}

# ------------------------------------------------- the reading, in one place
# The §70 gotcha, again: `python3 - <<'PY'` puts the SCRIPT on stdin, so the
# analyser can never also read the log from a pipe. File in, argv path out.
_parse_install() {   # _parse_install <raw log file> <json out|-> <stage> <ok|no>
python3 - "$1" "$2" "$3" "$4" <<'PY'
import json, sys, datetime

raw_path, out_path, stage, reached = sys.argv[1:5]
text = open(raw_path).read()
fields, images, steps, cur = {}, [], {}, None
for line in text.splitlines():
    s = line.strip()
    if s.startswith('###FIELD '):
        k, _, v = s[len('###FIELD '):].partition('=')
        fields[k.strip()] = v.strip()
    elif s.startswith('###STEP '):
        cur = s[len('###STEP '):].strip(); steps.setdefault(cur, [])
    elif s.startswith('###IMAGE '):
        parts = (s[len('###IMAGE '):].split('|') + ['', '', ''])[:3]
        images.append({'built': parts[0], 'id': parts[1], 'as': parts[2]})
    elif s.startswith('###POLARI-INSTALL'):
        continue
    elif cur:
        steps[cur].append(line)


def rc(name):
    v = fields.get('rc_%s' % name, '')
    try:
        return int(v)
    except Exception:
        return None


def secs(name):
    try:
        return int(fields.get('secs_%s' % name, '0') or 0)
    except Exception:
        return 0


online = fields.get('online') == 'yes'
log = []
for k in ('prereqs', 'images', 'deb', 'env', 'core-install', 'online'):
    log += steps.get(k, [])

if reached != 'ok':
    ok, why = False, 'the guest could not be reached over ssh — nothing was installed'
elif rc('prereqs') not in (0, None):
    ok, why = False, ('the prerequisites the deb does not depend on would not install (apt exit %s) — '
                      'docker/libvirt/dnsmasq' % rc('prereqs'))
elif rc('images') not in (0, None):
    ok, why = False, 'the images this run built would not load into the guest (exit %s)' % rc('images')
elif rc('deb') not in (0, None):
    ok, why = False, 'apt-get install of polari-complete exited %s' % rc('deb')
elif online:
    ok, why = True, ('the isle answers from inside the guest: /api/health 200 and /isle 200, '
                     '%ss after core-install returned' % secs('online'))
elif rc('core') == 124:
    ok, why = False, ('isle core-install did not finish inside its timeout (%ss) — the isle never came online'
                      % secs('core'))
else:
    ok, why = False, ('the isle did not answer: /api/health %s, /isle %s (core-install exited %s after %ss)'
                      % (fields.get('health_code') or 'no reply', fields.get('hub_code') or 'no reply',
                         fields.get('rc_core', '?'), secs('core')))

doc = {'kind': 'isle-install', 'stage': stage, 'ok': ok, 'why': why,
       'seconds': secs('prereqs') + secs('images') + secs('deb') + secs('core') + secs('online'),
       'seconds_by_step': {k: secs(k) for k in ('prereqs', 'images', 'deb', 'core', 'online')},
       'time_to_online': secs('core') + secs('online') if online else None,
       'deb': fields.get('deb', ''), 'deb_sha256': fields.get('deb_sha256', ''),
       'deb_version': fields.get('deb_version', ''),
       'images': {i['built']: i['id'] for i in images}, 'images_as': {i['built']: i['as'] for i in images},
       'kvm': fields.get('kvm', ''), 'docker': fields.get('docker', ''),
       'health_code': fields.get('health_code', ''), 'hub_code': fields.get('hub_code', ''),
       'rc_core_install': fields.get('rc_core', ''), 'env_seed': fields.get('env_seed', ''),
       'containers': [c for c in fields.get('containers', '').split(',') if c],
       'at': datetime.datetime.now().isoformat(timespec='seconds'),
       'log_tail': log[-60:]}
if out_path and out_path != '-':
    json.dump(doc, open(out_path, 'w'), indent=1)
print('%s|%s|%s' % ('ok' if ok else 'fail', doc['seconds'], why))
PY
}

# ----------------------------------------------------------------- the verb
install_do() {   # install_do <payload dir on THIS machine> [<json out>] [<stage>] [<modules>]
    local pay="${1:?install_do <payload> [json] [stage] [modules]}" out="${2:-}" stage="${3:-1}"
    local modules="${4:-${CI_ISLE_MODULES:-islemesh}}" raw reached=ok line ok secs why
    say "installing THE ARTIFACTS THIS RUN BUILT inside the guest — polari-complete + the run's own images"
    if ! exists; then
        say "no domain '$CI_ISLE_VM_NAME' — there is nothing to install into"
        raw=""; reached=no
    else
        local gdir="/home/$GUEST_USER/polari-ci-payload"
        say "pushing the payload into the guest ($(du -shL "$pay" | cut -f1))"
        # tar over ssh, NOT scp. OpenSSH 9 runs scp over SFTP, where `scp -r dir/.`
        # no longer reliably means "the contents of dir"; and `-h` here is
        # load-bearing, because images.tar.gz is a SYMLINK into the target's cache
        # whenever the tarball was already there (throwaway.sh install resolves it).
        if ! tar -C "$pay" -chf - . | guest_ssh "rm -rf $gdir && mkdir -p $gdir && tar -C $gdir -xf -"; then
            say "the payload could not be copied into the guest"
            raw=""; reached=no
        else
            raw=$(_install_guest_script "$gdir" "$modules" | guest_ssh 'bash -s' 2>&1) || true
            case "$raw" in *POLARI-INSTALL-END*) reached=ok ;; *) reached=no ;; esac
            # the payload STAYS in the guest: the `apps` verb is a second ssh
            # hop with its own scratch directory on the target, so the only
            # place the app debs still exist by then is here. The guest is
            # destroyed whole a few minutes later, which is the cleanup.
        fi
    fi
    printf '%s\n' "$raw"
    local tmp; tmp="$(mktemp)"; printf '%s' "$raw" > "$tmp"
    line=$(_parse_install "$tmp" "$out" "$stage" "$reached"); rm -f "$tmp"
    ok="${line%%|*}"; line="${line#*|}"; secs="${line%%|*}"; why="${line#*|}"
    echo
    echo "install: $ok in ${secs}s — $why"
    [ -n "$out" ] && say "recorded: $out" || true
    [ "$ok" = ok ] && return 0 || return 6
}

# ------------------------------------------------- the apps a stage tests
# A stage that names apps installs their debs INTO THE ISLE, then runs each
# app's selftest there (guest-selftests.sh). The debs are the ones
# isle/app-debs.sh built from polari-framework's ONE deb writer
# (modules/appstore/custom/app_deb_builder.py) and travelled in the same
# payload as the core.
#
# HONESTY NOTE, recorded rather than papered over: this installs them with
# `apt-get install ./polari-app-<m>_*.deb`, which is the LOCAL door. The isle's
# own store door (apt-on-mesh, `https://apt.isle`) is NOT exercised here,
# because core-install's step 5 publishes it only when step 4 staged the store
# deb, and on a polari-complete box step 4 does not (the `$HOME/polari-shells`
# lookup runs under sudo and looks in /root). That is a product finding and it
# is in the report; it is not something this file should route around.
_apps_guest_script() {
cat <<GUEST
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
PAY="$1"
APPS="$2"
GUEST
cat <<'GUEST'
echo "###POLARI-APPS-BEGIN"
for a in $APPS; do
    DEB=$(ls "$PAY"/app-debs/polari-app-"$a"_*.deb 2>/dev/null | head -1)
    if [ -z "$DEB" ]; then
        echo "###APP $a|missing|no polari-app-${a}_*.deb travelled in the payload"
        continue
    fi
    OUT=$(sudo apt-get install -y -qq "$DEB" 2>&1 | tail -10)
    RC=$?
    if [ "$RC" = 0 ]; then echo "###APP $a|installed|$(basename "$DEB")"
    else echo "###APP $a|failed|apt exit $RC: $(printf '%s' "$OUT" | tr '\n' ' ')"; fi
done
# the backend picks a newly installed module up on restart, not on the copy
sudo docker restart prf-isle-backend >/dev/null 2>&1 && echo "###FIELD restarted=yes" || echo "###FIELD restarted=no"
for i in $(seq 1 30); do
    C=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 8 \
        --resolve api.polari.isle:443:127.0.0.1 https://api.polari.isle/api/health 2>/dev/null || echo 000)
    [ "$C" = 200 ] && break
    sleep 5
done
echo "###FIELD health_after=$C"
echo "###POLARI-APPS-END"
GUEST
}

install_apps_do() {   # install_apps_do <apps> [<json out>] [<stage>]
    local apps="${1:-}" out="${2:-}" stage="${3:-1}" raw reached=ok
    [ -n "$apps" ] || { say "no apps in this stage — nothing to install"; return 0; }
    say "installing the app deb(s) this stage tests, into the isle: $apps"
    if ! exists; then raw=""; reached=no
    else
        raw=$(_apps_guest_script "/home/$GUEST_USER/polari-ci-payload" "$apps" | guest_ssh 'bash -s' 2>&1) || true
        case "$raw" in *POLARI-APPS-END*) reached=ok ;; *) reached=no ;; esac
    fi
    printf '%s\n' "$raw"
    local tmp; tmp="$(mktemp)"; printf '%s' "$raw" > "$tmp"
    python3 - "$tmp" "${out:--}" "$stage" "$reached" <<'PY'
import json, sys, datetime
raw, out, stage, reached = sys.argv[1:5]
apps, fields = {}, {}
for line in open(raw).read().splitlines():
    s = line.strip()
    if s.startswith('###APP '):
        p = (s[len('###APP '):].split('|') + ['', '', ''])[:3]
        apps[p[0]] = {'state': p[1], 'detail': p[2]}
    elif s.startswith('###FIELD '):
        k, _, v = s[len('###FIELD '):].partition('=')
        fields[k.strip()] = v.strip()
bad = sorted(a for a, v in apps.items() if v['state'] != 'installed')
ok = reached == 'ok' and bool(apps) and not bad
doc = {'kind': 'isle-app-install', 'stage': stage, 'ok': ok, 'apps': apps,
       'backend_restarted': fields.get('restarted', ''), 'health_after': fields.get('health_after', ''),
       'why': ('every app deb installed and the backend came back %s' % fields.get('health_after', '?')
               if ok else ('the guest could not be reached' if reached != 'ok'
                           else 'did not install: %s' % ', '.join(bad) if bad else 'no app deb was installed')),
       'at': datetime.datetime.now().isoformat(timespec='seconds')}
if out != '-':
    json.dump(doc, open(out, 'w'), indent=1)
print('%s|%s' % ('ok' if ok else 'fail', doc['why']))
PY
    rm -f "$tmp"
}

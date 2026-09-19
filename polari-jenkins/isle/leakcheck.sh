#!/bin/bash
# polari-jenkins/isle/leakcheck.sh — ci-10 (his ask 2026-09-19: *"we should be
# checking in between to make sure we are not missing things and having leaks
# between things as well"*).
#
# A SNAPSHOT AND A DIFF of the TARGET, taken around every throwaway isle:
#
#   leakcheck.sh baseline        once, BEFORE the first stage  → leak-baseline.json
#   leakcheck.sh check [-s N]    after every `down` (which now wipes) → leak-check-N.json
#   leakcheck.sh report [-s N]   the table: kind | item | baseline | now | verdict
#   leakcheck.sh snapshot        the raw reading, to stdout, writing nothing
#
# WHAT IT READS (all read-only, all through device.sh's on_target, so `local`
# and `ssh` targets are the same code path):
#   VMs (virsh list --all) · libvirt networks · libvirt storage volumes ·
#   files under the libvirt images dir and the pool's run dirs (name + bytes) ·
#   the Polari/isle FOOTPRINT (os-security/inventory.sh, via isle/footprint.sh:
#   debs, containers, images, volumes, units, checkouts, guests, /etc/isle-mesh,
#   /etc/polari) · mounts (loop/iso9660/nbd) · listening TCP+UDP ports ·
#   MemAvailable and swap used · free disk on the images dir and on / ·
#   processes matching qemu|libvirt|isle|polari, with RSS.
#
# WHAT COUNTS AS A LEAK — anything NEW that survived the wipe:
#   a VM, a file, a storage volume, a network, a mount, a listening port, a
#   process identity, a footprint item that was not in the baseline;
#   MemAvailable more than CI_LEAK_RAM_TOLERANCE_MB (default 512) BELOW the
#   baseline — memory that did not come back is exactly the "memory issues" he
#   named; free disk more than CI_LEAK_DISK_TOLERANCE_MB (default 1024) below it.
#
# WHAT IS EXPLICITLY NOT A LEAK:
#   · the offline cache (<cache>, ci-9). It holds the Ubuntu base image ON
#     PURPOSE and grows on the first run by design. Excluded by path, and the
#     exclusion is printed on every run so nobody has to wonder.
#   · <pool>/isle-test — the RESULTS directory. results.json, this baseline and
#     every leak-check-N.json are meant to persist; a diff that counted its own
#     bookkeeping would leak simply by running.
#   · a process that ENDED. Fewer of something is never a leak.
#   · anything the baseline already had. This measures what WE left, not what
#     the device carries.
#
# exit 0 = clean · exit 5 = at least one leak · exit 2 = misuse
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
J="$(cd "$HERE/.." && pwd)"
# shellcheck source=../device.sh
source "$J/device.sh"
# shellcheck source=footprint.sh
source "$HERE/footprint.sh"

CI_LEAK_RAM_TOLERANCE_MB="${CI_LEAK_RAM_TOLERANCE_MB:-512}"
CI_LEAK_DISK_TOLERANCE_MB="${CI_LEAK_DISK_TOLERANCE_MB:-1024}"

POOL="$(device_pool)"
CACHE_ROOT="${CI_CACHE_DIR:-$POOL/cache}"
DIR="${CI_LEAK_DIR:-$POOL/isle-test}"
STAGE=""

CMD="${1:-report}"; shift || true
while [ $# -gt 0 ]; do
    case "$1" in
        --dir)   DIR="$2"; shift ;;
        --stage|-s) STAGE="$2"; shift ;;
        --help|-h) sed -n '2,40p' "$0"; exit 0 ;;
        *) echo "leakcheck.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac; shift
done
case "$CMD" in baseline|check|report|snapshot) ;; --help|-h) sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "leakcheck.sh: unknown command '$CMD' (baseline|check|report|snapshot)" >&2; exit 2 ;;
esac
STAGE="${STAGE:-1}"
BASELINE="$DIR/leak-baseline.json"
CHECK="$DIR/leak-check-$STAGE.json"

# --------------------------------------------------------------- the reading
# ONE snippet, run on the target. Tagged lines, so the parser never guesses.
_snapshot_script() {
cat <<SH
set -u
: ci-10 leak snapshot
CACHE_ROOT='$CACHE_ROOT'
POOL='$POOL'
VMNAME='$CI_ISLE_VM_NAME'
SH
cat <<'SH'
S=""; sudo -n true >/dev/null 2>&1 && S="sudo -n"
V="$S virsh --connect ${LIBVIRT_URI:-qemu:///system}"

command -v virsh >/dev/null 2>&1 && {
    $V list --all --name 2>/dev/null   | sed '/^$/d;s/^/KIND vm /'
    $V net-list --all --name 2>/dev/null | sed '/^$/d;s/^/KIND net /'
    for p in $($V pool-list --name 2>/dev/null); do
        for vol in $($V vol-list "$p" --name 2>/dev/null); do echo "KIND vol $p/$vol"; done
    done
}

IMGDIR=""
for d in /var/lib/libvirt/images /var/lib/libvirt; do [ -d "$d" ] && { IMGDIR="$d"; break; }; done
[ -n "$IMGDIR" ] || IMGDIR="$POOL"
echo "STR imagedir $IMGDIR"

# files that could be ours or could be residue: the libvirt images dir and the
# pool's per-run tree. TWO deliberate exclusions — the CACHE (it holds the base
# image on purpose, ci-9) and <pool>/isle-test, which is where the RESULTS live:
# results.json, this very baseline and every leak-check-N.json are MEANT to
# persist, and a diff that counted its own bookkeeping would leak by existing.
for d in "$IMGDIR" "$POOL/ci-isle"; do
    [ -d "$d" ] || continue
    case "$d" in "$CACHE_ROOT"|"$CACHE_ROOT"/*) continue ;; esac
    # the two exclusions are by PATH, not by name: on a device with no
    # /var/lib/libvirt the images dir falls back to the pool itself, and the
    # results dir would then be swept in under it.
    find "$d" -maxdepth 2 -type f \
         -not -path "$CACHE_ROOT/*" -not -path "$POOL/isle-test/*" \
         -printf 'KIND file %p|%s\n' 2>/dev/null
done

mount 2>/dev/null | grep -E '(^/dev/loop|type iso9660|/dev/nbd)' \
  | awk '{print "KIND mount " $1 " on " $3}'

ss -lntu 2>/dev/null | awk 'NR>1 {print "KIND port " $1 "|" $5}' | sort -u

ps -eo comm=,rss=,args= 2>/dev/null \
  | grep -Ei 'qemu|libvirt|isle|polari' | grep -v 'grep -E' \
  | awk '{ comm=$1; rss=$2; guest="";
           for (i=3; i<=NF; i++) if ($i ~ /guest=/) { guest=$i; sub(/.*guest=/, "", guest); sub(/,.*/, "", guest) }
           print "KIND proc " comm (guest == "" ? "" : "(" guest ")") "|" rss }'

awk '/MemAvailable/{print "NUM mem_available_mb " int($2/1024)}' /proc/meminfo
awk '/SwapTotal/{t=$2} /SwapFree/{f=$2} END{print "NUM swap_used_mb " int((t-f)/1024)}' /proc/meminfo
echo "NUM disk_free_images_mb $(df -BM --output=avail "$IMGDIR" 2>/dev/null | tail -1 | tr -dc '0-9')"
echo "NUM disk_free_root_mb $(df -BM --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')"
SH
}

_read_target() {   # → tagged lines on stdout
    on_target "$(_snapshot_script)" 2>/dev/null || true
    # the footprint is read the ONE way the suite already reads it
    local f; f="$(target_footprint 2>/dev/null || true)"
    case "$f" in ''|unreadable) [ -n "$f" ] && echo "STR footprint_read $f" || true ;;
        *) local i; for i in $f; do echo "KIND footprint $i"; done ;;
    esac
}

# ------------------------------------------------------------ parse → json
_to_json() {   # _to_json <tagged file> <out path|-> ; extra argv → metadata
    python3 - "$@" <<'PY'
import json, sys, datetime, collections
src, out = sys.argv[1:3]
target, vm, cache = (sys.argv[3:6] + ['', '', ''])[:3]
kinds = collections.defaultdict(dict)
nums, strs = {}, {}
for line in open(src):
    line = line.rstrip('\n')
    if line.startswith('KIND '):
        kind, _, rest = line[5:].partition(' ')
        item, _, val = rest.partition('|')
        item = item.strip()
        if not item:
            continue
        if kind == 'proc':                       # aggregate: count + total RSS
            cur = kinds[kind].get(item) or {'count': 0, 'rss_kb': 0}
            cur['count'] += 1
            cur['rss_kb'] += int(val or 0)
            kinds[kind][item] = cur
        else:
            kinds[kind][item] = (int(val) if val.strip().isdigit() else (val.strip() or True))
    elif line.startswith('NUM '):
        k, _, v = line[4:].partition(' ')
        try:
            nums[k.strip()] = int(v.strip())
        except ValueError:
            pass
    elif line.startswith('STR '):
        k, _, v = line[4:].partition(' ')
        strs[k.strip()] = v.strip()
doc = {'kind': 'leak-snapshot', 'at': datetime.datetime.now().isoformat(timespec='seconds'),
       'target': target, 'vm': vm, 'cache_excluded': cache,
       'items': {k: kinds[k] for k in sorted(kinds)}, 'numbers': nums, 'strings': strs}
text = json.dumps(doc, indent=1)
if out and out != '-':
    open(out, 'w').write(text)
else:
    print(text)
PY
}

# ------------------------------------------------------------- the diff
_diff() {   # _diff <baseline.json> <now.json> <out.json|-> <stage> <ram tol> <disk tol> <cache>
    python3 - "$@" <<'PY'
import json, sys, datetime

base_p, now_p, out_p, stage, ram_tol, disk_tol, cache = sys.argv[1:8]
ram_tol, disk_tol = int(ram_tol), int(disk_tol)
base = json.load(open(base_p))
now = json.load(open(now_p))

LABEL = {'vm': 'VM', 'net': 'libvirt network', 'vol': 'storage volume', 'file': 'file',
         'mount': 'mount', 'port': 'listening port', 'proc': 'process', 'footprint': 'footprint item'}

def fmt(kind, v):
    if v is True or v is None:
        return 'present'
    if kind == 'file':
        b = int(v or 0)
        for unit, div in (('G', 1073741824), ('M', 1048576), ('K', 1024)):
            if b >= div:
                return '%.1f%s' % (b / div, unit)
        return '%dB' % b
    if kind == 'proc':
        return 'x%d, %d MB RSS' % (v.get('count', 0), v.get('rss_kb', 0) // 1024)
    return str(v)

rows, leaks = [], []
for kind in sorted(set(base.get('items', {})) | set(now.get('items', {}))):
    b_items = base.get('items', {}).get(kind, {})
    n_items = now.get('items', {}).get(kind, {})
    for item in sorted(set(b_items) | set(n_items)):
        in_b, in_n = item in b_items, item in n_items
        if in_b and not in_n:
            # fewer of something is NEVER a leak — a process that ended, a file we removed
            rows.append({'kind': LABEL.get(kind, kind), 'item': item,
                         'baseline': fmt(kind, b_items[item]), 'now': 'gone', 'verdict': 'ok (gone)'})
            continue
        if in_b and in_n:
            grew = (kind == 'proc' and n_items[item].get('count', 0) > b_items[item].get('count', 0))
            row = {'kind': LABEL.get(kind, kind), 'item': item, 'baseline': fmt(kind, b_items[item]),
                   'now': fmt(kind, n_items[item]), 'verdict': 'LEAK' if grew else 'ok'}
            rows.append(row)
            if grew:
                leaks.append(row)
            continue
        row = {'kind': LABEL.get(kind, kind), 'item': item, 'baseline': 'absent',
               'now': fmt(kind, n_items[item]), 'verdict': 'LEAK'}
        rows.append(row)
        leaks.append(row)

bn, nn = base.get('numbers', {}), now.get('numbers', {})
ram_delta = nn.get('mem_available_mb', 0) - bn.get('mem_available_mb', 0)
disk_delta = nn.get('disk_free_images_mb', 0) - bn.get('disk_free_images_mb', 0)
root_delta = nn.get('disk_free_root_mb', 0) - bn.get('disk_free_root_mb', 0)
swap_delta = nn.get('swap_used_mb', 0) - bn.get('swap_used_mb', 0)

def meter(kind, item, b, n, delta, tol, unit='MB'):
    bad = delta < -tol
    row = {'kind': kind, 'item': item, 'baseline': '%d %s' % (b, unit), 'now': '%d %s' % (n, unit),
           'verdict': 'LEAK' if bad else 'ok', 'delta_mb': delta}
    rows.append(row)
    if bad:
        leaks.append(row)
    return row

meter('memory', 'MemAvailable (did the RAM come back?)', bn.get('mem_available_mb', 0),
      nn.get('mem_available_mb', 0), ram_delta, ram_tol)
meter('disk', 'free on the images dir', bn.get('disk_free_images_mb', 0),
      nn.get('disk_free_images_mb', 0), disk_delta, disk_tol)
meter('disk', 'free on /', bn.get('disk_free_root_mb', 0),
      nn.get('disk_free_root_mb', 0), root_delta, disk_tol)
rows.append({'kind': 'memory', 'item': 'swap used', 'baseline': '%d MB' % bn.get('swap_used_mb', 0),
             'now': '%d MB' % nn.get('swap_used_mb', 0),
             'verdict': 'ok' if swap_delta <= ram_tol else 'note (swapped, not leaked)'})

doc = {'kind': 'leak-check', 'stage': stage,
       'at': datetime.datetime.now().isoformat(timespec='seconds'),
       'target': now.get('target', ''), 'vm': now.get('vm', ''),
       'baseline_at': base.get('at', ''),
       'excluded': [cache, 'the offline cache holds the base image on purpose (ci-9) — never a leak'],
       'ram_tolerance_mb': ram_tol, 'disk_tolerance_mb': disk_tol,
       'ram_delta_mb': ram_delta, 'disk_delta_mb': disk_delta, 'root_delta_mb': root_delta,
       'verdict': 'leaked' if leaks else 'clean',
       'leaks': leaks, 'rows': rows}
if out_p and out_p != '-':
    json.dump(doc, open(out_p, 'w'), indent=1)
print('%s %d' % (doc['verdict'], len(leaks)))
PY
}

# ------------------------------------------------------------- the table
_report() {   # _report <leak-check.json>
    python3 - "$1" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print('no leak check to report (%s)' % e)
    raise SystemExit(2)
print('leak check — stage %s, target %s, against the baseline of %s'
      % (d.get('stage'), d.get('target'), d.get('baseline_at') or '(unknown)'))
print('EXCLUDED: %s' % ' — '.join(str(x) for x in d.get('excluded', [])))
print('tolerances: RAM %d MB, disk %d MB (a reading below them is a LEAK: memory that did not come back)'
      % (d.get('ram_tolerance_mb', 0), d.get('disk_tolerance_mb', 0)))
print()
w = (18, 46, 16, 16)
print('%-*s %-*s %-*s %-*s %s' % (w[0], 'kind', w[1], 'item', w[2], 'baseline', w[3], 'now', 'verdict'))
print('%-*s %-*s %-*s %-*s %s' % (w[0], '-' * w[0], w[1], '-' * w[1], w[2], '-' * w[2], w[3], '-' * w[3], '-------'))
for r in d.get('rows', []):
    if r['verdict'].startswith('ok') and len(d.get('rows', [])) > 40 and r['kind'] not in ('memory', 'disk'):
        continue          # a long run prints the LEAKs and the meters; --json has every row
    item = r['item']
    if len(item) > w[1]:
        item = '…' + item[-(w[1] - 1):]
    print('%-*s %-*s %-*s %-*s %s' % (w[0], r['kind'], w[1], item, w[2], r['baseline'], w[3], r['now'], r['verdict']))
print()
n = len(d.get('leaks', []))
if n:
    print('LEAKED: %d thing(s) survived the wipe (exit 5). RAM delta %+d MB, images-dir disk delta %+d MB.'
          % (n, d.get('ram_delta_mb', 0), d.get('disk_delta_mb', 0)))
    print('  → run `pol jenkins isle wipe` and check again; if it persists the next stage would start on a dirty host.')
else:
    print('CLEAN: nothing new survived the wipe. RAM delta %+d MB, images-dir disk delta %+d MB — the memory came back.'
          % (d.get('ram_delta_mb', 0), d.get('disk_delta_mb', 0)))
raise SystemExit(5 if n else 0)
PY
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

case "$CMD" in
snapshot)
    _read_target > "$TMP/raw"
    _to_json "$TMP/raw" - "$(device_target_name)" "$CI_ISLE_VM_NAME" "$CACHE_ROOT"
    ;;
baseline)
    mkdir -p "$DIR"
    _read_target > "$TMP/raw"
    _to_json "$TMP/raw" "$BASELINE" "$(device_target_name)" "$CI_ISLE_VM_NAME" "$CACHE_ROOT"
    echo "leak baseline taken BEFORE the first stage: $BASELINE"
    echo "target: $(device_target_name)   vm: $CI_ISLE_VM_NAME"
    echo "EXCLUDED: $CACHE_ROOT — the offline cache holds the base image on purpose (ci-9); it is never a leak"
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1]));
print("read: " + ", ".join("%s %d" % (k, len(v)) for k, v in d["items"].items()));
print("     MemAvailable %d MB, images-dir free %d MB, / free %d MB" % (d["numbers"].get("mem_available_mb",0), d["numbers"].get("disk_free_images_mb",0), d["numbers"].get("disk_free_root_mb",0)))' "$BASELINE"
    ;;
check)
    [ -f "$BASELINE" ] || { echo "leakcheck: no baseline at $BASELINE — run 'leakcheck.sh baseline' before the first stage" >&2; exit 2; }
    mkdir -p "$DIR"
    _read_target > "$TMP/raw"
    _to_json "$TMP/raw" "$TMP/now.json" "$(device_target_name)" "$CI_ISLE_VM_NAME" "$CACHE_ROOT"
    _diff "$BASELINE" "$TMP/now.json" "$CHECK" "$STAGE" \
          "$CI_LEAK_RAM_TOLERANCE_MB" "$CI_LEAK_DISK_TOLERANCE_MB" "$CACHE_ROOT" >/dev/null
    _report "$CHECK"
    ;;
report)
    _report "$CHECK"
    ;;
esac

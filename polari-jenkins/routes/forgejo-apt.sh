#!/bin/bash
# The forge's apt repository (frg-3) — REPLACES the old self-run apt route (signing key + rsync host) (his ruling 2026-09-30): the same tested debs
# from the same release pool, byte-identical, uploaded to the forge's Debian registry, which signs its own indexes.
# People add ONE apt line + the forge's key (routes/destinations.sh dest_forge_apt_line / dest_forge_apt_key).
#   PUT  <forge>/api/packages/<owner>/debian/pool/<dist>/<component>/upload    201 uploaded · 409 already there (done)
#   GET  <forge>/api/packages/<owner>/debian/dists/<dist>/<component>/binary-<arch>/Packages
# THE APT PROOF: every uploaded package+version must be LISTED in that index afterwards — the route fails if not.
source "$(dirname "$0")/_lib.sh"
arm FORGE_TOKEN:forge/publish_token
source "$(dirname "$0")/_forge.sh"
APT="$(dest_forge_apt_url)"; DIST="$DEST_FORGE_APT_DIST"; COMP="$DEST_FORGE_APT_COMPONENT"
deb_fields(){  # <deb> → name<TAB>version<TAB>arch — from the control file, else the Debian file name convention
    local f="$1" b out
    out="$(dpkg-deb -f "$f" Package Version Architecture 2>/dev/null | sed 's/^[A-Za-z]*: //' | paste -sd '\t' -)" || out=""
    if [ "$(printf '%s' "$out" | awk -F'\t' '{print NF}')" = 3 ]; then printf '%s\n' "$out"; return 0; fi
    b="$(basename "$f" .deb)"
    printf '%s\t%s\t%s\n' "${b%%_*}" "$(b2="${b#*_}"; printf '%s' "${b2%_*}" | sed 's/%3[aA]/:/g')" "${b##*_}"
}
mapfile -t DEBS < <(release_assets "$POOL_DIR/debs" | grep '\.deb$' || true)
[ ${#DEBS[@]} -gt 0 ] || { say "no tested debs in $POOL_DIR/debs — nothing to upload"; record "$APT (nothing to upload)"; exit 0; }
say "apt: $APT  $DIST $COMP  (${#DEBS[@]} deb(s); the forge signs the index — $(dest_forge_apt_key))"
: > "$FJ_WORK/want"
for deb in "${DEBS[@]}"; do
    deb_fields "$deb" >> "$FJ_WORK/want"
    fj PUT "$APT/pool/$DIST/$COMP/upload" --upload-file "$deb"
    [ "$DRY_RUN" = 1 ] && continue
    case "$FJ_CODE" in
        200|201) ;;
        409) echo "[$ROUTE]   $(basename "$deb") is already in the registry (same name + version) — counts as done" ;;
        *)   echo "[$ROUTE] FAILED: uploading $(basename "$deb") — $(fj_why)"; FAILED=$((FAILED + 1)) ;;
    esac
done
# the proof: read each architecture's Packages index and find every package+version in it. An `all` deb is looked
# for in binary-all and in each architecture index (FORGE_APT_ARCHES, default amd64) — apt reads it from either.
ARCHES="$(cut -f3 "$FJ_WORK/want" | sort -u | tr '\n' ' ')"
case " $ARCHES " in *" all "*) for a in ${FORGE_APT_ARCHES:-amd64}; do case " $ARCHES " in *" $a "*) ;; *) ARCHES="$ARCHES $a" ;; esac; done ;; esac
: > "$FJ_WORK/listed"
for a in $ARCHES; do
    fj GET "$APT/dists/$DIST/$COMP/binary-$a/Packages"
    [ "$DRY_RUN" = 1 ] && continue
    [ "$FJ_CODE" = 200 ] && python3 - "$FJ_BODY" "$a" >> "$FJ_WORK/listed" <<'PY'
import sys
arch = sys.argv[2]; pkg = ver = None
for line in open(sys.argv[1], errors="replace").read().split("\n") + [""]:
    if not line.strip():
        if pkg and ver: print("%s\t%s\t%s" % (pkg, ver, arch))
        pkg = ver = None
    elif line.startswith("Package:"): pkg = line.split(":", 1)[1].strip()
    elif line.startswith("Version:"): ver = line.split(":", 1)[1].strip()
PY
done
if [ "$DRY_RUN" = 1 ]; then
    say "then assert each of $(wc -l < "$FJ_WORK/want") package(s) is listed: $(awk -F'\t' '{printf "%s=%s ", $1, $2}' "$FJ_WORK/want")"
else
    MISSING="$(python3 - "$FJ_WORK/want" "$FJ_WORK/listed" <<'PY'
import sys
listed = {tuple(l.rstrip("\n").split("\t")[:2]) for l in open(sys.argv[2]) if l.strip()}
for l in open(sys.argv[1]):
    if not l.strip(): continue
    name, ver, arch = l.rstrip("\n").split("\t")
    if (name, ver) not in listed: print("%s=%s (%s)" % (name, ver, arch))
PY
)"
    if [ -n "$MISSING" ]; then echo "[$ROUTE] FAILED: the apt index does not list:"; printf '%s\n' "$MISSING" | sed 's/^/    /'; FAILED=$((FAILED + 1))
    else echo "[$ROUTE] apt proof: all $(wc -l < "$FJ_WORK/want") package(s) are listed in the forge's Packages index"; fi
fi
[ "$FAILED" = 0 ] || { echo "[$ROUTE] FAILED — re-run polari-publish (an upload already there is a 409, which counts as done)"; exit 1; }
record "$APT ($DIST $COMP)"

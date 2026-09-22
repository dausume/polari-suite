#!/bin/bash
# polari-jenkins/tested-images.sh — THE TESTED IMAGES ARE THE RELEASED IMAGES, by construction (2026-09-22).
#
# Found live: polari-release #337 rebuilt prf-backend etc. from the SAME sha the isle had tested, and the
# image ids differed (a build is not byte-reproducible) — so routes/_lib.sh released_vs_tested would have
# refused every route ("released != tested"), and pol-reticulum was in the release although the isle never
# tested it. The rule (his, ci-7b) is "the pipeline only generates artifacts for things it TESTED"; this
# carries it through instead of checking it after the fact:
#
#   tested-images.sh keep <run-dir>            after a PASSED verdict: `docker save` exactly the images the
#                                              verdict's isle stage installed (isle.images: name:tag → id) into
#                                              <run-dir>/images/<name>.tar + DIGESTS.txt. Only a passed verdict
#                                              keeps anything (ci-13: test images are otherwise discarded).
#   tested-images.sh load <sha> <version> <out-dir>
#                                              at release time: `docker load` those tarballs, verify the ids
#                                              still match the verdict, tag <name>:<version>, save + DIGESTS.txt
#                                              into <out-dir>. exit 0 = the release's images ARE the tested
#                                              ones · 3 = no kept images for this sha (the release must not
#                                              rebuild and pretend: it says so and publishes nothing)
#   tested-images.sh list <run-dir>            what is kept, with ids
set -euo pipefail
POOL="${POLARI_POOL:-/var/polari-pool}"
DOCKER="${POLARI_DOCKER:-docker}"
say() { printf '[tested-images] %s\n' "$*"; }
verdict_images() {  # verdict_images <verdict.json> → "name:tag<TAB>id" lines
    python3 -c 'import json,sys
v = json.load(open(sys.argv[1]))
for k, i in ((v.get("isle") or {}).get("images") or {}).items(): print("%s\t%s" % (k, i))' "$1"
}
case "${1:-}" in
    keep)
        RUN="${2:?run-dir}"; V="$RUN/verdict.json"
        [ -f "$V" ] || { say "no verdict in $RUN — nothing kept"; exit 0; }
        VER="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("verdict"))' "$V")"
        if [ "$VER" != passed ]; then say "verdict is '$VER', not passed — the test images are discarded (only a release candidate is kept)"; exit 0; fi
        mkdir -p "$RUN/images"; : > "$RUN/images/DIGESTS.txt"; N=0
        while IFS=$'\t' read -r ref id; do
            [ -n "$ref" ] || continue
            have="$($DOCKER image inspect --format '{{.Id}}' "$ref" 2>/dev/null || true)"
            if [ "$have" != "$id" ]; then say "SKIP $ref: the image on this daemon is ${have:-absent}, the isle tested $id — not kept (it would not be the tested one)"; continue; fi
            name="${ref%%:*}"
            $DOCKER save -o "$RUN/images/$name.tar" "$ref"
            printf '%s %s\n' "$id" "$ref" >> "$RUN/images/DIGESTS.txt"; N=$((N+1))
            say "kept $ref ($id) → images/$name.tar ($(du -h "$RUN/images/$name.tar" | cut -f1))"
        done < <(verdict_images "$V")
        say "$N tested image(s) kept as the release candidate for $(basename "$RUN") — a release LOADS these, it does not rebuild"
        [ "$N" -gt 0 ] || exit 0 ;;
    load)
        SHA="${2:?sha}"; VERSION="${3:?version}"; OUT="${4:?out-dir}"
        RUN="$POOL/test/$SHA"; V="$RUN/verdict.json"
        [ -f "$V" ] && [ -s "$RUN/images/DIGESTS.txt" ] || { say "no kept tested images for $SHA under $RUN/images — the release cannot claim tested == released"; exit 3; }
        mkdir -p "$OUT"; : > "$OUT/DIGESTS.txt"; N=0
        while IFS=$'\t' read -r ref id; do
            [ -n "$ref" ] || continue
            name="${ref%%:*}"; tar="$RUN/images/$name.tar"
            [ -s "$tar" ] || { say "MISSING $tar for $ref — the release cannot claim tested == released"; exit 3; }
            $DOCKER load -q -i "$tar" >/dev/null
            have="$($DOCKER image inspect --format '{{.Id}}' "$id" 2>/dev/null || true)"
            [ "$have" = "$id" ] || { say "the tarball for $ref did not load as $id — refusing"; exit 3; }
            $DOCKER tag "$id" "$name:$VERSION"
            $DOCKER save -o "$OUT/${name}_$VERSION.tar" "$name:$VERSION"
            printf '%s %s:%s\n' "$id" "$name" "$VERSION" >> "$OUT/DIGESTS.txt"; N=$((N+1))
            say "$name:$VERSION IS the tested image $id (loaded, not rebuilt)"
        done < <(verdict_images "$V")
        say "$N image(s): released == tested by construction"
        [ "$N" -gt 0 ] || exit 3 ;;
    list)
        RUN="${2:?run-dir}"; cat "$RUN/images/DIGESTS.txt" 2>/dev/null || echo "(nothing kept)" ;;
    *) echo "usage: tested-images.sh keep <run-dir> | load <sha> <version> <out-dir> | list <run-dir>" >&2; exit 2 ;;
esac

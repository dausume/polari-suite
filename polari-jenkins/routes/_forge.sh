#!/bin/bash
# polari-jenkins/routes/_forge.sh — what the four forge routes share (frg-3). Sourced AFTER _lib.sh and `arm`,
# so DRY_RUN is already resolved and FORGE_TOKEN is either the secret or a "<absent:…>" placeholder.
#
# His rulings 2026-09-27/30: DUAL ROUTE always — GitHub is online availability, the forge (Forgejo 11) is
# self-sustaining and, on production, THE DEFAULT for people. Its Debian registry replaces the old self-run apt
# route. The pipeline stops at publish; devices pull (`pol prod update`, `isle update`) forge first.
#
# The token is NEVER on argv: every call reads its Authorization header from a process substitution (the same
# pattern polari-forge/scripts/_lib.sh uses), and every rendered line shows `<forge/publish_token>` instead.
# A WRITE goes through fj (rendered when DRY, executed + its HTTP code printed when ARMED) — so a DRY run and a
# real run print the same lines. A READ (fj_get) is only made when ARMED: a dry run talks to nobody.
FORGE="$(dest_forge_url)"; FOWNER="$(dest_forge_owner)"; FREPO="$(dest_forge_release_repo)"
FJ_WORK="$(mktemp -d)"; trap 'rm -rf "$FJ_WORK"' EXIT
FJ_BODY="$FJ_WORK/body"; FJ_CODE=""; : > "$FJ_BODY"
FJ_AUTH_SHOWN="-H 'Authorization: token <forge/publish_token>'"
FAILED=0

say(){ if [ "$DRY_RUN" = 1 ]; then echo "[dry-run:$ROUTE] $*"; else echo "[$ROUTE] $*"; fi; }
fj_api(){ printf '%s/api/v1/repos/%s%s' "$FORGE" "$FREPO" "$1"; }
fj_call(){  # fj_call METHOD URL [curl args…] — the raw call, never rendered; sets FJ_CODE (000 = no answer)
    local m="$1" u="$2"; shift 2
    FJ_CODE="$(curl -sS -m "${FORGE_TIMEOUT:-600}" -X "$m" -H @<(printf 'Authorization: token %s\n' "$FORGE_TOKEN") \
                    -o "$FJ_BODY" -w '%{http_code}' "$@" "$u" 2>"$FJ_WORK/err")" || true
    case "$FJ_CODE" in [0-9][0-9][0-9]) ;; *) FJ_CODE=000 ;; esac
}
fj_get(){ fj_call GET "$1"; }
fj(){  # fj METHOD URL [curl args…] — a WRITE (or a proof read): the same line DRY and ARMED
    local m="$1" u="$2"; shift 2
    if [ "$DRY_RUN" = 1 ]; then echo "[dry-run:$ROUTE] curl -X $m $FJ_AUTH_SHOWN $* $u"; FJ_CODE=dry; : > "$FJ_BODY"; return 0; fi
    echo "[$ROUTE] curl -X $m $FJ_AUTH_SHOWN $* $u"
    fj_call "$m" "$u" "$@"
    echo "[$ROUTE]   → HTTP $FJ_CODE"
}
fj_field(){ python3 -c 'import json,sys
try: d = json.load(open(sys.argv[1]))
except Exception: sys.exit(0)
v = eval(sys.argv[2], {"d": d})
print("" if v is None else v)' "$FJ_BODY" "$1" 2>/dev/null || true; }
fj_why(){ printf 'HTTP %s%s' "$FJ_CODE" "$(head -c 300 "$FJ_BODY" 2>/dev/null | tr '\n' ' ' | sed 's/^./ — &/')"; }
urlq(){ python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"; }

# clobber semantics, as `gh release upload --clobber`: an asset of the same name is DELETEd first, then POSTed.
fj_upload_asset(){  # fj_upload_asset <release id> <file>
    local id="$1" f="$2" name aid
    name="$(basename "$f")"
    if [ "$DRY_RUN" = 1 ]; then
        echo "[dry-run:$ROUTE] (clobber: an existing asset named $name is DELETEd first — /releases/$id/assets/<its id>)"
    else
        fj_get "$(fj_api "/releases/$id/assets")"
        aid="$(python3 - "$FJ_BODY" "$name" <<'PY'
import json, sys
try: d = json.load(open(sys.argv[1]))
except Exception: d = []
print(next((str(a.get("id")) for a in (d if isinstance(d, list) else []) if a.get("name") == sys.argv[2]), ""))
PY
)"
        [ -n "$aid" ] && fj DELETE "$(fj_api "/releases/$id/assets/$aid")"
    fi
    fj POST "$(fj_api "/releases/$id/assets?name=$(urlq "$name")")" -F "attachment=@$f"
    [ "$DRY_RUN" = 1 ] && return 0
    case "$FJ_CODE" in 200|201) return 0 ;; esac
    echo "[$ROUTE] FAILED: uploading $name — $(fj_why)"; FAILED=$((FAILED + 1)); return 1
}

fj_release_id(){  # fj_release_id <tag> → the forge release id ('' when there is none)
    fj_get "$(fj_api "/releases/tags/$1")"
    [ "$FJ_CODE" = 200 ] && fj_field 'd.get("id")' || true
}

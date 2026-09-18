#!/bin/bash
# ==============================================================================
# DEMONSTRATION ACCOUNTS — the Polari realm
# ==============================================================================
# Creates the groups and the four demonstration users a demo stack signs in as,
# so "who may see what" can be shown by actually logging in as each of them
# (AI-Notes/guides/ROLEPLAY_PERMISSIONS_GUIDE.md).
#
# THESE ARE NOT REAL ACCOUNTS. Every one of them shares ONE password, written
# by `pol prod` into .generated/demo-users.env on the host and handed here as
# DEMO_USER_PASSWORD — anyone who can read that file can sign in as any of
# them, the admin included. The script therefore refuses to run unless
# POLARI_DEMO_USERS=on, which `pol prod` sets only from the POL_PROD_DEMO_USERS
# answer (default: on for a dev posture, off for production).
#
# Idempotent: every user and group is created if absent and left alone if
# present, except the password, which is re-set on each run so a regenerated
# demo-users.env takes effect. Never exits non-zero — it runs from the
# entrypoint and must not take Keycloak down.
#
# Environment:
#   POLARI_DEMO_USERS     on|off (off => this script does nothing)
#   DEMO_USER_PASSWORD    the shared password
#   KEYCLOAK_ADMIN / KEYCLOAK_ADMIN_PASSWORD   the master-realm admin
# ==============================================================================

KEYCLOAK_URL="http://localhost:8080"
REALM="Polari"

if [ "${POLARI_DEMO_USERS:-off}" != "on" ]; then
    echo "[seed_demo_users] POLARI_DEMO_USERS is not 'on' — no demonstration accounts."
    exit 0
fi
if [ -z "${DEMO_USER_PASSWORD:-}" ]; then
    echo "[seed_demo_users] POLARI_DEMO_USERS=on but DEMO_USER_PASSWORD is empty — refusing to create accounts with a guessable password."
    exit 0
fi

echo "=============================================="
echo "Demonstration accounts (realm $REALM)"
echo "=============================================="

# ---- admin token -------------------------------------------------------------
TOKEN=""
for ((i=1; i<=10; i++)); do
    R=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=${KEYCLOAK_ADMIN:-admin}" -d "password=${KEYCLOAK_ADMIN_PASSWORD:-admin}" \
        -d "grant_type=password" -d "client_id=admin-cli")
    TOKEN=$(echo "$R" | jq -r '.access_token // empty')
    [ -n "$TOKEN" ] && break
    echo "[seed_demo_users] waiting for the admin token ($i/10)"; sleep 5
done
[ -n "$TOKEN" ] || { echo "[seed_demo_users] no admin token — skipping."; exit 0; }

AUTH=(-H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json")

if [ "$(curl -s -o /dev/null -w '%{http_code}' -X GET "$KEYCLOAK_URL/admin/realms/$REALM" "${AUTH[@]}")" != "200" ]; then
    echo "[seed_demo_users] realm '$REALM' is not present — skipping."
    exit 0
fi

# ---- groups ------------------------------------------------------------------
# The names are GRANT KEYS: the `groups` token claim carries them, and
# AppPermissionProfile.kc_groups_json matches against exactly these strings
# (polariapps/objects/apps_permissions/_shared.py: caller_groups + resolve_grants).
for G in journalist data-scientist operators; do
    EXISTING=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/groups?search=$G" "${AUTH[@]}" | jq -r --arg g "$G" '.[] | select(.name==$g) | .id')
    if [ -n "$EXISTING" ]; then
        echo "  group $G present"
    else
        CODE=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KEYCLOAK_URL/admin/realms/$REALM/groups" "${AUTH[@]}" -d "{\"name\": \"$G\"}")
        echo "  group $G created (HTTP $CODE)"
    fi
done

# ---- realm-role ids ----------------------------------------------------------
role_json() {  # role name -> [{id,name}] for the role-mapping endpoint
    local r; r=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/roles/$1" "${AUTH[@]}")
    echo "$r" | jq -c 'if .id then [{id: .id, name: .name}] else [] end'
}

# ---- users -------------------------------------------------------------------
# username | realm role | group (empty = none) | first name | last name
# E-mails are @example.invalid: a reserved TLD that can never be delivered to
# (his rule: no real identifiers anywhere in the tree or on a server).
seed_user() {
    local USERNAME=$1 ROLE=$2 GROUP=$3 FIRST=$4 LAST=$5
    local UID_
    UID_=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/users?username=$USERNAME&exact=true" "${AUTH[@]}" | jq -r '.[0].id // empty')
    if [ -z "$UID_" ]; then
        curl -s -o /dev/null -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users" "${AUTH[@]}" -d "$(jq -n \
            --arg u "$USERNAME" --arg e "$USERNAME@example.invalid" --arg f "$FIRST" --arg l "$LAST" \
            '{username: $u, email: $e, firstName: $f, lastName: $l, enabled: true, emailVerified: true}')"
        UID_=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/users?username=$USERNAME&exact=true" "${AUTH[@]}" | jq -r '.[0].id // empty')
        echo "  user $USERNAME created"
    else
        echo "  user $USERNAME present"
    fi
    [ -n "$UID_" ] || { echo "  WARNING: could not resolve $USERNAME — skipping its role/group/password"; return 0; }

    # password (re-set every run, so a regenerated demo-users.env takes effect)
    curl -s -o /dev/null -X PUT "$KEYCLOAK_URL/admin/realms/$REALM/users/$UID_/reset-password" "${AUTH[@]}" \
        -d "$(jq -n --arg p "$DEMO_USER_PASSWORD" '{type: "password", value: $p, temporary: false}')"

    if [ -n "$ROLE" ]; then
        local RJ; RJ=$(role_json "$ROLE")
        if [ "$RJ" = "[]" ]; then echo "  WARNING: realm role '$ROLE' not found"; else
            curl -s -o /dev/null -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users/$UID_/role-mappings/realm" "${AUTH[@]}" -d "$RJ"
            echo "    role $ROLE"
        fi
    fi
    if [ -n "$GROUP" ]; then
        local GID; GID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/groups?search=$GROUP" "${AUTH[@]}" | jq -r --arg g "$GROUP" '.[] | select(.name==$g) | .id')
        if [ -z "$GID" ]; then echo "  WARNING: group '$GROUP' not found"; else
            curl -s -o /dev/null -X PUT "$KEYCLOAK_URL/admin/realms/$REALM/users/$UID_/groups/$GID" "${AUTH[@]}"
            echo "    group $GROUP"
        fi
    fi
}

seed_user demo-admin      polari-admin  ""              Demo Admin
seed_user demo-journalist polari-user   journalist      Demo Journalist
seed_user demo-scientist  polari-user   data-scientist  Demo Scientist
seed_user demo-viewer     polari-viewer ""              Demo Viewer

echo "=============================================="
echo "Demonstration accounts ready. They all share ONE password"
echo "(.generated/demo-users.env on the server) — demonstration stacks only."
echo "=============================================="
exit 0

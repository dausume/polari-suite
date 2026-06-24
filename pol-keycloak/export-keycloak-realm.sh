#!/bin/bash
# ==============================================================================
# POLARI SUITE — KEYCLOAK REALM EXPORT
# ==============================================================================
#
# Snapshots a live Keycloak realm out of a running container and writes the
# JSON to a realm-imports/ directory so the next fresh deploy boots with the
# realm's current state (clients, groups, role-mappings, adminPermissions,
# and the auto-generated `admin-permissions` client carrying fine-grained
# admin authz rules).
#
# Lives in the suite-level pol-keycloak/ directory because both deployments
# need it: the suite (pol-keycloak container + Polari / Political-Scorecard
# realms) and the standalone PRF (prf-keycloak container + Polari realm).
# Defaults target the suite; pass args or set env vars for PRF.
#
# Usage:
#   ./export-keycloak-realm.sh
#       Exports the Polari realm from pol-keycloak → pol-keycloak/realm-imports/polari-realm.json
#
#   ./export-keycloak-realm.sh Political-Scorecard
#       Exports a specific realm. Output path auto-derived from realm name.
#
#   ./export-keycloak-realm.sh Polari /path/to/output.json
#       Explicit output path.
#
#   PRF_MODE=true ./export-keycloak-realm.sh
#       Switches defaults to the PRF deployment:
#         container       = prf-keycloak
#         output base dir = ../polari-rf-node/prf-keycloak/realm-imports/
#
# Full env overrides (take precedence over PRF_MODE):
#   KC_CONTAINER         keycloak container name (default: pol-keycloak)
#   KC_INTERNAL_URL      KC URL inside the container (default: http://localhost:8080)
#   KC_ADMIN_USER        master-realm admin (falls back to $KEYCLOAK_ADMIN, then 'admin')
#   KC_ADMIN_PASS        master-realm admin password (falls back to $KEYCLOAK_ADMIN_PASSWORD, then 'admin')
#   KC_OUTPUT_DIR        where to write <realm>.json (default: sibling realm-imports/)
#
# Caveat: the load_realms.sh startup hook only imports a realm when it
# doesn't already exist. To apply an exported snapshot to a running
# deployment, wipe the DB volume:
#   $DOCKER compose -f <compose-file> down --volumes
#   $DOCKER compose -f <compose-file> up -d --build
#
# Users + credentials are intentionally NOT included by KC's partial-export.
# Add `&exportUsers=true` below if you need them — be careful what you
# commit to source control.
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use sudo only when we actually need it. If the user is in the `docker`
# group, plain `docker ps` works; if not, fall back to `sudo docker`.
# This stops the Linux-user sudo prompt from showing up when it's
# unnecessary (and stops it from being mistaken for the Keycloak admin
# password prompt — they're unrelated).
if docker ps > /dev/null 2>&1; then
    DOCKER="docker"
else
    DOCKER="sudo docker"
fi

# --- defaults -----------------------------------------------------------------
if [ "${PRF_MODE:-false}" = "true" ]; then
    DEFAULT_CONTAINER="prf-keycloak"
    DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/../polari-rf-node/prf-keycloak/realm-imports"
else
    DEFAULT_CONTAINER="pol-keycloak"
    DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/realm-imports"
fi

KC_CONTAINER="${KC_CONTAINER:-$DEFAULT_CONTAINER}"
KC_URL="${KC_INTERNAL_URL:-http://localhost:8080}"
KC_USER="${KC_ADMIN_USER:-${KEYCLOAK_ADMIN:-admin}}"
KC_PASS="${KC_ADMIN_PASS:-${KEYCLOAK_ADMIN_PASSWORD:-admin}}"
OUT_DIR="${KC_OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}"

# --- positional args ----------------------------------------------------------
KC_REALM="${1:-Polari}"
OUT_FILE="${2:-$OUT_DIR/$(echo "$KC_REALM" | tr '[:upper:]' '[:lower:]')-realm.json}"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Keycloak Realm Export${NC}"
echo -e "${BLUE}============================================${NC}"
echo "Container : $KC_CONTAINER"
echo "Realm     : $KC_REALM"
echo "Output    : $OUT_FILE"
echo ""

# --- preflight ----------------------------------------------------------------
if ! $DOCKER ps --format '{{.Names}}' | grep -q "^${KC_CONTAINER}$"; then
    echo -e "${RED}ERROR: container '$KC_CONTAINER' is not running.${NC}"
    echo "Hint: start the stack, or set KC_CONTAINER / PRF_MODE=true if you"
    echo "      meant a different deployment."
    exit 1
fi

# --- 1. admin token from inside the container ---------------------------------
echo -e "${YELLOW}[1/3] Obtaining admin token...${NC}"
TOKEN_RESPONSE=$($DOCKER exec "$KC_CONTAINER" curl -sf \
    -X POST "$KC_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$KC_USER" \
    -d "password=$KC_PASS" \
    -d "grant_type=password" \
    -d "client_id=admin-cli") || {
    echo -e "${RED}ERROR: token request failed. Check KEYCLOAK_ADMIN / KEYCLOAK_ADMIN_PASSWORD.${NC}"
    exit 1
}

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | $DOCKER exec -i "$KC_CONTAINER" jq -r '.access_token')
if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo -e "${RED}ERROR: token response missing access_token.${NC}"
    echo "Response: $TOKEN_RESPONSE"
    exit 1
fi
echo -e "  ${GREEN}ok${NC}"

# --- 2. partial export --------------------------------------------------------
# exportClients=true       — polari-frontend, polari-backend, AND the
#                            auto-generated admin-permissions client (where
#                            fine-grained admin authz resources live).
# exportGroupsAndRoles=true — group → realm-role mappings.
echo -e "${YELLOW}[2/3] Requesting partial-export...${NC}"
EXPORT=$($DOCKER exec "$KC_CONTAINER" curl -sf \
    -X POST "$KC_URL/admin/realms/$KC_REALM/partial-export?exportClients=true&exportGroupsAndRoles=true" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json") || {
    echo -e "${RED}ERROR: partial-export failed. Does realm '$KC_REALM' exist?${NC}"
    exit 1
}

if ! echo "$EXPORT" | $DOCKER exec -i "$KC_CONTAINER" jq -e '.realm' > /dev/null 2>&1; then
    echo -e "${RED}ERROR: export response is not a valid realm JSON.${NC}"
    echo "$EXPORT" | head -c 500
    exit 1
fi
echo -e "  ${GREEN}ok${NC}"

# --- 3. pretty-print + write --------------------------------------------------
echo -e "${YELLOW}[3/3] Writing $OUT_FILE...${NC}"
mkdir -p "$(dirname "$OUT_FILE")"
echo "$EXPORT" | $DOCKER exec -i "$KC_CONTAINER" jq '.' > "$OUT_FILE"

if [ ! -s "$OUT_FILE" ]; then
    echo -e "${RED}ERROR: output file is empty.${NC}"
    exit 1
fi

REALM_NAME=$(jq -r '.realm' "$OUT_FILE" 2>/dev/null || echo '?')
CLIENT_COUNT=$(jq '.clients | length' "$OUT_FILE" 2>/dev/null || echo '?')
ROLE_COUNT=$(jq '.roles.realm | length' "$OUT_FILE" 2>/dev/null || echo '?')
GROUP_COUNT=$(jq '.groups | length' "$OUT_FILE" 2>/dev/null || echo '?')
ADMIN_PERMS=$(jq '.adminPermissionsEnabled // false' "$OUT_FILE" 2>/dev/null || echo '?')

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Export complete${NC}"
echo -e "${GREEN}============================================${NC}"
echo "  realm                   : $REALM_NAME"
echo "  clients                 : $CLIENT_COUNT"
echo "  realm roles             : $ROLE_COUNT"
echo "  groups                  : $GROUP_COUNT"
echo "  adminPermissionsEnabled : $ADMIN_PERMS"
echo ""
echo -e "${YELLOW}NOTE:${NC} load_realms.sh only imports a realm when it doesn't"
echo "      already exist. To replay this snapshot on a running deployment,"
echo "      wipe the DB volume:"
echo ""
echo -e "      ${BLUE}$DOCKER compose -f <compose-file> down --volumes${NC}"
echo -e "      ${BLUE}$DOCKER compose -f <compose-file> up -d --build${NC}"
echo ""

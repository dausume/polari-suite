#!/bin/bash

# ==============================================================================
# KEYCLOAK CLIENT CONFIGURATION SCRIPT
# ==============================================================================
# This script updates Keycloak client redirect URIs based on the deployment mode.
# It runs after realms are loaded to add environment-specific redirect URIs.
#
# Environment Variables (optional):
#   KEYCLOAK_MODE - "suite", "standalone", "staging", or "production" (default: auto)
#   KC_HOSTNAME  - Keycloak hostname (e.g. auth.10.0.0.102.nip.io or auth.example.com)
#                  Used by staging/production modes to derive subdomain redirect URIs
#   PSC_REDIRECT_URIS - Comma-separated list of additional redirect URIs for PSC frontend
#
# Usage:
#   ./configure_clients.sh [--suite | --standalone]
# ==============================================================================

KEYCLOAK_URL="http://localhost:8080"

# Determine mode from argument or environment
MODE="${KEYCLOAK_MODE:-auto}"
if [ "$1" = "--suite" ]; then
    MODE="suite"
elif [ "$1" = "--standalone" ]; then
    MODE="standalone"
fi

echo "=============================================="
echo "Keycloak Client Configuration"
echo "Mode: $MODE"
echo "=============================================="

# Define redirect URIs for each mode
# Suite mode: accessed via proxy (ports 2053, 2083, etc.)
SUITE_REDIRECT_URIS=(
    "https://localhost:2053/*"
    "https://localhost:2053"
)

# Standalone mode: direct access (ports 4200, 8580, etc.)
STANDALONE_REDIRECT_URIS=(
    "http://localhost:4200/*"
    "http://localhost:4200"
    "https://localhost:4200/*"
    "https://localhost:4200"
)

# Both modes should have these (base URIs from realm import)
BASE_REDIRECT_URIS=(
    "http://localhost:4200/*"
    "http://localhost:4200"
)

# Subdomain redirect URIs derived from KC_HOSTNAME
# KC_HOSTNAME is set by staging-setup.sh or prod-setup.sh (e.g. auth.10.0.0.102.nip.io or auth.example.com)
SUBDOMAIN_REDIRECT_URIS=()
PRF_SUBDOMAIN_REDIRECT_URIS=()
if [ -n "$KC_HOSTNAME" ]; then
    # Strip "auth." prefix to get the base domain (e.g. 10.0.0.102.nip.io or example.com)
    BASE_DOMAIN="${KC_HOSTNAME#auth.}"
    echo "Deriving redirect URIs from KC_HOSTNAME=$KC_HOSTNAME (base domain: $BASE_DOMAIN)"
    # PSC frontend subdomain URIs
    SUBDOMAIN_REDIRECT_URIS=(
        "https://psc.${BASE_DOMAIN}/*"
        "https://psc.${BASE_DOMAIN}"
    )
    # PRF (Polari) frontend subdomain URIs — used by the Polari realm's
    # `polari-frontend` client. Both `prf.` (matches the proxy convention
    # for the PRF Angular app) and `app.prf.` (in case a sub-app sub-
    # domain is later split out).
    PRF_SUBDOMAIN_REDIRECT_URIS=(
        "https://prf.${BASE_DOMAIN}/*"
        "https://prf.${BASE_DOMAIN}"
        "https://app.prf.${BASE_DOMAIN}/*"
        "https://app.prf.${BASE_DOMAIN}"
    )
elif [ "$MODE" = "staging" ] || [ "$MODE" = "production" ]; then
    echo "WARNING: MODE=$MODE but KC_HOSTNAME is not set. Cannot derive subdomain redirect URIs."
fi

# Build combined redirect URIs based on mode
if [ "$MODE" = "suite" ]; then
    REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${SUITE_REDIRECT_URIS[@]}")
elif [ "$MODE" = "standalone" ]; then
    REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${STANDALONE_REDIRECT_URIS[@]}")
elif [ "$MODE" = "staging" ] || [ "$MODE" = "production" ]; then
    REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${SUBDOMAIN_REDIRECT_URIS[@]}")
else
    # Auto mode: include all URIs for maximum compatibility
    # Also includes subdomain URIs if KC_HOSTNAME is set
    REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${SUITE_REDIRECT_URIS[@]}" "${STANDALONE_REDIRECT_URIS[@]}" "${SUBDOMAIN_REDIRECT_URIS[@]}")
fi

# Add any custom URIs from environment variable
if [ -n "$PSC_REDIRECT_URIS" ]; then
    IFS=',' read -ra CUSTOM_URIS <<< "$PSC_REDIRECT_URIS"
    REDIRECT_URIS+=("${CUSTOM_URIS[@]}")
fi

# Remove duplicates
REDIRECT_URIS=($(printf '%s\n' "${REDIRECT_URIS[@]}" | sort -u))

echo "Redirect URIs to configure:"
printf '  - %s\n' "${REDIRECT_URIS[@]}"

# Wait for Keycloak to be ready (reuse pattern from load_realms.sh)
MAX_RETRIES=30
RETRY_INTERVAL=5
KEYCLOAK_READY=false

echo ""
echo "Waiting for Keycloak to be ready..."

for ((i=1; i<=MAX_RETRIES; i++)); do
    if curl -s "$KEYCLOAK_URL/health/ready" > /dev/null 2>&1; then
        echo "Keycloak is ready."
        KEYCLOAK_READY=true
        break
    else
        echo "Waiting for Keycloak... (Attempt: $i/$MAX_RETRIES)"
        sleep $RETRY_INTERVAL
    fi
done

if [ "$KEYCLOAK_READY" = false ]; then
    echo "ERROR: Keycloak is not reachable after $MAX_RETRIES attempts. Exiting."
    exit 1
fi

# Get admin access token
MASTER_REALM="master"
MASTER_USERNAME="${KEYCLOAK_ADMIN:-admin}"
MASTER_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin}"
MASTER_CLIENT="admin-cli"

echo ""
echo "Obtaining admin access token..."

TOKEN_RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/$MASTER_REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$MASTER_USERNAME" \
    -d "password=$MASTER_PASSWORD" \
    -d "grant_type=password" \
    -d "client_id=$MASTER_CLIENT")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "ERROR: Failed to obtain access token. Response: $TOKEN_RESPONSE"
    exit 1
fi

echo "Access token obtained successfully."

# Configuration for clients to update
REALM="Political-Scorecard"
CLIENT_ID="political-scorecard-frontend"

echo ""
echo "Looking up client '$CLIENT_ID' in realm '$REALM'..."

# Get client by clientId to find its UUID
CLIENT_RESPONSE=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=$CLIENT_ID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json")

CLIENT_UUID=$(echo "$CLIENT_RESPONSE" | jq -r '.[0].id')

if [ "$CLIENT_UUID" = "null" ] || [ -z "$CLIENT_UUID" ]; then
    echo "ERROR: Client '$CLIENT_ID' not found in realm '$REALM'. Response: $CLIENT_RESPONSE"
    exit 1
fi

echo "Found client UUID: $CLIENT_UUID"

# Get current client configuration
CURRENT_CLIENT=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients/$CLIENT_UUID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json")

echo ""
echo "Current redirect URIs:"
echo "$CURRENT_CLIENT" | jq -r '.redirectUris[]' 2>/dev/null || echo "  (none)"

# Build JSON array of redirect URIs
REDIRECT_URIS_JSON=$(printf '%s\n' "${REDIRECT_URIS[@]}" | jq -R . | jq -s .)

# Build the update payload - only update redirectUris and webOrigins
UPDATE_PAYLOAD=$(echo "$CURRENT_CLIENT" | jq --argjson uris "$REDIRECT_URIS_JSON" '
    .redirectUris = $uris |
    .webOrigins = ["*"]
')

echo ""
echo "Updating client redirect URIs..."

UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$KEYCLOAK_URL/admin/realms/$REALM/clients/$CLIENT_UUID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$UPDATE_PAYLOAD")

HTTP_CODE=$(echo "$UPDATE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "SUCCESS: Client redirect URIs updated successfully."
else
    echo "ERROR: Failed to update client. HTTP $HTTP_CODE"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

# Verify the update
echo ""
echo "Verifying updated configuration..."

UPDATED_CLIENT=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients/$CLIENT_UUID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json")

echo "Updated redirect URIs:"
echo "$UPDATED_CLIENT" | jq -r '.redirectUris[]'

# ==============================================================================
# CONFIGURE SERVICE ACCOUNT ROLES FOR admin-permissions CLIENT
# ==============================================================================
# The admin-permissions client needs realm-management roles so the backend
# can manage user group memberships and role assignments via the Admin API.
# ==============================================================================

ADMIN_CLIENT_ID="admin-permissions"

echo ""
echo "=============================================="
echo "Configuring service account roles for '$ADMIN_CLIENT_ID'"
echo "=============================================="

# 1. Look up the admin-permissions client UUID
ADMIN_CLIENT_RESPONSE=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=$ADMIN_CLIENT_ID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json")

ADMIN_CLIENT_UUID=$(echo "$ADMIN_CLIENT_RESPONSE" | jq -r '.[0].id')

if [ "$ADMIN_CLIENT_UUID" = "null" ] || [ -z "$ADMIN_CLIENT_UUID" ]; then
    echo "ERROR: Client '$ADMIN_CLIENT_ID' not found in realm '$REALM'. Skipping service account config."
else
    echo "Found admin-permissions client UUID: $ADMIN_CLIENT_UUID"

    # 1b. Set the client secret from environment (generated by setup-polari-security.sh)
    if [ -n "$KEYCLOAK_ADMIN_CLIENT_SECRET" ]; then
        echo "Setting client secret for '$ADMIN_CLIENT_ID' from environment..."

        # Get the full current client config
        ADMIN_CLIENT_DETAIL=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients/$ADMIN_CLIENT_UUID" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json")

        # Update the secret in the client config
        UPDATED_CLIENT=$(echo "$ADMIN_CLIENT_DETAIL" | jq --arg secret "$KEYCLOAK_ADMIN_CLIENT_SECRET" '.secret = $secret')

        SECRET_UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
            "$KEYCLOAK_URL/admin/realms/$REALM/clients/$ADMIN_CLIENT_UUID" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$UPDATED_CLIENT")

        SECRET_HTTP_CODE=$(echo "$SECRET_UPDATE_RESPONSE" | tail -n1)
        if [ "$SECRET_HTTP_CODE" = "204" ] || [ "$SECRET_HTTP_CODE" = "200" ]; then
            echo "SUCCESS: Client secret set for '$ADMIN_CLIENT_ID'."
        else
            SECRET_BODY=$(echo "$SECRET_UPDATE_RESPONSE" | sed '$d')
            echo "WARNING: Failed to set client secret. HTTP $SECRET_HTTP_CODE. Response: $SECRET_BODY"
        fi
    else
        echo "WARNING: KEYCLOAK_ADMIN_CLIENT_SECRET not set in environment. Skipping secret configuration."
        echo "         Run setup-polari-security.sh to generate it."
    fi

    # 2. Get the service account user for admin-permissions
    SA_USER_RESPONSE=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients/$ADMIN_CLIENT_UUID/service-account-user" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json")

    SA_USER_ID=$(echo "$SA_USER_RESPONSE" | jq -r '.id')

    if [ "$SA_USER_ID" = "null" ] || [ -z "$SA_USER_ID" ]; then
        echo "ERROR: Service account user not found for '$ADMIN_CLIENT_ID'. Skipping."
    else
        echo "Found service account user ID: $SA_USER_ID"

        # 3. Get the realm-management client UUID
        RM_CLIENT_RESPONSE=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=realm-management" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json")

        RM_CLIENT_UUID=$(echo "$RM_CLIENT_RESPONSE" | jq -r '.[0].id')

        if [ "$RM_CLIENT_UUID" = "null" ] || [ -z "$RM_CLIENT_UUID" ]; then
            echo "ERROR: realm-management client not found. Skipping."
        else
            echo "Found realm-management client UUID: $RM_CLIENT_UUID"

            # 4. Get role representations for view-users, manage-users, view-realm
            ROLES_TO_ASSIGN=("view-users" "manage-users" "view-realm")
            ROLE_JSON_ARRAY="["

            for i in "${!ROLES_TO_ASSIGN[@]}"; do
                ROLE_NAME="${ROLES_TO_ASSIGN[$i]}"
                ROLE_RESPONSE=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients/$RM_CLIENT_UUID/roles/$ROLE_NAME" \
                    -H "Authorization: Bearer $ACCESS_TOKEN" \
                    -H "Content-Type: application/json")

                ROLE_ID=$(echo "$ROLE_RESPONSE" | jq -r '.id')
                if [ "$ROLE_ID" = "null" ] || [ -z "$ROLE_ID" ]; then
                    echo "WARNING: Role '$ROLE_NAME' not found in realm-management client. Skipping this role."
                    continue
                fi

                echo "  Found role '$ROLE_NAME' (id: $ROLE_ID)"

                if [ "$ROLE_JSON_ARRAY" != "[" ]; then
                    ROLE_JSON_ARRAY="$ROLE_JSON_ARRAY,"
                fi
                ROLE_JSON_ARRAY="$ROLE_JSON_ARRAY$(echo "$ROLE_RESPONSE" | jq -c '{id: .id, name: .name}')"
            done

            ROLE_JSON_ARRAY="$ROLE_JSON_ARRAY]"

            if [ "$ROLE_JSON_ARRAY" = "[]" ]; then
                echo "WARNING: No roles found to assign. Skipping."
            else
                # 5. Assign roles to the service account user
                echo "Assigning roles to service account user..."
                ASSIGN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
                    "$KEYCLOAK_URL/admin/realms/$REALM/users/$SA_USER_ID/role-mappings/clients/$RM_CLIENT_UUID" \
                    -H "Authorization: Bearer $ACCESS_TOKEN" \
                    -H "Content-Type: application/json" \
                    -d "$ROLE_JSON_ARRAY")

                ASSIGN_HTTP_CODE=$(echo "$ASSIGN_RESPONSE" | tail -n1)
                ASSIGN_BODY=$(echo "$ASSIGN_RESPONSE" | sed '$d')

                if [ "$ASSIGN_HTTP_CODE" = "204" ] || [ "$ASSIGN_HTTP_CODE" = "200" ]; then
                    echo "SUCCESS: Service account roles assigned successfully."
                else
                    echo "ERROR: Failed to assign roles. HTTP $ASSIGN_HTTP_CODE"
                    echo "Response: $ASSIGN_BODY"
                fi
            fi
        fi
    fi
fi

# ==============================================================================
# CONFIGURE POLARI REALM CLIENTS
# ==============================================================================
# Mirrors the PSC config pass above, applied to the `Polari` realm:
#   - polari-frontend → patch redirect URIs from KC_HOSTNAME (prf.${BASE_DOMAIN})
#   - polari-backend  → patch client secret from KEYCLOAK_POLARI_BACKEND_CLIENT_SECRET
# Skips gracefully if the realm or clients don't exist (e.g. if polari-realm.json
# wasn't imported), so this script remains safe for PSC-only deployments.
# ==============================================================================

POLARI_REALM="Polari"
POLARI_FE_CLIENT_ID="polari-frontend"
POLARI_BE_CLIENT_ID="polari-backend"

echo ""
echo "=============================================="
echo "Configuring Polari realm clients"
echo "=============================================="

# Build the Polari frontend's redirect URI list using the same base/mode
# logic as PSC, swapping in PRF-specific subdomains.
if [ "$MODE" = "suite" ]; then
    POLARI_REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${SUITE_REDIRECT_URIS[@]}")
elif [ "$MODE" = "standalone" ]; then
    POLARI_REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${STANDALONE_REDIRECT_URIS[@]}")
elif [ "$MODE" = "staging" ] || [ "$MODE" = "production" ]; then
    POLARI_REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${PRF_SUBDOMAIN_REDIRECT_URIS[@]}")
else
    POLARI_REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${SUITE_REDIRECT_URIS[@]}" "${STANDALONE_REDIRECT_URIS[@]}" "${PRF_SUBDOMAIN_REDIRECT_URIS[@]}")
fi

# Allow operator override.
if [ -n "$PRF_REDIRECT_URIS" ]; then
    IFS=',' read -ra PRF_CUSTOM_URIS <<< "$PRF_REDIRECT_URIS"
    POLARI_REDIRECT_URIS+=("${PRF_CUSTOM_URIS[@]}")
fi
POLARI_REDIRECT_URIS=($(printf '%s\n' "${POLARI_REDIRECT_URIS[@]}" | sort -u))

echo "Polari frontend redirect URIs to configure:"
printf '  - %s\n' "${POLARI_REDIRECT_URIS[@]}"

# --- 1. Locate the Polari realm ----------------------------------------------
POLARI_REALM_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "$KEYCLOAK_URL/admin/realms/$POLARI_REALM" \
    -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$POLARI_REALM_CHECK" != "200" ]; then
    echo "INFO: Polari realm not present (HTTP $POLARI_REALM_CHECK). Skipping Polari client configuration."
else
    echo "Found Polari realm — configuring clients."

    # --- 2. Configure polari-frontend redirect URIs --------------------------
    PFE_RESPONSE=$(curl -s -X GET \
        "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients?clientId=$POLARI_FE_CLIENT_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json")
    PFE_UUID=$(echo "$PFE_RESPONSE" | jq -r '.[0].id')

    if [ "$PFE_UUID" = "null" ] || [ -z "$PFE_UUID" ]; then
        echo "WARNING: Client '$POLARI_FE_CLIENT_ID' not found in '$POLARI_REALM'. Skipping."
    else
        echo "Found $POLARI_FE_CLIENT_ID UUID: $PFE_UUID"

        PFE_CURRENT=$(curl -s -X GET \
            "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients/$PFE_UUID" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json")

        PFE_URIS_JSON=$(printf '%s\n' "${POLARI_REDIRECT_URIS[@]}" | jq -R . | jq -s .)
        PFE_PAYLOAD=$(echo "$PFE_CURRENT" | jq --argjson uris "$PFE_URIS_JSON" '
            .redirectUris = $uris |
            .webOrigins = ["*"]
        ')

        PFE_UPDATE=$(curl -s -w "\n%{http_code}" -X PUT \
            "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients/$PFE_UUID" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$PFE_PAYLOAD")
        PFE_HTTP=$(echo "$PFE_UPDATE" | tail -n1)

        if [ "$PFE_HTTP" = "204" ] || [ "$PFE_HTTP" = "200" ]; then
            echo "SUCCESS: $POLARI_FE_CLIENT_ID redirect URIs updated."
        else
            echo "ERROR: Failed to update $POLARI_FE_CLIENT_ID. HTTP $PFE_HTTP"
            echo "$PFE_UPDATE" | sed '$d'
        fi
    fi

    # --- 2b. polari-shell: re-assert the fixed shell redirect URIs -----------
    # Host-INDEPENDENT URIs (custom scheme + one fixed loopback port —
    # Keycloak has no port wildcards), so no KC_HOSTNAME derivation.
    POLARI_SHELL_CLIENT_ID="polari-shell"
    PSH_RESPONSE=$(curl -s -X GET \
        "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients?clientId=$POLARI_SHELL_CLIENT_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json")
    PSH_UUID=$(echo "$PSH_RESPONSE" | jq -r '.[0].id')

    if [ "$PSH_UUID" = "null" ] || [ -z "$PSH_UUID" ]; then
        echo "WARNING: Client '$POLARI_SHELL_CLIENT_ID' not found in '$POLARI_REALM'. Skipping (re-import the realm to create it)."
    else
        PSH_CURRENT=$(curl -s -X GET \
            "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients/$PSH_UUID" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json")
        PSH_PAYLOAD=$(echo "$PSH_CURRENT" | jq '
            .redirectUris = ["polari://oauth/callback", "http://127.0.0.1:41300/callback"] |
            .webOrigins = ["+"] |
            .publicClient = true |
            .directAccessGrantsEnabled = false |
            .attributes["pkce.code.challenge.method"] = "S256"
        ')
        PSH_UPDATE=$(curl -s -w "\n%{http_code}" -X PUT \
            "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients/$PSH_UUID" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$PSH_PAYLOAD")
        PSH_HTTP=$(echo "$PSH_UPDATE" | tail -n1)
        if [ "$PSH_HTTP" = "204" ] || [ "$PSH_HTTP" = "200" ]; then
            echo "SUCCESS: $POLARI_SHELL_CLIENT_ID redirect URIs asserted."
        else
            echo "ERROR: Failed to update $POLARI_SHELL_CLIENT_ID. HTTP $PSH_HTTP"
            echo "$PSH_UPDATE" | sed '$d'
        fi
    fi

    # --- 3. Configure polari-backend client secret + service-account roles ----
    PBE_RESPONSE=$(curl -s -X GET \
        "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients?clientId=$POLARI_BE_CLIENT_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json")
    PBE_UUID=$(echo "$PBE_RESPONSE" | jq -r '.[0].id')

    if [ "$PBE_UUID" = "null" ] || [ -z "$PBE_UUID" ]; then
        echo "WARNING: Client '$POLARI_BE_CLIENT_ID' not found in '$POLARI_REALM'. Skipping."
    else
        echo "Found $POLARI_BE_CLIENT_ID UUID: $PBE_UUID"

        # 3a. Set the client secret from env (parallel to PSC's admin-permissions
        # secret pattern). Preferred env var name is
        # KEYCLOAK_POLARI_BACKEND_CLIENT_SECRET; falls back to the existing
        # KEYCLOAK_ADMIN_CLIENT_SECRET so a single setup-polari-security.sh run
        # can populate both realms without proliferating env vars.
        POLARI_BE_SECRET="${KEYCLOAK_POLARI_BACKEND_CLIENT_SECRET:-$KEYCLOAK_ADMIN_CLIENT_SECRET}"
        if [ -n "$POLARI_BE_SECRET" ]; then
            echo "Setting client secret for '$POLARI_BE_CLIENT_ID'..."
            PBE_DETAIL=$(curl -s -X GET \
                "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients/$PBE_UUID" \
                -H "Authorization: Bearer $ACCESS_TOKEN" \
                -H "Content-Type: application/json")
            PBE_PATCHED=$(echo "$PBE_DETAIL" | jq --arg secret "$POLARI_BE_SECRET" '.secret = $secret')

            PBE_SECRET_UPDATE=$(curl -s -w "\n%{http_code}" -X PUT \
                "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients/$PBE_UUID" \
                -H "Authorization: Bearer $ACCESS_TOKEN" \
                -H "Content-Type: application/json" \
                -d "$PBE_PATCHED")
            PBE_SECRET_HTTP=$(echo "$PBE_SECRET_UPDATE" | tail -n1)

            if [ "$PBE_SECRET_HTTP" = "204" ] || [ "$PBE_SECRET_HTTP" = "200" ]; then
                echo "SUCCESS: Client secret set for '$POLARI_BE_CLIENT_ID'."
            else
                echo "WARNING: Failed to set secret. HTTP $PBE_SECRET_HTTP"
                echo "$PBE_SECRET_UPDATE" | sed '$d'
            fi
        else
            echo "WARNING: No secret env var set for '$POLARI_BE_CLIENT_ID'."
            echo "         Set KEYCLOAK_POLARI_BACKEND_CLIENT_SECRET in keycloak-admin.env."
        fi

        # 3b. Grant the backend's service account the realm-management roles
        # needed for user/group management calls (mirrors PSC's admin-permissions
        # pattern: view-users, manage-users, view-realm).
        PBE_SA_RESPONSE=$(curl -s -X GET \
            "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients/$PBE_UUID/service-account-user" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json")
        PBE_SA_UUID=$(echo "$PBE_SA_RESPONSE" | jq -r '.id')

        if [ "$PBE_SA_UUID" = "null" ] || [ -z "$PBE_SA_UUID" ]; then
            echo "INFO: service-account-user not available for '$POLARI_BE_CLIENT_ID' (serviceAccountsEnabled may be off). Skipping role grant."
        else
            P_RM_RESPONSE=$(curl -s -X GET \
                "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients?clientId=realm-management" \
                -H "Authorization: Bearer $ACCESS_TOKEN" \
                -H "Content-Type: application/json")
            P_RM_UUID=$(echo "$P_RM_RESPONSE" | jq -r '.[0].id')

            if [ "$P_RM_UUID" = "null" ] || [ -z "$P_RM_UUID" ]; then
                echo "WARNING: realm-management client not found in '$POLARI_REALM'. Skipping."
            else
                P_ROLES=("view-users" "manage-users" "view-realm")
                P_ROLE_JSON="["
                for rn in "${P_ROLES[@]}"; do
                    RR=$(curl -s -X GET \
                        "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/clients/$P_RM_UUID/roles/$rn" \
                        -H "Authorization: Bearer $ACCESS_TOKEN" \
                        -H "Content-Type: application/json")
                    RID=$(echo "$RR" | jq -r '.id')
                    if [ "$RID" = "null" ] || [ -z "$RID" ]; then
                        echo "  WARN: role '$rn' missing in Polari realm-management. Skipping."
                        continue
                    fi
                    if [ "$P_ROLE_JSON" != "[" ]; then P_ROLE_JSON="$P_ROLE_JSON,"; fi
                    P_ROLE_JSON="$P_ROLE_JSON$(echo "$RR" | jq -c '{id: .id, name: .name}')"
                done
                P_ROLE_JSON="$P_ROLE_JSON]"

                if [ "$P_ROLE_JSON" != "[]" ]; then
                    P_ASSIGN=$(curl -s -w "\n%{http_code}" -X POST \
                        "$KEYCLOAK_URL/admin/realms/$POLARI_REALM/users/$PBE_SA_UUID/role-mappings/clients/$P_RM_UUID" \
                        -H "Authorization: Bearer $ACCESS_TOKEN" \
                        -H "Content-Type: application/json" \
                        -d "$P_ROLE_JSON")
                    P_HTTP=$(echo "$P_ASSIGN" | tail -n1)
                    if [ "$P_HTTP" = "204" ] || [ "$P_HTTP" = "200" ]; then
                        echo "SUCCESS: $POLARI_BE_CLIENT_ID service-account roles assigned."
                    else
                        echo "WARNING: Polari service-account role grant failed. HTTP $P_HTTP"
                        echo "$P_ASSIGN" | sed '$d'
                    fi
                fi
            fi
        fi
    fi
fi

echo ""
echo "=============================================="
echo "Client configuration completed successfully!"
echo "=============================================="

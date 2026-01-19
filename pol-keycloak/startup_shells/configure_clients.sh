#!/bin/bash

# ==============================================================================
# KEYCLOAK CLIENT CONFIGURATION SCRIPT
# ==============================================================================
# This script updates Keycloak client redirect URIs based on the deployment mode.
# It runs after realms are loaded to add environment-specific redirect URIs.
#
# Environment Variables (optional):
#   PSC_REDIRECT_URIS - Comma-separated list of additional redirect URIs for PSC frontend
#   KEYCLOAK_MODE - "suite" or "standalone" (default: auto-detect)
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

# Build combined redirect URIs based on mode
if [ "$MODE" = "suite" ]; then
    REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${SUITE_REDIRECT_URIS[@]}")
elif [ "$MODE" = "standalone" ]; then
    REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${STANDALONE_REDIRECT_URIS[@]}")
else
    # Auto mode: include all URIs for maximum compatibility
    REDIRECT_URIS=("${BASE_REDIRECT_URIS[@]}" "${SUITE_REDIRECT_URIS[@]}" "${STANDALONE_REDIRECT_URIS[@]}")
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
MASTER_USERNAME="admin"
MASTER_PASSWORD="admin"  # In production, use secrets management
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

echo ""
echo "=============================================="
echo "Client configuration completed successfully!"
echo "=============================================="

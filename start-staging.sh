#!/bin/bash
# ==============================================================================
# POLARI SUITE - SINGLE-COMMAND STAGING LAUNCHER
# ==============================================================================
#
# Detects whether setup has been done and conditionally runs it before booting
# the docker compose staging stack.
#
# Usage:
#   ./start-staging.sh                        # Detect + setup if needed + launch
#   ./start-staging.sh --force-setup          # Force re-run all setup steps
#   ./start-staging.sh --setup-only           # Run setup but don't start compose
#   ./start-staging.sh --down                 # Stop the staging stack
#   ./start-staging.sh --build prf-backend    # Pass extra args to docker compose
#   OVERRIDE_IP=1.2.3.4 ./start-staging.sh   # Use a specific IP
#
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.staging-nip.yml"
ENV_FILE="$SCRIPT_DIR/.generated/.env.staging"
CA_CERT="$SCRIPT_DIR/pol-proxy/certs/ca/pol-ca.crt"

# Colors for output (matches existing scripts)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================
FORCE_SETUP=false
SETUP_ONLY=false
DOWN=false
COMPOSE_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --force-setup)
            FORCE_SETUP=true
            shift
            ;;
        --setup-only)
            SETUP_ONLY=true
            shift
            ;;
        --down)
            DOWN=true
            shift
            ;;
        *)
            COMPOSE_ARGS+=("$1")
            shift
            ;;
    esac
done

# ==============================================================================
# DOWN MODE
# ==============================================================================
if [[ "$DOWN" == "true" ]]; then
    echo -e "${BLUE}Stopping staging stack...${NC}"
    sudo docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down "${COMPOSE_ARGS[@]}"
    echo -e "${GREEN}Staging stack stopped.${NC}"
    exit 0
fi

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Polari Suite - Staging Launcher${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ==============================================================================
# IP DETECTION (same logic as nip-staging-setup.sh)
# ==============================================================================
detect_ip() {
    local ip=""

    # Method 1: ip route (Linux)
    if command -v ip &> /dev/null; then
        ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[\d.]+' | head -1)
    fi

    # Method 2: hostname -I (Linux fallback)
    if [ -z "$ip" ] && command -v hostname &> /dev/null; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi

    # Method 3: ifconfig (macOS/BSD)
    if [ -z "$ip" ] && command -v ifconfig &> /dev/null; then
        ip=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
    fi

    echo "$ip"
}

LOCAL_IP=$(detect_ip)

if [ -z "$LOCAL_IP" ]; then
    echo -e "${RED}ERROR: Could not detect local IP address${NC}"
    echo "Please set OVERRIDE_IP environment variable:"
    echo "  OVERRIDE_IP=192.168.x.x ./start-staging.sh"
    exit 1
fi

if [ -n "$OVERRIDE_IP" ]; then
    LOCAL_IP="$OVERRIDE_IP"
    echo -e "  Using override IP: ${GREEN}$LOCAL_IP${NC}"
else
    echo -e "  Detected IP: ${GREEN}$LOCAL_IP${NC}"
fi

if ! [[ $LOCAL_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}ERROR: Invalid IP address format: $LOCAL_IP${NC}"
    exit 1
fi

echo ""

# ==============================================================================
# STEP 1: Check if security setup is needed
# ==============================================================================
RAN_SECURITY=false
RAN_STAGING=false

if [[ "$FORCE_SETUP" == "true" ]] || [[ ! -f "$CA_CERT" ]]; then
    if [[ "$FORCE_SETUP" == "true" ]]; then
        echo -e "${YELLOW}[1/3] Running security setup (forced)...${NC}"
    else
        echo -e "${YELLOW}[1/3] CA certificate not found, running security setup...${NC}"
    fi
    "$SCRIPT_DIR/setup-polari-security.sh" dev
    RAN_SECURITY=true
    echo ""
else
    echo -e "${GREEN}[1/3] Security setup: already done${NC} (found $CA_CERT)"
fi

# ==============================================================================
# STEP 2: Check if staging setup is needed
# ==============================================================================
NEED_STAGING=false

if [[ "$FORCE_SETUP" == "true" ]]; then
    NEED_STAGING=true
    echo -e "${YELLOW}[2/3] Running staging setup (forced)...${NC}"
elif [[ ! -f "$ENV_FILE" ]]; then
    NEED_STAGING=true
    echo -e "${YELLOW}[2/3] Staging env not found, running staging setup...${NC}"
else
    # Check if IP has changed
    EXISTING_IP=$(grep '^LOCAL_IP=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2)
    if [[ "$EXISTING_IP" != "$LOCAL_IP" ]]; then
        NEED_STAGING=true
        echo -e "${YELLOW}[2/3] IP changed ($EXISTING_IP -> $LOCAL_IP), running staging setup...${NC}"
    else
        echo -e "${GREEN}[2/3] Staging setup: already done${NC} (IP matches: $LOCAL_IP)"
    fi
fi

if [[ "$NEED_STAGING" == "true" ]]; then
    # Pass OVERRIDE_IP through so nip-staging-setup.sh uses the same IP
    OVERRIDE_IP="$LOCAL_IP" "$SCRIPT_DIR/nip-staging-setup.sh"
    RAN_STAGING=true
    echo ""
fi

# ==============================================================================
# STEP 3: Launch docker compose
# ==============================================================================
if [[ "$SETUP_ONLY" == "true" ]]; then
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Setup complete (--setup-only mode)${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "To start the stack, run:"
    echo -e "  ${YELLOW}./start-staging.sh${NC}"
    exit 0
fi

echo -e "${YELLOW}[3/3] Starting staging stack...${NC}"
echo ""

sudo docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d "${COMPOSE_ARGS[@]}"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Staging stack is running!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Your staging URLs:"
echo -e "  ${BLUE}Landing:${NC}        https://${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}Keycloak:${NC}       https://auth.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}PSC Frontend:${NC}   https://psc.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}PSC API:${NC}        https://api.psc.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}PRF Frontend:${NC}   https://prf.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}PRF API:${NC}        https://api.prf.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}MinIO Console:${NC}  https://files.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}MinIO S3 API:${NC}   https://s3.${LOCAL_IP}.nip.io"
echo ""
echo -e "To stop: ${YELLOW}./start-staging.sh --down${NC}"
echo ""

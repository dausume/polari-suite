#!/bin/bash
# ==============================================================================
# POLARI SUITE - SINGLE-COMMAND PRODUCTION LAUNCHER
# ==============================================================================
#
# Detects whether setup has been done and conditionally runs it before booting
# the docker compose production stack. Collects all credentials once upfront
# to avoid duplicate prompts across setup scripts.
#
# Usage:
#   ./start-prod.sh                        # Detect + setup if needed + launch
#   ./start-prod.sh --force-setup          # Force re-run all setup steps
#   ./start-prod.sh --setup-only           # Run setup but don't start compose
#   ./start-prod.sh --down                 # Stop the production stack
#   ./start-prod.sh --build prf-backend    # Pass extra args to docker compose
#
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.prod.yml"
ENV_FILE="$SCRIPT_DIR/.generated/.env.prod"
CA_CERT="$SCRIPT_DIR/pol-proxy/certs/ca/pol-ca.crt"

# Colors for output (matches existing scripts)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================
generate_password() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24
}

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
    echo -e "${BLUE}Stopping production stack...${NC}"
    if [[ -f "$ENV_FILE" ]]; then
        sudo docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down "${COMPOSE_ARGS[@]}"
    else
        sudo docker compose -f "$COMPOSE_FILE" down "${COMPOSE_ARGS[@]}"
    fi
    echo -e "${GREEN}Production stack stopped.${NC}"
    exit 0
fi

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Polari Suite - Production Launcher${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ==============================================================================
# DETERMINE WHAT SETUP IS NEEDED
# ==============================================================================
NEED_SECURITY=false
NEED_PROD_SETUP=false

if [[ "$FORCE_SETUP" == "true" ]] || [[ ! -f "$CA_CERT" ]]; then
    NEED_SECURITY=true
fi

if [[ "$FORCE_SETUP" == "true" ]] || [[ ! -f "$ENV_FILE" ]]; then
    NEED_PROD_SETUP=true
fi

# ==============================================================================
# FORCE SETUP: Stop stack and reset database volumes
# ==============================================================================
# MariaDB init scripts only run on first start with an empty data directory.
# When --force-setup regenerates credentials, we must also reset the database
# volume so init.sh creates users with the new passwords.
if [[ "$FORCE_SETUP" == "true" ]]; then
    echo -e "${YELLOW}Force setup requested — stopping stack and resetting database volume...${NC}"
    if [[ -f "$ENV_FILE" ]]; then
        sudo docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down 2>/dev/null || true
    else
        sudo docker compose -f "$COMPOSE_FILE" down 2>/dev/null || true
    fi
    # Find and remove the MariaDB volume (name depends on docker compose project name)
    MARIADB_VOL=$(sudo docker volume ls --format '{{.Name}}' | grep 'pol_mariadb_data$' | head -1)
    if [[ -n "$MARIADB_VOL" ]]; then
        echo -e "  Removing MariaDB volume: ${YELLOW}$MARIADB_VOL${NC}"
        sudo docker volume rm "$MARIADB_VOL"
        echo -e "  ${GREEN}Volume removed — init.sh will run fresh on next start${NC}"
    else
        echo -e "  ${GREEN}No existing MariaDB volume found${NC}"
    fi
    echo ""
fi

# ==============================================================================
# COLLECT CREDENTIALS UPFRONT (single prompt session)
# ==============================================================================
if [[ "$NEED_SECURITY" == "true" || "$NEED_PROD_SETUP" == "true" ]]; then
    echo -e "${YELLOW}Collecting configuration...${NC}"
    echo ""
fi

# --- Domain (needed by both security and prod-setup) ---
if [[ "$NEED_SECURITY" == "true" || "$NEED_PROD_SETUP" == "true" ]]; then
    if [[ -z "${POLARI_PROD_DOMAIN:-}" ]]; then
        echo "  Enter your production domain (e.g., example.com):"
        echo "  This will be used for all service URLs (auth, psc, prf, etc.)"
        echo ""
        read -p "  Production domain: " POLARI_PROD_DOMAIN

        if [[ -z "$POLARI_PROD_DOMAIN" ]]; then
            echo -e "${RED}ERROR: Domain is required${NC}"
            exit 1
        fi
    fi
    export POLARI_PROD_DOMAIN
    echo -e "  Domain: ${GREEN}$POLARI_PROD_DOMAIN${NC}"
    echo ""
fi

# --- Security-specific credentials ---
if [[ "$NEED_SECURITY" == "true" ]]; then
    # Server IP
    if [[ -z "${POLARI_SERVER_IP:-}" ]]; then
        read -p "  Server public IPv6 address: " POLARI_SERVER_IP
        if [[ -z "$POLARI_SERVER_IP" ]]; then
            echo -e "${RED}ERROR: IPv6 address is required for production${NC}"
            exit 1
        fi
    fi
    export POLARI_SERVER_IP
    echo -e "  Server IP: ${GREEN}$POLARI_SERVER_IP${NC}"
    echo ""

    # Keycloak admin
    if [[ -z "${POLARI_KC_ADMIN_USER:-}" ]]; then
        read -p "  Keycloak admin username [admin]: " POLARI_KC_ADMIN_USER
        POLARI_KC_ADMIN_USER="${POLARI_KC_ADMIN_USER:-admin}"
    fi
    export POLARI_KC_ADMIN_USER
    echo -e "  Keycloak admin user: ${GREEN}$POLARI_KC_ADMIN_USER${NC}"

    if [[ -z "${POLARI_KC_ADMIN_PASS:-}" ]]; then
        read -sp "  Keycloak admin password (Enter for random): " POLARI_KC_ADMIN_PASS
        echo ""
        if [[ -z "$POLARI_KC_ADMIN_PASS" ]]; then
            POLARI_KC_ADMIN_PASS=$(generate_password)
            echo -e "  Generated Keycloak admin password: ${GREEN}$POLARI_KC_ADMIN_PASS${NC}"
        fi
    fi
    export POLARI_KC_ADMIN_PASS
    echo ""

    # MariaDB root password (shared with prod-setup)
    if [[ -z "${POLARI_MYSQL_ROOT_PASS:-}" ]]; then
        read -sp "  MariaDB root password (Enter for random): " POLARI_MYSQL_ROOT_PASS
        echo ""
        if [[ -z "$POLARI_MYSQL_ROOT_PASS" ]]; then
            POLARI_MYSQL_ROOT_PASS=$(generate_password)
            echo -e "  Generated MariaDB root password: ${GREEN}$POLARI_MYSQL_ROOT_PASS${NC}"
        fi
    fi
    export POLARI_MYSQL_ROOT_PASS

    # Keycloak DB password
    if [[ -z "${POLARI_KC_DB_PASS:-}" ]]; then
        read -sp "  Keycloak DB password (Enter for random): " POLARI_KC_DB_PASS
        echo ""
        if [[ -z "$POLARI_KC_DB_PASS" ]]; then
            POLARI_KC_DB_PASS=$(generate_password)
            echo -e "  Generated Keycloak DB password: ${GREEN}$POLARI_KC_DB_PASS${NC}"
        fi
    fi
    export POLARI_KC_DB_PASS

    # PSC DB password (shared with prod-setup)
    if [[ -z "${POLARI_PSC_DB_PASS:-}" ]]; then
        read -sp "  PSC DB password (Enter for random): " POLARI_PSC_DB_PASS
        echo ""
        if [[ -z "$POLARI_PSC_DB_PASS" ]]; then
            POLARI_PSC_DB_PASS=$(generate_password)
            echo -e "  Generated PSC DB password: ${GREEN}$POLARI_PSC_DB_PASS${NC}"
        fi
    fi
    export POLARI_PSC_DB_PASS
    echo ""

    # Skip the interactive confirmation in setup-polari-security.sh
    export POLARI_CONFIRM_PROD=yes

elif [[ "$NEED_PROD_SETUP" == "true" ]]; then
    # Only prod-setup needed — collect DB passwords if not already set
    if [[ -z "${POLARI_KC_DB_PASS:-}" ]]; then
        read -p "  Keycloak database password [kcpassword]: " POLARI_KC_DB_PASS
        POLARI_KC_DB_PASS="${POLARI_KC_DB_PASS:-kcpassword}"
    fi
    export POLARI_KC_DB_PASS

    if [[ -z "${POLARI_PSC_DB_PASS:-}" ]]; then
        read -p "  PSC database password [pscpassword]: " POLARI_PSC_DB_PASS
        POLARI_PSC_DB_PASS="${POLARI_PSC_DB_PASS:-pscpassword}"
    fi
    export POLARI_PSC_DB_PASS

    if [[ -z "${POLARI_MYSQL_ROOT_PASS:-}" ]]; then
        read -p "  MariaDB root password [rootpassword]: " POLARI_MYSQL_ROOT_PASS
        POLARI_MYSQL_ROOT_PASS="${POLARI_MYSQL_ROOT_PASS:-rootpassword}"
    fi
    export POLARI_MYSQL_ROOT_PASS
    echo ""
fi

# ==============================================================================
# STEP 1: Security setup
# ==============================================================================
if [[ "$NEED_SECURITY" == "true" ]]; then
    if [[ "$FORCE_SETUP" == "true" ]]; then
        echo -e "${YELLOW}[1/3] Running security setup (forced)...${NC}"
    else
        echo -e "${YELLOW}[1/3] CA certificate not found, running security setup...${NC}"
    fi
    "$SCRIPT_DIR/setup-polari-security.sh" prod
    echo ""
else
    echo -e "${GREEN}[1/3] Security setup: already done${NC} (found $CA_CERT)"
fi

# ==============================================================================
# STEP 2: Production config setup
# ==============================================================================
if [[ "$NEED_PROD_SETUP" == "true" ]]; then
    if [[ "$FORCE_SETUP" == "true" ]]; then
        echo -e "${YELLOW}[2/3] Running production setup (forced)...${NC}"
    else
        echo -e "${YELLOW}[2/3] Production env not found, running production setup...${NC}"
    fi
    "$SCRIPT_DIR/prod-setup.sh"
    echo ""
else
    echo -e "${GREEN}[2/3] Production setup: already done${NC} (found $ENV_FILE)"
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
    echo -e "  ${YELLOW}./start-prod.sh${NC}"
    exit 0
fi

echo -e "${YELLOW}[3/3] Starting production stack...${NC}"
echo ""

sudo docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up --build -d "${COMPOSE_ARGS[@]}"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Production stack is running!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# Read domain from env file for URL display
PROD_DOMAIN="${POLARI_PROD_DOMAIN:-}"
if [[ -z "$PROD_DOMAIN" && -f "$ENV_FILE" ]]; then
    PROD_DOMAIN=$(grep "^PROD_DOMAIN=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2)
fi

if [[ -n "$PROD_DOMAIN" ]]; then
    echo -e "Your production URLs:"
    echo -e "  ${BLUE}Landing:${NC}      https://${PROD_DOMAIN}"
    echo -e "  ${BLUE}Keycloak:${NC}     https://auth.${PROD_DOMAIN}"
    echo -e "  ${BLUE}PSC Frontend:${NC} https://psc.${PROD_DOMAIN}"
    echo -e "  ${BLUE}PSC API:${NC}      https://api.psc.${PROD_DOMAIN}"
    echo -e "  ${BLUE}PRF Frontend:${NC} https://prf.${PROD_DOMAIN}"
    echo -e "  ${BLUE}PRF API:${NC}      https://api.prf.${PROD_DOMAIN}"
    echo ""
fi

echo -e "To stop: ${YELLOW}./start-prod.sh --down${NC}"
echo ""

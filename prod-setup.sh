#!/bin/bash
# ==============================================================================
# POLARI SUITE - PRODUCTION SETUP SCRIPT
# ==============================================================================
#
# This script sets up the production environment by prompting for sensitive
# configuration values and generating the necessary files.
#
# Run this script before deploying to production:
#   ./prod-setup.sh
#
# Then deploy:
#   sudo docker compose -f docker-compose.prod.yml up -d --build
#
# SECURITY NOTE: Generated files contain sensitive configuration and are
# gitignored. Never commit the .generated/ directory contents to version control.
#
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_DIR="$SCRIPT_DIR/pol-proxy"
GENERATED_DIR="$SCRIPT_DIR/.generated"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Polari Suite - Production Setup${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ==============================================================================
# STEP 1: Prompt for Production Domain
# ==============================================================================
echo -e "${YELLOW}[1/5] Production Domain Configuration${NC}"
echo ""

if [[ -n "${POLARI_PROD_DOMAIN:-}" ]]; then
    PROD_DOMAIN="$POLARI_PROD_DOMAIN"
else
    # Check for existing config
    EXISTING_DOMAIN=""
    if [ -f "$GENERATED_DIR/.env.prod" ]; then
        EXISTING_DOMAIN=$(grep "^PROD_DOMAIN=" "$GENERATED_DIR/.env.prod" 2>/dev/null | cut -d'=' -f2)
    fi

    if [ -n "$EXISTING_DOMAIN" ]; then
        echo -e "  Existing domain found: ${GREEN}$EXISTING_DOMAIN${NC}"
        read -p "  Use existing domain? (Y/n): " USE_EXISTING
        if [[ "$USE_EXISTING" =~ ^[Nn] ]]; then
            EXISTING_DOMAIN=""
        fi
    fi

    if [ -z "$EXISTING_DOMAIN" ]; then
        echo "  Enter your production domain (e.g., example.com):"
        echo "  This will be used for:"
        echo "    - Landing page:    https://example.com"
        echo "    - Keycloak:        https://auth.example.com"
        echo "    - PSC Frontend:    https://psc.example.com"
        echo "    - PSC API:         https://api.psc.example.com"
        echo "    - PRF Frontend:    https://prf.example.com"
        echo "    - PRF API:         https://api.prf.example.com"
        echo ""
        read -p "  Production domain: " PROD_DOMAIN

        if [ -z "$PROD_DOMAIN" ]; then
            echo -e "${RED}ERROR: Domain is required${NC}"
            exit 1
        fi
    else
        PROD_DOMAIN="$EXISTING_DOMAIN"
    fi
fi

echo -e "  Using domain: ${GREEN}$PROD_DOMAIN${NC}"

# ==============================================================================
# STEP 2: Prompt for Database Credentials (optional)
# ==============================================================================
echo ""
echo -e "${YELLOW}[2/5] Database Credentials (optional)${NC}"
echo ""
echo "  Press Enter to use defaults, or enter custom values."
echo ""

# PSC Database
if [[ -n "${POLARI_PSC_DB_PASS:-}" ]]; then
    PSC_DB_PASSWORD="$POLARI_PSC_DB_PASS"
    echo -e "  Using provided PSC database password"
else
    read -p "  PSC database password [pscpassword]: " PSC_DB_PASSWORD
    PSC_DB_PASSWORD="${PSC_DB_PASSWORD:-pscpassword}"
fi

# MariaDB root password
if [[ -n "${POLARI_MYSQL_ROOT_PASS:-}" ]]; then
    MARIADB_ROOT_PASSWORD="$POLARI_MYSQL_ROOT_PASS"
    echo -e "  Using provided MariaDB root password"
else
    read -p "  MariaDB root password [rootpassword]: " MARIADB_ROOT_PASSWORD
    MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-rootpassword}"
fi

echo ""

# ==============================================================================
# STEP 3: Generate nginx configuration
# ==============================================================================
echo -e "${YELLOW}[3/5] Generating nginx configuration...${NC}"

mkdir -p "$GENERATED_DIR"

TEMPLATE_FILE="$PROXY_DIR/nginx.prod.conf.template"
OUTPUT_FILE="$GENERATED_DIR/nginx.prod.conf"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}ERROR: Template file not found: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Replace ${PROD_DOMAIN} placeholder with actual domain
sed "s/\${PROD_DOMAIN}/$PROD_DOMAIN/g" "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo -e "  Generated: ${GREEN}$OUTPUT_FILE${NC}"

# ==============================================================================
# STEP 4: Generate environment file
# ==============================================================================
echo ""
echo -e "${YELLOW}[4/5] Generating environment file...${NC}"

ENV_FILE="$GENERATED_DIR/.env.prod"

cat > "$ENV_FILE" << EOF
# ==============================================================================
# POLARI SUITE - PRODUCTION ENVIRONMENT
# ==============================================================================
# Generated by prod-setup.sh on $(date)
# Domain: ${PROD_DOMAIN}
#
# SECURITY: This file contains sensitive configuration.
# DO NOT commit to version control.
# ==============================================================================

PROD_DOMAIN=${PROD_DOMAIN}

# Base domain
BASE_DOMAIN=${PROD_DOMAIN}

# Service URLs
AUTH_URL=https://auth.${PROD_DOMAIN}
PSC_URL=https://psc.${PROD_DOMAIN}
PSC_API_URL=https://api.psc.${PROD_DOMAIN}
PRF_URL=https://prf.${PROD_DOMAIN}
PRF_API_URL=https://api.prf.${PROD_DOMAIN}

# CORS Origins (comma-separated)
CORS_ORIGINS=https://psc.${PROD_DOMAIN},https://prf.${PROD_DOMAIN},https://auth.${PROD_DOMAIN},https://${PROD_DOMAIN},https://www.${PROD_DOMAIN}
# Spring Boot reads this env var for CORS allowed origins
APP_CORS_ALLOWED_ORIGINS=https://psc.${PROD_DOMAIN},https://prf.${PROD_DOMAIN},https://auth.${PROD_DOMAIN},https://${PROD_DOMAIN},https://www.${PROD_DOMAIN}

# Keycloak
KC_HOSTNAME=auth.${PROD_DOMAIN}

# Database credentials
PSC_DB_PASSWORD=${PSC_DB_PASSWORD}
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}

# Deployment
DEPLOY_ENV=production
EOF

echo -e "  Generated: ${GREEN}$ENV_FILE${NC}"

# ==============================================================================
# STEP 5: Generate frontend runtime configurations
# ==============================================================================
echo ""
echo -e "${YELLOW}[5/5] Generating frontend runtime configurations...${NC}"

# PRF Frontend runtime-config.json
PRF_CONFIG_FILE="$GENERATED_DIR/prf-runtime-config.prod.json"
cat > "$PRF_CONFIG_FILE" << EOF
{
  "_comment": "PRODUCTION: Generated by prod-setup.sh",
  "_generated": "$(date)",
  "_domain": "${PROD_DOMAIN}",

  "backend": {
    "http": {
      "protocol": "http",
      "url": "api.prf.${PROD_DOMAIN}",
      "port": "80"
    },
    "https": {
      "protocol": "https",
      "url": "api.prf.${PROD_DOMAIN}",
      "port": "443"
    },
    "preferHttps": true
  },

  "frontend": {
    "http": {
      "protocol": "http",
      "url": "prf.${PROD_DOMAIN}",
      "port": "80"
    },
    "https": {
      "protocol": "https",
      "url": "prf.${PROD_DOMAIN}",
      "port": "443"
    }
  },

  "connection": {
    "retryInterval": 3000,
    "maxRetryTime": 60000,
    "timeout": 30000
  },

  "features": {
    "enableHttps": true,
    "enableRuntimeConfig": false,
    "allowBackendChange": false
  }
}
EOF
echo -e "  Generated: ${GREEN}$PRF_CONFIG_FILE${NC}"

# PSC Frontend runtime-config.json
PSC_CONFIG_FILE="$GENERATED_DIR/psc-runtime-config.prod.json"
cat > "$PSC_CONFIG_FILE" << EOF
{
  "_comment": "PRODUCTION: Generated by prod-setup.sh",
  "_generated": "$(date)",
  "_domain": "${PROD_DOMAIN}",

  "backendUri": "https://api.psc.${PROD_DOMAIN}/",
  "backendHttpsUri": "https://api.psc.${PROD_DOMAIN}/",

  "keycloak": {
    "authority": "https://auth.${PROD_DOMAIN}/realms/Political-Scorecard",
    "clientId": "political-scorecard-frontend",
    "realm": "Political-Scorecard",
    "redirectUri": "https://psc.${PROD_DOMAIN}",
    "postLogoutRedirectUri": "https://psc.${PROD_DOMAIN}",
    "responseType": "code",
    "scope": "openid profile email roles",
    "silentRedirectUri": "https://psc.${PROD_DOMAIN}/silent-refresh.html"
  }
}
EOF
echo -e "  Generated: ${GREEN}$PSC_CONFIG_FILE${NC}"

# ==============================================================================
# DONE
# ==============================================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Production Setup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Your production URLs:"
echo -e "  ${BLUE}Landing:${NC}      https://${PROD_DOMAIN}"
echo -e "  ${BLUE}Keycloak:${NC}     https://auth.${PROD_DOMAIN}"
echo -e "  ${BLUE}PSC Frontend:${NC} https://psc.${PROD_DOMAIN}"
echo -e "  ${BLUE}PSC API:${NC}      https://api.psc.${PROD_DOMAIN}"
echo -e "  ${BLUE}PRF Frontend:${NC} https://prf.${PROD_DOMAIN}"
echo -e "  ${BLUE}PRF API:${NC}      https://api.prf.${PROD_DOMAIN}"
echo ""
echo -e "Generated files (gitignored):"
echo -e "  ${BLUE}$GENERATED_DIR/nginx.prod.conf${NC}"
echo -e "  ${BLUE}$GENERATED_DIR/.env.prod${NC}"
echo -e "  ${BLUE}$GENERATED_DIR/prf-runtime-config.prod.json${NC}"
echo -e "  ${BLUE}$GENERATED_DIR/psc-runtime-config.prod.json${NC}"
echo ""
echo -e "To deploy:"
echo -e "  ${YELLOW}sudo docker compose -f docker-compose.prod.yml up -d --build${NC}"
echo ""
echo -e "${RED}SECURITY REMINDER:${NC} The .generated/ directory contains sensitive"
echo -e "configuration. Ensure it remains gitignored and never committed."
echo ""

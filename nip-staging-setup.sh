#!/bin/bash
# ==============================================================================
# POLARI SUITE - STAGING SETUP SCRIPT
# ==============================================================================
#
# This script sets up the staging environment with nip.io subdomain routing.
# It auto-detects your local IP and generates the necessary configuration.
#
# Run this script before starting the staging environment:
#   ./nip-staging-setup.sh
#
# Then start the environment:
#   sudo docker compose -f docker-compose.staging-nip.yml --env-file .generated/.env.staging up -d --build
#
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_DIR="$SCRIPT_DIR/pol-proxy"
CERTS_DIR="$PROXY_DIR/certs"
NIP_CERTS_DIR="$CERTS_DIR/nip.io"
GENERATED_DIR="$SCRIPT_DIR/.generated"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Polari Suite - Prod-Local Setup${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ==============================================================================
# STEP 1: Detect Local IP
# ==============================================================================
echo -e "${YELLOW}[1/6] Detecting local IP address...${NC}"

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
    echo "Please set LOCAL_IP environment variable manually:"
    echo "  export LOCAL_IP=192.168.x.x"
    echo "  ./nip-staging-setup.sh"
    exit 1
fi

# Allow override via environment variable
if [ -n "$OVERRIDE_IP" ]; then
    LOCAL_IP="$OVERRIDE_IP"
    echo -e "  Using override IP: ${GREEN}$LOCAL_IP${NC}"
else
    echo -e "  Detected IP: ${GREEN}$LOCAL_IP${NC}"
fi

# Validate IP format
if ! [[ $LOCAL_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}ERROR: Invalid IP address format: $LOCAL_IP${NC}"
    exit 1
fi

# ---------------------------------------------------------------------------
# Base domain for staging. Defaults to this machine's nip.io wildcard; set
# POLARI_STAGING_DOMAIN (e.g. polari-staging.test) for a custom local domain.
# A custom domain has no public DNS, so STEP 6b adds it to /etc/hosts, mapping
# it (and every subdomain) at this machine.
# ---------------------------------------------------------------------------
BASE_DOMAIN="${POLARI_STAGING_DOMAIN:-${LOCAL_IP}.nip.io}"
if [[ "$BASE_DOMAIN" == *.nip.io ]]; then IS_CUSTOM_DOMAIN=false; else IS_CUSTOM_DOMAIN=true; fi
if [ "$IS_CUSTOM_DOMAIN" = true ]; then
    echo -e "  Base domain: ${GREEN}${BASE_DOMAIN}${NC} (custom — local /etc/hosts resolution will be added)"
else
    echo -e "  Base domain: ${GREEN}${BASE_DOMAIN}${NC}"
fi

# ---------------------------------------------------------------------------
# Cert trust model. self-signed (default): today's plain openssl leaf signed
# by pol-ca — zero new dependencies, unchanged behavior. step-ca: issue the
# same leaf from the suite's step-ca (ca/) instead — one unified internal
# root shared with every other step-ca-issued service, same guided-import
# walkthrough either way. There is no "web"/Let's Encrypt option here: a
# .test or nip.io BASE_DOMAIN can never get a publicly-issued cert (no real
# DNS to validate) — see CERT_MODE=web in prod-setup.sh instead.
# ---------------------------------------------------------------------------
CERT_MODE="${CERT_MODE:-self-signed}"
case "$CERT_MODE" in
    self-signed|step-ca) ;;
    *) echo -e "${RED}ERROR: CERT_MODE must be 'self-signed' or 'step-ca' (got '$CERT_MODE').${NC}"
       exit 1 ;;
esac
echo -e "  Cert mode:   ${GREEN}${CERT_MODE}${NC}"

# ==============================================================================
# STEP 2: Generate nginx configuration
# ==============================================================================
echo ""
echo -e "${YELLOW}[2/6] Generating nginx configuration...${NC}"

mkdir -p "$GENERATED_DIR"

TEMPLATE_FILE="$PROXY_DIR/nginx.staging.conf.template"
OUTPUT_FILE="$GENERATED_DIR/nginx.staging.conf"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}ERROR: Template file not found: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Render the proxy conf for this base domain. The template carries
# ${LOCAL_IP}.nip.io host tokens: collapse the whole host to the base domain
# first (prf.${LOCAL_IP}.nip.io -> prf.$BASE_DOMAIN), then fill any bare
# ${LOCAL_IP}. For the nip.io default the two passes are equivalent.
sed -e "s/\${LOCAL_IP}\.nip\.io/$BASE_DOMAIN/g" -e "s/\${LOCAL_IP}/$LOCAL_IP/g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo -e "  Generated: ${GREEN}$OUTPUT_FILE${NC}"

# ==============================================================================
# STEP 3: Generate SSL certificates for nip.io
# ==============================================================================
echo ""
echo -e "${YELLOW}[3/6] Generating SSL certificates for *.${BASE_DOMAIN}...${NC}"

mkdir -p "$NIP_CERTS_DIR"

CA_CERT="$CERTS_DIR/ca/pol-ca.crt"
CA_KEY="$CERTS_DIR/ca/pol-ca.key"

if [ "$CERT_MODE" = "step-ca" ]; then
    echo "  Using step-ca (unified internal CA) — see CENTRALIZED_CA_PLAN.md..."
    CA_FLAGS=""
    [ "${POLARI_CA_NON_INTERACTIVE:-}" = "yes" ] && CA_FLAGS="--non-interactive"

    CA_ENV=staging BASE_DOMAIN="$BASE_DOMAIN" bash "$SCRIPT_DIR/ca/setup-step-ca.sh" $CA_FLAGS
    CA_ENV=staging BASE_DOMAIN="$BASE_DOMAIN" bash "$SCRIPT_DIR/ca/issue-internal-certs.sh" $CA_FLAGS

    ISSUED_CRT="$SCRIPT_DIR/ca/issued/pol-proxy-public.crt"
    ISSUED_KEY="$SCRIPT_DIR/ca/issued/pol-proxy-public.key"
    if [ ! -f "$ISSUED_CRT" ] || [ ! -f "$ISSUED_KEY" ]; then
        echo -e "${RED}ERROR: step-ca did not produce pol-proxy-public.{crt,key} at $SCRIPT_DIR/ca/issued/${NC}"
        exit 1
    fi
    # Redirect the SAME path pol-proxy already mounts — no compose changes.
    cp "$ISSUED_CRT" "$NIP_CERTS_DIR/server.crt"
    cp "$ISSUED_KEY" "$NIP_CERTS_DIR/server.key"
    STEP_CA_ROOT="$SCRIPT_DIR/ca/root_ca.crt"
    echo -e "  Certificate signed by: ${GREEN}step-ca${NC} (unified root: $STEP_CA_ROOT)"
# Check if we have the CA
elif [ -f "$CA_CERT" ] && [ -f "$CA_KEY" ]; then
    echo "  Using existing CA to sign certificate..."

    # Generate private key
    openssl genrsa -out "$NIP_CERTS_DIR/server.key" 2048 2>/dev/null

    # Create certificate signing request with SAN
    cat > "$NIP_CERTS_DIR/openssl.cnf" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = US
ST = State
L = City
O = Polari Systems
OU = Development
CN = *.${BASE_DOMAIN}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.${BASE_DOMAIN}
DNS.2 = ${BASE_DOMAIN}
DNS.3 = auth.${BASE_DOMAIN}
DNS.4 = psc.${BASE_DOMAIN}
DNS.5 = api.psc.${BASE_DOMAIN}
DNS.6 = prf.${BASE_DOMAIN}
DNS.7 = api.prf.${BASE_DOMAIN}
DNS.8 = files.${BASE_DOMAIN}
DNS.9 = s3.${BASE_DOMAIN}
DNS.10 = odoo.${BASE_DOMAIN}
EOF

    # Generate CSR
    openssl req -new \
        -key "$NIP_CERTS_DIR/server.key" \
        -out "$NIP_CERTS_DIR/server.csr" \
        -config "$NIP_CERTS_DIR/openssl.cnf" \
        2>/dev/null

    # Sign with CA (valid for 365 days)
    openssl x509 -req \
        -in "$NIP_CERTS_DIR/server.csr" \
        -CA "$CA_CERT" \
        -CAkey "$CA_KEY" \
        -CAcreateserial \
        -out "$NIP_CERTS_DIR/server.crt" \
        -days 365 \
        -sha256 \
        -extfile "$NIP_CERTS_DIR/openssl.cnf" \
        -extensions req_ext \
        2>/dev/null

    echo -e "  Certificate signed by: ${GREEN}pol-ca${NC}"
else
    echo "  CA not found, generating self-signed certificate..."

    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$NIP_CERTS_DIR/server.key" \
        -out "$NIP_CERTS_DIR/server.crt" \
        -subj "/C=US/ST=State/L=City/O=Polari Systems/OU=Dev/CN=*.${BASE_DOMAIN}" \
        -addext "subjectAltName=DNS:*.${BASE_DOMAIN},DNS:${BASE_DOMAIN},DNS:files.${BASE_DOMAIN},DNS:s3.${BASE_DOMAIN}" \
        2>/dev/null

    echo -e "  ${YELLOW}Note: Self-signed certificate generated${NC}"
fi

echo -e "  Generated: ${GREEN}$NIP_CERTS_DIR/server.crt${NC}"
echo -e "  Generated: ${GREEN}$NIP_CERTS_DIR/server.key${NC}"

# ==============================================================================
# STEP 4: Ensure credential env files + generate environment file
# ==============================================================================
echo ""
echo -e "${YELLOW}[4/6] Generating environment file...${NC}"

# Self-sufficiency: a fresh clone has NO credential env files (they are all
# gitignored + generated). If any is missing, generate them now via
# setup-polari-security.sh (dev mode = random, no prompts; skip-if-exists
# protects live installs).
for _cred in pol-keycloak/keycloak-admin.env pol-mariadb/mariadb.env \
             pol-file-store/minio.env pol-file-store/client.env \
             pol-odoo-postgres/odoo-postgres.env pol-odoo/odoo.env; do
    if [ ! -f "$SCRIPT_DIR/$_cred" ]; then
        echo -e "  Missing $_cred — running setup-polari-security.sh dev --env-only --skip-subs"
        "$SCRIPT_DIR/setup-polari-security.sh" dev --env-only --skip-subs
        break
    fi
done

ENV_FILE="$GENERATED_DIR/.env.staging"

cat > "$ENV_FILE" << EOF
# ==============================================================================
# POLARI SUITE - STAGING ENVIRONMENT
# ==============================================================================
# Generated by nip-staging-setup.sh on $(date)
# IP Address: ${LOCAL_IP}
# ==============================================================================

LOCAL_IP=${LOCAL_IP}
# Base staging domain (nip.io wildcard by default, or a custom .test domain)
BASE_DOMAIN=${BASE_DOMAIN}

# Base domain
NIP_DOMAIN=${BASE_DOMAIN}

# Service URLs
AUTH_URL=https://auth.${BASE_DOMAIN}
PSC_URL=https://psc.${BASE_DOMAIN}
PSC_API_URL=https://api.psc.${BASE_DOMAIN}
PRF_URL=https://prf.${BASE_DOMAIN}
PRF_API_URL=https://api.prf.${BASE_DOMAIN}
MINIO_CONSOLE_URL=https://files.${BASE_DOMAIN}
MINIO_S3_URL=https://s3.${BASE_DOMAIN}
# Odoo ERP (compose profile 'odoo' — started via pol odoo up, not suite up)
ODOO_URL=https://odoo.${BASE_DOMAIN}

# CORS Origins (comma-separated)
CORS_ORIGINS=https://psc.${BASE_DOMAIN},https://prf.${BASE_DOMAIN},https://auth.${BASE_DOMAIN},https://files.${BASE_DOMAIN}
# Spring Boot reads this env var for CORS allowed origins
APP_CORS_ALLOWED_ORIGINS=https://psc.${BASE_DOMAIN},https://prf.${BASE_DOMAIN},https://auth.${BASE_DOMAIN},https://files.${BASE_DOMAIN}

# Keycloak — shared
KC_HOSTNAME=auth.${BASE_DOMAIN}

# Keycloak — PSC realm (issuer URI is the public-facing URL clients see in token claims)
KEYCLOAK_ISSUER_URI=https://auth.${BASE_DOMAIN}/realms/Political-Scorecard

# Keycloak — Polari realm
# Public issuer (matches the 'iss' claim) — used by the PRF backend to validate JWTs.
POLARI_KEYCLOAK_ISSUER_URI=https://auth.${BASE_DOMAIN}/realms/Polari
# JWKS endpoint — public-key set the backend pulls to verify token signatures
# without round-tripping Keycloak on every request. Uses the in-network HTTP
# URL because the backend container reaches Keycloak via the docker network.
POLARI_KEYCLOAK_JWKS_URI=http://pol-keycloak:8080/realms/Polari/protocol/openid-connect/certs
# Admin API base for server-to-server calls (user/group management, etc).
POLARI_KEYCLOAK_ADMIN_URL=http://pol-keycloak:8080
# Realm + service-account client identity for the PRF backend.
POLARI_KEYCLOAK_REALM=Polari
POLARI_KEYCLOAK_ADMIN_CLIENT_ID=polari-backend
EOF

# Append credential-interpolation values sourced from the generated env files
# (setup-polari-security.sh owns the source files; this keeps compose
# ${VAR:-default} interpolation in sync when this file is passed as
# --env-file to docker compose).
PSC_DB_PASSWORD_CUR=$(grep -E '^PSC_DB_PASSWORD=' "$SCRIPT_DIR/pol-mariadb/mariadb.env" 2>/dev/null | cut -d= -f2-)
if [ -n "$PSC_DB_PASSWORD_CUR" ]; then
    cat >> "$ENV_FILE" << EOF

# PSC DB password (derived from pol-mariadb/mariadb.env) — resolves the
# \${PSC_DB_PASSWORD:-...} interpolation for psc-backend.
PSC_DB_PASSWORD=$PSC_DB_PASSWORD_CUR
EOF
fi

echo -e "  Generated: ${GREEN}$ENV_FILE${NC}"

# ==============================================================================
# STEP 5: Generate frontend runtime configurations
# ==============================================================================
echo ""
echo -e "${YELLOW}[5/6] Generating frontend runtime configurations...${NC}"

# PRF Frontend runtime-config.json
PRF_CONFIG_FILE="$GENERATED_DIR/prf-runtime-config.json"
cat > "$PRF_CONFIG_FILE" << EOF
{
  "_comment": "STAGING: Generated by nip-staging-setup.sh for nip.io testing",
  "_generated": "$(date)",
  "_ip": "${LOCAL_IP}",

  "backend": {
    "http": {
      "protocol": "http",
      "url": "api.prf.${BASE_DOMAIN}",
      "port": "80"
    },
    "https": {
      "protocol": "https",
      "url": "api.prf.${BASE_DOMAIN}",
      "port": "443"
    },
    "ws": {
      "protocol": "ws",
      "url": "api.prf.${BASE_DOMAIN}",
      "port": "3001"
    },
    "preferHttps": true
  },

  "frontend": {
    "http": {
      "protocol": "http",
      "url": "prf.${BASE_DOMAIN}",
      "port": "80"
    },
    "https": {
      "protocol": "https",
      "url": "prf.${BASE_DOMAIN}",
      "port": "443"
    }
  },

  "connection": {
    "retryInterval": 3000,
    "maxRetryTime": 60000,
    "timeout": 30000
  },

  "keycloak": {
    "authority": "https://auth.${BASE_DOMAIN}/realms/Polari",
    "clientId": "polari-frontend",
    "realm": "Polari",
    "redirectUri": "https://prf.${BASE_DOMAIN}",
    "postLogoutRedirectUri": "https://prf.${BASE_DOMAIN}",
    "responseType": "code",
    "scope": "openid profile email roles",
    "silentRedirectUri": "https://prf.${BASE_DOMAIN}/silent-refresh.html"
  },

  "features": {
    "enableHttps": true,
    "enableRuntimeConfig": true,
    "allowBackendChange": true
  }
}
EOF
echo -e "  Generated: ${GREEN}$PRF_CONFIG_FILE${NC}"

# PSC Frontend runtime-config.json
PSC_CONFIG_FILE="$GENERATED_DIR/psc-runtime-config.json"
cat > "$PSC_CONFIG_FILE" << EOF
{
  "_comment": "STAGING: Generated by nip-staging-setup.sh for nip.io testing",
  "_generated": "$(date)",
  "_ip": "${LOCAL_IP}",

  "backendUri": "https://api.psc.${BASE_DOMAIN}/",
  "backendHttpsUri": "https://api.psc.${BASE_DOMAIN}/",

  "keycloak": {
    "authority": "https://auth.${BASE_DOMAIN}/realms/Political-Scorecard",
    "clientId": "political-scorecard-frontend",
    "realm": "Political-Scorecard",
    "redirectUri": "https://psc.${BASE_DOMAIN}",
    "postLogoutRedirectUri": "https://psc.${BASE_DOMAIN}",
    "responseType": "code",
    "scope": "openid profile email roles",
    "silentRedirectUri": "https://psc.${BASE_DOMAIN}/silent-refresh.html"
  }
}
EOF
echo -e "  Generated: ${GREEN}$PSC_CONFIG_FILE${NC}"

# pol-hub (informational hub) runtime-config.json — the outbound project links.
# prf/dps/oseb resolve to real staging URLs; oseb is PRF's tech-tree route.
# Isle-Mesh has no suite service, so mesh points at the hub's own docs (or an
# ISLE_MESH_URL override) — always a valid URL for this environment.
HUB_CONFIG_FILE="$GENERATED_DIR/pol-hub-runtime-config.json"
HUB_MESH_URL="${ISLE_MESH_URL:-https://${BASE_DOMAIN}/docs.html}"
cat > "$HUB_CONFIG_FILE" << EOF
{
  "_comment": "STAGING: Generated by nip-staging-setup.sh — per-env project URLs for the Polari hub",
  "_generated": "$(date)",
  "_ip": "${LOCAL_IP}",
  "env": "staging",
  "links": {
    "prf": "https://prf.${BASE_DOMAIN}",
    "dps": "https://psc.${BASE_DOMAIN}",
    "mesh": "${HUB_MESH_URL}",
    "oseb": "https://prf.${BASE_DOMAIN}/tech-tree"
  }
}
EOF
echo -e "  Generated: ${GREEN}$HUB_CONFIG_FILE${NC}"

# ==============================================================================
# STEP 6b: Local DNS resolution (custom domains only)
# ==============================================================================
# A custom staging domain does not resolve via public DNS. Point it (and every
# subdomain the proxy serves) at this machine so `https://<domain>` works here.
# nip.io domains already resolve via public DNS, so this is skipped for them.
if [ "$IS_CUSTOM_DOMAIN" = true ]; then
    echo ""
    echo -e "${YELLOW}[6b/6] Configuring local resolution: ${BASE_DOMAIN} -> 127.0.0.1...${NC}"
    HOSTS_FILE="/etc/hosts"
    MARK_BEGIN="# >>> polari-staging: ${BASE_DOMAIN} >>>"
    MARK_END="# <<< polari-staging: ${BASE_DOMAIN} <<<"
    HOST_NAMES="${BASE_DOMAIN} www.${BASE_DOMAIN} auth.${BASE_DOMAIN} psc.${BASE_DOMAIN} api.psc.${BASE_DOMAIN} prf.${BASE_DOMAIN} api.prf.${BASE_DOMAIN} files.${BASE_DOMAIN} s3.${BASE_DOMAIN} odoo.${BASE_DOMAIN}"

    HOSTS_BLOCK="$MARK_BEGIN"
    for h in $HOST_NAMES; do HOSTS_BLOCK="$HOSTS_BLOCK"$'\n'"127.0.0.1   $h"; done
    HOSTS_BLOCK="$HOSTS_BLOCK"$'\n'"$MARK_END"

    # Idempotent: strip any prior block for this domain, then append the fresh
    # one, written atomically. sudo may prompt for your password.
    TMP_HOSTS="$(mktemp)"
    sed "\|$MARK_BEGIN|,\|$MARK_END|d" "$HOSTS_FILE" > "$TMP_HOSTS" 2>/dev/null || cp "$HOSTS_FILE" "$TMP_HOSTS"
    printf '%s\n' "$HOSTS_BLOCK" >> "$TMP_HOSTS"
    if sudo cp "$TMP_HOSTS" "$HOSTS_FILE"; then
        echo -e "  ${GREEN}Local resolution set for:${NC} $HOST_NAMES"
    else
        echo -e "${RED}  Could not write ${HOSTS_FILE}. Add these lines yourself:${NC}"
        printf '%s\n' "$HOSTS_BLOCK"
    fi
    rm -f "$TMP_HOSTS"
fi

# ==============================================================================
# STEP 6: Verify MinIO configuration
# ==============================================================================
echo ""
echo -e "${YELLOW}[6/6] Verifying MinIO file store configuration...${NC}"

MINIO_ENV="$SCRIPT_DIR/pol-file-store/minio.env"
MINIO_CLIENT_ENV="$SCRIPT_DIR/pol-file-store/client.env"

if [ -f "$MINIO_ENV" ]; then
    echo -e "  MinIO server env: ${GREEN}$MINIO_ENV${NC}"
else
    echo -e "  ${RED}WARNING: MinIO server env not found: $MINIO_ENV${NC}"
    echo -e "  ${RED}Run setup-polari-security.sh or create pol-file-store/minio.env${NC}"
fi

if [ -f "$MINIO_CLIENT_ENV" ]; then
    echo -e "  MinIO client env: ${GREEN}$MINIO_CLIENT_ENV${NC}"
else
    echo -e "  ${RED}WARNING: MinIO client env not found: $MINIO_CLIENT_ENV${NC}"
    echo -e "  ${RED}PRF backend needs pol-file-store/client.env for object storage${NC}"
fi

# ==============================================================================
# DONE
# ==============================================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Your staging URLs:"
echo -e "  ${BLUE}Landing:${NC}        https://${BASE_DOMAIN}"
echo -e "  ${BLUE}Keycloak:${NC}       https://auth.${BASE_DOMAIN}"
echo -e "  ${BLUE}PSC Frontend:${NC}   https://psc.${BASE_DOMAIN}"
echo -e "  ${BLUE}PSC API:${NC}        https://api.psc.${BASE_DOMAIN}"
echo -e "  ${BLUE}PRF Frontend:${NC}   https://prf.${BASE_DOMAIN}"
echo -e "  ${BLUE}PRF API:${NC}        https://api.prf.${BASE_DOMAIN}"
echo -e "  ${BLUE}MinIO Console:${NC}  https://files.${BASE_DOMAIN}"
echo -e "  ${BLUE}MinIO S3 API:${NC}   https://s3.${BASE_DOMAIN}"
echo ""
echo -e "To start the environment:"
echo -e "  ${YELLOW}sudo docker compose -f docker-compose.staging-nip.yml --env-file .generated/.env.staging up -d --build${NC}"
echo ""
if [ "$CERT_MODE" = "step-ca" ] && [ -f "$SCRIPT_DIR/ca/root_ca.crt" ]; then
    echo -e "${YELLOW}Trust the CA certificate${NC} (one root covers every step-ca-issued Polari service):"
    bash "$SCRIPT_DIR/ca/walkthrough.sh" "$SCRIPT_DIR/ca/root_ca.crt"
elif [ -f "$CA_CERT" ]; then
    echo -e "${YELLOW}TIP:${NC} If you haven't already, trust the CA certificate in your browser:"
    echo -e "  ${BLUE}$CA_CERT${NC}"
    echo -e "  (or re-run with ${BLUE}CERT_MODE=step-ca${NC} for a guided multi-OS/browser walkthrough"
    echo -e "   and one unified root shared with every other step-ca-issued service)"
fi
echo ""

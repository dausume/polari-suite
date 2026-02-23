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

# Replace ${LOCAL_IP} placeholder with actual IP
sed "s/\${LOCAL_IP}/$LOCAL_IP/g" "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo -e "  Generated: ${GREEN}$OUTPUT_FILE${NC}"

# ==============================================================================
# STEP 3: Generate SSL certificates for nip.io
# ==============================================================================
echo ""
echo -e "${YELLOW}[3/6] Generating SSL certificates for *.${LOCAL_IP}.nip.io...${NC}"

mkdir -p "$NIP_CERTS_DIR"

CA_CERT="$CERTS_DIR/ca/pol-ca.crt"
CA_KEY="$CERTS_DIR/ca/pol-ca.key"

# Check if we have the CA
if [ -f "$CA_CERT" ] && [ -f "$CA_KEY" ]; then
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
CN = *.${LOCAL_IP}.nip.io

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.${LOCAL_IP}.nip.io
DNS.2 = ${LOCAL_IP}.nip.io
DNS.3 = auth.${LOCAL_IP}.nip.io
DNS.4 = psc.${LOCAL_IP}.nip.io
DNS.5 = api.psc.${LOCAL_IP}.nip.io
DNS.6 = prf.${LOCAL_IP}.nip.io
DNS.7 = api.prf.${LOCAL_IP}.nip.io
DNS.8 = files.${LOCAL_IP}.nip.io
DNS.9 = s3.${LOCAL_IP}.nip.io
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
        -subj "/C=US/ST=State/L=City/O=Polari Systems/OU=Dev/CN=*.${LOCAL_IP}.nip.io" \
        -addext "subjectAltName=DNS:*.${LOCAL_IP}.nip.io,DNS:${LOCAL_IP}.nip.io,DNS:files.${LOCAL_IP}.nip.io,DNS:s3.${LOCAL_IP}.nip.io" \
        2>/dev/null

    echo -e "  ${YELLOW}Note: Self-signed certificate generated${NC}"
fi

echo -e "  Generated: ${GREEN}$NIP_CERTS_DIR/server.crt${NC}"
echo -e "  Generated: ${GREEN}$NIP_CERTS_DIR/server.key${NC}"

# ==============================================================================
# STEP 4: Generate environment file
# ==============================================================================
echo ""
echo -e "${YELLOW}[4/6] Generating environment file...${NC}"

ENV_FILE="$GENERATED_DIR/.env.staging"

cat > "$ENV_FILE" << EOF
# ==============================================================================
# POLARI SUITE - STAGING ENVIRONMENT
# ==============================================================================
# Generated by nip-staging-setup.sh on $(date)
# IP Address: ${LOCAL_IP}
# ==============================================================================

LOCAL_IP=${LOCAL_IP}

# Base domain
NIP_DOMAIN=${LOCAL_IP}.nip.io

# Service URLs
AUTH_URL=https://auth.${LOCAL_IP}.nip.io
PSC_URL=https://psc.${LOCAL_IP}.nip.io
PSC_API_URL=https://api.psc.${LOCAL_IP}.nip.io
PRF_URL=https://prf.${LOCAL_IP}.nip.io
PRF_API_URL=https://api.prf.${LOCAL_IP}.nip.io
MINIO_CONSOLE_URL=https://files.${LOCAL_IP}.nip.io
MINIO_S3_URL=https://s3.${LOCAL_IP}.nip.io

# CORS Origins (comma-separated)
CORS_ORIGINS=https://psc.${LOCAL_IP}.nip.io,https://prf.${LOCAL_IP}.nip.io,https://auth.${LOCAL_IP}.nip.io,https://files.${LOCAL_IP}.nip.io
# Spring Boot reads this env var for CORS allowed origins
APP_CORS_ALLOWED_ORIGINS=https://psc.${LOCAL_IP}.nip.io,https://prf.${LOCAL_IP}.nip.io,https://auth.${LOCAL_IP}.nip.io,https://files.${LOCAL_IP}.nip.io

# Keycloak
KC_HOSTNAME=auth.${LOCAL_IP}.nip.io
KEYCLOAK_ISSUER_URI=https://auth.${LOCAL_IP}.nip.io/realms/Political-Scorecard
EOF

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
      "url": "api.prf.${LOCAL_IP}.nip.io",
      "port": "80"
    },
    "https": {
      "protocol": "https",
      "url": "api.prf.${LOCAL_IP}.nip.io",
      "port": "443"
    },
    "preferHttps": true
  },

  "frontend": {
    "http": {
      "protocol": "http",
      "url": "prf.${LOCAL_IP}.nip.io",
      "port": "80"
    },
    "https": {
      "protocol": "https",
      "url": "prf.${LOCAL_IP}.nip.io",
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

  "backendUri": "https://api.psc.${LOCAL_IP}.nip.io/",
  "backendHttpsUri": "https://api.psc.${LOCAL_IP}.nip.io/",

  "keycloak": {
    "authority": "https://auth.${LOCAL_IP}.nip.io/realms/Political-Scorecard",
    "clientId": "political-scorecard-frontend",
    "realm": "Political-Scorecard",
    "redirectUri": "https://psc.${LOCAL_IP}.nip.io",
    "postLogoutRedirectUri": "https://psc.${LOCAL_IP}.nip.io",
    "responseType": "code",
    "scope": "openid profile email roles",
    "silentRedirectUri": "https://psc.${LOCAL_IP}.nip.io/silent-refresh.html"
  }
}
EOF
echo -e "  Generated: ${GREEN}$PSC_CONFIG_FILE${NC}"

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
echo -e "  ${BLUE}Landing:${NC}        https://${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}Keycloak:${NC}       https://auth.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}PSC Frontend:${NC}   https://psc.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}PSC API:${NC}        https://api.psc.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}PRF Frontend:${NC}   https://prf.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}PRF API:${NC}        https://api.prf.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}MinIO Console:${NC}  https://files.${LOCAL_IP}.nip.io"
echo -e "  ${BLUE}MinIO S3 API:${NC}   https://s3.${LOCAL_IP}.nip.io"
echo ""
echo -e "To start the environment:"
echo -e "  ${YELLOW}sudo docker compose -f docker-compose.staging-nip.yml --env-file .generated/.env.staging up -d --build${NC}"
echo ""
if [ -f "$CA_CERT" ]; then
    echo -e "${YELLOW}TIP:${NC} If you haven't already, trust the CA certificate in your browser:"
    echo -e "  ${BLUE}$CA_CERT${NC}"
fi
echo ""

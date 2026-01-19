#!/bin/bash
set -e

# ==============================================================================
# Polari Suite Certificate Generator (Parent Orchestrator)
# ==============================================================================
# Generates certificates for all Polari Suite services:
#   - Polari Core (Keycloak, main proxy)
#   - Political Scorecard (PSC)
#   - Polari Research Framework (PRF)
#
# This script handles all interactive prompts and passes collected information
# to downstream certificate generators, avoiding redundant prompts.
#
# Usage:
#   ./generate-pol-certs.sh dev              # Generate dev certs for all services
#   ./generate-pol-certs.sh prod             # Generate prod certs (prompts for confirmation)
#   ./generate-pol-certs.sh cleanup          # Remove all certificates
#   ./generate-pol-certs.sh dev --skip-subs  # Only generate core Polari certs
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================
ENV="${1:-dev}"
SKIP_SUBPROJECTS=false

# Parse additional arguments
shift || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-subs|--skip-subprojects)
            SKIP_SUBPROJECTS=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [[ "$ENV" != "dev" && "$ENV" != "prod" && "$ENV" != "cleanup" ]]; then
    echo "Usage: $0 [dev|prod|cleanup] [options]"
    echo ""
    echo "Environments:"
    echo "  dev     - Development environment (localhost, self-signed)"
    echo "  prod    - Production environment (polari-systems.org)"
    echo "  cleanup - Remove all existing certificates and keys"
    echo ""
    echo "Options:"
    echo "  --skip-subs    Only generate core Polari certs, skip PSC and PRF"
    exit 1
fi

# ==============================================================================
# SUBPROJECT DETECTION
# ==============================================================================
PSC_DIR="$SCRIPT_DIR/political-scorecard-node"
PRF_DIR="$SCRIPT_DIR/polari-rf-node"
PSC_SCRIPT="$PSC_DIR/generate-psc-certs.sh"
PRF_SCRIPT="$PRF_DIR/generate-prf-certs.sh"

# Check which subprojects exist
HAS_PSC=false
HAS_PRF=false

if [[ -f "$PSC_SCRIPT" ]]; then
    HAS_PSC=true
fi

if [[ -f "$PRF_SCRIPT" ]]; then
    HAS_PRF=true
fi

# ==============================================================================
# DIRECTORY STRUCTURE
# ==============================================================================
CA_DIR="$SCRIPT_DIR/pol-proxy/certs/ca"
PROXY_CERTS_DIR="$SCRIPT_DIR/pol-proxy/certs"
KC_CERTS_DIR="$SCRIPT_DIR/pol-keycloak/certs"

# ==============================================================================
# CLEANUP HANDLING
# ==============================================================================
if [[ "$ENV" == "cleanup" ]]; then
    echo "============================================"
    echo "Polari Suite Certificate Cleanup"
    echo "============================================"
    echo ""
    echo "Cleaning up core Polari certificates..."

    if [[ -d "$PROXY_CERTS_DIR" ]]; then
        rm -rf "$PROXY_CERTS_DIR"
        echo "  - Removed $PROXY_CERTS_DIR"
    fi

    if [[ -d "$KC_CERTS_DIR" ]]; then
        rm -rf "$KC_CERTS_DIR"
        echo "  - Removed $KC_CERTS_DIR"
    fi

    # Cleanup subprojects if not skipped
    if [[ "$SKIP_SUBPROJECTS" != "true" ]]; then
        echo ""
        if [[ "$HAS_PSC" == "true" ]]; then
            echo "Cleaning up PSC certificates..."
            "$PSC_SCRIPT" cleanup
        fi

        if [[ "$HAS_PRF" == "true" ]]; then
            echo "Cleaning up PRF certificates..."
            "$PRF_SCRIPT" cleanup
        fi
    fi

    echo ""
    echo "============================================"
    echo "Cleanup complete!"
    echo "============================================"
    echo ""
    echo "Run '$0 dev' or '$0 prod' to generate new certificates."
    exit 0
fi

# ==============================================================================
# HEADER
# ==============================================================================
echo "============================================"
echo "Polari Suite Certificate Generator"
echo "Environment: $ENV"
echo "============================================"
echo ""
echo "Detected subprojects:"
if [[ "$HAS_PSC" == "true" ]]; then
    echo "  - Political Scorecard (PSC)"
fi
if [[ "$HAS_PRF" == "true" ]]; then
    echo "  - Polari Research Framework (PRF)"
fi
if [[ "$HAS_PSC" != "true" && "$HAS_PRF" != "true" ]]; then
    echo "  (none)"
fi
echo ""

# ==============================================================================
# PRODUCTION PROMPTS (Collected once, passed to subprojects)
# ==============================================================================
SERVER_IP=""

if [[ "$ENV" == "dev" ]]; then
    CA_SUBJ="/C=US/ST=State/L=City/O=Polari/OU=CA/CN=Polari Dev CA"
    KC_CN="keycloak.internal"
    KC_SANS="DNS.1 = keycloak.internal
DNS.2 = pol-keycloak
DNS.3 = localhost
DNS.4 = host.docker.internal"
    PROXY_CN="localhost"
    PROXY_SANS="DNS.1 = localhost
DNS.2 = pol-proxy
DNS.3 = host.docker.internal
DNS.4 = *.localhost"
else
    # Production environment - collect prompts once
    echo ""
    echo "WARNING: Production certificates should only be generated on the production server itself."
    echo "         Do not run this on a development machine."
    echo ""
    read -p "Are you running this on the production server? (yes/no): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        echo "Aborting. Please run this script on the production server."
        exit 1
    fi

    read -p "Enter the server's public IPv6 address: " SERVER_IP
    if [[ -z "$SERVER_IP" ]]; then
        echo "Error: IPv6 address is required for production."
        exit 1
    fi

    echo ""
    echo "Server IP: $SERVER_IP"
    echo "This will be used for all Polari Suite certificates."
    echo ""

    CA_SUBJ="/C=US/ST=VA/L=Arlington/O=Polari/OU=CA/CN=polari-systems.org CA"
    KC_CN="auth.polari-systems.org"
    KC_SANS="DNS.1 = auth.polari-systems.org
DNS.2 = pol-keycloak
DNS.3 = keycloak.internal
IP.1 = $SERVER_IP"
    PROXY_CN="polari-systems.org"
    PROXY_SANS="DNS.1 = polari-systems.org
DNS.2 = www.polari-systems.org
DNS.3 = auth.polari-systems.org
DNS.4 = psc.polari-systems.org
DNS.5 = api.psc.polari-systems.org
DNS.6 = prf.polari-systems.org
DNS.7 = api.prf.polari-systems.org
DNS.8 = pol-proxy
IP.1 = $SERVER_IP"
fi

# ==============================================================================
# CORE POLARI CERTIFICATE GENERATION
# ==============================================================================
echo "============================================"
echo "Phase 1: Core Polari Certificates"
echo "============================================"
echo ""

# Create directory structure
mkdir -p "$CA_DIR"
mkdir -p "$KC_CERTS_DIR"

echo "1. Generating CA certificate..."
openssl genrsa -out "$CA_DIR/pol-ca.key" 4096
openssl req -new -x509 -days 3650 -key "$CA_DIR/pol-ca.key" -out "$CA_DIR/pol-ca.crt" \
    -subj "$CA_SUBJ"
echo "   CA certificate created: $CA_DIR/pol-ca.crt"

echo ""
echo "2. Generating Keycloak certificate (CN=$KC_CN)..."
openssl genrsa -out "$KC_CERTS_DIR/pol-kc.key" 2048

cat > "$KC_CERTS_DIR/pol-kc.cnf" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=US
ST=VA
L=Arlington
O=Polari
OU=Keycloak
CN=$KC_CN

[v3_req]
subjectAltName = @alt_names

[alt_names]
$KC_SANS
EOF

openssl req -new -key "$KC_CERTS_DIR/pol-kc.key" -out "$KC_CERTS_DIR/pol-kc.csr" \
    -config "$KC_CERTS_DIR/pol-kc.cnf"

openssl x509 -req -in "$KC_CERTS_DIR/pol-kc.csr" -CA "$CA_DIR/pol-ca.crt" \
    -CAkey "$CA_DIR/pol-ca.key" -CAcreateserial -out "$KC_CERTS_DIR/pol-kc.crt" \
    -days 825 -sha256 -extfile "$KC_CERTS_DIR/pol-kc.cnf" -extensions v3_req

rm "$KC_CERTS_DIR/pol-kc.csr" "$KC_CERTS_DIR/pol-kc.cnf"
chmod 600 "$KC_CERTS_DIR/pol-kc.key"
echo "   Keycloak certificate created: $KC_CERTS_DIR/pol-kc.crt"

echo ""
echo "3. Generating Polari Proxy certificate (CN=$PROXY_CN)..."
openssl genrsa -out "$PROXY_CERTS_DIR/pol-proxy.key" 2048

cat > "$PROXY_CERTS_DIR/pol-proxy.cnf" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=US
ST=VA
L=Arlington
O=Polari
OU=Proxy
CN=$PROXY_CN

[v3_req]
subjectAltName = @alt_names

[alt_names]
$PROXY_SANS
EOF

openssl req -new -key "$PROXY_CERTS_DIR/pol-proxy.key" -out "$PROXY_CERTS_DIR/pol-proxy.csr" \
    -config "$PROXY_CERTS_DIR/pol-proxy.cnf"

openssl x509 -req -in "$PROXY_CERTS_DIR/pol-proxy.csr" -CA "$CA_DIR/pol-ca.crt" \
    -CAkey "$CA_DIR/pol-ca.key" -CAcreateserial -out "$PROXY_CERTS_DIR/pol-proxy.crt" \
    -days 825 -sha256 -extfile "$PROXY_CERTS_DIR/pol-proxy.cnf" -extensions v3_req

rm "$PROXY_CERTS_DIR/pol-proxy.csr" "$PROXY_CERTS_DIR/pol-proxy.cnf"
chmod 600 "$PROXY_CERTS_DIR/pol-proxy.key"
echo "   Proxy certificate created: $PROXY_CERTS_DIR/pol-proxy.crt"

echo ""
echo "Core Polari certificates generated:"
echo "  CA:       $CA_DIR/pol-ca.{crt,key}"
echo "  Keycloak: $KC_CERTS_DIR/pol-kc.{crt,key}"
echo "  Proxy:    $PROXY_CERTS_DIR/pol-proxy.{crt,key}"

# ==============================================================================
# SUBPROJECT CERTIFICATE GENERATION
# ==============================================================================
if [[ "$SKIP_SUBPROJECTS" != "true" ]]; then
    # Build common arguments for subproject scripts
    SUBPROJECT_ARGS="--parent-call"
    if [[ "$ENV" == "prod" && -n "$SERVER_IP" ]]; then
        SUBPROJECT_ARGS="$SUBPROJECT_ARGS --server-ip=$SERVER_IP"
    fi
    # Optionally share the CA (subprojects will generate their own if not provided)
    SUBPROJECT_ARGS="$SUBPROJECT_ARGS --shared-ca=$CA_DIR"

    # Generate PSC certificates
    if [[ "$HAS_PSC" == "true" ]]; then
        echo ""
        echo "============================================"
        echo "Phase 2: Political Scorecard (PSC) Certificates"
        echo "============================================"
        echo ""
        "$PSC_SCRIPT" "$ENV" $SUBPROJECT_ARGS
    fi

    # Generate PRF certificates
    if [[ "$HAS_PRF" == "true" ]]; then
        echo ""
        echo "============================================"
        echo "Phase 3: Polari Research Framework (PRF) Certificates"
        echo "============================================"
        echo ""
        "$PRF_SCRIPT" "$ENV" $SUBPROJECT_ARGS
    fi
fi

# ==============================================================================
# SUMMARY
# ==============================================================================
echo ""
echo "============================================"
echo "Polari Suite Certificate Generation Complete!"
echo "============================================"
echo ""
echo "Environment: $ENV"
echo ""
echo "Core Polari certificates:"
echo "  CA:       $CA_DIR/pol-ca.{crt,key}"
echo "  Keycloak: $KC_CERTS_DIR/pol-kc.{crt,key}"
echo "  Proxy:    $PROXY_CERTS_DIR/pol-proxy.{crt,key}"

if [[ "$SKIP_SUBPROJECTS" != "true" ]]; then
    if [[ "$HAS_PSC" == "true" ]]; then
        echo ""
        echo "PSC certificates:"
        echo "  CA:    $PSC_DIR/psc-proxy/certs/ca/psc-ca.{crt,key}"
        echo "  Proxy: $PSC_DIR/psc-proxy/certs/psc-proxy.{crt,key}"
    fi

    if [[ "$HAS_PRF" == "true" ]]; then
        echo ""
        echo "PRF certificates:"
        echo "  CA:    $PRF_DIR/prf-proxy/certs/ca/prf-ca.{crt,key}"
        echo "  Proxy: $PRF_DIR/prf-proxy/certs/prf-proxy.{crt,key}"
    fi
fi

echo ""
echo "Verifying certificates..."
echo ""
echo "Core Keycloak certificate:"
openssl x509 -in "$KC_CERTS_DIR/pol-kc.crt" -noout -subject -ext subjectAltName
echo ""
echo "Core Proxy certificate:"
openssl x509 -in "$PROXY_CERTS_DIR/pol-proxy.crt" -noout -subject -ext subjectAltName

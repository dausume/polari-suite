#!/bin/bash
set -e

# ==============================================================================
# Polari Suite Security Setup
# ==============================================================================
# Sets up all security components for Polari Suite:
#   - SSL/TLS Certificates (CA, Keycloak, Proxy, subprojects)
#   - Environment files with credentials (Keycloak admin, MariaDB, etc.)
#
# This script handles all interactive prompts and passes collected information
# to downstream generators, avoiding redundant prompts.
#
# Usage:
#   ./setup-polari-security.sh dev              # Dev setup (localhost, self-signed)
#   ./setup-polari-security.sh prod             # Production setup (prompts for all)
#   ./setup-polari-security.sh cleanup          # Remove all certs and env files
#   ./setup-polari-security.sh dev --skip-subs  # Only setup core Polari
#   ./setup-polari-security.sh dev --certs-only # Only generate certificates
#   ./setup-polari-security.sh dev --env-only   # Only create env files
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================
ENV="${1:-dev}"
SKIP_SUBPROJECTS=false
CERTS_ONLY=false
ENV_ONLY=false

# Parse additional arguments
shift || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-subs|--skip-subprojects)
            SKIP_SUBPROJECTS=true
            shift
            ;;
        --certs-only)
            CERTS_ONLY=true
            shift
            ;;
        --env-only)
            ENV_ONLY=true
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
    echo "  dev     - Development environment (localhost, self-signed, default passwords)"
    echo "  prod    - Production environment (prompts for secure passwords)"
    echo "  cleanup - Remove all certificates, keys, and generated env files"
    echo ""
    echo "Options:"
    echo "  --skip-subs    Only setup core Polari, skip PSC and PRF"
    echo "  --certs-only   Only generate certificates, skip env files"
    echo "  --env-only     Only create env files, skip certificates"
    exit 1
fi

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================
generate_password() {
    # Generate a secure random password
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24
}

prompt_password() {
    local prompt="$1"
    local default="$2"
    local varname="$3"

    if [[ "$ENV" == "dev" ]]; then
        # Use default for dev
        eval "$varname='$default'"
        echo "  Using default: $default"
    else
        # Prompt for production
        echo ""
        read -sp "$prompt (or press Enter for random): " input
        echo ""
        if [[ -z "$input" ]]; then
            input=$(generate_password)
            echo "  Generated: $input"
        fi
        eval "$varname='$input'"
    fi
}

# ==============================================================================
# SUBPROJECT DETECTION
# ==============================================================================
PSC_DIR="$SCRIPT_DIR/political-scorecard-node"
PRF_DIR="$SCRIPT_DIR/polari-rf-node"
PSC_SCRIPT="$PSC_DIR/generate-psc-certs.sh"
PRF_SCRIPT="$PRF_DIR/generate-prf-certs.sh"

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

# Env file locations
KC_ENV_FILE="$SCRIPT_DIR/pol-keycloak/keycloak-admin.env"
MARIADB_ENV_FILE="$SCRIPT_DIR/pol-mariadb/mariadb.env"
PSC_FRONTEND_ENV="$PSC_DIR/political-scorecard-frontend/.env"
PRF_ENV="$PRF_DIR/.env"

# ==============================================================================
# CLEANUP HANDLING
# ==============================================================================
if [[ "$ENV" == "cleanup" ]]; then
    echo "============================================"
    echo "Polari Suite Security Cleanup"
    echo "============================================"
    echo ""

    echo "Cleaning up certificates..."
    if [[ -d "$PROXY_CERTS_DIR" ]]; then
        rm -rf "$PROXY_CERTS_DIR"
        echo "  - Removed $PROXY_CERTS_DIR"
    fi

    if [[ -d "$KC_CERTS_DIR" ]]; then
        rm -rf "$KC_CERTS_DIR"
        echo "  - Removed $KC_CERTS_DIR"
    fi

    echo ""
    echo "Cleaning up env files..."
    for envfile in "$KC_ENV_FILE" "$MARIADB_ENV_FILE"; do
        if [[ -f "$envfile" ]]; then
            rm "$envfile"
            echo "  - Removed $envfile"
        fi
    done

    # Cleanup subprojects if not skipped
    if [[ "$SKIP_SUBPROJECTS" != "true" ]]; then
        echo ""
        if [[ "$HAS_PSC" == "true" ]]; then
            echo "Cleaning up PSC..."
            "$PSC_SCRIPT" cleanup 2>/dev/null || true
        fi

        if [[ "$HAS_PRF" == "true" ]]; then
            echo "Cleaning up PRF..."
            "$PRF_SCRIPT" cleanup 2>/dev/null || true
        fi
    fi

    echo ""
    echo "============================================"
    echo "Cleanup complete!"
    echo "============================================"
    exit 0
fi

# ==============================================================================
# HEADER
# ==============================================================================
echo "============================================"
echo "Polari Suite Security Setup"
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
# PRODUCTION PROMPTS
# ==============================================================================
SERVER_IP=""

if [[ "$ENV" == "prod" ]]; then
    echo ""
    echo "WARNING: Production setup should only be run on the production server."
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
fi

# ==============================================================================
# PHASE 1: ENVIRONMENT FILES WITH CREDENTIALS
# ==============================================================================
if [[ "$CERTS_ONLY" != "true" ]]; then
    echo "============================================"
    echo "Phase 1: Environment Files & Credentials"
    echo "============================================"
    echo ""

    # --- Keycloak Admin Credentials ---
    echo "1. Keycloak Admin Credentials"
    echo "   File: $KC_ENV_FILE"

    if [[ "$ENV" == "dev" ]]; then
        KC_ADMIN_USER="admin"
        KC_ADMIN_PASS="admin"
        echo "   Using dev defaults: admin/admin"
    else
        read -p "   Keycloak admin username [admin]: " KC_ADMIN_USER
        KC_ADMIN_USER="${KC_ADMIN_USER:-admin}"

        read -sp "   Keycloak admin password (Enter for random): " KC_ADMIN_PASS
        echo ""
        if [[ -z "$KC_ADMIN_PASS" ]]; then
            KC_ADMIN_PASS=$(generate_password)
            echo "   Generated password: $KC_ADMIN_PASS"
        fi
    fi

    mkdir -p "$(dirname "$KC_ENV_FILE")"
    cat > "$KC_ENV_FILE" << EOF
# Keycloak Admin Credentials
# Generated by setup-polari-security.sh
KEYCLOAK_ADMIN=$KC_ADMIN_USER
KEYCLOAK_ADMIN_PASSWORD=$KC_ADMIN_PASS
EOF
    chmod 600 "$KC_ENV_FILE"
    echo "   Created: $KC_ENV_FILE"
    echo ""

    # --- MariaDB Credentials ---
    echo "2. MariaDB Credentials"
    echo "   File: $MARIADB_ENV_FILE"

    if [[ "$ENV" == "dev" ]]; then
        MYSQL_ROOT_PASS="rootpassword"
        KC_DB_PASS="kcpassword"
        PSC_DB_PASS="pscpassword"
        echo "   Using dev defaults"
    else
        read -sp "   MariaDB root password (Enter for random): " MYSQL_ROOT_PASS
        echo ""
        if [[ -z "$MYSQL_ROOT_PASS" ]]; then
            MYSQL_ROOT_PASS=$(generate_password)
            echo "   Generated root password: $MYSQL_ROOT_PASS"
        fi

        read -sp "   Keycloak DB password (Enter for random): " KC_DB_PASS
        echo ""
        if [[ -z "$KC_DB_PASS" ]]; then
            KC_DB_PASS=$(generate_password)
            echo "   Generated KC DB password: $KC_DB_PASS"
        fi

        read -sp "   PSC DB password (Enter for random): " PSC_DB_PASS
        echo ""
        if [[ -z "$PSC_DB_PASS" ]]; then
            PSC_DB_PASS=$(generate_password)
            echo "   Generated PSC DB password: $PSC_DB_PASS"
        fi
    fi

    mkdir -p "$(dirname "$MARIADB_ENV_FILE")"
    cat > "$MARIADB_ENV_FILE" << EOF
# MariaDB Credentials
# Generated by setup-polari-security.sh

# Root password
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS

# Keycloak database
KC_DB_NAME=keycloak
KC_DB_USER=kc
KC_DB_PASSWORD=$KC_DB_PASS

# PSC databases
PSC_DB_NAME=psc
PSC_SCORING_DB_NAME=psc_scoring_db
PSC_LOCATION_DB_NAME=psc_location_db
PSC_DB_USER=psc-scorecard-server
PSC_DB_PASSWORD=$PSC_DB_PASS
EOF
    chmod 600 "$MARIADB_ENV_FILE"
    echo "   Created: $MARIADB_ENV_FILE"
    echo ""

    # --- PSC Frontend .env (if exists) ---
    if [[ "$HAS_PSC" == "true" ]]; then
        echo "3. PSC Frontend Environment"
        if [[ ! -f "$PSC_FRONTEND_ENV" ]]; then
            mkdir -p "$(dirname "$PSC_FRONTEND_ENV")"
            cat > "$PSC_FRONTEND_ENV" << EOF
# PSC Frontend Environment
# Generated by setup-polari-security.sh
DEPLOY_ENV=$ENV
EOF
            echo "   Created: $PSC_FRONTEND_ENV"
        else
            echo "   Already exists: $PSC_FRONTEND_ENV (skipped)"
        fi
        echo ""
    fi

    # --- PRF .env (if exists) ---
    if [[ "$HAS_PRF" == "true" ]]; then
        echo "4. PRF Environment"
        if [[ ! -f "$PRF_ENV" ]]; then
            echo "   PRF .env not found - please copy from .env.defaults"
            echo "   Run: cp $PRF_DIR/.env.defaults $PRF_ENV"
        else
            echo "   Already exists: $PRF_ENV (skipped)"
        fi
        echo ""
    fi

    echo ""
    echo "Environment files created successfully!"
    echo ""

    # Save credentials summary for production
    if [[ "$ENV" == "prod" ]]; then
        CREDS_FILE="$SCRIPT_DIR/.credentials-summary.txt"
        cat > "$CREDS_FILE" << EOF
==============================================
POLARI SUITE CREDENTIALS SUMMARY
Generated: $(date)
==============================================

KEYCLOAK ADMIN:
  Username: $KC_ADMIN_USER
  Password: $KC_ADMIN_PASS
  URL: https://auth.polari-systems.org

MARIADB:
  Root Password: $MYSQL_ROOT_PASS

  Keycloak DB:
    Database: keycloak
    User: kc
    Password: $KC_DB_PASS

  PSC DB:
    Databases: psc, psc_scoring_db, psc_location_db
    User: psc-scorecard-server
    Password: $PSC_DB_PASS

==============================================
SAVE THIS FILE SECURELY AND DELETE FROM SERVER
==============================================
EOF
        chmod 600 "$CREDS_FILE"
        echo "IMPORTANT: Credentials saved to $CREDS_FILE"
        echo "           Save this securely and delete from server!"
        echo ""
    fi
fi

# ==============================================================================
# PHASE 2: CERTIFICATES
# ==============================================================================
if [[ "$ENV_ONLY" != "true" ]]; then
    echo "============================================"
    echo "Phase 2: SSL/TLS Certificates"
    echo "============================================"
    echo ""

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

    # ==============================================================================
    # SUBPROJECT CERTIFICATES
    # ==============================================================================
    if [[ "$SKIP_SUBPROJECTS" != "true" ]]; then
        SUBPROJECT_ARGS="--parent-call"
        if [[ "$ENV" == "prod" && -n "$SERVER_IP" ]]; then
            SUBPROJECT_ARGS="$SUBPROJECT_ARGS --server-ip=$SERVER_IP"
        fi
        SUBPROJECT_ARGS="$SUBPROJECT_ARGS --shared-ca=$CA_DIR"

        if [[ "$HAS_PSC" == "true" ]]; then
            echo ""
            echo "4. Generating PSC certificates..."
            "$PSC_SCRIPT" "$ENV" $SUBPROJECT_ARGS
        fi

        if [[ "$HAS_PRF" == "true" ]]; then
            echo ""
            echo "5. Generating PRF certificates..."
            "$PRF_SCRIPT" "$ENV" $SUBPROJECT_ARGS
        fi
    fi
fi

# ==============================================================================
# SUMMARY
# ==============================================================================
echo ""
echo "============================================"
echo "Polari Suite Security Setup Complete!"
echo "============================================"
echo ""
echo "Environment: $ENV"
echo ""

if [[ "$CERTS_ONLY" != "true" ]]; then
    echo "Credentials files:"
    echo "  Keycloak: $KC_ENV_FILE"
    echo "  MariaDB:  $MARIADB_ENV_FILE"
    echo ""
fi

if [[ "$ENV_ONLY" != "true" ]]; then
    echo "Certificates:"
    echo "  CA:       $CA_DIR/pol-ca.{crt,key}"
    echo "  Keycloak: $KC_CERTS_DIR/pol-kc.{crt,key}"
    echo "  Proxy:    $PROXY_CERTS_DIR/pol-proxy.{crt,key}"

    if [[ "$SKIP_SUBPROJECTS" != "true" ]]; then
        if [[ "$HAS_PSC" == "true" ]]; then
            echo "  PSC:      $PSC_DIR/psc-proxy/certs/"
        fi
        if [[ "$HAS_PRF" == "true" ]]; then
            echo "  PRF:      $PRF_DIR/prf-proxy/certs/"
        fi
    fi
fi

echo ""
echo "Next steps:"
echo "  1. Review the generated credentials"
echo "  2. Run: docker compose -f docker-compose.yml -f docker-compose.prod-limits.yml --profile prod up -d --build"
echo ""

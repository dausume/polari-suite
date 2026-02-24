#!/bin/bash
# ==============================================================================
# POLARI SUITE - CONSOLIDATED MARIADB INITIALIZATION
# ==============================================================================
# This script initializes the shared MariaDB instance with separate databases
# and users for each service (Keycloak and PSC).
#
# Passwords are read from environment variables with sensible defaults for
# local development. Production deployments MUST set these via env_file or
# environment in docker-compose.
#
# Environment variables:
#   KC_DB_PASSWORD      - Keycloak DB user password  (default: kcpassword)
#   PSC_DB_PASSWORD     - PSC DB user password        (default: pscpassword)
# ==============================================================================

set -e

KC_PASS="${KC_DB_PASSWORD:-kcpassword}"
PSC_PASS="${PSC_DB_PASSWORD:-pscpassword}"

echo "[init.sh] Initializing databases and users..."

mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" <<-EOSQL

-- ==============================================================================
-- KEYCLOAK DATABASE AND USER
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS keycloak
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'kc'@'%' IDENTIFIED BY '${KC_PASS}';
GRANT ALL PRIVILEGES ON keycloak.* TO 'kc'@'%';

-- ==============================================================================
-- POLITICAL SCORECARD (PSC) DATABASES AND USER
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS psc
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS psc_scoring_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS psc_location_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'psc-scorecard-server'@'%' IDENTIFIED BY '${PSC_PASS}';

GRANT ALL PRIVILEGES ON psc.* TO 'psc-scorecard-server'@'%';
GRANT ALL PRIVILEGES ON psc_scoring_db.* TO 'psc-scorecard-server'@'%';
GRANT ALL PRIVILEGES ON psc_location_db.* TO 'psc-scorecard-server'@'%';
GRANT SELECT ON mysql.* TO 'psc-scorecard-server'@'%';

-- ==============================================================================
-- APPLY PRIVILEGES
-- ==============================================================================
FLUSH PRIVILEGES;

EOSQL

echo "[init.sh] Database initialization complete."

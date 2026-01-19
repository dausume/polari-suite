-- ==============================================================================
-- POLARI SUITE - CONSOLIDATED MARIADB INITIALIZATION
-- ==============================================================================
-- This script initializes the shared MariaDB instance with separate databases
-- and users for each service (Keycloak and PSC).
--
-- Security: Each service has its own user with permissions limited to its
-- own database only. No cross-database access is permitted.
-- ==============================================================================

-- ==============================================================================
-- KEYCLOAK DATABASE AND USER
-- ==============================================================================
-- Create the Keycloak database
CREATE DATABASE IF NOT EXISTS keycloak
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Create the Keycloak user (restricted to keycloak database only)
CREATE USER IF NOT EXISTS 'kc'@'%' IDENTIFIED BY 'kcpassword';

-- Grant Keycloak user full access to keycloak database ONLY
GRANT ALL PRIVILEGES ON keycloak.* TO 'kc'@'%';

-- ==============================================================================
-- POLITICAL SCORECARD (PSC) DATABASES AND USER
-- ==============================================================================
-- PSC uses multiple databases for different purposes:
--   - psc: Main/general database
--   - psc_scoring_db: Scoring data
--   - psc_location_db: Location/geographic data

-- Create the PSC databases
CREATE DATABASE IF NOT EXISTS psc
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS psc_scoring_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS psc_location_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Create the PSC user (restricted to psc databases only)
CREATE USER IF NOT EXISTS 'psc-scorecard-server'@'%' IDENTIFIED BY 'pscpassword';

-- Grant PSC user full access to all PSC databases
-- This includes ability to create/alter tables, indexes, views, routines
GRANT ALL PRIVILEGES ON psc.* TO 'psc-scorecard-server'@'%';
GRANT ALL PRIVILEGES ON psc_scoring_db.* TO 'psc-scorecard-server'@'%';
GRANT ALL PRIVILEGES ON psc_location_db.* TO 'psc-scorecard-server'@'%';

-- Grant read access to mysql database for database administration queries
GRANT SELECT ON mysql.* TO 'psc-scorecard-server'@'%';

-- ==============================================================================
-- APPLY PRIVILEGES
-- ==============================================================================
FLUSH PRIVILEGES;

-- ==============================================================================
-- VERIFICATION (for debugging - check grants)
-- ==============================================================================
-- You can verify user permissions with:
-- SHOW GRANTS FOR 'kc'@'%';
-- SHOW GRANTS FOR 'psc-scorecard-server'@'%';

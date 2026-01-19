FROM mariadb:latest

# Copy initialization script
COPY init.sql /docker-entrypoint-initdb.d/01-init.sql

# Ensure init script has proper permissions
RUN chmod 644 /docker-entrypoint-initdb.d/01-init.sql

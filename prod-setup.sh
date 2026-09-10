#!/bin/bash
# prod-setup.sh — RETIRED 2026-09-09 (PRODUCTION_DEPLOY_PLAN §11). The inputs it
# used to write (.generated/.env.prod, the runtime configs, nginx.prod.conf, the
# edge certificate, the distribution directories) are written by `pol prod`:
#   pol prod render      (full profile when POL_PROD_AUTH=keycloak)
# This wrapper delegates so old instructions still work.
set -eu
export POL_PROD_AUTH="${POL_PROD_AUTH:-keycloak}"
[ -n "${POLARI_PROD_DOMAIN:-}" ] && export POL_PROD_DOMAIN="$POLARI_PROD_DOMAIN"
echo "prod-setup.sh is retired — running: pol prod render (full profile). See: pol prod help"
exec pol prod render

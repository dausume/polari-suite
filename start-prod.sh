#!/bin/bash
# start-prod.sh — RETIRED 2026-09-09 (PRODUCTION_DEPLOY_PLAN §11): production is a
# docker SWARM deployment driven by `pol prod`. This wrapper keeps the old
# entry point working by delegating to it (full profile = Keycloak logins).
#   ./start-prod.sh            → pol prod guide   (menus; full profile preselected)
#   ./start-prod.sh --apply    → pol prod apply --yes
#   ./start-prod.sh --down     → pol prod down
set -eu
export POL_PROD_AUTH="${POL_PROD_AUTH:-keycloak}"
case "${1:-}" in
    --down)  exec pol prod down ;;
    --apply|--setup-only|--force-setup) exec pol prod apply --yes ;;
    *) echo "start-prod.sh is retired — running: pol prod guide (full profile). See: pol prod help"; exec pol prod guide ;;
esac

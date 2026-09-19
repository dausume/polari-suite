#!/bin/bash
# polari-jenkins/cache-proxies.sh — tier TWO of the offline-first cache (ci-9).
#
#   cache-proxies.sh up | down | status
#
# Four caching proxies on 127.0.0.1 (docker-compose.proxies.yml): a docker
# pull-through registry, devpi for pip, verdaccio for npm, apt-cacher-ng for
# apt. OFF by default. A PIPELINE NEVER CALLS `up` — only a person does, and
# only after setting CI_CACHE_PROXIES=on in device.env.
#
# The pipeline's only contact with them is `cache.sh build-args`, which probes
# the ports and hands the build PIP_INDEX_URL / NPM_CONFIG_REGISTRY / APT_PROXY
# when they answer and NOTHING when they do not. A build never fails because a
# proxy is down; it just goes to the internet as before.
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cache.sh
source "$J/cache.sh"

COMPOSE_FILE="$J/docker-compose.proxies.yml"
PROJECT=polari-jenkins-cache
compose() { docker compose -f "$COMPOSE_FILE" -p "$PROJECT" "$@"; }

export CI_CACHE_PROXY_DIR="$(cache_area proxies)"
export CACHE_PROXY_REG_PORT CACHE_PROXY_PIP_PORT CACHE_PROXY_NPM_PORT CACHE_PROXY_APT_PORT

row() { printf '  %-14s %-24s %s\n' "$1" "$2" "$3"; }

case "${1:-status}" in
    up)
        if ! cache_proxies_on; then
            echo "CI_CACHE_PROXIES=off in device.env — tier two is deliberately opt-in."
            echo "Turn it on first, so the pipeline knows it may use them:"
            echo "    pol jenkins config                        (see the knob)"
            echo "    CI_CACHE_PROXIES=on in polari-jenkins/device.env"
            echo "Nothing was started."
            exit 3
        fi
        mkdir -p "$CI_CACHE_PROXY_DIR"/{registry,devpi,verdaccio,apt}
        echo "starting the four caching proxies — 127.0.0.1 only, volumes under $CI_CACHE_PROXY_DIR"
        compose up -d
        echo
        bash "$0" status
        ;;
    down)
        compose down
        echo "tier two is down. The tier-one cache directory is untouched — builds keep using it." ;;
    status)
        echo "polari-jenkins cache — TIER TWO (the proxies). CI_CACHE_PROXIES=${CI_CACHE_PROXIES:-off}"
        echo "compose: $COMPOSE_FILE   volumes: $CI_CACHE_PROXY_DIR"
        echo
        row service "bound to (loopback only)" "answering?"
        for pair in "registry:$CACHE_PROXY_REG_PORT" "devpi:$CACHE_PROXY_PIP_PORT" \
                    "verdaccio:$CACHE_PROXY_NPM_PORT" "apt-cacher-ng:$CACHE_PROXY_APT_PORT"; do
            name="${pair%%:*}"; port="${pair##*:}"
            if curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null; then a=yes; else a="no"; fi
            row "$name" "127.0.0.1:$port" "$a"
        done
        echo
        echo "build-args the pipeline would pass right now:"
        ARGS="$(cache_build_args)"
        printf '  %s\n' "${ARGS:-(none — every build goes straight to the public indexes, exactly as before)}"
        ;;
    --help|-h) sed -n '2,20p' "$0" ;;
    *) echo "cache-proxies.sh up|down|status" >&2; exit 2 ;;
esac

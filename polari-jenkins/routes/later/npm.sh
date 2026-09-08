#!/bin/bash
# npm: @polari/pol and @polari/isle from the checked-out CLIs (semver = each repo's VERSION file, ver-1). Needs the @polari org.
source "$(dirname "$0")/../_lib.sh"
need NPM_TOKEN packaging/npm_token
export NPM_CONFIG_USERCONFIG="$(mktemp)"; printf '//registry.npmjs.org/:_authToken=%s\n' "$NPM_TOKEN" > "$NPM_CONFIG_USERCONFIG"
for pkg in polari-cli Isle-Mesh/isle-cli; do
    [ -f "$pkg/package.json" ] || { echo "[$ROUTE] no $pkg/package.json in workspace — run from the release checkout"; continue; }
    run npm publish --access public --workspace "$pkg" --dry-run="$([ "$DRY_RUN" = 1 ] && echo true || echo false)"
done
rm -f "$NPM_CONFIG_USERCONFIG"; record "https://www.npmjs.com/org/polari"

#!/bin/bash
# PyPI: polari-framework (sdist + wheel from polari-rf-node/polari-framework). Version from its VERSION file (ver-1).
source "$(dirname "$0")/../_lib.sh"
need PYPI_TOKEN packaging/pypi_token
SRC=polari-rf-node/polari-framework; [ -f "$SRC/setup.py" ] || { echo "[$ROUTE] $SRC not in workspace"; exit 1; }
run python3 -m pip install -q --user build twine
run python3 -m build --outdir "$POOL_DIR/pypi" "$SRC"
run env TWINE_USERNAME=__token__ TWINE_PASSWORD="$PYPI_TOKEN" python3 -m twine upload --non-interactive "$POOL_DIR"/pypi/*
record "https://pypi.org/project/polari-framework/"

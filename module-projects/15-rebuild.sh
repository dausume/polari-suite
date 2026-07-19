#!/bin/bash
# One staging-backend rebuild + proxy restart + serve-wait — run this
# ONCE after a run of --no-deploy waves, before ./90-verify-all.sh.
source "$(dirname "$0")/lib.sh"
rebuild_backend
say "rebuilt — now run ./90-verify-all.sh"

#!/bin/bash
# polari-jenkins/controller-stamp.sh — what pipeline files the controller was last (re)started with.
#
#   controller-stamp.sh write     after `pol jenkins up`: record the hashes of every file the controller
#                                 consumes at start (the Jenkinsfiles the seed job copies INTO the job
#                                 configs, the Job DSL, casc, and the single-file bind mounts)
#   controller-stamp.sh check     exit 0 when the checkout still matches that record; exit 3 with the
#                                 changed files named when it does not
#
# WHY (found live 2026-09-20, ci-13): a `git pull` on the pipeline device replaced Jenkinsfile.test, the
# promotion ran, and the job executed the PREVIOUS Jenkinsfile — the seed job copies each Jenkinsfile's text
# into the job config when it runs (at `pol jenkins up`), and single-file bind mounts bind an inode. The
# doctor already says "the container is running an OLDER copy" for the file mounts; the stamp makes the same
# fact refuse a promotion, because a run on stale pipeline code is a run whose verdict is about the wrong code.
set -euo pipefail
J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="${CI_CONTROLLER_STAMP:-$J/.controller-stamp}"

stamp_files() {
    ( cd "$J" && ls pipelines/Jenkinsfile.* jobs/*.groovy casc/*.yaml casc/*.txt \
        quiet.sh verdict.py test-wipe.sh selftests.sh cicd-sync.sh device.sh retention.sh scan/scan.sh \
        report.py jsonget.py 2>/dev/null | sort )
}
stamp_hashes() { ( cd "$J" && stamp_files | xargs sha256sum 2>/dev/null ); }

case "${1:-check}" in
    write) stamp_hashes > "$STAMP"; echo "[controller-stamp] $(wc -l < "$STAMP") pipeline files recorded as what the controller started with" ;;
    check)
        [ -s "$STAMP" ] || { echo "[controller-stamp] no record of what the controller started with — run: pol jenkins up"; exit 3; }
        changed="$(diff <(stamp_hashes) "$STAMP" | awk '$1==">"||$1=="<"{print $3}' | sort -u | tr '\n' ' ' || true)"
        if [ -n "$changed" ]; then
            echo "[controller-stamp] the controller was (re)started with DIFFERENT pipeline files — changed since: $changed"
            echo "[controller-stamp] the seed copies Jenkinsfiles into the job configs at start, so a run now would execute the OLD ones → pol jenkins up first"
            exit 3
        fi
        echo "[controller-stamp] the controller runs the pipeline files this checkout holds" ;;
    *) echo "usage: controller-stamp.sh write|check" >&2; exit 2 ;;
esac

#!/bin/bash
# bootstrap-dev.sh — from a bare suite clone to a full development
# checkout, PIECE-WISE. The development flow is:
#
#     git clone https://github.com/dausume/polari-suite.git
#     cd polari-suite && ./bootstrap-dev.sh [piece ...]
#
# With no arguments it pulls every piece; name pieces to pull only what
# you need (each piece is independent — a failure or a private repo you
# can't reach never blocks the rest):
#
#     ./bootstrap-dev.sh --list            show the pieces
#     ./bootstrap-dev.sh polari-rf-node    just the polari node (+ its
#                                          nested framework + angular)
#     ./bootstrap-dev.sh Isle-Mesh         just the isle-mesh project
#
# After pulling, each piece is checked out on its dev branch when the
# recorded pointer matches origin's dev tip; otherwise it stays on the
# recorded (detached) commit with a note — honest about pointers that
# are ahead of what's pushed.
#
# Final step (all-pieces runs only): offers the pol CLI install
# (polari-cli/shells/install-cli.sh) so `pol help` works from here.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G="\033[0;32m"; Y="\033[1;33m"; C="\033[0;36m"; N="\033[0m"
ok(){ echo -e "${G}[ OK ]${N} $*"; }
warn(){ echo -e "${Y}[WARN]${N} $*"; }
step(){ echo; echo -e "${C}==> $*${N}"; }

# piece|note  (pieces = the suite's direct submodules; nested ones ride
# their parent). All sub-projects are PUBLIC repos as of 2026-08-17.
PIECES=(
    "polari-cli|the pol CLI (build/run/test orchestration)"
    "polari-rf-node|polari node: Python/Falcon backend + Angular frontend (nested submodules)"
    "political-scorecard-node|political scorecard frontend+backend"
    "Isle-Mesh|isle-mesh: agents, router, isle CLI, store plumbing"
    "polari-app-shell|native app shells (JavaFX/android/iOS + launcher builders)"
)

list_pieces(){
    echo "pieces:"
    local e; for e in "${PIECES[@]}"; do
        printf '  %-26s %s\n' "${e%%|*}" "${e#*|}"
    done
}

checkout_dev_if_pushed(){  # DIR — dev when pointer == origin/dev, else note
    local dir=$1
    git -C "$dir" fetch -q origin dev 2>/dev/null || true
    local want have
    want=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
    have=$(git -C "$dir" rev-parse origin/dev 2>/dev/null || echo "")
    if [ -n "$have" ] && [ "$want" = "$have" ]; then
        git -C "$dir" checkout -q dev 2>/dev/null && ok "$dir on branch dev"
    else
        warn "$dir stays on the recorded commit (origin/dev is behind or absent — push pending)"
    fi
}

pull_piece(){  # NAME
    local name=$1
    step "$name"
    if ! git config -f "$ROOT/.gitmodules" --get "submodule.$name.url" >/dev/null 2>&1; then
        warn "unknown piece '$name' (see --list)"; return 1
    fi
    local out rc
    out=$(git submodule update --init "$name" 2>&1); rc=$?
    [ -n "$out" ] && printf '%s\n' "$out" | tail -2
    if [ $rc -ne 0 ]; then
        warn "$name could not be pulled (private repo without auth, network,"
        warn "or a pointer not yet pushed to its origin) — continuing"
        return 0
    fi
    ok "$name pulled"
    # nested submodules (polari-rf-node carries framework + angular)
    if [ -f "$ROOT/$name/.gitmodules" ]; then
        git -C "$ROOT/$name" submodule update --init 2>&1 | tail -2
        local sub
        for sub in $(git config -f "$ROOT/$name/.gitmodules" --get-regexp 'submodule\..*\.path' | awk '{print $2}'); do
            checkout_dev_if_pushed "$ROOT/$name/$sub"
        done
    fi
    checkout_dev_if_pushed "$ROOT/$name"
}

cd "$ROOT"
case "${1:-}" in
    --list|-l) list_pieces; exit 0 ;;
esac

if [ $# -gt 0 ]; then
    for p in "$@"; do pull_piece "$p"; done
    exit 0
fi

for e in "${PIECES[@]}"; do pull_piece "${e%%|*}"; done

step "pol CLI"
if command -v pol >/dev/null 2>&1; then
    ok "pol already installed ($(command -v pol))"
elif [ -f "$ROOT/polari-cli/shells/install-cli.sh" ]; then
    if [ -t 0 ]; then
        read -p "Install the pol CLI now? (Y/n): " A
        [[ "$A" =~ ^[Nn] ]] || bash "$ROOT/polari-cli/shells/install-cli.sh"
    else
        echo "   install later: bash polari-cli/shells/install-cli.sh"
    fi
else
    warn "polari-cli not pulled — the pol CLI install lives there"
fi

echo
ok "development checkout ready — README.md is the build/run/test guide"
echo "   suite:            pol suite up --env staging"
echo "   standalone node:  pol node up --env dev|test|staging|prod"
echo "   bundle deb from THIS code (normal debian install route):"
echo "                     ./build-polari-isle-deb.sh"

#!/bin/bash
# get-polari.sh — from a fresh Ubuntu machine to the production guide, in one line.
# Paste this into the machine's terminal (on DigitalOcean: the droplet's browser
# console, no ssh needed):
#
#   curl -fsSL https://raw.githubusercontent.com/dausume/polari-suite/main/get-polari.sh | bash
#
# What it does, in order (every step is idempotent — paste it again if anything
# was interrupted):
#   1. installs the few packages the CLI needs (git, curl, node, whiptail for the menus)
#   2. installs docker from docker's own script, unless it is already there
#   3. gets the Polari suite (branch main, history-free clone) into /opt/polari
#      (or ~/polari for a non-root user) plus the pieces a server needs
#   4. installs the `pol` command
#   5. opens `pol prod bootstrap` — swarm init, then the guided questions
#
# Knobs (environment): POLARI_BRANCH=main|dev   POLARI_DIR=<path>
#   POLARI_PIECES="polari-cli polari-rf-node Isle-Mesh polari-app-shell"   POLARI_NO_DOCKER=1   POLARI_NO_GUIDE=1
set -e
BRANCH="${POLARI_BRANCH:-main}"
PIECES="${POLARI_PIECES:-polari-cli polari-rf-node Isle-Mesh polari-app-shell}"   # the last two only for building the installers (debs)
if [ "$(id -u)" = 0 ]; then DIR="${POLARI_DIR:-/opt/polari}"; SUDO=""; else DIR="${POLARI_DIR:-$HOME/polari}"; SUDO="sudo"; fi
G="\033[0;32m"; Y="\033[1;33m"; C="\033[0;36m"; N="\033[0m"
ok(){ echo -e "${G}[ OK ]${N} $*"; }; warn(){ echo -e "${Y}[WARN]${N} $*"; }; step(){ echo; echo -e "${C}==> $*${N}"; }

command -v apt-get >/dev/null 2>&1 || { echo "get-polari.sh expects Ubuntu or Debian (apt). On another system: install git, node, docker, then clone https://github.com/dausume/polari-suite and run polari-cli/shells/install-cli.sh"; exit 1; }
[ -n "$SUDO" ] && ! sudo -n true 2>/dev/null && echo "This will ask for your password once (sudo) to install packages."

step "1/5 packages"
export DEBIAN_FRONTEND=noninteractive
# a fresh machine runs its first-boot updates right after login and holds the package lock for minutes —
# say so instead of looking frozen
n=0; while $SUDO fuser /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock >/dev/null 2>&1; do
    [ $n = 0 ] && echo "   waiting for the system's own first-boot package updates to finish (this can take a few minutes) …"
    n=$((n+1)); sleep 5; [ $((n % 12)) = 0 ] && echo "   still waiting ($((n*5))s) — nothing is wrong"
done
echo "   apt-get update …"
$SUDO apt-get update -qq 2>&1 | grep -v "^$" | tail -2 || true
echo "   installing git, node, whiptail, python (a minute or two; the lines below are apt's) …"
$SUDO apt-get install -y -q git curl ca-certificates nodejs whiptail python3 python3-pip python3-venv python3-yaml python3-jinja2 openssl 2>&1 | grep -E "^(Setting up|Unpacking|E:|W:)" | sed 's/^/   /' | tail -n 30
command -v node >/dev/null 2>&1 || { echo "node did not install — run: apt-get install -y nodejs"; exit 1; }
ok "git $(git --version | awk '{print $3}'), node $(node --version), whiptail"

step "2/5 docker"
if [ -n "${POLARI_NO_DOCKER:-}" ]; then warn "skipped (POLARI_NO_DOCKER)"
elif command -v docker >/dev/null 2>&1; then ok "docker already installed: $(docker --version | cut -d, -f1)"
else
    # docker's own script first (current engine, its repo carries every Ubuntu release incl. 26.04 'resolute');
    # if it refuses this release, Ubuntu's own packages (docker.io + the compose v2 plugin) — swarm works on both
    echo "   installing docker from docker's own repository (one to three minutes) …"
    if curl -fsSL https://get.docker.com | $SUDO sh 2>&1 | grep -E "^(\+ sh -c|E:|W:|ERROR)" | sed 's/^/   /' | tail -n 8; command -v docker >/dev/null 2>&1; then
        ok "docker installed (docker's repo): $(docker --version | cut -d, -f1)"
    else
        warn "docker's install script did not work on this release — using Ubuntu's docker.io package instead"
        $SUDO apt-get install -y -qq docker.io docker-compose-v2 docker-buildx >/dev/null
        $SUDO systemctl enable --now docker >/dev/null 2>&1 || true
        ok "docker installed (Ubuntu package): $(docker --version | cut -d, -f1)"
    fi
    [ -n "$SUDO" ] && $SUDO usermod -aG docker "$USER" && warn "added $USER to the docker group — log out and in once for it to apply"
fi

step "3/5 the Polari suite → $DIR (branch $BRANCH)"
if [ -d "$DIR/.git" ]; then
    git -C "$DIR" fetch -q origin "$BRANCH" && git -C "$DIR" checkout -q "$BRANCH" && git -C "$DIR" merge -q --ff-only "origin/$BRANCH" && ok "updated (fast-forward)"
else
    $SUDO mkdir -p "$(dirname "$DIR")"; [ -n "$SUDO" ] && $SUDO chown "$USER" "$(dirname "$DIR")" 2>/dev/null || true
    git clone -q --branch "$BRANCH" --filter=blob:none https://github.com/dausume/polari-suite.git "$DIR" && ok "cloned"
fi
for p in $PIECES; do
    git -C "$DIR" submodule update -q --init --recursive --filter=blob:none "$p" && ok "piece $p"
done

step "4/5 the pol command"
bash "$DIR/polari-cli/shells/install-cli.sh" >/dev/null
hash -r 2>/dev/null || true
if command -v pol >/dev/null 2>&1; then ok "pol installed: $(command -v pol)"; else
    for c in "$HOME/.local/bin" /usr/local/bin; do [ -x "$c/pol" ] && { export PATH="$c:$PATH"; ok "pol installed at $c/pol (this shell's PATH updated)"; break; }; done
    command -v pol >/dev/null 2>&1 || { warn "pol is installed but not on PATH yet — open a new terminal and run: pol prod bootstrap"; exit 0; }
fi

step "4b  the guided screens (Textual, python)"
( cd "$DIR" && pol prod tui-install 2>&1 | tail -1 ) || warn "Textual not installed — the guide uses plain dialogs"

step "5/5 the production guide"
cd "$DIR"
if [ -n "${POLARI_NO_GUIDE:-}" ]; then echo "Next: cd $DIR && pol prod bootstrap"; exit 0; fi
if [ -t 0 ] || [ -e /dev/tty ]; then
    # `curl | bash` leaves stdin as the pipe; the guide's menus need the terminal
    exec pol prod bootstrap </dev/tty
else
    echo "No terminal for the questions. Next: cd $DIR && pol prod bootstrap"
fi

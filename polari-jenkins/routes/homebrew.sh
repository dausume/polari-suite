#!/bin/bash
# Homebrew tap: bump the pol formula in dausume/homebrew-polari to this release's tarball + sha256.
source "$(dirname "$0")/_lib.sh"
need GITHUB_TOKEN github/github_token
export GH_TOKEN="$GITHUB_TOKEN"; TAP=dausume/homebrew-polari; TAG="polari-v$VERSION"
URL="https://github.com/dausume/polari-suite/archive/refs/tags/$TAG.tar.gz"
SHA=$( [ "$DRY_RUN" = 1 ] && echo "<sha256 of $URL>" || curl -fsSL "$URL" | sha256sum | cut -d' ' -f1 )
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
run gh repo clone "$TAP" "$WORK/tap" -- -q
mkdir -p "$WORK/tap/Formula"
cat > "$WORK/tap/Formula/pol.rb" <<RB
class Pol < Formula
  desc "Polari suite CLI (pol)"
  homepage "https://polari-systems.org"
  url "$URL"
  sha256 "$SHA"
  license "GPL-3.0-or-later"
  depends_on "node"
  def install
    libexec.install Dir["polari-cli/*"]
    bin.install_symlink libexec/"index.js" => "pol"
  end
end
RB
run git -C "$WORK/tap" -c user.name=polari-jenkins -c user.email=jenkins@polari-systems.org commit -qam "pol $VERSION" 
run git -C "$WORK/tap" push -q
record "https://github.com/$TAP"

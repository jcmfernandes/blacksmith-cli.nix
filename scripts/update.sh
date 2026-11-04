#!/usr/bin/env bash
# Bump package.nix to the newest Blacksmith CLI release.
#
# Upstream publishes no version index: the only way to learn what
# "latest" is, is to download it and ask it.  Needs curl and nix.
set -euo pipefail

base=https://clireleases.blacksmith.sh/cli
cd "$(dirname "$0")/.."

current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' package.nix)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$base/latest/linux/amd64/blacksmith" -o "$tmp/blacksmith"
echo "$(curl -fsSL "$base/latest/linux/amd64/blacksmith.sha256" | cut -d' ' -f1)  $tmp/blacksmith" |
  sha256sum -c --quiet
chmod +x "$tmp/blacksmith"
latest=$(HOME=$tmp BLACKSMITH_DISABLE_AUTO_UPDATE=1 "$tmp/blacksmith" --version | awk '{print $NF}')

# Also guards against "latest" rolling back to an older release.
if [ "$(printf '%s\n' "$current" "$latest" | sort -V | tail -n1)" = "$current" ]; then
  echo "up to date: $current"
  exit 0
fi

mapfile -t paths < <(sed -n 's/^ *path = "\(.*\)";$/\1/p' package.nix)
for path in "${paths[@]}"; do
  hex=$(curl -fsSL "$base/v$latest/$path/blacksmith.sha256" | cut -d' ' -f1)
  sri=$(nix hash convert --hash-algo sha256 --to sri "$hex")
  sed -i "\|path = \"$path\";|{n;s|hash = \".*\";|hash = \"$sri\";|}" package.nix
done
sed -i "s/^  version = \".*\";$/  version = \"$latest\";/" package.nix

echo "updated: $current -> $latest"

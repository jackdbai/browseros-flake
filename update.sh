#!/usr/bin/env bash
set -euo pipefail

# Get directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# 1. Fetch latest version from GitHub API (releases)
CURL_ARGS=(-s)
if [ -n "${GITHUB_TOKEN:-}" ]; then
  CURL_ARGS+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

echo "Fetching latest BrowserOS releases..."
RELEASES_JSON=$(curl "${CURL_ARGS[@]}" https://api.github.com/repos/browseros-ai/BrowserOS/releases)

# Extract the latest version that has an AppImage asset, separating tag version (urlver) and package version (pkgver)
LATEST_JSON=$(echo "$RELEASES_JSON" | jq -r '[.[] | select(.tag_name | test("^v[0-9]")) | .tag_name as $tag | .assets[] | select(.name | endswith("_x64.AppImage")) | { urlver: ($tag | sub("^v"; "")), pkgver: (.name | capture("BrowserOS_v(?<v>.*)_x64.AppImage").v) }][0]')

if [ -z "$LATEST_JSON" ] || [ "$LATEST_JSON" = "null" ]; then
  echo "Error: Could not retrieve latest version with AppImage asset." >&2
  exit 1
fi

LATEST_URLVER=$(echo "$LATEST_JSON" | jq -r '.urlver')
LATEST_PKGVER=$(echo "$LATEST_JSON" | jq -r '.pkgver')

# 2. Read current versions from package.nix
CURRENT_PKGVER=$(sed -n 's/.*pkgver = "\(.*\)";.*/\1/p' package.nix)
CURRENT_URLVER=$(sed -n 's/.*urlver = "\(.*\)";.*/\1/p' package.nix)

echo "Current in package.nix: pkgver=$CURRENT_PKGVER, urlver=$CURRENT_URLVER"
echo "Latest on GitHub:      pkgver=$LATEST_PKGVER, urlver=$LATEST_URLVER"

if [ "$LATEST_PKGVER" = "$CURRENT_PKGVER" ] && [ "$LATEST_URLVER" = "$CURRENT_URLVER" ]; then
  echo "No update needed."
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "updated=false" >> "$GITHUB_OUTPUT"
  fi
  exit 0
fi

# 3. Update version variables and set hash to dummy in package.nix
echo "Updating package.nix variables..."
sed -i "s/pkgver = \"$CURRENT_PKGVER\";/pkgver = \"$LATEST_PKGVER\";/" package.nix
sed -i "s/urlver = \"$CURRENT_URLVER\";/urlver = \"$LATEST_URLVER\";/" package.nix
sed -i 's/hash = "[^"]*";/hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";/' package.nix

# 4. Run nix-build to get the correct hash
echo "Running nix-build to compute new hash..."
BUILD_OUTPUT=$(nix-build -E 'with import <nixpkgs> {}; callPackage ./package.nix {}' 2>&1 || true)

# Extract hash from the mismatch error
NEW_HASH=$(echo "$BUILD_OUTPUT" | grep 'got:' | grep -o 'sha256-[A-Za-z0-9+/]\{43\}=')

if [ -z "$NEW_HASH" ]; then
  echo "Error: Failed to extract new hash from nix-build output." >&2
  echo "nix-build output was:" >&2
  echo "$BUILD_OUTPUT" >&2
  exit 1
fi

echo "Extracted new hash: $NEW_HASH"

# 5. Replace dummy hash with the correct hash in package.nix
sed -i "s|hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";|hash = \"$NEW_HASH\";|" package.nix

echo "Successfully updated package.nix to pkgver=$LATEST_PKGVER, urlver=$LATEST_URLVER with hash $NEW_HASH."

# Set outputs for GitHub Actions
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "updated=true" >> "$GITHUB_OUTPUT"
  echo "version=$LATEST_PKGVER" >> "$GITHUB_OUTPUT"
fi

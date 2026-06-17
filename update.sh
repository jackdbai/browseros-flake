#!/usr/bin/env bash
set -euo pipefail

# Get directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# 1. Fetch latest version from GitHub API (releases)
# We prioritize GITHUB_TOKEN if it's set to avoid rate limit issues
CURL_ARGS=(-s)
if [ -n "${GITHUB_TOKEN:-}" ]; then
  CURL_ARGS+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

echo "Fetching latest BrowserOS releases..."
RELEASES_JSON=$(curl "${CURL_ARGS[@]}" https://api.github.com/repos/browseros-ai/BrowserOS/releases)

# Extract the latest version that has an AppImage asset
LATEST_VERSION=$(echo "$RELEASES_JSON" | jq -r '[.[] | select(.tag_name | test("^v[0-9]")) | select(.assets[].name | endswith(".AppImage"))][0].tag_name | sub("^v"; "")')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
  echo "Error: Could not retrieve latest version with AppImage asset." >&2
  exit 1
fi

# 2. Read the current version from package.nix
CURRENT_VERSION=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' package.nix)
echo "Current version in package.nix: $CURRENT_VERSION"
echo "Latest version on GitHub: $LATEST_VERSION"

if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
  echo "No update needed."
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "updated=false" >> "$GITHUB_OUTPUT"
  fi
  exit 0
fi

# 3. Update version and set hash to dummy in package.nix
echo "Updating package.nix to version $LATEST_VERSION..."
sed -i "s/version = \"$CURRENT_VERSION\";/version = \"$LATEST_VERSION\";/" package.nix
sed -i 's/hash = "[^"]*";/hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";/' package.nix

# 4. Run nix-build to get the correct hash
echo "Running nix-build to compute new hash..."
# We expect this to fail with hash mismatch
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

echo "Successfully updated package.nix to version $LATEST_VERSION with hash $NEW_HASH."

# Set outputs for GitHub Actions
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "updated=true" >> "$GITHUB_OUTPUT"
  echo "version=$LATEST_VERSION" >> "$GITHUB_OUTPUT"
fi

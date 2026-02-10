#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

# --- Validation ---

if [ -z "$VERSION" ]; then
  echo "Usage: ./release.sh <version>"
  echo "Example: ./release.sh 1.2.0"
  exit 1
fi

if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Error: version must be semver (e.g. 1.2.0), got: $VERSION"
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: working tree has uncommitted changes. Commit or stash them first."
  exit 1
fi

if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "Error: tag v$VERSION already exists."
  exit 1
fi

# --- Update plugin.json files ---

PLUGIN_FILES=$(find plugins -path '*/\.claude-plugin/plugin.json' 2>/dev/null)

if [ -z "$PLUGIN_FILES" ]; then
  echo "Error: no plugin.json files found under plugins/"
  exit 1
fi

echo "Updating version to $VERSION in:"
for f in $PLUGIN_FILES; do
  echo "  $f"
  sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" "$f"
done

# --- Commit and tag ---

git add $PLUGIN_FILES
git commit -m "release v$VERSION"
git tag "v$VERSION"

echo ""
echo "Created commit and tag v$VERSION"

# --- Push prompt ---

echo ""
read -rp "Push commit and tag to origin? [y/N] " PUSH
if [[ "$PUSH" =~ ^[Yy]$ ]]; then
  git push origin HEAD
  git push origin "v$VERSION"
  echo "Pushed to origin."
else
  echo "Skipped push. Run manually:"
  echo "  git push origin HEAD && git push origin v$VERSION"
fi

# --- Summary ---

echo ""
echo "Version state: $(git describe --tags)"

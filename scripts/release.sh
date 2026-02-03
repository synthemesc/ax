#!/bin/bash
set -euo pipefail

# Usage: ./scripts/release.sh 1.0.0

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

TAG="v$VERSION"
REPO="synthemesc/ax"
TAP_DIR="${TAP_DIR:-../homebrew-ax}"

echo "==> Releasing ax $TAG"

# Ensure we're on main and up to date
git checkout main
git pull origin main

# Run tests
echo "==> Running tests..."
./tests/test_ax.sh

# Create and push tag
echo "==> Creating tag $TAG..."
git tag -a "$TAG" -m "Release $VERSION"
git push origin "$TAG"

# Wait for GitHub to process the tag
echo "==> Waiting for GitHub to create release tarball..."
sleep 5

# Get SHA256 of the release tarball
TARBALL_URL="https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz"
echo "==> Fetching SHA256 for $TARBALL_URL..."
SHA256=$(curl -sL "$TARBALL_URL" | shasum -a 256 | cut -d' ' -f1)
echo "SHA256: $SHA256"

# Update the formula
FORMULA="$TAP_DIR/Formula/ax.rb"
if [[ -f "$FORMULA" ]]; then
    echo "==> Updating formula..."
    sed -i '' "s|url \".*\"|url \"$TARBALL_URL\"|" "$FORMULA"
    sed -i '' "s|sha256 \".*\"|sha256 \"$SHA256\"|" "$FORMULA"

    # Commit and push formula update
    cd "$TAP_DIR"
    git add Formula/ax.rb
    git commit -m "Update ax to $VERSION"
    git push origin main
    cd -

    echo "==> Formula updated and pushed!"
else
    echo "==> Formula not found at $FORMULA"
    echo "    Update manually with:"
    echo "    url: $TARBALL_URL"
    echo "    sha256: $SHA256"
fi

echo "==> Release $TAG complete!"
echo ""
echo "Users can now install with:"
echo "  brew tap synthemesc/ax"
echo "  brew install ax"

#!/usr/bin/env bash
# Vercel install step: fetch a pinned Flutter SDK and resolve dependencies.
# Pinned deliberately so CI and local builds cannot drift.
set -euo pipefail

FLUTTER_VERSION="3.41.6"
FLUTTER_HOME="/tmp/flutter"
TARBALL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

echo "==> Downloading Flutter ${FLUTTER_VERSION}"
curl -fsSL "$TARBALL" | tar -xJ -C /tmp --no-same-owner

# The tarball ships a .git dir whose ownership does not match the build user,
# so git's safe.directory check blocks Flutter from reading its own version.
git config --global --add safe.directory "$FLUTTER_HOME"

export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version
flutter pub get

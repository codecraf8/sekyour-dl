#!/usr/bin/env bash
set -euo pipefail

DL="https://github.com/codecraf8/sekyour-dl/releases/latest/download"
OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" = "Darwin" ]; then
  URL="$DL/Sekyour-macOS-AppleSilicon.app.tar.gz"
  [ "$ARCH" != "arm64" ] && URL="$DL/Sekyour-macOS-Intel.app.tar.gz"
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  echo "↓ Downloading Sekyour for macOS ($ARCH)..."
  curl -fSL -o "$TMP/s.tar.gz" "$URL"
  tar -xzf "$TMP/s.tar.gz" -C "$TMP"
  xattr -cr "$TMP/Sekyour.app"
  mkdir -p ~/Applications
  mv "$TMP/Sekyour.app" ~/Applications/
  echo "✓ Installed to ~/Applications/Sekyour.app"
elif [ "$OS" = "Linux" ]; then
  DEST="$HOME/.local/bin"
  mkdir -p "$DEST"
  echo "↓ Downloading Sekyour for Linux..."
  curl -fSL -o "$DEST/sekyour" "$DL/Sekyour-Linux.AppImage"
  chmod +x "$DEST/sekyour"
  echo "✓ Installed to $DEST/sekyour"
  echo "$PATH" | grep -q "$DEST" || echo "⚠ Add to PATH: export PATH=\"$DEST:\$PATH\""
else
  echo "Unsupported: $OS. Use the .exe installer on Windows." >&2
  exit 1
fi

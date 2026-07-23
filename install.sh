#!/usr/bin/env bash
set -euo pipefail

DL="https://github.com/codecraf8/sekyour-dl/releases/latest/download"
OS="$(uname -s)"
ARCH="$(uname -m)"

# --- Linux: install secd daemon (system-level) + UI (user-level) ---
install_secd_linux() {
  if command -v secd >/dev/null 2>&1 && systemctl is-active --quiet secd 2>/dev/null; then
    echo "✓ secd already installed and running"
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    PKG=deb
    INSTALL="sudo apt-get install -y"
  elif command -v dnf >/dev/null 2>&1; then
    PKG=rpm
    INSTALL="sudo dnf install -y"
  elif command -v yum >/dev/null 2>&1; then
    PKG=rpm
    INSTALL="sudo yum install -y"
  else
    echo "✗ No apt/dnf/yum found — install secd manually from GitHub releases" >&2
    return 1
  fi

  echo "↓ Downloading secd daemon..."
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  curl -fSL -o "$TMP/secd.$PKG" "$DL/secd-linux-amd64.$PKG"

  echo "🔒 Installing secd (needs sudo)..."
  $INSTALL "$TMP/secd.$PKG"

  if ! groups "$USER" | grep -qw secd; then
    sudo usermod -aG secd "$USER"
    SECD_NEED_RELOGIN=1
  fi
}

install_ui_linux() {
  DEST="$HOME/.local/bin"
  mkdir -p "$DEST"
  echo "↓ Downloading Sekyour UI..."
  curl -fSL -o "$DEST/sekyour" "$DL/Sekyour-Linux.AppImage"
  chmod +x "$DEST/sekyour"
  echo "✓ UI installed to $DEST/sekyour"
  echo "$PATH" | grep -q "$DEST" || echo "⚠ Add to PATH: export PATH=\"$DEST:\$PATH\""
}

if [ "$OS" = "Linux" ]; then
  install_secd_linux
  echo ""
  install_ui_linux
  echo ""
  if [ "${SECD_NEED_RELOGIN:-0}" = "1" ]; then
    echo ""
    echo "Almost done — one more step:"
    echo "  1. Log out and back in (or reboot) — secd group needs a new session"
    echo "  2. Run: sekyour"
  else
    echo "Done. Run: sekyour"
  fi

elif [ "$OS" = "Darwin" ]; then
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
  echo ""
  echo "⚠ Sekyour needs the secd daemon (Linux only, requires eBPF)."
  echo "  On macOS, the app will start but cannot monitor network traffic."

else
  echo "Unsupported: $OS." >&2
  echo "Windows: download the .exe installer from dl.sekyour.com" >&2
  exit 1
fi

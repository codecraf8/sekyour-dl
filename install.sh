#!/usr/bin/env bash
set -euo pipefail

DL="https://github.com/codecraf8/sekyour-dl/releases/latest/download"
OS="$(uname -s)"
ARCH="$(uname -m)"
NEED_RELOGIN=0
TMP=""

cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT

# ─── Linux ────────────────────────────────────────────────────────────
install_secd_linux() {
  if command -v secd >/dev/null 2>&1 && systemctl is-active --quiet secd 2>/dev/null; then
    echo "  ✓ secd already running"
    return 0
  fi

  if   command -v apt-get >/dev/null 2>&1; then PKG=deb; INSTALL="sudo apt-get install -y"
  elif command -v dnf     >/dev/null 2>&1; then PKG=rpm; INSTALL="sudo dnf install -y"
  elif command -v yum     >/dev/null 2>&1; then PKG=rpm; INSTALL="sudo yum install -y"
  elif command -v zypper  >/dev/null 2>&1; then PKG=rpm; INSTALL="sudo zypper install -y"
  elif command -v pacman  >/dev/null 2>&1; then
    echo "  Arch Linux: install secd from AUR (secd-git) or .deb manually." >&2
    return 0
  else
    echo "  ✗ No package manager found. Download secd manually:" >&2
    echo "    $DL/secd-linux-amd64.deb" >&2
    return 1
  fi

  echo "  ↓ Downloading secd daemon..."
  curl -fSL -o "$TMP/secd.$PKG" "$DL/secd-linux-amd64.$PKG"

  echo "  🔒 Installing secd (needs sudo)..."
  $INSTALL "$TMP/secd.$PKG"

  if ! groups "$USER" | grep -qw secd; then
    sudo usermod -aG secd "$USER"
    NEED_RELOGIN=1
  fi

  sudo systemctl enable --now secd.service 2>/dev/null || true
}

install_ui_linux() {
  local bin="$HOME/.local/bin/sekyour"
  local apps="$HOME/.local/share/applications"
  local icons="$HOME/.local/share/icons/hicolor/512x512/apps"

  mkdir -p "$(dirname "$bin")" "$apps" "$icons"

  echo "  ↓ Downloading Sekyour UI..."
  curl -fSL -o "$bin" "$DL/Sekyour-Linux.AppImage"
  chmod +x "$bin"

  curl -fsSL -o "$icons/sekyour.png" "$DL/sekyour-icon.png" 2>/dev/null || true

  cat > "$apps/sekyour.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Sekyour
Comment=Local-first network observability + AI co-pilot
Exec=$bin
Icon=sekyour
Categories=Network;Security;System;
Terminal=false
StartupWMClass=Sekyour
EOF

  echo "  ✓ UI installed — find it in your application menu"
}

# ─── macOS ────────────────────────────────────────────────────────────
install_macos() {
  local url="$DL/Sekyour-macOS-AppleSilicon.app.tar.gz"
  [ "$ARCH" != "arm64" ] && url="$DL/Sekyour-macOS-Intel.app.tar.gz"

  echo "  ↓ Downloading Sekyour for macOS ($ARCH)..."
  curl -fSL -o "$TMP/s.tar.gz" "$url"
  tar -xzf "$TMP/s.tar.gz" -C "$TMP"
  xattr -cr "$TMP/Sekyour.app"
  mkdir -p ~/Applications
  mv "$TMP/Sekyour.app" ~/Applications/
  echo "  ✓ Installed to ~/Applications/Sekyour.app"
}

# ─── main ─────────────────────────────────────────────────────────────
main() {
  TMP=$(mktemp -d)
  echo ""
  echo "  Sekyour Installer"
  echo "  ─────────────────────────────────"
  echo ""

  case "$OS" in
    Linux)
      echo "  [1/2] Daemon (secd)"
      install_secd_linux
      echo ""
      echo "  [2/2] Desktop App"
      install_ui_linux
      echo ""

      if [ "$NEED_RELOGIN" = "1" ]; then
        echo "  ┌─────────────────────────────────────────────┐"
        echo "  │  ONE MORE STEP: Log out and back in        │"
        echo "  │  (or reboot) for secd group to take effect  │"
        echo "  └─────────────────────────────────────────────┘"
      else
        echo "  ✓ All done. Launch Sekyour from your app menu."
      fi
      ;;

    Darwin)
      install_macos
      echo ""
      echo "  ⚠ secd daemon requires Linux (eBPF)."
      echo "    The app will start but cannot monitor traffic on macOS."
      ;;

    *)
      echo "  Unsupported OS: $OS" >&2
      echo "  Windows: use PowerShell install command from dl.sekyour.com" >&2
      exit 1
      ;;
  esac

  echo ""
}

main "$@"

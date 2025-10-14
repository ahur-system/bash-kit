#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/alikhaleghi/bash-kit"
INSTALL_DIR="/usr/local/bash-kit"
BIN_DIR="/usr/local/bin"
TOOLS_URL="$REPO/raw/master/tools"

usage() {
  cat <<EOF
bash-kit installer

Usage:
  $(basename "$0") @ install [tool1] [tool2] ...
  $(basename "$0") @ list
  $(basename "$0") @ uninstall [tool]
EOF
}

list_tools() {
  echo "[*] Fetching available tools from GitHub..."
  curl -sL "https://api.github.com/repos/alikhaleghi/bash-kit/contents/tools" \
    | grep '"name":' | grep '.sh' | cut -d'"' -f4 | sed 's/.sh$//' | sort
}

install_tool() {
  local tool="$1"
  local target="$INSTALL_DIR/tools/$tool.sh"
  mkdir -p "$INSTALL_DIR/tools"

  echo "[+] Installing tool: $tool"
  if ! curl -fsSL "$TOOLS_URL/$tool.sh" -o "$target"; then
    echo "  ✗ Tool '$tool' not found in repository."
    exit 1
  fi

  chmod +x "$target"
  ln -sf "$target" "$BIN_DIR/$tool"
  echo "  ✓ Linked: $BIN_DIR/$tool"
}

uninstall_tool() {
  local tool="$1"
  echo "[-] Uninstalling $tool..."
  rm -f "$INSTALL_DIR/tools/$tool.sh"
  rm -f "$BIN_DIR/$tool"
  echo "  ✓ Removed."
}

case "${1:-}" in
  @)
    shift
    case "${1:-}" in
      install)
        shift
        if [ $# -eq 0 ]; then
          echo "Available tools:"
          list_tools
          echo ""
          echo "Install one with:"
          echo "  sudo bash -c \"\$(curl -sL $REPO/raw/master/scripts.sh)\" @ install <tool>"
        else
          mkdir -p "$INSTALL_DIR/tools"
          for tool in "$@"; do install_tool "$tool"; done
        fi
        ;;
      list)
        list_tools
        ;;
      uninstall)
        shift
        for tool in "$@"; do uninstall_tool "$tool"; done
        ;;
      *)
        usage ;;
    esac
    ;;
  *)
    usage ;;
esac

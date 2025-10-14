#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/ahur-system/bash-kit"
INSTALL_DIR="/usr/local/bash-kit"
BIN_DIR="/usr/local/bin"
TOOLS_URL="$REPO/raw/main/tools"
TOOLS_API_URL="https://api.github.com/repos/ahur-system/bash-kit/contents/tools"

usage() {
  cat <<EOF
bash-kit installer

Usage:
  curl -sL $REPO/raw/main/scripts.sh | sudo bash -s @ install [tool1] [tool2] ...
  curl -sL $REPO/raw/main/scripts.sh | sudo bash -s @ list
  curl -sL $REPO/raw/main/scripts.sh | sudo bash -s @ uninstall [tool]
EOF
}

list_tools() {
  echo "[*] Fetching available tools from GitHub..."
  echo "[DEBUG] API URL: $TOOLS_API_URL"
  curl -sL "$TOOLS_API_URL" \
    | grep '"type": "dir"' -B2 | grep '"name":' | cut -d'"' -f4 | sort
}

install_tool() {
  local tool="$1"
  local tool_dir="$INSTALL_DIR/tools/$tool"
  local main_script="$tool_dir/$tool.sh"
  local service_name="$tool"

  mkdir -p "$tool_dir"

  echo "[+] Installing tool: $tool"
  echo "[DEBUG] Tool URL: $TOOLS_URL/$tool/$tool.sh"

  # Install main script
  if ! curl -fsSL "$TOOLS_URL/$tool/$tool.sh" -o "$main_script"; then
    echo "  ✗ Tool '$tool' not found in repository."
    exit 1
  fi

  chmod +x "$main_script"
  ln -sf "$main_script" "$BIN_DIR/$tool"
  echo "  ✓ Main script: $BIN_DIR/$tool"

  # Install additional files (systemd, README, etc.)
  local files_installed=0

  # Try to install systemd service
  echo "[DEBUG] systemd service URL: $TOOLS_URL/$tool/systemd/$tool.service"
  if curl -fsSL "$TOOLS_URL/$tool/systemd/$tool.service" -o "$tool_dir/$tool.service" 2>/dev/null; then
    echo "  ✓ systemd service downloaded: $tool_dir/$tool.service"

    # Install and enable systemd service
    cp "$tool_dir/$tool.service" "/etc/systemd/system/$service_name.service"
    systemctl daemon-reload
    systemctl enable "$service_name.service"
    systemctl start "$service_name.service"

    echo "  ✓ systemd service installed and started: $service_name.service"
    files_installed=1
  fi

  # Try to install tool README
  echo "[DEBUG] README URL: $TOOLS_URL/$tool/README.md"
  if curl -fsSL "$TOOLS_URL/$tool/README.md" -o "$tool_dir/README.md" 2>/dev/null; then
    echo "  ✓ Documentation: $tool_dir/README.md"
    files_installed=1
  fi

  if [ $files_installed -eq 1 ]; then
    echo "  → Additional files in: $tool_dir/"
  fi
}

uninstall_tool() {
  local tool="$1"
  local service_name="$tool"

  echo "[-] Uninstalling $tool..."

  # Remove systemd service if it exists
  if [ -f "/etc/systemd/system/$service_name.service" ]; then
    echo "  [-] Stopping and removing systemd service..."
    systemctl stop "$service_name.service" 2>/dev/null || true
    systemctl disable "$service_name.service" 2>/dev/null || true
    rm -f "/etc/systemd/system/$service_name.service"
    systemctl daemon-reload
    echo "  ✓ systemd service removed: $service_name.service"
  fi

  # Remove tool files
  rm -rf "$INSTALL_DIR/tools/$tool"
  rm -f "$BIN_DIR/$tool"
  echo "  ✓ Tool files removed."
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
          echo "  curl -sL $REPO/raw/main/scripts.sh | sudo bash -s @ install <tool>"
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

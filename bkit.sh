#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/ahur-system/bash-kit"
INSTALL_DIR="/usr/local/bash-kit"
BIN_DIR="/usr/local/bin"
TOOLS_URL="$REPO/raw/main/tools"
TOOLS_API_URL="https://api.github.com/repos/ahur-system/bash-kit/contents/tools"
BKIT_URL="$REPO/raw/main/bkit.sh"

usage() {
  cat <<EOF
bash-kit installer

Usage:
  curl -sL $REPO/raw/main/bkit.sh | sudo bash -s @ install [tool1] [tool2] ...
  curl -sL $REPO/raw/main/bkit.sh | sudo bash -s @ list
  curl -sL $REPO/raw/main/bkit.sh | sudo bash -s @ uninstall [tool]

  # Install bkit locally for easier use:
  sudo bash -c "\$(curl -sL $REPO/raw/main/bkit.sh)" @ install bkit

  # Then use locally:
  bkit list
  bkit install proxy_watcher
  bkit uninstall proxy_watcher
EOF
}

list_tools() {
  echo "[*] Fetching available tools from GitHub..."

  local response
  response=$(curl -sL --max-time 5 "$TOOLS_API_URL" 2>/dev/null)
  local curl_exit=$?

  if [ $curl_exit -ne 0 ]; then
    echo "✗ Failed to fetch from GitHub API"
    echo ""
    echo "Available tools:"
    echo "  proxy_watcher"
    return
  fi

  local tools=$(echo "$response" | grep '"name":' | cut -d'"' -f4 | sort)

  if [ -z "$tools" ]; then
    echo "✗ No tools found"
    echo ""
    echo "Available tools:"
    echo "  proxy_watcher"
  else
    echo "$tools"
  fi
}

install_tool() {
  local tool="$1"

  # Special case: installing bkit itself
  if [ "$tool" = "bkit" ]; then
    echo "[+] Installing bkit locally..."
    mkdir -p "$INSTALL_DIR"

    if curl -fsSL "$BKIT_URL" -o "$INSTALL_DIR/bkit.sh"; then
      chmod +x "$INSTALL_DIR/bkit.sh"
      ln -sf "$INSTALL_DIR/bkit.sh" "$BIN_DIR/bkit"
      echo "  ✓ bkit installed: $BIN_DIR/bkit"
      echo "  → Now you can use: bkit list, bkit install <tool>, etc."
      return
    else
      echo "  ✗ Failed to download bkit installer"
      exit 1
    fi
  fi

  # Regular tool installation
  local tool_dir="$INSTALL_DIR/tools/$tool"
  local main_script="$tool_dir/$tool.sh"
  local service_name="$tool"

  mkdir -p "$tool_dir"

  echo "[+] Installing tool: $tool"

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

  # Try to install systemd service (optional)
  if curl -fsSL "$TOOLS_URL/$tool/systemd/$tool.service" -o "$tool_dir/$tool.service" 2>/dev/null; then
    echo "  ✓ systemd service downloaded: $tool_dir/$tool.service"

    # Install and enable systemd service
    if cp "$tool_dir/$tool.service" "/etc/systemd/system/$service_name.service" 2>/dev/null && \
       systemctl daemon-reload 2>/dev/null && \
       systemctl enable "$service_name.service" >/dev/null 2>&1 && \
       systemctl start --no-block "$service_name.service" >/dev/null 2>&1; then

      # Wait a moment and check if service started properly
      sleep 2
      if systemctl is-active --quiet "$service_name.service" 2>/dev/null; then
        echo "  ✓ systemd service installed and started: $service_name.service"
      else
        echo "  ✓ systemd service installed (may need manual start)"
        echo "    Start with: sudo systemctl start $service_name"
      fi
    else
      echo "  ! systemd service downloaded but failed to install"
      echo "    Install manually: sudo cp $tool_dir/$tool.service /etc/systemd/system/"
    fi
    files_installed=1
  fi

  # Try to install tool README
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

  echo "[-] Uninstalling $tool..."

  # Special case: uninstalling bkit itself
  if [ "$tool" = "bkit" ]; then
    rm -f "$INSTALL_DIR/bkit.sh"
    rm -f "$BIN_DIR/bkit"
    echo "  ✓ bkit removed"
    return
  fi

  # Regular tool uninstallation
  local service_name="$tool"

  # Remove systemd service if it exists
  if [ -f "/etc/systemd/system/$service_name.service" ]; then
    echo "  [-] Stopping and removing systemd service..."
    systemctl stop "$service_name.service" >/dev/null 2>&1 || true
    systemctl disable "$service_name.service" >/dev/null 2>&1 || true
    rm -f "/etc/systemd/system/$service_name.service"
    systemctl daemon-reload >/dev/null 2>&1 || true
    echo "  ✓ systemd service removed: $service_name.service"
  fi

  # Remove tool files
  rm -rf "$INSTALL_DIR/tools/$tool"
  rm -f "$BIN_DIR/$tool"
  echo "  ✓ Tool files removed."
}

# Handle different invocation methods
if [ "${1:-}" = "@" ]; then
  # Called with @ (curl | bash -s @ command)
  shift
  COMMAND="${1:-}"
elif [ $# -gt 0 ]; then
  # Called directly (bkit command)
  COMMAND="${1:-}"
else
  # No arguments
  COMMAND=""
fi

case "$COMMAND" in
  install)
    shift 2>/dev/null || shift
    if [ $# -eq 0 ]; then
      echo "Available tools:"
      list_tools
      echo ""
      echo "Install one with:"
      echo "  curl -sL $REPO/raw/main/bkit.sh | sudo bash -s @ install <tool>"
      echo "Or install bkit locally:"
      echo "  sudo bash -c \"\$(curl -sL $REPO/raw/main/bkit.sh)\" @ install bkit"
    else
      mkdir -p "$INSTALL_DIR/tools"
      for tool in "$@"; do install_tool "$tool"; done
    fi
    ;;
  list)
    list_tools
    ;;
  uninstall)
    shift 2>/dev/null || shift
    if [ $# -eq 0 ]; then
      echo "Usage: uninstall <tool>"
      exit 1
    fi
    for tool in "$@"; do uninstall_tool "$tool"; done
    ;;
  *)
    usage ;;
esac

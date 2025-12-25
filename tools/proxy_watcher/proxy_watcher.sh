#!/usr/bin/env bash
# bash-kit tool: proxy_watcher
# Continuously fetches and maintains a list of working free proxies
#
# Version: 0.1.0
# Part of bash-kit: https://github.com/alikhaleghi/bash-kit
# Requires: curl, awk, grep, sort, shuf

set -euo pipefail

# --- CONFIG ---
WORKDIR="$HOME/.local/share/bash-kit/proxy_watcher"
FETCH_INTERVAL_MIN=30          # minutes between fetching new proxies
CHECK_INTERVAL_SEC=60          # seconds between random health checks
MAX_CONCURRENT_CHECKS=10       # concurrent curl checks
CURL_TIMEOUT=6                 # seconds per proxy test
TEST_URL="https://www.google.com"
IP_CHECK_URL="https://api.ipify.org"
SOURCES=(
  "https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=5000&country=all"
  "https://www.proxy-list.download/api/v1/get?type=https"
  "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt"
  "https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies.txt"
)
# --- END CONFIG ---

# --- INITIALIZATION ---

check_dependencies() {
  local deps=("curl" "awk" "grep" "sort" "shuf")
  for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: Required command '$cmd' not found. Please install it first." >&2
      exit 1
    fi
  done
}

validate_ip() {
  local ip="$1"
  # IPv4 validation with octet range checking
  if [[ "$ip" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
    local octet
    for octet in "${BASH_REMATCH[@]:1}"; do
      if (( octet > 255 )); then
        return 1
      fi
    done
    return 0
  fi
  # Basic IPv6 validation
  if [[ "$ip" =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]; then
    return 0
  fi
  return 1
}

log() {
  local level="$1"
  local message="$2"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >&2
}

# --- GNOME PROXY SUPPORT ---

check_gsettings() {
  # Check if gsettings is available and we're in a graphical session
  if command -v gsettings >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ] && [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
    # Test if we can access proxy settings
    if gsettings list-keys org.gnome.system.proxy >/dev/null 2>&1; then
      log "DEBUG" "GNOME gsettings proxy support available"
      return 0
    else
      log "DEBUG" "GNOME gsettings available but proxy schema not accessible"
      return 1
    fi
  else
    log "DEBUG" "GNOME gsettings not available or not in graphical session"
    return 1
  fi
}

set_gsettings_proxy() {
  local proxy="$1"
  local host="${proxy%:*}"
  local port="${proxy#*:}"
  
  log "INFO" "Setting GNOME system proxy: $host:$port"
  
  # Set proxy mode to manual
  gsettings set org.gnome.system.proxy mode 'manual' 2>/dev/null || {
    log "WARN" "Failed to set GNOME proxy mode to manual"
    return 1
  }
  
  # Set HTTP proxy
  gsettings set org.gnome.system.proxy.http host "$host" 2>/dev/null || {
    log "WARN" "Failed to set GNOME HTTP proxy host"
    return 1
  }
  
  gsettings set org.gnome.system.proxy.http port "$port" 2>/dev/null || {
    log "WARN" "Failed to set GNOME HTTP proxy port"
    return 1
  }
  
  # Set HTTPS proxy (use same as HTTP)
  gsettings set org.gnome.system.proxy.https host "$host" 2>/dev/null || {
    log "WARN" "Failed to set GNOME HTTPS proxy host"
    return 1
  }
  
  gsettings set org.gnome.system.proxy.https port "$port" 2>/dev/null || {
    log "WARN" "Failed to set GNOME HTTPS proxy port"
    return 1
  }
  
  # Use same proxy for all protocols
  gsettings set org.gnome.system.proxy use-same-proxy true 2>/dev/null || {
    log "WARN" "Failed to set GNOME use-same-proxy setting"
    return 1
  }
  
  log "INFO" "GNOME system proxy configured successfully"
  return 0
}

unset_gsettings_proxy() {
  log "INFO" "Removing GNOME system proxy settings"
  
  # Set proxy mode to none (disable proxy)
  gsettings set org.gnome.system.proxy mode 'none' 2>/dev/null || {
    log "WARN" "Failed to disable GNOME proxy"
    return 1
  }
  
  log "INFO" "GNOME system proxy disabled"
  return 0
}

get_gsettings_proxy() {
  local mode host port
  mode=$(gsettings get org.gnome.system.proxy mode 2>/dev/null || echo "unknown")
  
  if [ "$mode" = "'manual'" ]; then
    host=$(gsettings get org.gnome.system.proxy.http host 2>/dev/null | tr -d "'" || echo "")
    port=$(gsettings get org.gnome.system.proxy.http port 2>/dev/null || echo "")
    if [ -n "$host" ] && [ -n "$port" ]; then
      echo "$host:$port"
      return 0
    fi
  fi
  
  return 1
}

cleanup() {
  # Kill background jobs
  jobs -p | xargs -r kill 2>/dev/null || true
  log "INFO" "Script interrupted, cleanup completed"
}

trap cleanup EXIT INT TERM

# Check dependencies on startup
check_dependencies

# --- ARGUMENT HANDLING ---
show_usage() {
  echo "Usage: proxy_watcher [healthy|bad|all|set|unset|status|version]"
  echo
  echo "Commands:"
  echo "  healthy    List all working proxies"
  echo "  bad        List all failed proxies with timestamps"
  echo "  all        List all discovered proxies"
  echo "  set        Find and set a working proxy for current session (use eval)"
  echo "  set --system   Find and set a working proxy system-wide (bashrc + GNOME)"
  echo "  unset      Remove proxy from current session immediately"
  echo "  unset --system Remove proxy from system (bashrc + GNOME)"
  echo "  status     Show current proxy configuration and connectivity"
  echo "  version    Show version information"
  echo "  (no args)  Run continuous proxy monitoring (default)"
  echo
  echo "Data directory: $WORKDIR"
}

check_proxy() {
  local proxy="$1"
  curl -s --max-time "$CURL_TIMEOUT" --proxy "http://$proxy" -I "$TEST_URL" -o /dev/null
}

test_proxy_live() {
  local proxy="$1"
  local ip
  ip=$(curl -s --max-time "$CURL_TIMEOUT" --proxy "http://$proxy" "$IP_CHECK_URL" 2>/dev/null)
  if [ -n "$ip" ] && validate_ip "$ip"; then
    log "DEBUG" "Proxy $proxy returned valid IP: $ip"
    return 0
  else
    log "DEBUG" "Proxy $proxy failed IP validation: ${ip:-'no response'}"
    return 1
  fi
}

show_version() {
  echo "proxy_watcher version 0.1.0"
  echo "Part of bash-kit: https://github.com/alikhaleghi/bash-kit"
}

show_status() {
  echo "=== Proxy Status ==="
  
  # Check shell environment variables
  if [ -n "${http_proxy:-}" ] || [ -n "${https_proxy:-}" ]; then
    echo "Shell Environment:"
    [ -n "${http_proxy:-}" ] && echo "  http_proxy: $http_proxy"
    [ -n "${https_proxy:-}" ] && echo "  https_proxy: $https_proxy"
  else
    echo "Shell Environment: No proxy set"
  fi
  
  # Check GNOME system proxy
  if check_gsettings; then
    echo ""
    echo "GNOME System Proxy:"
    local mode
    mode=$(gsettings get org.gnome.system.proxy mode 2>/dev/null | tr -d "'" || echo "unknown")
    echo "  Mode: $mode"
    
    if [ "$mode" = "manual" ]; then
      local current_proxy
      if current_proxy=$(get_gsettings_proxy 2>/dev/null); then
        echo "  Proxy: $current_proxy"
      else
        echo "  Proxy: Not configured"
      fi
    fi
  else
    echo ""
    echo "GNOME System Proxy: Not available"
  fi
  
  # Check if proxy is actually working
  echo ""
  echo "Connectivity Test:"
  if [ -n "${http_proxy:-}" ]; then
    local test_ip
    if test_ip=$(curl -s --max-time 5 --proxy "$http_proxy" "$IP_CHECK_URL" 2>/dev/null); then
      if validate_ip "$test_ip"; then
        echo "  Status: Working (IP: $test_ip)"
      else
        echo "  Status: Failed (invalid response)"
      fi
    else
      echo "  Status: Failed (no response)"
    fi
  else
    echo "  Status: No proxy configured"
  fi
}

set_proxy_session() {
  local proxy="$1"
  # Set GNOME system proxy if available (for Firefox, Chrome, etc.)
  if check_gsettings; then
    set_gsettings_proxy "$proxy" || log "WARN" "Failed to set GNOME system proxy"
  fi
  
  # Output to stderr for user info
  log "INFO" "Proxy found: $proxy"
  echo "# [+] Run: eval \"\$(proxy_watcher set)\" to apply" >&2
  
  # Output actual export commands to stdout for eval
  echo "export http_proxy=\"http://$proxy\""
  echo "export https_proxy=\"http://$proxy\""
  echo "export HTTP_PROXY=\"http://$proxy\""
  echo "export HTTPS_PROXY=\"http://$proxy\""
}

set_proxy_system() {
  local proxy="$1"
  local bashrc="$HOME/.bashrc"
  local backup="$bashrc.proxy_watcher.backup"

  # Create backup
  if [ -f "$bashrc" ]; then
    cp "$bashrc" "$backup"
    log "INFO" "Created backup of .bashrc at $backup"
  fi

  # Remove only proxy_watcher settings
  sed -i '/# proxy_watcher proxy settings/,/# End proxy_watcher settings/d' "$bashrc" 2>/dev/null || true

  # Add new proxy settings with clear markers
  {
    echo ""
    echo "# proxy_watcher proxy settings"
    echo "export http_proxy=\"http://$proxy\""
    echo "export https_proxy=\"http://$proxy\""
    echo "export HTTP_PROXY=\"http://$proxy\""
    echo "export HTTPS_PROXY=\"http://$proxy\""
    echo "# End proxy_watcher settings"
  } >> "$bashrc"

  # Set GNOME system proxy if available (for Firefox, Chrome, etc.)
  if check_gsettings; then
    set_gsettings_proxy "$proxy" || log "WARN" "Failed to set GNOME system proxy"
  fi

  log "INFO" "Proxy set system-wide in $bashrc: $proxy"
  echo "[+] Run 'source ~/.bashrc' or start a new terminal to apply"
}

unset_proxy_session() {
  # Check if proxy variables exist in current session and warn user
  local found_vars=()
  [ -n "${http_proxy:-}" ] && found_vars+=("http_proxy")
  [ -n "${https_proxy:-}" ] && found_vars+=("https_proxy")
  [ -n "${HTTP_PROXY:-}" ] && found_vars+=("HTTP_PROXY")
  [ -n "${HTTPS_PROXY:-}" ] && found_vars+=("HTTPS_PROXY")
  
  if [ ${#found_vars[@]} -gt 0 ]; then
    log "WARN" "Proxy environment variables detected in current session:"
    printf "  %s\n" "${found_vars[@]}" >&2
    log "INFO" "To remove them from your current session, run:"
    echo "  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY" >&2
  fi
  
  # Unset GNOME system proxy if available
  if check_gsettings; then
    unset_gsettings_proxy || log "WARN" "Failed to unset GNOME system proxy"
  fi
  
  # Execute immediately for direct use
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
  log "INFO" "Shell proxy variables unset from current session"
}

unset_proxy_system() {
  local bashrc="$HOME/.bashrc"

  # Remove only proxy_watcher settings using markers
  sed -i '/# proxy_watcher proxy settings/,/# End proxy_watcher settings/d' "$bashrc" 2>/dev/null || true

  # Unset GNOME system proxy if available
  if check_gsettings; then
    unset_gsettings_proxy || log "WARN" "Failed to unset GNOME system proxy"
  fi

  log "INFO" "Proxy removed from $bashrc"
  echo "[+] Run 'source ~/.bashrc' or start a new terminal to apply"
}

cmd_set() {
  local system_wide=false

  if [ "$#" -eq 1 ] && [ "$1" = "--system" ]; then
    system_wide=true
  elif [ "$#" -gt 0 ]; then
    echo "Error: Invalid arguments for 'set' command"
    echo "Usage: proxy_watcher set [--system]"
    exit 1
  fi

  # Ensure data directory exists
  mkdir -p "$WORKDIR"
  cd "$WORKDIR" || exit 1

  if [ ! -f healthy.txt ] || [ ! -s healthy.txt ]; then
    echo "[-] No healthy proxies found. Run 'proxy_watcher' to start monitoring first." >&2
    exit 1
  fi

  echo "[*] Testing proxies for live connectivity..." >&2

  while read -r proxy; do
    echo "[*] Testing $proxy..." >&2
    if test_proxy_live "$proxy"; then
      echo "[OK] $proxy is working!" >&2

      if [ "$system_wide" = true ]; then
        set_proxy_system "$proxy"
      else
        set_proxy_session "$proxy"
      fi

      exit 0
    else
      log "WARN" "$proxy failed live test, moving to bad list"
      echo "$(date '+%F %T') $proxy" >> bad.txt
      # Safer approach: use grep -v with temp file
      if [ -f healthy.txt ]; then
        grep -vxF "$proxy" healthy.txt > healthy.txt.tmp && mv healthy.txt.tmp healthy.txt
      fi
    fi
  done < healthy.txt

  echo "[-] No working proxy found. All proxies failed." >&2
  exit 1
}

cmd_unset() {
  local system_wide=false

  if [ "$#" -eq 1 ] && [ "$1" = "--system" ]; then
    system_wide=true
  elif [ "$#" -gt 0 ]; then
    echo "Error: Invalid arguments for 'unset' command"
    echo "Usage: proxy_watcher unset [--system]"
    echo "  --system    Remove from .bashrc and GNOME system proxy"
    exit 1
  fi

  if [ "$system_wide" = true ]; then
    unset_proxy_system
  else
    unset_proxy_session
  fi
}

list_proxies() {
  local type="$1"
  # Ensure data directory exists
  mkdir -p "$WORKDIR"
  cd "$WORKDIR" || exit 1
  case "$type" in
    healthy)
      if [ -f healthy.txt ] && [ -s healthy.txt ]; then
        echo "[+] Working proxies ($(wc -l < healthy.txt)):"
        cat healthy.txt
      else
        echo "[-] No healthy proxies found. Run proxy_watcher to start monitoring."
      fi
      ;;
    bad)
      if [ -f bad.txt ] && [ -s bad.txt ]; then
        echo "[+] Failed proxies with timestamps ($(wc -l < bad.txt)):"
        cat bad.txt
      else
        echo "[-] No bad proxies logged yet."
      fi
      ;;
    all)
      if [ -f all.txt ] && [ -s all.txt ]; then
        echo "[+] All discovered proxies ($(wc -l < all.txt)):"
        cat all.txt
      else
        echo "[-] No proxy list found. Run proxy_watcher to fetch proxies."
      fi
      ;;
    *)
      echo "Error: Invalid argument '$type'"
      show_usage
      exit 1
      ;;
  esac
}

fetch_proxies() {
  log "INFO" "Fetching fresh proxy lists..."
  local TMP
  TMP="$(mktemp)" || {
    log "ERROR" "Failed to create temporary file"
    return 1
  }
  
  for url in "${SOURCES[@]}"; do
    log "DEBUG" "Fetching from: $url"
    curl -s --max-time 10 "$url" >>"$TMP" || true
  done
  
  # Improved proxy validation with stricter regex
  grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{2,5}' "$TMP" | \
  while read -r proxy; do
    # Validate IP ranges
    local ip="${proxy%:*}"
    if validate_ip "$ip"; then
      echo "$proxy"
    fi
  done | sort -u > all.txt
  
  rm -f "$TMP"
  local count
  count=$(wc -l < all.txt 2>/dev/null || echo "0")
  log "INFO" "Got $count unique proxies with valid IP ranges."
}

update_health() {
  local p="$1"
  local result
  result=0
  
  if check_proxy "$p"; then
    # File locking for healthy.txt operations
    (
      flock -x 200
      grep -qxF "$p" healthy.txt || echo "$p" >> healthy.txt
    ) 200>"$WORKDIR/healthy.txt.lock"
    log "DEBUG" "OK: $p"
    result=0
  else
    # File locking for bad.txt operations
    (
      flock -x 201
      echo "$(date '+%F %T') $p" >> bad.txt
    ) 201>"$WORKDIR/bad.txt.lock"
    
    # Remove from healthy.txt with locking
    if [ -f healthy.txt ]; then
      (
        flock -x 200
        grep -vxF "$p" healthy.txt > healthy.txt.tmp && mv healthy.txt.tmp healthy.txt 2>/dev/null || true
      ) 200>"$WORKDIR/healthy.txt.lock"
    fi
    log "DEBUG" "BAD: $p"
    result=1
  fi
  
  return $result
}

random_health_check() {
  if [ ! -s healthy.txt ]; then return; fi
  # pick random subset
  mapfile -t sample < <(shuf -n 10 healthy.txt 2>/dev/null || cat healthy.txt)
  for p in "${sample[@]}"; do
    update_health "$p" &
    # limit concurrency
    while (( $(jobs -rp | wc -l) >= MAX_CONCURRENT_CHECKS )); do sleep 0.2; done
  done
  wait
}

main_loop() {
  local last_fetch=0
  while true; do
    now=$(date +%s)
    if (( now - last_fetch > FETCH_INTERVAL_MIN * 60 )); then
      fetch_proxies
      last_fetch=$now
      # Check all newly fetched ones
      echo "[*] Checking new proxies..."
      while read -r p; do
        update_health "$p" &
        while (( $(jobs -rp | wc -l) >= MAX_CONCURRENT_CHECKS )); do sleep 0.2; done
      done < all.txt
      wait
      echo "[+] Health list updated: $(wc -l < healthy.txt) working proxies."
    fi
    echo "[*] Random recheck of existing healthy proxies..."
    random_health_check
    echo "[*] Sleeping ${CHECK_INTERVAL_SEC}s..."
    sleep "$CHECK_INTERVAL_SEC"
  done
}

# Handle command line arguments
if [ $# -ge 1 ]; then
  case "$1" in
    healthy|bad|all)
      list_proxies "$1"
      exit 0
      ;;
    set)
      shift
      cmd_set "$@"
      exit 0
      ;;
    unset)
      shift
      cmd_unset "$@"
      exit 0
      ;;
    status)
      show_status
      exit 0
      ;;
    version)
      show_version
      exit 0
      ;;
    -h|--help|help)
      show_usage
      exit 0
      ;;
    *)
      echo "Error: Unknown argument '$1'"
      show_usage
      exit 1
      ;;
  esac
fi

# No arguments - run main loop
# Ensure data directory exists and initialize files
mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1
touch healthy.txt bad.txt all.txt

main_loop

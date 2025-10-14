#!/usr/bin/env bash
# bash-kit tool: proxy_watcher
# Continuously fetches and maintains a list of working free proxies
#
# Part of bash-kit: https://github.com/alikhaleghi/bash-kit
# Requires: curl, awk, grep, sort, shuf

set -euo pipefail

# --- CONFIG ---
WORKDIR="/tmp/proxy_watcher"
FETCH_INTERVAL_MIN=30          # minutes between fetching new proxies
CHECK_INTERVAL_SEC=60          # seconds between random health checks
MAX_CONCURRENT_CHECKS=10       # concurrent curl checks
CURL_TIMEOUT=6                 # seconds per proxy test
TEST_URL="https://www.google.com"
SOURCES=(
  "https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=5000&country=all"
  "https://www.proxy-list.download/api/v1/get?type=https"
  "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt"
  "https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies.txt"
)
# --- END CONFIG ---

mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1
touch healthy.txt bad.txt all.txt

fetch_proxies() {
  echo "[+] Fetching fresh proxy lists..."
  TMP="$(mktemp)"
  for url in "${SOURCES[@]}"; do
    curl -s --max-time 10 "$url" >>"$TMP" || true
  done
  grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{2,5}' "$TMP" \
    | sort -u > all.txt
  rm -f "$TMP"
  echo "[+] Got $(wc -l < all.txt) unique proxies."
}

check_proxy() {
  local proxy="$1"
  curl -s --max-time "$CURL_TIMEOUT" --proxy "http://$proxy" -I "$TEST_URL" -o /dev/null
}

update_health() {
  local p="$1"
  if check_proxy "$p"; then
    grep -qxF "$p" healthy.txt || echo "$p" >> healthy.txt
    echo "[OK] $p"
  else
    echo "$(date '+%F %T') $p" >> bad.txt
    sed -i "/^$p$/d" healthy.txt
    echo "[BAD] $p"
  fi
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

main_loop

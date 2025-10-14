# proxy_watcher

Continuously fetches and maintains a list of working free proxies.

## Features

- ✅ **Multi-source fetching** - Pulls from 4+ public proxy lists
- ✅ **Health monitoring** - Tests proxies against Google with configurable timeout
- ✅ **Smart caching** - Keeps working proxies in `healthy.txt`
- ✅ **Dead proxy logging** - Timestamped failures in `bad.txt`
- ✅ **Randomized testing** - Avoids predictable patterns
- ✅ **Concurrent checks** - Configurable parallel testing (default: 10)
- ✅ **Continuous operation** - Runs forever with configurable intervals

## Installation

```bash
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install proxy_watcher
```

## Usage

### Manual Run
```bash
proxy_watcher
```

### Background Run
```bash
nohup proxy_watcher >/tmp/proxy_watcher.log 2>&1 &
```

### systemd Service (Automatic)
```bash
# Installation automatically installs and starts the systemd service
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install proxy_watcher

# Check status
sudo systemctl status proxy_watcher
sudo journalctl -u proxy_watcher -f

# Manual control (if needed)
sudo systemctl stop proxy_watcher
sudo systemctl restart proxy_watcher
```

## Uninstallation
```bash
# Completely removes tool and systemd service
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ uninstall proxy_watcher
```

## Configuration

Edit the script to modify these settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `FETCH_INTERVAL_MIN` | 30 | Minutes between fetching new proxy lists |
| `CHECK_INTERVAL_SEC` | 60 | Seconds between random health checks |
| `MAX_CONCURRENT_CHECKS` | 10 | Parallel proxy tests |
| `CURL_TIMEOUT` | 6 | Seconds per proxy test |
| `TEST_URL` | https://www.google.com | URL to test proxies against |

## Files Created

**All runs:** Files created in `/usr/local/bash-kit/tools/proxy_watcher/data/`

- **`healthy.txt`** - Always up-to-date working proxies (one per line)
- **`bad.txt`** - Failed proxies with timestamps
- **`all.txt`** - Latest raw proxy list from all sources

## Proxy Sources

Currently fetches from:
- ProxyScrape API (HTTP)
- Proxy-List Download API (HTTPS)
- TheSpeedX GitHub (HTTP)
- Proxifly GitHub (mixed)

## Requirements

- `curl` - For fetching and testing proxies
- `awk`, `grep`, `sort`, `shuf` - Standard GNU utilities
- Bash 4.0+

## Output Format

```
[+] Fetching fresh proxy lists...
[+] Got 1247 unique proxies.
[*] Checking new proxies...
[OK] 192.168.1.1:8080
[BAD] 10.0.0.1:3128
[+] Health list updated: 23 working proxies.
[*] Random recheck of existing healthy proxies...
[*] Sleeping 60s...
```

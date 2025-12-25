# proxy_watcher v0.1.0

Continuously fetches and maintains a list of working free proxies.

## Features

- ✅ **Multi-source fetching** - Pulls from 4+ public proxy lists
- ✅ **Health monitoring** - Tests proxies against Google with configurable timeout
- ✅ **Smart caching** - Keeps working proxies in `healthy.txt`
- ✅ **Dead proxy logging** - Timestamped failures in `bad.txt`
- ✅ **Randomized testing** - Avoids predictable patterns
- ✅ **Concurrent checks** - Configurable parallel testing (default: 10)
- ✅ **Continuous operation** - Runs forever with configurable intervals
- 🆕 **Proxy management** - Set/unset proxies for session or system-wide
- 🆕 **Enhanced IP validation** - Validates IP ranges and supports IPv6
- 🆕 **File locking** - Prevents race conditions during concurrent operations
- 🆕 **Dependency checking** - Verifies required tools are available
- 🆕 **Safe .bashrc editing** - Creates backups, targets only proxy_watcher settings
- 🆕 **Signal handling** - Graceful shutdown and cleanup
- 🆕 **User-writable data** - No root privileges required
- 🆕 **GNOME proxy support** - Configures system proxy for Firefox, Chrome, etc.
- 🆕 **Smart detection** - Automatically detects desktop environments with gsettings
- 🆕 **Cross-platform** - Works on servers without breaking when gsettings unavailable
- 🆕 **Status command** - Shows current proxy configuration and connectivity

## Installation

```bash
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install proxy_watcher
```

## Usage

### Continuous Monitoring (Default)
```bash
proxy_watcher
```

### List Proxies
```bash
# List all working proxies
proxy_watcher healthy

# List all failed proxies with timestamps
proxy_watcher bad

# List all discovered proxies
proxy_watcher all
```

### Set/Unset Proxies
```bash
# Find and set a working proxy for current session
# Sets shell environment + GNOME system proxy (for Firefox, Chrome, etc.)
eval "$(proxy_watcher set)"

# Find and set a working proxy system-wide (persists across sessions)
# Sets .bashrc + GNOME system proxy
proxy_watcher set --system

# Remove proxy from current session (executes immediately)
# Removes shell environment + GNOME system proxy
proxy_watcher unset
# Note: If proxy vars were set with eval, you may need to manually run:
# unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

# Remove proxy from system (both current and future sessions)
proxy_watcher unset --system
```

### Proxy Status
```bash
# Check current proxy configuration and connectivity
proxy_watcher status
```

### Version Information
```bash
# Show version
proxy_watcher version
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
| `IP_CHECK_URL` | https://api.ipify.org | URL to test proxy IP detection (reliable) |
| `WORKDIR` | $HOME/.local/share/bash-kit/proxy_watcher | Directory for proxy data files |

## Files Created

**All runs:** Files created in `$HOME/.local/share/bash-kit/proxy_watcher/`

- **`healthy.txt`** - Always up-to-date working proxies (one per line)
- **`bad.txt`** - Failed proxies with timestamps
- **`healthy.txt.lock`** - File lock for concurrent access to healthy.txt
- **`bad.txt.lock`** - File lock for concurrent access to bad.txt
- **`all.txt`** - Latest raw proxy list from all sources

**System-wide settings:**
- **`$HOME/.bashrc.proxy_watcher.backup`** - Backup of original .bashrc (created when using --system)

### Viewing Data Files
Instead of manually accessing files, use the built-in listing commands:
```bash
# View working proxies
proxy_watcher healthy

# View failed proxies with failure times
proxy_watcher bad  

# View all discovered proxies
proxy_watcher all
```

**Manual file access:**
```bash
ls -la ~/.local/share/bash-kit/proxy_watcher/
cat ~/.local/share/bash-kit/proxy_watcher/healthy.txt
```

## Proxy Sources

Currently fetches from:
- ProxyScrape API (HTTP)
- Proxy-List Download API (HTTPS)
- TheSpeedX GitHub (HTTP)
- Proxifly GitHub (mixed)

## Requirements

- `curl` - For fetching and testing proxies
- `awk`, `grep`, `sort`, `shuf` - Standard GNU utilities
- `flock` - For file locking (usually included with util-linux)
- Bash 4.0+

**Note:** The script automatically checks for all dependencies on startup.

## Output Format

### Continuous Monitoring Mode
```
[2025-12-25 21:09:36] [INFO] Fetching fresh proxy lists...
[2025-12-25 21:09:36] [INFO] Got 1247 unique proxies with valid IP ranges.
[*] Checking new proxies...
[2025-12-25 21:09:40] [DEBUG] OK: 192.168.1.1:8080
[2025-12-25 21:09:41] [DEBUG] BAD: 10.0.0.1:3128
[+] Health list updated: 23 working proxies.
[*] Random recheck of existing healthy proxies...
[*] Sleeping 60s...
```

### Listing Commands
```bash
$ proxy_watcher healthy
[+] Working proxies (23):
192.168.1.1:8080
203.0.113.5:3128
...
```

## Troubleshooting

### Q: I ran `proxy_watcher unset` but `curl` still uses the proxy
**A:** This happens when proxy environment variables were set with `eval "$(proxy_watcher set)"`. The unset command runs in a subprocess and doesn't affect your current terminal session. Manually run:
```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
```

### Q: Firefox doesn't use the proxy I set
**A:** Make sure GNOME gsettings is available and you're in a graphical session. The script automatically configures GNOME system proxy for desktop browsers. Check with:
```bash
proxy_watcher status
```

### Q: The script says "No proxy configured" but my terminal still uses proxy
**A:** See the first Q/A - this is a shell session issue, not a script issue.

### Q: Manual IP checking with `curl ipinfo.io/ip` shows different IP than script
**A:** `ipinfo.io/ip` is unreliable. Use reliable IP detection services:
```bash
curl https://api.ipify.org        # ✅ Reliable (script default)
curl https://icanhazip.com       # ✅ Reliable
curl https://checkip.amazonaws.com # ✅ Reliable
# curl https://ipinfo.io/ip       # ❌ Unreliable (don't use)
```

## Version History

### v0.1.0 (Current)
- 🆕 Added proxy setting/unsetting functionality for session and system-wide use
- 🆕 Added version command and proper versioning
- 🆕 Enhanced IP validation with octet range checking and IPv6 support
- 🆕 Added file locking to prevent race conditions during concurrent operations
- 🆕 Added dependency checking for all required commands
- 🆕 Implemented safe .bashrc modification with backup creation
- 🆕 Added signal handling for graceful shutdown and cleanup
- 🆕 Improved proxy format validation with stricter regex patterns
- 🆕 Added comprehensive logging with timestamps and log levels
- 🔧 Changed data directory to user-writable location (`$HOME/.local/share/bash-kit/proxy_watcher`)
- 🔧 Removed duplicate function definitions
- 🔧 Fixed unsafe regex escaping in proxy removal operations
- 🔧 Improved error handling and user feedback throughout the script
- 🔧 Added GNOME gsettings integration for desktop browsers (Firefox, Chrome)
- 🔧 Added automatic desktop environment detection with graceful fallback
- 🔧 Added warning for persistent proxy environment variables in shell sessions

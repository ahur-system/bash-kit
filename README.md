# 🧰 bash-kit

**bash-kit** is a lightweight, modular toolkit of Bash utilities — easily installable via a single command.

---

## 🚀 Quick Install

```bash
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install
```

This will list available tools.

Or install directly:

```bash
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install proxy_watcher
```

## 🔧 Available Tools

| Tool | Description | Version |
|------|-------------|---------|
| **proxy_watcher** | Continuously fetches and maintains a list of working free proxies | v0.1.0 |
| **dirstat** | Analyzes directory and filesystem usage with optional recursive tree view | - |

## 🧩 Usage Examples

```bash
# List all available tools
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ list

# Install bkit locally for easier use
sudo bash -c "$(curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh)" @ install bkit

# Then use locally:
bkit list
bkit install proxy_watcher
bkit uninstall proxy_watcher

# Or use directly without installing:
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install proxy_watcher

# Check running service
sudo systemctl status proxy_watcher
```

## 📁 Directory Structure

```
bash-kit/
├── bkit.sh              # Universal installer/manager
└── tools/
    ├── proxy_watcher/
    │   ├── proxy_watcher.sh      # Main script
    │   ├── README.md             # Tool documentation
    │   └── systemd/
    │       ├── proxy-watcher.service
    │       └── README.md
    └── dirstat/
        ├── dirstat.sh            # Main script
        └── README.md             # Tool documentation
```

## 🛠️ Tool Details

### proxy_watcher v0.1.0

Continuously fetches and maintains a list of working free proxies with enhanced management capabilities.

**Features:**
- Multi-source proxy fetching from 4+ public lists
- Real-time health monitoring with configurable timeouts
- Smart caching with `healthy.txt` and timestamped `bad.txt`
- Randomized testing to avoid detection patterns
- Concurrent checks for faster validation
- **NEW:** Proxy setting/unsetting for session or system-wide use
- **NEW:** Enhanced IP validation (IPv4/IPv6, octet range checking)
- **NEW:** File locking to prevent race conditions
- **NEW:** Safe .bashrc modification with backup creation
- **NEW:** Dependency checking and signal handling
- **NEW:** User-writable data directory (no root required)
- **NEW:** Comprehensive logging with timestamps
- **NEW:** GNOME proxy support for desktop browsers (Firefox, Chrome)
- **NEW:** Smart desktop environment detection with server compatibility
- **NEW:** Status command for proxy configuration and connectivity
- **NEW:** Version command and proper versioning

**Files created:**
- **Data:** `$HOME/.local/share/bash-kit/proxy_watcher/` directory
  - `healthy.txt` → always-up-to-date working proxies  
  - `bad.txt` → failed proxies with timestamps
  - `all.txt` → latest fetched raw proxy list
  - `*.lock` → file locks for concurrent access
- **Backup:** `$HOME/.bashrc.proxy_watcher.backup` (when using --system)

**Usage:**
```bash
# Install and auto-start as systemd service
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install proxy_watcher

# Basic proxy operations
proxy_watcher healthy    # List working proxies
proxy_watcher bad        # List failed proxies
proxy_watcher all        # List all discovered proxies

# Set/unset proxies (works with shell + GNOME system proxy)
eval "$(proxy_watcher set)"           # Set for current session
proxy_watcher set --system          # Set system-wide
proxy_watcher unset                  # Remove from session (immediate)
proxy_watcher unset --system         # Remove system-wide

# Status and version
proxy_watcher status     # Show proxy configuration and connectivity
proxy_watcher version    # Show version info
proxy_watcher help       # Show usage

# Manual IP checking (use reliable services)
curl https://api.ipify.org        # ✅ Reliable (script default)
curl https://icanhazip.com       # ✅ Reliable
# curl https://ipinfo.io/ip       # ❌ Unreliable (don't use)

# Check service status
sudo systemctl status proxy_watcher
```

### dirstat

Analyzes directory and filesystem usage with optional recursive tree view for quick disk space analysis.

**Features:**
- Shows filesystem total, used, and available space
- Calculates directory usage as percentage of filesystem
- Recursive tree view of subdirectories sorted by size
- Human-readable size formatting (B/K/M/G/T)
- Handles paths with spaces gracefully
- Uses only standard Linux utilities
- Visual tree structure with emojis

**Usage:**
```bash
# Install dirstat
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install dirstat

# Basic directory analysis
dirstat /home

# Recursive tree view
dirstat -r /var/log

# Current directory
dirstat

# Show help
dirstat --help
```

## 🪄 Philosophy

- **Minimal** — Pure Bash + curl, no external dependencies
- **Modular** — Each tool is standalone and independent  
- **Self-contained** — Clean installation and uninstallation
- **Universal** — Works on any Linux system with Bash

## 📋 Requirements

- Bash 4.0+
- curl
- Standard GNU utilities (awk, grep, sort, etc.)

## 🗂️ Installation Location
**Installation Location**

Tools are installed to:
- **Tool files:** `/usr/local/bash-kit/tools/<tool>/`
- **Executables:** `/usr/local/bin/<tool>` (symlinked)
- **Additional files:** systemd services, documentation, etc.

---

**Made with ❤️ for sysadmins who love simple, effective tools.**
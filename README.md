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

| Tool | Description |
|------|-------------|
| **proxy_watcher** | Continuously fetches and maintains a list of working free proxies |
| **dirstat** | Analyzes directory and filesystem usage with optional recursive tree view |

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

### proxy_watcher

Fetches multiple free proxy lists periodically, tests them, and maintains a `healthy.txt` file with working proxies.

**Features:**
- Keeps working proxies in `healthy.txt`
- Logs dead ones to `bad.txt` (with timestamps)  
- Runs forever in a loop (perfect for systemd service)
- Randomizes testing order
- Pulls from multiple public proxy lists
- All timeouts and intervals configurable
- **Automatic systemd service** - installs and starts on installation

**Files created:**
- **All runs:** `/usr/local/bash-kit/tools/proxy_watcher/data/` directory with proxy files
- `healthy.txt` → always-up-to-date working proxies  
- `bad.txt` → log of failed proxies (with timestamp)
- `all.txt` → latest fetched raw proxy list

**Usage:**
```bash
# Install and auto-start as systemd service
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install proxy_watcher

# Or install bkit locally first:
sudo bash -c "$(curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh)" @ install bkit
bkit install proxy_watcher

# Check service status
sudo systemctl status proxy_watcher

# Manual run (if needed)
nohup proxy_watcher >/tmp/proxy_watcher.log 2>&1 &
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
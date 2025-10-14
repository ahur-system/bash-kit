# 🧰 bash-kit

**bash-kit** is a lightweight, modular toolkit of Bash utilities — easily installable via a single command.

---

## 🚀 Quick Install

```bash
curl -sL https://github.com/ahur-system/bash-kit/raw/main/scripts.sh | sudo bash -s @ install
```

This will list available tools.

Or install directly:

```bash
curl -sL https://github.com/ahur-system/bash-kit/raw/main/scripts.sh | sudo bash -s @ install proxy_watcher
```

## 🔧 Available Tools

| Tool | Description |
|------|-------------|
| **proxy_watcher** | Continuously fetches and maintains a list of working free proxies |

## 🧩 Usage Examples

```bash
# List all available tools
curl -sL https://github.com/ahur-system/bash-kit/raw/main/scripts.sh | sudo bash -s @ list

# Install multiple tools at once (each auto-starts systemd service if available)
curl -sL https://github.com/ahur-system/bash-kit/raw/main/scripts.sh | sudo bash -s @ install proxy_watcher backup_mysql

# Uninstall a tool (stops/removes systemd service automatically)
curl -sL https://github.com/ahur-system/bash-kit/raw/main/scripts.sh | sudo bash -s @ uninstall proxy_watcher

# Check running service
sudo systemctl status proxy_watcher
```

## 📁 Directory Structure

```
bash-kit/
├── scripts.sh           # Universal installer/manager
└── tools/
    └── proxy_watcher/
        ├── proxy_watcher.sh      # Main script
        ├── README.md             # Tool documentation
        └── systemd/
            ├── proxy-watcher.service
            └── README.md
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
- `~/proxy_watcher/all.txt` → latest fetched raw proxy list
- `~/proxy_watcher/healthy.txt` → always-up-to-date working proxies  
- `~/proxy_watcher/bad.txt` → log of failed proxies (with timestamp)

**Usage:**
```bash
# Install and auto-start as systemd service
curl -sL https://github.com/ahur-system/bash-kit/raw/main/scripts.sh | sudo bash -s @ install proxy_watcher

# Check service status
sudo systemctl status proxy_watcher

# Manual run (if needed)
nohup proxy_watcher >/tmp/proxy_watcher.log 2>&1 &
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
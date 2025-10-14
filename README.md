# 🧰 bash-kit

**bash-kit** is a lightweight, modular toolkit of Bash utilities — easily installable via a single command.

---

## 🚀 Quick Install

```bash
sudo bash -c "$(curl -sL https://github.com/alikhaleghi/bash-kit/raw/master/scripts.sh)" @ install
```

This will list available tools.

Or install directly:

```bash
sudo bash -c "$(curl -sL https://github.com/alikhaleghi/bash-kit/raw/master/scripts.sh)" @ install proxy_watcher
```

## 🔧 Available Tools

| Tool | Description |
|------|-------------|
| **proxy_watcher** | Continuously fetches and maintains a list of working free proxies |

## 🧩 Usage Examples

```bash
# List all available tools
sudo bash -c "$(curl -sL https://github.com/alikhaleghi/bash-kit/raw/master/scripts.sh)" @ list

# Install multiple tools at once
sudo bash -c "$(curl -sL https://github.com/alikhaleghi/bash-kit/raw/master/scripts.sh)" @ install proxy_watcher backup_mysql

# Uninstall a tool
sudo bash -c "$(curl -sL https://github.com/alikhaleghi/bash-kit/raw/master/scripts.sh)" @ uninstall proxy_watcher

# Run an installed tool
proxy_watcher
```

## 📁 Directory Structure

```
bash-kit/
├── scripts.sh           # Universal installer/manager
└── tools/
    ├── proxy_watcher.sh
    ├── backup_mysql.sh
    └── sysmedic_agent.sh
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

**Files created:**
- `~/proxy_watcher/all.txt` → latest fetched raw proxy list
- `~/proxy_watcher/healthy.txt` → always-up-to-date working proxies  
- `~/proxy_watcher/bad.txt` → log of failed proxies (with timestamp)

**Background usage:**
```bash
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

Tools are installed to:
- **Scripts:** `/usr/local/bash-kit/tools/`
- **Symlinks:** `/usr/local/bin/` (added to PATH)

---

**Made with ❤️ for sysadmins who love simple, effective tools.**
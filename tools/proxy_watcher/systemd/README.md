# systemd Service for proxy_watcher

This directory contains the systemd service file to run `proxy_watcher` as a system service.

## Automatic Installation

The systemd service is **automatically installed, enabled, and started** when you install the tool:

```bash
curl -sL https://github.com/ahur-system/bash-kit/raw/main/scripts.sh | sudo bash -s @ install proxy_watcher
```

That's it! The service will be running immediately after installation.

## Management Commands

```bash
# Check status
sudo systemctl status proxy_watcher

# View logs
sudo journalctl -u proxy_watcher -f

# Stop service
sudo systemctl stop proxy_watcher

# Restart service
sudo systemctl restart proxy_watcher

# Disable service (won't start on boot)
sudo systemctl disable proxy_watcher
```

## Uninstallation

Complete removal (stops service, disables it, removes all files):

```bash
curl -sL https://github.com/ahur-system/bash-kit/raw/main/scripts.sh | sudo bash -s @ uninstall proxy_watcher
```

## Service Details

- **User:** `nobody` (runs with minimal privileges)
- **Working Directory:** `/tmp/proxy_watcher/`
- **Log Output:** systemd journal (use `journalctl`)
- **Auto-restart:** Yes (if crashes)
- **Memory limit:** 256MB
- **Process limit:** 50 tasks

## Files Location

The service will create files in `/tmp/proxy_watcher/`:
- `healthy.txt` - Working proxies
- `bad.txt` - Failed proxies log
- `all.txt` - Raw proxy lists

## Notes

- Service runs as `nobody` user for security
- Logs are managed by systemd journal
- Automatic restart on failure
- Resource limits prevent runaway processes
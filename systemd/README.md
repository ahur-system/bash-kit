# systemd Service for proxy_watcher

This directory contains the systemd service file to run `proxy_watcher` as a system service.

## Installation

1. **Install the proxy_watcher tool first:**
   ```bash
   sudo bash -c "$(curl -sL https://github.com/alikhaleghi/bash-kit/raw/master/scripts.sh)" @ install proxy_watcher
   ```

2. **Install the systemd service:**
   ```bash
   sudo cp proxy-watcher.service /etc/systemd/system/
   sudo systemctl daemon-reload
   ```

3. **Enable and start the service:**
   ```bash
   sudo systemctl enable proxy-watcher
   sudo systemctl start proxy-watcher
   ```

## Management Commands

```bash
# Check status
sudo systemctl status proxy-watcher

# View logs
sudo journalctl -u proxy-watcher -f

# Stop service
sudo systemctl stop proxy-watcher

# Restart service
sudo systemctl restart proxy-watcher

# Disable service (won't start on boot)
sudo systemctl disable proxy-watcher

# Remove service
sudo systemctl stop proxy-watcher
sudo systemctl disable proxy-watcher
sudo rm /etc/systemd/system/proxy-watcher.service
sudo systemctl daemon-reload
```

## Service Details

- **User:** `nobody` (runs with minimal privileges)
- **Working Directory:** `/home/nobody/proxy_watcher/`
- **Log Output:** systemd journal (use `journalctl`)
- **Auto-restart:** Yes (if crashes)
- **Memory limit:** 256MB
- **Process limit:** 50 tasks

## Files Location

The service will create files in `/home/nobody/proxy_watcher/`:
- `healthy.txt` - Working proxies
- `bad.txt` - Failed proxies log
- `all.txt` - Raw proxy lists

## Notes

- Service runs as `nobody` user for security
- Logs are managed by systemd journal
- Automatic restart on failure
- Resource limits prevent runaway processes
#!/bin/bash

# ==============================================================================
# FINAL BETTER STACK & VECTOR REMOVAL SCRIPT
# Targeted for non-Docker installations (Native Vector/Logtail/Rsyslog)
# ==============================================================================

echo "--- 1. Stopping and Disabling Services ---"
# Vector is the primary engine for modern Better Stack native installs
sudo systemctl stop vector 2>/dev/null || true
sudo systemctl disable vector 2>/dev/null || true

# Legacy Logtail agent
sudo systemctl stop logtail 2>/dev/null || true
sudo systemctl disable logtail 2>/dev/null || true

echo "--- 2. Cleaning up Rsyslog (The 'Sneaky' Reporter) ---"
# Check for common Better Stack rsyslog redirects
REPORTS_TO_CLEAN=(
  "/etc/rsyslog.d/99-logtail.conf"
  "/etc/rsyslog.d/99-betterstack.conf"
  "/etc/rsyslog.d/logtail.conf"
  "/etc/rsyslog.d/22-logtail.conf"
)

for file in "${REPORTS_TO_CLEAN[@]}"; do
  if [ -f "$file" ]; then
    echo "Removing $file..."
    sudo rm "$file"
    RSYSLOG_NEED_RESTART=true
  fi
done

if [ "$RSYSLOG_NEED_RESTART" = true ]; then
  echo "Restarting rsyslog to apply changes..."
  sudo systemctl restart rsyslog
fi

echo "--- 3. Deleting Binaries and Data Directories ---"
# Purge Vector
sudo rm -rf /etc/vector
sudo rm -rf /var/lib/vector
sudo rm -f /usr/bin/vector

# Purge Logtail
sudo rm -rf /etc/logtail
sudo rm -rf /var/lib/logtail
sudo rm -f /usr/bin/logtail

echo "--- 4. Cleaning APT Repositories ---"
sudo rm -f /etc/apt/sources.list.d/logtail.list
sudo rm -f /etc/apt/sources.list.d/better-stack.list
sudo rm -f /etc/apt/sources.list.d/betterstack.list
sudo rm -f /etc/apt/sources.list.d/timber.list

echo "--- 5. System Cleanup ---"
sudo systemctl daemon-reload
sudo apt-get update &>/dev/null # Optional: refresh local cache
sudo apt-get autoremove -y

echo "--- 6. Final Verification ---"
echo "Checking for any remaining connections to Better Stack/Logtail..."
# This checks for open network connections to common log ingestion ports
if sudo ss -tpn | grep -Ei "vector|logtail|betterstack|in.logs.betterstack"; then
  echo "⚠️ Warning: Some connections still appear active. You may need to reboot."
else
  echo "✅ No active connections found. Cleanup successful."
fi

echo "--- Done! ---"

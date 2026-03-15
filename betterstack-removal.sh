#!/bin/bash

# ==============================================================================
# BETTER STACK REMOVAL SCRIPT
# This script stops and removes the Logtail/Better Stack Agent and its configs.
# ==============================================================================

echo "--- Starting Better Stack Cleanup ---"

# 1. Stop and disable the Logtail/Better Stack service
echo "Stopping services..."
sudo systemctl stop logtail 2>/dev/null || true
sudo systemctl disable logtail 2>/dev/null || true
sudo systemctl stop better-stack-agent 2>/dev/null || true
sudo systemctl disable better-stack-agent 2>/dev/null || true

# 2. Remove the packages (Debian/Ubuntu)
echo "Removing agent packages..."
sudo apt-get purge -y logtail 2>/dev/null || true
sudo apt-get purge -y better-stack-agent 2>/dev/null || true
sudo apt-get autoremove -y

# 3. Clean up configuration and log directories
echo "Cleaning up files..."
sudo rm -rf /etc/logtail
sudo rm -rf /var/lib/logtail
sudo rm -rf /etc/better-stack-agent
sudo rm -rf /var/lib/better-stack-agent
sudo rm -f /etc/apt/sources.list.d/logtail.list
sudo rm -f /etc/apt/sources.list.d/better-stack.list

# 4. Remove GPG keys
echo "Removing repository keys..."
sudo apt-key del 41A70337 2>/dev/null || true

echo "--- Cleanup Complete! ---"
echo "Better Stack has been removed. You are ready to deploy Beszel & CrowdSec."

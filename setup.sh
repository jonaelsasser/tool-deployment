#!/bin/bash

# ==============================================================================
# AUTOMATIC FLEET DEPLOYMENT: BESZEL + CROWDSEC
# ==============================================================================

set -e

# --- 1. VALIDATION ---
if [ -z "$BESZEL_KEY" ] || [ -z "$BESZEL_TOKEN" ]|| [ -z "$CROWDSEC_KEY" ]; then
    echo "Error: BESZEL_KEY, BESZEL_TOKEN and CROWDSEC_KEY environment variables are required."
    echo "Usage: BESZEL_KEY=xxx BESZEL_TOKEN=xxx CROWDSEC_KEY=yyy bash deploy_fleet.sh"
    exit 1
fi

echo "--- Starting Automatic Deployment for $(hostname) ---"

# --- 2. INSTALL DOCKER ---
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
fi

# --- 3. DEPLOY BESZEL AGENT (WEB-SOCKET MODE) ---
# We use host mode to get accurate system stats for your 'Single Pane of Glass'
echo "Configuring Beszel Agent..."
sudo mkdir -p /opt/beszel-agent
cat <<EOF | sudo tee /opt/beszel-agent/docker-compose.yml
services:
  beszel-agent:
    image: henrygd/beszel-agent
    container_name: beszel-agent
    restart: unless-stopped
    network_mode: host
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./beszel_agent_data:/var/lib/beszel-agent
      # monitor other disks / partitions by mounting a folder in /extra-filesystems
      # - /mnt/disk/.beszel:/extra-filesystems/sda1:ro
    environment:
      LISTEN: 45876
      KEY: "$BESZEL_KEY"
      TOKEN: "$BESZEL_TOKEN"
      HUB_URL: https://monitoring.elsasser.cloud
      APP_URL: https://monitoring.elsasser.cloud
EOF

cd /opt/beszel-agent
sudo docker compose up -d

# --- 4. INSTALL CROWDSEC (AUTO-BLOCKING) ---
echo "Installing CrowdSec Security Engine..."
curl -s https://install.crowdsec.net | sudo sh
sudo apt-get update
sudo apt-get install -y crowdsec

echo "Installing Firewall Bouncer..."
sudo apt-get install -y crowdsec-firewall-bouncer-iptables

echo "Enrolling in CrowdSec Cloud Console..."
# --overwrite ensures it works even if you run the script twice
sudo cscli console enroll --overwrite "$CROWDSEC_KEY"

# --- 5. FINALIZING ---
sudo systemctl restart crowdsec
sudo systemctl restart crowdsec-firewall-bouncer

echo "-------------------------------------------------------"
echo "✅ DEPLOYMENT SUCCESSFUL"
echo "Beszel: Check your Bunny.net Hub"
echo "CrowdSec: Accept the enrollment at https://app.crowdsec.net"
echo "-------------------------------------------------------"

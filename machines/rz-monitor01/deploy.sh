#!/bin/bash
# ================================================================
# VulnCorp — Machine 6: rz-monitor01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp Monitor (rz-monitor01)  "
echo "============================================="

if ! command -v docker &> /dev/null; then
    echo "[*] Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi

if ! docker compose version &> /dev/null; then
    echo "[*] Installing Docker Compose plugin..."
    apt-get update && apt-get install -y docker-compose-v2
fi

echo "[*] Building and starting rz-monitor01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  rz-monitor01 DEPLOYED SUCCESSFULLY!        "
echo "============================================="
echo "  Nagios (nagiosadmin/nagios): Port 80 (/nagios4)"
echo "  SNMP (public community):     Port 161/udp"
echo "  SSH:                         Port 22"
echo "============================================="

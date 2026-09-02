#!/bin/bash
# ================================================================
# VulnCorp — Machine 5: rz-vpn01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp VPN Server (rz-vpn01)   "
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

echo "[*] Building and starting rz-vpn01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  rz-vpn01 DEPLOYED SUCCESSFULLY!            "
echo "============================================="
echo "  VPN Admin (admin/admin): Port 8443"
echo "  SSH:                     Port 22"
echo "============================================="

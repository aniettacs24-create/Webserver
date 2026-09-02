#!/bin/bash
# ================================================================
# VulnCorp — Machine 10: int-files01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp File Server (int-files01)"
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

echo "[*] Building and starting int-files01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  int-files01 DEPLOYED SUCCESSFULLY!         "
echo "============================================="
echo "  Samba (SMBv1 / Anon): Port 445"
echo "  NFS (no_root_squash): Port 2049"
echo "  SSH:                  Port 22"
echo "============================================="

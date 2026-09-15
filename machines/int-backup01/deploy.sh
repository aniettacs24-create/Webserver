#!/bin/bash
# ================================================================
# VulnCorp — Machine 11: int-backup01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp Backup (int-backup01)   "
echo "============================================="

# Ensure curl is available (some fresh Debian VMs lack it)
if ! command -v curl &> /dev/null; then
    echo "[*] Installing curl..."
    apt-get update -qq && apt-get install -y -qq curl
fi

if ! command -v docker &> /dev/null; then
    echo "[*] Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi

if ! docker compose version &> /dev/null; then
    echo "[*] Installing Docker Compose plugin..."
    apt-get update && apt-get install -y docker-compose-v2
fi

echo "[*] Building and starting int-backup01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  int-backup01 DEPLOYED SUCCESSFULLY!        "
echo "============================================="
echo "  rsync (No Auth):                 Port 873"
echo "  SSH (backupadmin/backup123):     Port 2222"
echo "============================================="

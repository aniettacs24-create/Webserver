#!/bin/bash
# ================================================================
# VulnCorp — Machine 4: rz-db01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp DB Server (rz-db01)     "
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

echo "[*] Building and starting rz-db01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  rz-db01 DEPLOYED SUCCESSFULLY!             "
echo "============================================="
echo "  MySQL (root/toor):       Port 3306"
echo "  PostgreSQL (COPY Prog):  Port 5432"
echo "  Redis (No Auth):         Port 6379"
echo "  SSH:                     Port 22"
echo "============================================="

#!/bin/bash
# ================================================================
# VulnCorp — Machine 8: int-erp01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp ERP (int-erp01)         "
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

echo "[*] Building and starting int-erp01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  int-erp01 DEPLOYED SUCCESSFULLY!           "
echo "============================================="
echo "  ERP App (SQLi, IDOR, SSRF): Port 80"
echo "  PostgreSQL:                 Port 5432"
echo "  SSH:                        Port 22"
echo "============================================="

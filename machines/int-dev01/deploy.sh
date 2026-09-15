#!/bin/bash
# ================================================================
# VulnCorp — Machine 9: int-dev01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp DevOps (int-dev01)      "
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

echo "[*] Building and starting int-dev01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  int-dev01 DEPLOYED SUCCESSFULLY!           "
echo "============================================="
echo "  GitLab (root/gitlab_root_pass): Port 80"
echo "  Jenkins (No Auth):              Port 8080"
echo "  Docker API (No TLS):            Port 2375"
echo "  SSH (developer/dev123):         Port 2222"
echo "============================================="

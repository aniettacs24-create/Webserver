#!/bin/bash
# ================================================================
# VulnCorp — Machine 2: dmz-mail01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp Mail Server (dmz-mail01)"
echo "============================================="

# Ensure Docker is installed
if ! command -v docker &> /dev/null; then
    echo "[*] Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi

# Ensure docker compose plugin exists
if ! docker compose version &> /dev/null; then
    echo "[*] Installing Docker Compose plugin..."
    apt-get update && apt-get install -y docker-compose-v2
fi

echo "[*] Building and starting dmz-mail01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  dmz-mail01 DEPLOYED SUCCESSFULLY!          "
echo "============================================="
echo "  SMTP (Open Relay):  Port 25"
echo "  IMAP (Plaintext):   Port 143"
echo "  POP3 (Plaintext):   Port 110"
echo "  SSH:                Port 2222 (admin / Admin@2024!)"
echo "============================================="

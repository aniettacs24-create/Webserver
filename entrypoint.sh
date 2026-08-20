#!/bin/bash
# ================================================================
# VulnCorp Lab — Entrypoint Script
# ================================================================
# Starts all services and the vulnerable web application.
# ================================================================

echo "============================================="
echo "  VulnCorp Vulnerable Lab — Starting Up      "
echo "============================================="

# Start cron daemon (for writable cron privesc)
echo "[*] Starting cron..."
service cron start

# Start SSH
echo "[*] Starting SSH..."
service ssh start

# Start FTP
echo "[*] Starting vsftpd..."
service vsftpd start

# Initialize database and start web application
echo "[*] Starting web application on port 80..."
cd /opt/vulncorp/app

# Run as webuser (the target user for initial shell)
su -c "cd /opt/vulncorp/app && /opt/venv/bin/python3 app.py" webuser &

echo ""
echo "============================================="
echo "  VulnCorp Lab is RUNNING                    "
echo "============================================="
echo ""
echo "  Web:  http://localhost:80"
echo "  SSH:  ssh webuser@localhost -p 22"
echo "  FTP:  ftp localhost 21"
echo ""
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="

# Keep container alive
tail -f /dev/null

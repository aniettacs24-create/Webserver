#!/bin/bash
echo "============================================="
echo "  VulnCorp Workstation (int-ws01)            "
echo "============================================="
echo "[*] Starting SSH..."
service ssh start

echo "[*] Starting Samba (SMBv1, open shares)..."
service smbd start
service nmbd start

echo "[*] Starting credential dump HTTP server (Port 80)..."
cd /opt/www && python3 -m http.server 80 &

echo ""
echo "  SMB:   smbclient -L \\\\localhost -N"
echo "  HTTP:  http://localhost/credentials.html"
echo "  SSH:   Port 22 (host maps to 2222)"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null

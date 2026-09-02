#!/bin/bash
echo "============================================="
echo "  VulnCorp VPN Server (rz-vpn01)             "
echo "============================================="
echo "[*] Starting SSH..."
service ssh start
echo "[*] Starting VPN Admin Panel (Port 8443)..."
cd /opt/vpn_admin && python3 app.py &
echo ""
echo "  Web Admin: http://localhost:8443  (admin/admin)"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null

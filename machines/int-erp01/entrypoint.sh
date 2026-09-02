#!/bin/bash
echo "============================================="
echo "  VulnCorp ERP Server (int-erp01)            "
echo "============================================="
echo "[*] Starting SSH..."
service ssh start
echo "[*] Starting PostgreSQL..."
service postgresql start
echo "[*] Initializing ERP database..."
/opt/setup/setup_erp.sh
echo "[*] Starting Flask ERP App (Port 80)..."
cd /opt/erp_app && python3 app.py &
echo ""
echo "  ERP: http://localhost:80/erp/login  (admin/admin123)"
echo "  SQLi: admin' OR '1'='1' --"
echo "  IDOR: /erp/records?id=1"
echo "  SSRF: /erp/import?url=http://192.168.1.50:873/"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null

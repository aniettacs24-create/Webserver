#!/bin/bash
echo "============================================="
echo "  VulnCorp Backup Server (int-backup01)      "
echo "============================================="
echo "[*] Starting SSH..."
service ssh start
echo "[*] Starting cron..."
service cron start
echo "[*] Starting rsyncd (NO AUTH)..."
rsync --daemon --no-detach --config=/etc/rsyncd.conf &
echo ""
echo "  rsync rsync://localhost/              (list modules)"
echo "  rsync rsync://localhost/full-backup/  (no password!)"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null

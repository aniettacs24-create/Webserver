#!/bin/bash
# ================================================================
# VulnCorp Lab — dmz-mail01 Entrypoint
# ================================================================
echo "============================================="
echo "  VulnCorp Mail Server (dmz-mail01)          "
echo "============================================="

echo "[*] Starting SSH..."
service ssh start

echo "[*] Starting Postfix (Open Relay)..."
service postfix start

echo "[*] Starting Dovecot (Plaintext IMAP/POP3)..."
service dovecot start

echo "[*] Starting Apache (Webmail)..."
service apache2 start

echo ""
echo "============================================="
echo "  VulnCorp Mail01 is RUNNING                 "
echo "============================================="
echo ""
echo "  SMTP:  telnet localhost 25      (OPEN RELAY)"
echo "  IMAP:  nc localhost 143         (plaintext)"
echo "  SSH:   ssh admin@localhost -p 22"
echo ""
echo "  Users: admin / sysadmin / developer / helpdesk"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="

tail -f /dev/null

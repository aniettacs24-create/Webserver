#!/bin/bash
# ================================================================
# VulnCorp Lab — dmz-mail01 Entrypoint
# ================================================================
echo "============================================="
echo "  VulnCorp Mail Server (dmz-mail01)          "
echo "============================================="

# Clean any stale pid files from previous container runs
rm -f /var/spool/postfix/pid/master.pid /var/run/dovecot/master.pid /var/run/apache2/apache2.pid /var/run/sshd.pid 2>/dev/null || true

echo "[*] Starting SSH..."
service ssh start || /usr/sbin/sshd

echo "[*] Preparing Postfix aliases..."
newaliases 2>/dev/null || postalias /etc/aliases 2>/dev/null || true

echo "[*] Starting Postfix (Open Relay on Port 25)..."
/usr/sbin/postfix start || service postfix start

echo "[*] Starting Dovecot (Plaintext IMAP/POP3)..."
service dovecot start || /usr/sbin/dovecot

echo "[*] Starting Apache (Webmail)..."
service apache2 start || true

echo ""
echo "============================================="
echo "  VulnCorp Mail01 Services Status            "
echo "============================================="

# Verification
if ss -tlpn | grep -q ':25 ' || netstat -tlpn 2>/dev/null | grep -q ':25 '; then
    echo "[+] Postfix SMTP is LISTENING on port 25 (Open Relay Active)"
else
    echo "[!] Warning: Postfix checking status..."
    /usr/sbin/postfix status || true
fi

echo ""
echo "  SMTP:  telnet localhost 25      (OPEN RELAY)"
echo "  IMAP:  nc localhost 143         (plaintext)"
echo "  POP3:  nc localhost 110         (plaintext)"
echo "  SSH:   ssh admin@localhost -p 22"
echo ""
echo "  Users: admin / sysadmin / developer / helpdesk"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="

tail -f /dev/null

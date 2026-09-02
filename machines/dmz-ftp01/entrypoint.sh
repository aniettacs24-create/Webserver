#!/bin/bash
echo "============================================="
echo "  VulnCorp FTP Server (dmz-ftp01)            "
echo "============================================="
echo "[*] Starting SSH..."
service ssh start
echo "[*] Starting vsftpd (Anonymous Write)..."
service vsftpd start
echo "[*] Starting ProFTPD (mod_copy / CVE-2015-3306)..."
service proftpd start
echo "[*] Starting Apache..."
service apache2 start
echo ""
echo "  vsftpd: ftp localhost 21     (anon login + write)"
echo "  ProFTPD: ftp localhost 2121  (SITE CPFR/CPTO RCE)"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null

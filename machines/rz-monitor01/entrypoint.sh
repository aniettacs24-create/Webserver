#!/bin/bash
echo "============================================="
echo "  VulnCorp Monitor Server (rz-monitor01)     "
echo "============================================="
echo "[*] Starting SSH..."
service ssh start
echo "[*] Starting Apache (Nagios)..."
service apache2 start
echo "[*] Starting Nagios4..."
service nagios4 start
echo "[*] Starting SNMPD (public community)..."
service snmpd start
echo ""
echo "  Nagios: http://localhost/nagios4  (nagiosadmin/nagios)"
echo "  SNMP:   snmpwalk -v2c -c public localhost"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null

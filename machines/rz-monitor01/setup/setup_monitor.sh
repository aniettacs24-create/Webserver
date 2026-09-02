#!/bin/bash
# setup_monitor.sh — Nagios + SNMP vulnerability configuration
set -e

echo "[+] Setting Nagios default password (nagiosadmin/nagios)..."
htpasswd -c -b /etc/nagios4/htpasswd.users nagiosadmin nagios

echo "[+] Configuring SNMP with public community string..."
cat > /etc/snmp/snmpd.conf << 'EOF'
# SNMP v1/v2c — community 'public' readable from everywhere (intentional)
rocommunity  public  0.0.0.0/0
rwcommunity  private 0.0.0.0/0

syslocation "VulnCorp Data Center, Server Room B"
syscontact  sysadmin@vulncorp.local

view systemview included .1
EOF

echo "[+] Writing Nagios hosts config (reveals full topology)..."
cat > /etc/nagios4/conf.d/vulncorp_hosts.cfg << 'EOF'
define host {
    host_name       rz-db01
    alias           Production Database
    address         172.16.0.10
    max_check_attempts 3
    check_period    24x7
    notification_period 24x7
}
define host {
    host_name       int-dc01
    alias           Domain Controller (AD)
    address         192.168.1.10
    max_check_attempts 3
    check_period    24x7
    notification_period 24x7
}
define host {
    host_name       int-erp01
    alias           ERP Server
    address         192.168.1.20
    max_check_attempts 3
    check_period    24x7
    notification_period 24x7
}
define host {
    host_name       int-files01
    alias           File Server (SMB/NFS)
    address         192.168.1.40
    max_check_attempts 3
    check_period    24x7
    notification_period 24x7
}
define host {
    host_name       int-backup01
    alias           Backup Server
    address         192.168.1.50
    max_check_attempts 3
    check_period    24x7
    notification_period 24x7
}
EOF

echo "[+] Making Nagios plugin dir world-writable (privesc vector)..."
chmod 777 /usr/lib/nagios/plugins/

echo "[+] Configuring SSH..."
mkdir -p /var/run/sshd
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
MaxAuthTries 10
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo "[+] Planting flags..."
echo "VULN{n4g10s_d3f4ult}"            > /etc/nagios4/flag.txt
echo "VULN{snmp_c0mmun1ty_l34k}"       > /tmp/snmp_flag.txt
echo "VULN{m0n1t0r_r00t3d_m4ch1n3_6}" > /root/root.txt

echo "[+] Monitoring setup complete!"

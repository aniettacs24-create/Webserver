#!/bin/bash
# ================================================================
# setup_breadcrumbs.sh — Plant flags & lateral movement clues
# ================================================================
set -e

echo "[+] Planting credential emails (breadcrumbs)..."

# VPN credentials email in admin's mailbox
mkdir -p /home/admin/Maildir/new
cat > /home/admin/Maildir/new/vpn_creds << 'EOF'
From: sysadmin@vulncorp.local
To: admin@vulncorp.local
Subject: VPN Access Details - CONFIDENTIAL
Date: Mon, 01 Sep 2026 09:00:00 +0530

Hi Admin,

VPN Server: 172.16.0.20
Web Admin: http://172.16.0.20:8443
Username: vpnadmin
Password: Sysadmin#99

- Sysadmin
EOF
chown admin:admin /home/admin/Maildir/new/vpn_creds

# DB credentials email in sysadmin's mailbox
mkdir -p /home/sysadmin/Maildir/new
cat > /home/sysadmin/Maildir/new/db_creds << 'EOF'
From: dbadmin@vulncorp.local
To: sysadmin@vulncorp.local
Subject: Production DB Credentials - DO NOT FORWARD

MySQL Host: 172.16.0.10
User: root
Password: toor

Redis Host: 172.16.0.10:6379
Auth: (none configured — fix this!)

DBAdmin
EOF
chown sysadmin:sysadmin /home/sysadmin/Maildir/new/db_creds

# Internal network map in developer's mailbox
mkdir -p /home/developer/Maildir/new
cat > /home/developer/Maildir/new/network_update << 'EOF'
From: sysadmin@vulncorp.local
To: developer@vulncorp.local
Subject: Network Diagram Update

Updated internal network layout:
  DMZ:       10.10.10.0/24  (web01, mail01, ftp01)
  Restricted: 172.16.0.0/24 (db01, vpn01, monitor01)
  Internal:  192.168.1.0/24 (dc01, erp01, dev01, files01, backup01)

DC admin: john.doe / Corp@Admin2024
EOF
chown developer:developer /home/developer/Maildir/new/network_update

echo "[+] Planting flags..."
echo "VULN{m41l_ph1sh_cr3ds}"          >  /home/admin/flag.txt
echo "VULN{sm7p_0p3n_r3l4y}"           > /tmp/smtp_flag.txt
echo "VULN{m41l_s3rv3r_r00t3d_m4ch1n3_2}" > /root/root.txt
chown admin:admin /home/admin/flag.txt
chmod 600 /root/root.txt

echo "[+] Breadcrumbs planted!"

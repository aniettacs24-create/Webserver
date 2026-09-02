#!/bin/bash
# setup_files.sh — Samba SMBv1 + NFS no_root_squash setup
set -e

echo "[+] Creating shares and planting sensitive files..."
mkdir -p /srv/shares/{IT_Share,HR,SSH_Keys,backup_scripts}
mkdir -p /exports/{backup,HR}
chmod -R 777 /srv/shares/ /exports/

cat > /srv/shares/backup_scripts/backup_db.sh << 'EOF'
#!/bin/bash
# Backup script — hardcoded credentials (intentional vuln)
MYSQL_HOST="172.16.0.10"
MYSQL_USER="root"
MYSQL_PASS="toor"
MSSQL_HOST="192.168.1.20"
MSSQL_USER="sa"
MSSQL_PASS="sa"
rsync -avz /backups/ backupadmin@192.168.1.50:/backups/db-backup/ --password-file=/etc/rsync.pass
EOF

cat > /srv/shares/IT_Share/README.txt << 'EOF'
VulnCorp IT Share
=================
Password policy: Corp@<Year>! format (e.g., Corp@Admin2024)
For access issues: helpdesk@vulncorp.local
EOF

# Generate leaked SSH keys
ssh-keygen -t rsa -b 2048 -f /srv/shares/SSH_Keys/dc01_admin_rsa -N "" -C "admin@vulncorp-dc01" -q
ssh-keygen -t rsa -b 2048 -f /srv/shares/SSH_Keys/backup_rsa     -N "" -C "backupadmin@backup01" -q

echo "[+] Configuring Samba (SMBv1, open shares, guest ok)..."
cat > /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = VULNCORP
   server string = VulnCorp File Server
   security = user
   # SMBv1 ENABLED — EternalBlue vector (intentional)
   server min protocol = NT1
   server max protocol = SMB3
   server signing = disabled
   map to guest = Bad User
   guest account = nobody

[IT_Share]
   path = /srv/shares/IT_Share
   browseable = yes
   writable = yes
   guest ok = yes
   create mask = 0777

[HR]
   path = /srv/shares/HR
   browseable = yes
   writable = yes
   guest ok = yes

[SSH_Keys]
   path = /srv/shares/SSH_Keys
   browseable = yes
   guest ok = yes

[backup_scripts]
   path = /srv/shares/backup_scripts
   browseable = yes
   guest ok = yes
EOF

cp -r /srv/shares/backup_scripts /exports/backup/
cp -r /srv/shares/HR/* /exports/HR/ 2>/dev/null || true

echo "[+] Configuring NFS (no_root_squash — intentional critical vuln)..."
cat > /etc/exports << 'EOF'
# no_root_squash: root on client = root on this server (intentional)
/exports/backup  *(rw,sync,no_root_squash,no_subtree_check)
/exports/HR      *(rw,sync,no_root_squash,no_subtree_check)
EOF

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
echo "VULN{smb_sh4r3_0p3n}"                   > /srv/shares/IT_Share/flag.txt
echo "VULN{nfs_n0_r00t_squ4sh}"               > /exports/backup/flag.txt
echo "VULN{f1l3_s3rv3r_r00t3d_m4ch1n3_10}"    > /root/root.txt

echo "[+] File server setup complete!"

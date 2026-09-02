#!/bin/bash
# setup_backup.sh — rsync daemon (no auth) + writable cron privesc
set -e

echo "[+] Creating backup data with sensitive content..."
mkdir -p /backups/{full-backup,db-backup,config-backup}

# Simulate shadow dump from DC
cat > /backups/full-backup/etc_shadow_dc01.txt << 'EOF'
Administrator:$6$rounds=5000$saltvalue$hash_of_Corp@Admin2024:19237:0:99999:7:::
john.doe:$6$rounds=5000$saltvalue$hash_of_Corp@Admin2024:19237:0:99999:7:::
svc_backup:$6$rounds=5000$saltvalue$hash_of_Backup@Svc2024:19237:0:99999:7:::
EOF

# DB backup with plaintext credentials in the SQL
cat > /backups/db-backup/mysql_backup.sql << 'EOF'
-- VulnCorp MySQL Full Backup
CREATE TABLE internal_credentials (id INT, service VARCHAR(50), host VARCHAR(50), username VARCHAR(50), password VARCHAR(100));
INSERT INTO internal_credentials VALUES
(1,'SSH','192.168.1.10','Administrator','Corp@Admin2024'),
(2,'RDP','192.168.1.10','john.doe','Corp@Admin2024'),
(3,'MSSQL','192.168.1.20','sa','sa'),
(4,'SMB','192.168.1.40','fileuser','File@User2024'),
(5,'SSH','192.168.1.50','backupadmin','backup123');
EOF

cat > /backups/config-backup/rsyncd.secrets << 'EOF'
backupadmin:backup123
EOF

echo "[+] Configuring rsyncd (NO AUTH — intentional)..."
cat > /etc/rsyncd.conf << 'EOF'
uid = root
gid = root
use chroot = no
max connections = 4
log file = /var/log/rsyncd.log

[full-backup]
    path = /backups/full-backup
    comment = Full System Backups (ALL SERVERS)
    read only = no
    list = yes

[db-backup]
    path = /backups/db-backup
    comment = Database Backups
    read only = no
    list = yes

[config-backup]
    path = /backups/config-backup
    comment = Config Files (rsyncd secrets included!)
    read only = no
    list = yes
EOF

echo "[+] Setting up writable cron for privesc..."
mkdir -p /opt/backup
echo '#!/bin/bash' > /opt/backup/run.sh
chmod 777 /opt/backup/run.sh
echo "* * * * * root /opt/backup/run.sh" > /etc/cron.d/backup-job

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
echo "VULN{rsync_c0nf_cr3ds}"               >> /backups/config-backup/rsyncd.secrets
echo "VULN{rsync_full_b4ckup}"               > /backups/full-backup/flag.txt
echo "VULN{b4ckup_s3rv3r_r00t3d_m4ch1n3_11}" > /root/root.txt

echo "[+] Backup server setup complete!"

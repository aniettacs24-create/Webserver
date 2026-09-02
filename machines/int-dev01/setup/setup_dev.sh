#!/bin/bash
# setup_dev.sh — Setup for int-dev01 (DevOps Server)
set -e

echo "[+] Configuring weak SSH..."
mkdir -p /var/run/sshd
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
MaxAuthTries 10
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo "[+] Creating dev user..."
useradd -m -s /bin/bash developer && echo "developer:dev123" | chpasswd
usermod -aG sudo developer 2>/dev/null || true

echo "[+] Planting secrets and flags..."
mkdir -p /opt
cat > /opt/leaked_secrets.env << 'EOF'
# VulnCorp DevOps Infrastructure Credentials - DO NOT COMMIT
AWS_ACCESS_KEY_ID=AKIA1234567890ABCDEF
AWS_SECRET_ACCESS_KEY=super_secret_aws_key_dont_commit_this
DB_PASSWORD=Corp@Admin2024
REDIS_HOST=172.16.0.10
AD_ADMIN_PASSWORD=Corp@Admin2024
SLACK_WEBHOOK=https://hooks.slack.com/services/fake/webhook
EOF

echo "VULN{d3v0ps_s3cr3ts_l3ak3d}" > /opt/dev_flag.txt
echo "VULN{d0ck3r_api_rce}"        > /root/root.txt
chmod 600 /root/root.txt

echo "[+] DevOps setup complete!"

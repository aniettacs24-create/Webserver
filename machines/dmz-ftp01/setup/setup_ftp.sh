#!/bin/bash
# setup_ftp.sh — vsftpd + ProFTPD vulnerability configuration
set -e

echo "[+] Configuring vsftpd (Anonymous Write)..."
cat > /etc/vsftpd.conf << 'EOF'
listen=YES
listen_ipv6=NO
# ANONYMOUS WRITE — intentional vulnerability
anonymous_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
write_enable=YES
local_enable=YES
local_umask=022
anon_root=/var/ftp
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
ftpd_banner=VulnCorp FTP Server v2.3.4 — Internal Use Only
chroot_local_user=NO
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
seccomp_sandbox=NO
EOF

echo "[+] Configuring ProFTPD with mod_copy (CVE-2015-3306)..."
cat > /etc/proftpd/proftpd.conf << 'EOF'
ServerName "VulnCorp ProFTPD"
ServerType standalone
DefaultServer on
Port 2121
# mod_copy enables SITE CPFR/CPTO — allows unauthenticated file copy (RCE vector)
LoadModule mod_copy.c
<Anonymous /var/ftp>
  User ftp
  Group nogroup
  RequireValidShell off
  UserAlias anonymous ftp
  <Limit WRITE>
    AllowAll
  </Limit>
</Anonymous>
EOF

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

echo "[+] FTP service setup complete!"

#!/bin/bash
# ================================================================
# Services Setup Script — SSH & FTP Configuration
# ================================================================

set -e

echo "[+] Setting up services..."

# ─────────────────────────────────────────────────────────────────
# SSH Configuration (Intentionally Weak)
# ─────────────────────────────────────────────────────────────────
mkdir -p /var/run/sshd

cat > /etc/ssh/sshd_config << 'SEOF'
# VulnCorp SSH Configuration — INTENTIONALLY WEAK
Port 22
ListenAddress 0.0.0.0
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords no
PubkeyAuthentication yes
MaxAuthTries 10
UsePAM yes
X11Forwarding yes
PrintMotd yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
SEOF

# SSH Banner — information disclosure
cat > /etc/ssh/banner.txt << 'BEOF'
*************************************************************
*  VulnCorp Internal Server — vulncorp-web01                *
*  Authorized access only. All sessions are logged.         *
*  Contact: it-support@vulncorp.local                       *
*  Server: Debian 12 (Bookworm) / Flask 3.x                *
*************************************************************
BEOF
echo "Banner /etc/ssh/banner.txt" >> /etc/ssh/sshd_config

# Generate SSH host keys
ssh-keygen -A

echo "[+] SSH configured (root login enabled, weak auth settings)"


# ─────────────────────────────────────────────────────────────────
# FTP Configuration (Anonymous Access Enabled)
# ─────────────────────────────────────────────────────────────────
mkdir -p /var/ftp/pub

cat > /etc/vsftpd.conf << 'FEOF'
# VulnCorp FTP Configuration
listen=YES
listen_ipv6=NO
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_root=/var/ftp
anon_upload_enable=NO
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
ftpd_banner=VulnCorp FTP Service v2.1 — Internal Use Only
chroot_local_user=NO
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
seccomp_sandbox=NO
FEOF

# Plant files on FTP for information disclosure
cat > /var/ftp/pub/welcome.txt << 'WEOF'
Welcome to VulnCorp FTP Server
===============================

This FTP server hosts internal files for the VulnCorp team.

NOTE: If you need access to the production database server,
contact dbadmin or check the internal credentials in the web portal.

Server Map:
  - vulncorp-web01 (this server):  192.168.56.101
  - vulncorp-db01  (prod DB):     192.168.56.102
  - vulncorp-fs01  (file server): 192.168.56.103

For SSH access, use your portal credentials.
WEOF

cat > /var/ftp/pub/network_map.txt << 'NEOF'
VulnCorp Internal Network Map
==============================

    ┌─────────────────┐     ┌─────────────────┐
    │  vulncorp-web01 │     │  vulncorp-db01  │
    │  192.168.56.101 │────▶│  192.168.56.102 │
    │  Ports: 80,22,21│     │  Ports: 22,3306 │
    └─────────────────┘     └─────────────────┘
            │                        │
            │               ┌────────┴────────┐
            │               │  vulncorp-fs01  │
            └──────────────▶│  192.168.56.103 │
                            │  Ports: 21,22   │
                            └─────────────────┘

    ┌─────────────────┐
    │   Windows Jump  │
    │   10.10.10.50   │
    │   Port: 3389    │
    └─────────────────┘

Credentials: See web portal admin panel or /opt/vulncorp/db/vulncorp.db
NEOF

echo "[+] FTP configured with anonymous access and info disclosure"


# ─────────────────────────────────────────────────────────────────
# MOTD — Hints when user gets SSH access
# ─────────────────────────────────────────────────────────────────
cat > /etc/motd << 'MEOF'

╔══════════════════════════════════════════════════════════════╗
║          Welcome to VulnCorp Web Server (web01)             ║
║                                                              ║
║  Maintenance Notes:                                          ║
║  - Backup script: /opt/scripts/cleanup.sh (cron, every min) ║
║  - App directory: /opt/vulncorp/                             ║
║  - Check: sudo -l                                            ║
║                                                              ║
║  Report issues to: it-support@vulncorp.local                 ║
╚══════════════════════════════════════════════════════════════╝

MEOF

echo "[+] Services setup complete!"

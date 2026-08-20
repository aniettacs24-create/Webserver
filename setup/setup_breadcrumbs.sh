#!/bin/bash
# ================================================================
# Breadcrumbs Setup — Clues Pointing to Machine 2
# ================================================================
# Plants various credentials and hints that lead the attacker
# from this machine to the next machine in the lab.
# ================================================================

set -e

echo "[+] Planting breadcrumbs for lateral movement..."

# ─────────────────────────────────────────────────────────────────
# Root's notes — visible after privesc
# ─────────────────────────────────────────────────────────────────
cat > /root/notes.txt << 'NEOF'
Personal Notes (Admin)
=======================

Production DB Migration:
  - New server: 192.168.56.102 (vulncorp-db01)
  - SSH: sysadmin / Pr0d#Server!99
  - MySQL root: toor_mysql@prod
  - Backup runs at 2AM — uses the same SSH key

TODO:
  - Rotate all credentials (been saying this for months...)
  - The webuser account has too many sudo permissions
  - Need to disable anonymous FTP after migration is done
  - Check if port 3306 is firewalled on db01

IMPORTANT:
  - Windows jump box at 10.10.10.50 has RDP open
  - Creds: Administrator / W1nd0ws@Admin!
  - Only use for emergency maintenance
NEOF

chmod 600 /root/notes.txt

echo "[+] Root notes planted at /root/notes.txt"


# ─────────────────────────────────────────────────────────────────
# SSH key for Machine 2 — found after privesc
# ─────────────────────────────────────────────────────────────────
mkdir -p /root/.ssh
ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa_db01 -N "" -q

cat > /root/.ssh/config << 'SEOF'
# SSH Config for internal servers

Host db01
    HostName 192.168.56.102
    User sysadmin
    IdentityFile ~/.ssh/id_rsa_db01
    StrictHostKeyChecking no

Host fileserver
    HostName 192.168.56.103
    User ftpuser
    Port 22
    StrictHostKeyChecking no
SEOF

chmod 600 /root/.ssh/config
chmod 600 /root/.ssh/id_rsa_db01

echo "[+] SSH key and config for Machine 2 planted in /root/.ssh/"


# ─────────────────────────────────────────────────────────────────
# Database config file with credentials
# ─────────────────────────────────────────────────────────────────
mkdir -p /opt/vulncorp/config

cat > /opt/vulncorp/config/database.yml << 'DEOF'
# VulnCorp Database Configuration
# Last updated: 2024-08-01

production:
  adapter: mysql2
  host: 192.168.56.102
  port: 3306
  database: vulncorp_prod
  username: root
  password: toor_mysql@prod
  pool: 10
  timeout: 5000

backup:
  adapter: mysql2
  host: 192.168.56.102
  port: 3306
  database: vulncorp_backup
  username: backup_user
  password: bkup_2024!secure
  pool: 5
DEOF

# Make readable by webuser (info disclosure)
chmod 644 /opt/vulncorp/config/database.yml

echo "[+] Database config with creds at /opt/vulncorp/config/database.yml"


# ─────────────────────────────────────────────────────────────────
# Credential flag files — proof of compromise
# ─────────────────────────────────────────────────────────────────
cat > /home/webuser/user.txt << 'UEOF'
╔═══════════════════════════════════════════╗
║            USER FLAG CAPTURED!            ║
║                                           ║
║   Flag: VULN{w3b_sh3ll_1n1t1al_acc3ss}   ║
║                                           ║
║   Congrats! You got user-level access.    ║
║   Now try to escalate to root.            ║
║                                           ║
║   Hints:                                  ║
║   - Check: sudo -l                        ║
║   - Check: find / -perm -4000 2>/dev/null ║
║   - Check: cat /etc/crontab               ║
║   - Check: ls -la /opt/scripts/           ║
╚═══════════════════════════════════════════╝
UEOF
chown webuser:webuser /home/webuser/user.txt
chmod 644 /home/webuser/user.txt

cat > /root/root.txt << 'REOF'
╔═══════════════════════════════════════════════╗
║             ROOT FLAG CAPTURED!               ║
║                                               ║
║   Flag: VULN{pr1v3sc_r00t_pwn3d_m4ch1n3_1}   ║
║                                               ║
║   Excellent! Full control of Machine 1.       ║
║                                               ║
║   Next Steps — Lateral Movement:              ║
║   - Check /root/notes.txt                     ║
║   - Check /root/.ssh/ for keys                ║
║   - Check /opt/vulncorp/config/database.yml   ║
║   - Query: SELECT * FROM internal_credentials ║
║                                               ║
║   Target: 192.168.56.102 (vulncorp-db01)      ║
╚═══════════════════════════════════════════════╝
REOF
chmod 600 /root/root.txt

echo "[+] Flag files planted (user.txt & root.txt)"
echo "[+] Breadcrumbs setup complete!"

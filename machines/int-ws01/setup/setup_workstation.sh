#!/bin/bash
# setup_workstation.sh — Windows workstation simulation setup
# Configures Samba (SMBv1, guest access), stored credentials, flags, breadcrumbs
set -e

echo "[+] Creating user profiles with stored credentials..."
# Simulate Windows user profiles
mkdir -p /home/john.doe/Documents
mkdir -p /home/john.doe/Desktop
mkdir -p /home/john.doe/AppData/Local/Google/Chrome/UserData

cat > /home/john.doe/Documents/saved_passwords.txt << 'EOF'
# VulnCorp Saved Credentials — DO NOT SHARE
# ==========================================
# Found in browser credential store / password manager

Domain Controller (192.168.1.10):
  Username: john.doe
  Password: Corp@Admin2024
  Protocol: RDP / SMB

Domain Controller (192.168.1.10):
  Username: svc_backup
  Password: Backup@Svc2024
  Protocol: LDAP (Service Account)

ERP Server (192.168.1.20):
  Username: admin
  Password: admin123
  Protocol: HTTP

File Server (192.168.1.40):
  Username: fileuser
  Password: File@User2024
  Protocol: SMB

Backup Server (192.168.1.50):
  Username: backupadmin
  Password: backup123
  Protocol: rsync / SSH
EOF

cat > /home/john.doe/Desktop/TODO.txt << 'EOF'
TODO — John Doe (IT Admin)
===========================
[ ] Rotate svc_backup password (currently Backup@Svc2024 — CHANGE ASAP)
[ ] Disable AlwaysInstallElevated on workstations
[ ] Patch PrintNightmare (CVE-2021-34527) on all endpoints
[ ] Fix unquoted service path for VulnCorp Monitoring Agent
[ ] Remove plaintext creds from backup scripts on int-files01
[ ] Enable NLA on all RDP endpoints
[ ] Disable SMBv1 (EternalBlue risk!)
[ ] Check if LLMNR is still enabled — Responder could be used
EOF

cat > /home/john.doe/AppData/Local/Google/Chrome/UserData/LoginData.txt << 'EOF'
# Chrome Credential Store Dump (simulated)
# ==========================================
URL:      https://dc01.vulncorp.local/admin
Username: john.doe
Password: Corp@Admin2024

URL:      https://erp.vulncorp.local/login
Username: admin
Password: admin123

URL:      https://gitlab.vulncorp.local
Username: root
Password: gitlab_root_pass

URL:      https://jenkins.vulncorp.local
Username: admin
Password: jenkins_no_auth
EOF

cat > /home/john.doe/Documents/wifi_enterprise.xml << 'EOF'
<?xml version="1.0"?>
<WLANProfile>
  <name>VulnCorp-Internal</name>
  <SSIDConfig><SSID><name>VulnCorp-Internal</name></SSID></SSIDConfig>
  <MSM><security>
    <EAPConfig>
      <Identity>john.doe</Identity>
      <Password>Corp@Admin2024</Password>
    </EAPConfig>
  </security></MSM>
</WLANProfile>
EOF

chown -R john.doe:john.doe /home/john.doe/

echo "[+] Creating SMB shares with sensitive files..."
mkdir -p /srv/shares/{Public,Users,IT_Admin}
chmod -R 777 /srv/shares/

cat > /srv/shares/Public/IT_Notes.txt << 'EOF'
IT Team Notes — Internal Use Only
==================================
DC Admin Password: Corp@Admin2024
WiFi PSK: VulnCorp2024!
VPN: Connect via rz-vpn01 (172.16.0.20)
Backup user: svc_backup / Backup@Svc2024
Next password rotation: TBD (overdue!)
EOF

cat > /srv/shares/IT_Admin/service_accounts.csv << 'EOF'
Service,Host,Username,Password,Notes
"Active Directory","192.168.1.10","Administrator","Corp@Admin2024","Domain Admin"
"ERP Application","192.168.1.20","sa","sa","SQL Server SA"
"GitLab","192.168.1.30","root","gitlab_root_pass","DevOps"
"File Server","192.168.1.40","fileuser","File@User2024","SMB Share"
"Backup Server","192.168.1.50","backupadmin","backup123","rsync"
EOF

# Simulate unquoted service path info
mkdir -p "/srv/shares/IT_Admin/Program Files/VulnCorp/Monitoring Agent"
cat > "/srv/shares/IT_Admin/Program Files/VulnCorp/Monitoring Agent/config.ini" << 'EOF'
[VulnCorpMonitor]
; Service registered with UNQUOTED path:
; C:\Program Files\VulnCorp\Monitoring Agent\monitor.exe
; Privesc: drop Monitoring.exe in C:\Program Files\VulnCorp\
ServiceName=VulnCorpMonitor
LogPath=C:\ProgramData\VulnCorp\logs
Interval=60
EOF

# Copy user files to SMB Users share
cp -r /home/john.doe/Documents /srv/shares/Users/john.doe_Documents

echo "[+] Configuring Samba (SMBv1, open shares, guest ok, domain VULNCORP)..."
cat > /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = VULNCORP
   realm = VULNCORP.LOCAL
   server string = VulnCorp Workstation WS01
   security = user
   # SMBv1 ENABLED — EternalBlue vector (intentional)
   server min protocol = NT1
   server max protocol = SMB3
   server signing = disabled
   client signing = disabled
   map to guest = Bad User
   guest account = nobody

[Public]
   path = /srv/shares/Public
   browseable = yes
   writable = yes
   guest ok = yes
   create mask = 0777
   comment = Public Share — IT Notes

[Users]
   path = /srv/shares/Users
   browseable = yes
   writable = yes
   guest ok = yes
   comment = User Profile Backups (contains saved passwords!)

[IT_Admin]
   path = /srv/shares/IT_Admin
   browseable = yes
   guest ok = yes
   comment = IT Admin Tools & Configs (service_accounts.csv!)
EOF

echo "[+] Configuring SSH (weak settings)..."
mkdir -p /var/run/sshd
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
MaxAuthTries 10
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo "[+] Creating credential dump web page..."
mkdir -p /opt/www
cat > /opt/www/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>VULNCORP-WS01 — Workstation</title></head>
<body style="font-family:Consolas,monospace;background:#0c0c0c;color:#33ff33;padding:40px">
<h1>VULNCORP-WS01 — Domain Workstation</h1>
<p>Domain: vulncorp.local | IP: 192.168.1.60</p>
<p>Status: Domain-Joined | User: john.doe</p>
<hr>
<p><a href="/credentials.html" style="color:#ff6633">📋 Credential Store</a></p>
<p><a href="/services.html" style="color:#ff6633">🔧 Service Info</a></p>
</body>
</html>
HTMLEOF

cat > /opt/www/credentials.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>VULNCORP-WS01 — Stored Credentials</title></head>
<body style="font-family:Consolas,monospace;background:#0c0c0c;color:#33ff33;padding:40px">
<h1>🔓 Browser Credential Store Dump</h1>
<p style="color:#ff3333">⚠️ WARNING: These credentials were extracted from the local browser password store.</p>
<hr>
<pre>
┌──────────────────────────────────────────────────────────────────┐
│ URL / Service                │ Username    │ Password            │
├──────────────────────────────┼─────────────┼─────────────────────┤
│ dc01.vulncorp.local (RDP)    │ john.doe    │ Corp@Admin2024      │
│ dc01.vulncorp.local (LDAP)   │ svc_backup  │ Backup@Svc2024      │
│ erp.vulncorp.local (HTTP)    │ admin       │ admin123            │
│ gitlab.vulncorp.local (HTTP) │ root        │ gitlab_root_pass    │
│ files01 (SMB)                │ fileuser    │ File@User2024       │
│ backup01 (rsync/SSH)         │ backupadmin │ backup123           │
└──────────────────────────────┴─────────────┴─────────────────────┘

Flag: VULN{st0r3d_cr3ds_p1vot}
</pre>
</body>
</html>
HTMLEOF

cat > /opt/www/services.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>VULNCORP-WS01 — Services</title></head>
<body style="font-family:Consolas,monospace;background:#0c0c0c;color:#33ff33;padding:40px">
<h1>🔧 Workstation Service Information</h1>
<hr>
<pre>
Hostname:       VULNCORP-WS01
Domain:         vulncorp.local
OS:             Windows 10 Enterprise (simulated)
Local Admin:    ws_admin / Desktop@2024

Vulnerabilities Present:
========================
[CRITICAL] SMBv1 Enabled                    → CVE-2017-0144 (EternalBlue)
[CRITICAL] Print Spooler Running            → CVE-2021-34527 (PrintNightmare)
[HIGH]     Unquoted Service Path            → VulnCorp Monitoring Agent
[HIGH]     AlwaysInstallElevated            → MSI privilege escalation
[HIGH]     Stored Plaintext Credentials     → Browser credential dump
[MEDIUM]   LLMNR/NetBIOS Enabled            → Responder poisoning
[MEDIUM]   RDP Without NLA                  → Direct RDP access (port 3389)
[HIGH]     Weak Local Admin Password        → ws_admin / Desktop@2024

Pivot Targets:
==============
→ Domain Controller:  192.168.1.10 (john.doe / Corp@Admin2024 = Domain Admin)
→ ERP Server:         192.168.1.20 (admin / admin123)
→ File Server:        192.168.1.40 (fileuser / File@User2024)
→ Backup Server:      192.168.1.50 (backupadmin / backup123)

Flag: VULN{w0rkst4t10n_4dm1n_pwn3d}
</pre>
</body>
</html>
HTMLEOF

echo "[+] Planting flags..."
mkdir -p /opt/flags
echo "VULN{3t3rn4l_blu3_w0rkst4t10n}" > /opt/flags/eternalblue_flag.txt
echo "VULN{st0r3d_cr3ds_p1vot}"       > /opt/flags/creds_flag.txt
echo "VULN{w0rkst4t10n_4dm1n_pwn3d}"  > /root/root.txt
chmod 600 /root/root.txt

echo "[+] Workstation setup complete!"

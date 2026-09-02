# 🏢 Machine 7 — int-dc01 (Windows Server 2019 Domain Controller)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY**

## 🚀 One-Command Deployment (PowerShell)

On your fresh **Windows Server 2019 VM** (`192.168.1.10`):

1. Open **PowerShell as Administrator**.
2. Run:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\deploy_dc.ps1
```
3. The server will install AD DS and promote itself to `vulncorp.local`, then reboot.
4. After reboot, log back in and run `.\deploy_dc.ps1` once more to finish configuring all intentional vulnerabilities and flags.

---

## 🎯 Configured Vulnerabilities
1. **AS-REP Roasting:** `svc_backup` has Kerberos pre-authentication disabled (`DoesNotRequirePreAuth = $true`).
2. **Kerberoasting:** `svc_erp` and `svc_sql` have Service Principal Names (SPNs) registered.
3. **DCSync Rights:** `svc_backup` has `GenericAll` rights on the domain root.
4. **GPP cPassword:** `SYSVOL\vulncorp.local\Policies\...\Groups.xml` contains encrypted cPassword (`backdoor`).
5. **SMB Signing Disabled:** NTLM relay attacks permitted.
6. **RDP Without NLA:** Port 3389 accessible without Network Level Authentication.
7. **Flag Planted:** `C:\flags\domain_flag.txt` (`VULN{d0m41n_4dm1n_3mp1r3_f3ll}`).

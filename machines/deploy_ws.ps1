# ================================================================
# VulnCorp — Machine 12: int-win10-01 (Windows 10 Workstation)
# Automated Vulnerability Deployment Script
# Run this in PowerShell as Administrator on Windows 10 Pro 21H2
# Domain: vulncorp.local  |  IP: 192.168.1.60
# ================================================================

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  VulnCorp WS Deployment (VULNCORP-WS01)     " -ForegroundColor Cyan
Write-Host "  192.168.1.60  |  Windows 10 Pro (21H2)     " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# ── Prerequisites check ─────────────────────────────────────────
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "[!] Please re-run this script as Administrator!" -ForegroundColor Red
    Exit 1
}

# ── Rename computer and set static IP (optional, adjust NIC name) ──
# Rename-Computer -NewName "VULNCORP-WS01" -Force
# New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "192.168.1.60" -PrefixLength 24 -DefaultGateway "192.168.1.1"
# Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.1.10"
# Write-Host "[*] Network configured. Rename and join domain manually if needed, then re-run." -ForegroundColor Yellow

# ================================================================
# VULNERABILITY 1 — Enable SMBv1 (EternalBlue / MS17-010)
# CVE-2017-0144
# ================================================================
Write-Host "[*] [1/10] Enabling SMBv1 (EternalBlue)..." -ForegroundColor Yellow
Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue
Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force
Write-Host "[+] SMBv1 enabled — host is vulnerable to CVE-2017-0144 (EternalBlue)" -ForegroundColor Green

# ================================================================
# VULNERABILITY 2 — PrintNightmare (CVE-2021-34527)
#   Ensure Print Spooler is running and no patch applied
# ================================================================
Write-Host "[*] [2/10] Configuring Print Spooler for PrintNightmare..." -ForegroundColor Yellow
Set-Service -Name Spooler -StartupType Automatic
Start-Service -Name Spooler -ErrorAction SilentlyContinue
# Allow remote print driver installation (the actual PrintNightmare vector)
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" `
    -Name "NoWarningNoElevationOnInstall" -Value 1 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" `
    -Name "UpdatePromptSettings" -Value 2 -Type DWord -Force
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" `
    -Force -ErrorAction SilentlyContinue | Out-Null
Write-Host "[+] Print Spooler running with PrintNightmare-permissive registry settings (CVE-2021-34527)" -ForegroundColor Green

# ================================================================
# VULNERABILITY 3 — WDigest Plaintext Credentials in LSASS
#   CWE-312: Cleartext Storage of Sensitive Information
# ================================================================
Write-Host "[*] [3/10] Enabling WDigest plaintext credential caching..." -ForegroundColor Yellow
$wdigestPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest"
if (-not (Test-Path $wdigestPath)) { New-Item -Path $wdigestPath -Force | Out-Null }
Set-ItemProperty -Path $wdigestPath -Name "UseLogonCredential" -Value 1 -Type DWord
Write-Host "[+] WDigest enabled — mimikatz 'sekurlsa::wdigest' will dump cleartext passwords" -ForegroundColor Green

# ================================================================
# VULNERABILITY 4 — Stored Domain Credentials in Plaintext Script
#   CWE-312 / CWE-538
# ================================================================
Write-Host "[*] [4/10] Planting hardcoded credentials in a world-readable script..." -ForegroundColor Yellow
$scriptDir = "C:\Automation"
New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null

Set-Content "$scriptDir\domain_sync.ps1" @'
# VulnCorp Domain Sync Script
# TODO: move credentials to vault before production!

$domain   = "vulncorp.local"
$dcHost   = "192.168.1.10"
$user     = "VULNCORP\john.doe"
$password = "Corp@Admin2024"   # <-- DA password

$secPass  = ConvertTo-SecureString $password -AsPlainText -Force
$cred     = New-Object System.Management.Automation.PSCredential($user, $secPass)

# Sync GPO
Invoke-Command -ComputerName $dcHost -Credential $cred -ScriptBlock {
    gpupdate /force
}
'@

# Make it world-readable
icacls "$scriptDir\domain_sync.ps1" /grant "Everyone:(R)" /T | Out-Null
Write-Host "[+] Plaintext DA credentials planted at $scriptDir\domain_sync.ps1 (world-readable)" -ForegroundColor Green

# ================================================================
# VULNERABILITY 5 — AutoRun / AutoPlay enabled
#   CWE-641
# ================================================================
Write-Host "[*] [5/10] Enabling AutoRun (USB autorun attack surface)..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -Name "NoDriveTypeAutoRun" -Value 0 -Type DWord -Force
Write-Host "[+] AutoRun enabled for all drive types" -ForegroundColor Green

# ================================================================
# VULNERABILITY 6 — RDP without Network Level Authentication
#   CWE-306
# ================================================================
Write-Host "[*] [6/10] Enabling RDP without NLA..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
    -Name "UserAuthentication" -Value 0 -Type DWord
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
Write-Host "[+] RDP enabled on port 3389, NLA disabled" -ForegroundColor Green

# Create a local account matching the leaked credentials
$rdpPass = ConvertTo-SecureString "W1nd0ws@Admin!" -AsPlainText -Force
try {
    New-LocalUser -Name "Administrator" -Password $rdpPass -FullName "VulnCorp Admin" `
        -Description "Built-in admin" -PasswordNeverExpires -ErrorAction SilentlyContinue
} catch {}
try {
    Set-LocalUser -Name "Administrator" -Password $rdpPass -ErrorAction SilentlyContinue
    Enable-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
} catch {}
Add-LocalGroupMember -Group "Administrators" -Member "Administrator" -ErrorAction SilentlyContinue
Write-Host "[+] Local Administrator account set (pass: W1nd0ws@Admin!)" -ForegroundColor Green

# ================================================================
# VULNERABILITY 7 — Disable Windows Defender
#   CWE-693
# ================================================================
Write-Host "[*] [7/10] Disabling Windows Defender real-time protection..." -ForegroundColor Yellow
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
} catch {}
# Registry fallback
$defenderPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
if (-not (Test-Path $defenderPath)) { New-Item -Path $defenderPath -Force | Out-Null }
Set-ItemProperty -Path $defenderPath -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force

$rtPath = "$defenderPath\Real-Time Protection"
if (-not (Test-Path $rtPath)) { New-Item -Path $rtPath -Force | Out-Null }
Set-ItemProperty -Path $rtPath -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -Force
Write-Host "[+] Windows Defender disabled" -ForegroundColor Green

# ================================================================
# VULNERABILITY 8 — Unquoted Service Path
#   CWE-428: Uncontrolled Search Path Element
# ================================================================
Write-Host "[*] [8/10] Creating service with unquoted path..." -ForegroundColor Yellow
$svcBinDir = "C:\Program Files\VulnCorp Helper\bin"
New-Item -ItemType Directory -Path $svcBinDir -Force | Out-Null

# Drop a benign placeholder binary (copy cmd.exe as a stand-in)
Copy-Item "$env:SystemRoot\System32\cmd.exe" "$svcBinDir\helper.exe" -Force

# Create the vulnerable service with an unquoted, space-containing path
sc.exe create VulnCorpHelperSvc `
    binPath= "C:\Program Files\VulnCorp Helper\bin\helper.exe" `
    DisplayName= "VulnCorp Helper Service" `
    start= auto | Out-Null

# Grant Everyone modify rights to C:\Program Files\VulnCorp Helper
# so a low-priv user can plant C:\Program Files\VulnCorp.exe
icacls "C:\Program Files\VulnCorp Helper" /grant "Everyone:(OI)(CI)(M)" /T | Out-Null

Write-Host "[+] VulnCorpHelperSvc created with unquoted path — drop payload at 'C:\Program Files\VulnCorp.exe'" -ForegroundColor Green

# ================================================================
# VULNERABILITY 9 — AlwaysInstallElevated
#   CWE-269: Improper Privilege Management
# ================================================================
Write-Host "[*] [9/10] Enabling AlwaysInstallElevated..." -ForegroundColor Yellow
$installerHKLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$installerHKCU = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer"
if (-not (Test-Path $installerHKLM)) { New-Item -Path $installerHKLM -Force | Out-Null }
if (-not (Test-Path $installerHKCU)) { New-Item -Path $installerHKCU -Force | Out-Null }
Set-ItemProperty -Path $installerHKLM -Name "AlwaysInstallElevated" -Value 1 -Type DWord
Set-ItemProperty -Path $installerHKCU -Name "AlwaysInstallElevated" -Value 1 -Type DWord
Write-Host "[+] AlwaysInstallElevated = 1 — malicious .msi installs run as SYSTEM" -ForegroundColor Green

# ================================================================
# VULNERABILITY 10 — World-Writable Scheduled Task Script
#   CWE-732: Incorrect Permission Assignment
# ================================================================
Write-Host "[*] [10/10] Creating world-writable scheduled task..." -ForegroundColor Yellow
$taskScriptDir = "C:\Scripts"
New-Item -ItemType Directory -Path $taskScriptDir -Force | Out-Null
Set-Content "$taskScriptDir\cleanup.ps1" @'
# VulnCorp Scheduled Cleanup Script
# Runs every minute as SYSTEM
Remove-Item -Path "C:\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
'@

# Make the script world-writable (Everyone: Full Control)
icacls "$taskScriptDir\cleanup.ps1" /grant "Everyone:(F)" | Out-Null
icacls "$taskScriptDir" /grant "Everyone:(OI)(CI)(F)" | Out-Null

# Register scheduled task running as SYSTEM every minute
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-ExecutionPolicy Bypass -NonInteractive -File C:\Scripts\cleanup.ps1"
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 1) -Once `
            -At (Get-Date)
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName "VulnCorpCleanup" -Action $action -Trigger $trigger `
    -RunLevel Highest -User "SYSTEM" -Settings $settings -Force | Out-Null

Write-Host "[+] Scheduled task 'VulnCorpCleanup' runs C:\Scripts\cleanup.ps1 as SYSTEM every minute (world-writable)" -ForegroundColor Green

# ================================================================
# LATERAL MOVEMENT BREADCRUMBS
# ================================================================
Write-Host "[*] Planting lateral movement breadcrumbs..." -ForegroundColor Yellow

$johnDocs = "C:\Users\john.doe\Documents"
New-Item -ItemType Directory -Path $johnDocs -Force | Out-Null

Set-Content "$johnDocs\network_notes.txt" @'
VulnCorp Internal Network Notes — john.doe (IT Admin)
======================================================

Backup Server (int-backup01)
  Host : 192.168.1.50
  Proto: rsync  (no auth — module name: backups)
  SSH  : ssh backup@192.168.1.50  (key at C:\keys\backup_rsa)

File Server (int-files01)
  Host : 192.168.1.40
  SMB  : \\192.168.1.40\share  (null session works)
  Creds: guest / (no password)

Domain Admin Hash (for pass-the-hash):
  Administrator : aad3b435b51404eeaad3b435b51404ee:8846f7eaee8fb117ad06bdd830b7586c

NOTE: DO NOT share this file outside the IT team!
'@

icacls "$johnDocs\network_notes.txt" /grant "Everyone:(R)" | Out-Null

# SSH key for backup server
$keyDir = "C:\keys"
New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
Set-Content "$keyDir\backup_rsa" @'
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBFAKEXAMPLEKEY0000000000000000000000000000000000000000AAAA
AAAAAAAAAAAAAB3NzaC1lZDI1NTE5AAAAIEUAkEXAMPLEKEY000000000000000000000
000000000000000AAAAQXhhbXBsZV9rZXlfZm9yX2xhYl9wdXJwb3Nlc19vbmx5AAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAXzZXhhbXBsZV9rZXk=
-----END OPENSSH PRIVATE KEY-----
'@
icacls "$keyDir\backup_rsa" /grant "Everyone:(R)" | Out-Null

Write-Host "[+] Breadcrumbs planted: network_notes.txt + backup SSH key" -ForegroundColor Green

# ================================================================
# FLAGS
# ================================================================
Write-Host "[*] Planting flags..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "C:\flags" -Force | Out-Null

"VULN{wdig3st_cl34rt3xt_cr3dz}"   | Set-Content "C:\flags\wdigest_flag.txt"
"VULN{unqu0t3d_s3rv1c3_syst3m}"   | Set-Content "C:\flags\privesc_flag.txt"
"VULN{4lw4ys_1nst4ll_3l3v4t3d}"   | Set-Content "C:\flags\msi_flag.txt"

# Restrict flags — only readable after SYSTEM/Admin escalation
icacls "C:\flags" /inheritance:r /grant "SYSTEM:(OI)(CI)(F)" /grant "Administrators:(OI)(CI)(F)" | Out-Null

Write-Host "[+] Flags planted in C:\flags\ (require elevated access to read)" -ForegroundColor Green

# ================================================================
# SMB Signing disabled (enable NTLM relay)
# ================================================================
Set-SmbServerConfiguration -RequireSecuritySignature $false -Force
Set-SmbClientConfiguration -RequireSecuritySignature $false -Force
Write-Host "[+] SMB Signing disabled — NTLM relay (Responder/ntlmrelayx) possible" -ForegroundColor Green

# ================================================================
# SUMMARY
# ================================================================
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  VULNCORP-WS01 Deployment COMPLETE!         " -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configured Vulnerabilities:" -ForegroundColor White
Write-Host "  [1]  SMBv1 / EternalBlue           (CVE-2017-0144)" -ForegroundColor Red
Write-Host "  [2]  PrintNightmare                 (CVE-2021-34527)" -ForegroundColor Red
Write-Host "  [3]  WDigest Plaintext Creds        (CWE-312)" -ForegroundColor Red
Write-Host "  [4]  Hardcoded Credentials in Script(CWE-312/538) → C:\Automation\domain_sync.ps1" -ForegroundColor Red
Write-Host "  [5]  AutoRun Enabled                (CWE-641)" -ForegroundColor Yellow
Write-Host "  [6]  RDP without NLA (port 3389)   (CWE-306)" -ForegroundColor Yellow
Write-Host "  [7]  Windows Defender Disabled      (CWE-693)" -ForegroundColor Red
Write-Host "  [8]  Unquoted Service Path          (CWE-428) → VulnCorpHelperSvc" -ForegroundColor Red
Write-Host "  [9]  AlwaysInstallElevated          (CWE-269)" -ForegroundColor Red
Write-Host "  [10] World-Writable Scheduled Task  (CWE-732) → C:\Scripts\cleanup.ps1" -ForegroundColor Red
Write-Host ""
Write-Host "Flags: C:\flags\  (need SYSTEM/Admin to read)" -ForegroundColor Cyan
Write-Host "IP   : 192.168.1.60  |  RDP creds: Administrator / W1nd0ws@Admin!" -ForegroundColor Cyan

# ================================================================
# VulnCorp — Machine 7: int-dc01 (Domain Controller)
# Automated AD DS & Vulnerability Deployment Script
# Run this in PowerShell as Administrator on Windows Server 2019
# ================================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  VulnCorp DC Deployment (VULNCORP-DC01)    " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Step 1: Install AD DS Role if not installed
if (!(Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    Write-Host "[*] Installing Active Directory Domain Services..." -ForegroundColor Yellow
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

    Write-Host "[*] Promoting to Domain Controller (vulncorp.local)..." -ForegroundColor Yellow
    Import-Module ADDSDeployment
    Install-ADDSForest `
      -DomainName "vulncorp.local" `
      -DomainNetbiosName "VULNCORP" `
      -ForestMode "WinThreshold" `
      -DomainMode "WinThreshold" `
      -InstallDns:$true `
      -Force:$true `
      -SafeModeAdministratorPassword (ConvertTo-SecureString "Corp@Admin2024" -AsPlainText -Force)

    Write-Host "[!] Server will reboot now. Re-run this script after reboot to finish vulnerability configuration." -ForegroundColor Green
    Exit
}

Write-Host "[*] Configuring Active Directory Vulnerabilities..." -ForegroundColor Yellow
Import-Module ActiveDirectory

# Create OUs
New-ADOrganizationalUnit -Name "VulnCorp Users" -Path "DC=vulncorp,DC=local" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name "Service Accounts" -Path "DC=vulncorp,DC=local" -ErrorAction SilentlyContinue

# Create Users
$users = @(
  @{Name="John Doe";    SAM="john.doe";   Pass="Corp@Admin2024";   Desc="IT Admin"},
  @{Name="Jane Smith";  SAM="jane.smith"; Pass="Jane@Dev2024";     Desc="Developer"},
  @{Name="Help Desk";   SAM="helpdesk";   Pass="Helpdesk@123";     Desc="Help Desk"},
  @{Name="Backup Agent";SAM="svc_backup"; Pass="Backup@Svc2024";   Desc="Backup Service Account"},
  @{Name="ERP Service"; SAM="svc_erp";    Pass="Erp@Service99!";   Desc="ERP Application Service"},
  @{Name="SQL Service"; SAM="svc_sql";    Pass="Sql@Service77!";   Desc="SQL Server Service"}
)

foreach ($u in $users) {
  try {
    New-ADUser `
      -Name $u.Name `
      -SamAccountName $u.SAM `
      -UserPrincipalName "$($u.SAM)@vulncorp.local" `
      -AccountPassword (ConvertTo-SecureString $u.Pass -AsPlainText -Force) `
      -Enabled $true `
      -PasswordNeverExpires $true `
      -Description $u.Desc `
      -Path "OU=VulnCorp Users,DC=vulncorp,DC=local"
    Write-Host "[+] Created user: $($u.SAM)" -ForegroundColor Green
  } catch {
    Write-Host "[-] User $($u.SAM) may already exist" -ForegroundColor Gray
  }
}

# Add john.doe to Domain Admins
Add-ADGroupMember -Identity "Domain Admins" -Members "john.doe" -ErrorAction SilentlyContinue

# 1. AS-REP Roasting on svc_backup
Set-ADAccountControl -Identity "svc_backup" -DoesNotRequirePreAuth $true
Write-Host "[+] svc_backup is now AS-REP Roastable (PreAuth disabled)" -ForegroundColor Green

# 2. Kerberoasting — register SPNs on svc_erp & svc_sql
Set-ADUser "svc_erp" -ServicePrincipalNames @{Add="HTTP/erp.vulncorp.local:80"} -ErrorAction SilentlyContinue
Set-ADUser "svc_sql" -ServicePrincipalNames @{Add="MSSQLSvc/sql.vulncorp.local:1433"} -ErrorAction SilentlyContinue
Write-Host "[+] svc_erp and svc_sql are Kerberoastable (SPNs registered)" -ForegroundColor Green

# 3. DCSync Rights for svc_backup
try {
    $acl = Get-Acl "AD:\DC=vulncorp,DC=local"
    $identity = (Get-ADUser "svc_backup").SID
    $adRights = [System.DirectoryServices.ActiveDirectoryRights]"GenericAll"
    $rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity, $adRights, [System.Security.AccessControl.AccessControlType]"Allow")
    $acl.AddAccessRule($rule)
    Set-Acl -Path "AD:\DC=vulncorp,DC=local" -AclObject $acl
    Write-Host "[+] svc_backup granted DCSync rights (GenericAll on Domain root)" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not set DCSync ACL: $_" -ForegroundColor Yellow
}

# 4. GPP cPassword in SYSVOL
$gppPath = "\\vulncorp.local\SYSVOL\vulncorp.local\Policies\{FAKE-GPP-POLICY}\Machine\Preferences\Groups"
New-Item -ItemType Directory -Force -Path $gppPath | Out-Null
Set-Content "$gppPath\Groups.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<Groups clsid="{3125E937-EB16-4b4c-9934-544FC6D24D26}">
  <Group clsid="{6D4A79E4-529C-4481-ABD0-F5BD7EA93BA7}" name="Administrators">
    <Properties action="U" groupName="Administrators">
      <Members>
        <Member name="backdoor" action="ADD">
          <Properties cpassword="VZBQoGpDMEUESqPnEFTqMg==" userName="backdoor"/>
        </Member>
      </Members>
    </Properties>
  </Group>
</Groups>
'@
Write-Host "[+] GPP cPassword planted in SYSVOL" -ForegroundColor Green

# 5. Disable SMB Signing (NTLM Relay possible)
Set-SmbServerConfiguration -RequireSecuritySignature $false -Force
Set-SmbClientConfiguration -RequireSecuritySignature $false -Force
Write-Host "[+] SMB Signing disabled" -ForegroundColor Green

# 6. RDP without NLA
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
Write-Host "[+] RDP enabled without NLA on port 3389" -ForegroundColor Green

# 7. Flags
New-Item C:\flags -ItemType Directory -Force | Out-Null
"VULN{gpp_p4ssw0rd_l34k}" | Set-Content C:\flags\gpp_flag.txt
"VULN{d0m41n_4dm1n_3mp1r3_f3ll}" | Set-Content C:\flags\domain_flag.txt

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Domain Controller Setup COMPLETE!          " -ForegroundColor Green
Write-Host "  IP: 192.168.1.10                           " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

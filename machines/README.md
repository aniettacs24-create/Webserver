# 🏢 VulnCorp Enterprise Lab — Machine Deployment Packages

Every machine in the VulnCorp Enterprise testbed is organized as a self-contained, deployable package with its own `Dockerfile`, `docker-compose.yml`, and `deploy.sh` (or `deploy_dc.ps1` for Windows).

---

## 📋 Machine Directory & Deployment Commands

| # | Folder | Target VM Hostname | Zone | OS | Quick Deploy Command |
|---|--------|--------------------|------|----|----------------------|
| 1 | `../` *(root)* | `vulncorp-web01` | DMZ (`10.10.10.10`) | Debian 13 | `sudo ./deploy.sh` |
| 2 | `dmz-mail01/` | `vulncorp-mail01` | DMZ (`10.10.10.20`) | Debian 13 | `sudo ./deploy.sh` |
| 3 | `dmz-ftp01/` | `vulncorp-ftp01` | DMZ (`10.10.10.30`) | Debian 13 | `sudo ./deploy.sh` |
| 4 | `rz-db01/` | `vulncorp-db01` | Restricted (`172.16.0.10`) | Ubuntu 24 | `sudo ./deploy.sh` |
| 5 | `rz-vpn01/` | `vulncorp-vpn01` | Restricted (`172.16.0.20`) | Ubuntu 24 | `sudo ./deploy.sh` |
| 6 | `rz-monitor01/` | `vulncorp-monitor01` | Restricted (`172.16.0.30`) | Debian 13 | `sudo ./deploy.sh` |
| 7 | `int-dc01/` | `VULNCORP-DC01` | Internal (`192.168.1.10`) | Win Server 2019 | `.\deploy_dc.ps1` *(PowerShell Admin)* |
| 8 | `int-erp01/` | `vulncorp-erp01` | Internal (`192.168.1.20`) | Ubuntu 24 | `sudo ./deploy.sh` |
| 9 | `int-dev01/` | `vulncorp-dev01` | Internal (`192.168.1.30`) | Ubuntu 24 | `sudo ./deploy.sh` |
| 10 | `int-files01/` | `VULNCORP-FILES01` | Internal (`192.168.1.40`) | Debian 13 | `sudo ./deploy.sh` |
| 11 | `int-backup01/` | `vulncorp-backup01` | Internal (`192.168.1.50`) | Debian 13 | `sudo ./deploy.sh` |

---

## 🚀 How to Deploy on Each VM

1. Boot the fresh VM (set static IP as per `BUILD_GUIDE.md`).
2. Clone your repository or copy the corresponding machine subfolder to `/opt/<machine-name>` on the VM.
3. Run the one-command deployment script:
   ```bash
   chmod +x deploy.sh
   sudo ./deploy.sh
   ```
4. The script automatically installs Docker & Compose if needed, builds the container image with all intentional vulnerabilities, and starts all services in the background.

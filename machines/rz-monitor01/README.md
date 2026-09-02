# 🏢 VulnCorp — Machine 6: rz-monitor01 (Monitoring Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Machine 6 in the **Restricted Zone (`172.16.0.30`)** runs Nagios Core and SNMP, exposing the entire enterprise network topology and providing an RCE path via writable monitoring plugins.

---

## 🚀 Quick Start (One-Command Deploy)

Run this on your **Debian 13 VM** (`172.16.0.30`):

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/webserver.git
cd webserver/machines/rz-monitor01

chmod +x deploy.sh
sudo ./deploy.sh
```

---

## 📡 Exposed Ports & Services

| Service | Port | Vulnerability |
|---------|------|---------------|
| **Nagios Web UI** | `80` (`/nagios4`) | **Default Credentials** (`nagiosadmin` / `nagios`), hosts configuration leaks all internal server IPs |
| **SNMP Daemon** | `161/udp` | **Public Community String** (`public`) allowing full MIB walk / network mapping |
| **SSH** | `22` | OpenSSH root login allowed |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. SNMP Walk Topology Discovery
```bash
# Query system info and routing tables
snmpwalk -v2c -c public 172.16.0.30 .1.3.6.1.2.1.1
snmpwalk -v2c -c public 172.16.0.30 .1.3.6.1.2.1.4
```

### 2. Nagios Web Console Login
Access `http://172.16.0.30/nagios4/` with credentials `nagiosadmin` : `nagios`.
Inspect monitored hosts to map out:
- `rz-db01` (`172.16.0.10`)
- `int-dc01` (`192.168.1.10`)
- `int-erp01` (`192.168.1.20`)
- `int-files01` (`192.168.1.40`)
- `int-backup01` (`192.168.1.50`)

### 3. Writable Nagios Plugin Privesc
The directory `/usr/lib/nagios/plugins/` is world-writable (`chmod 777`).

---

## 🏆 Flags

- **Nagios Flag:** `/etc/nagios4/flag.txt` (`VULN{n4g10s_d3f4ult}`)
- **SNMP Leak Flag:** `/tmp/snmp_flag.txt` (`VULN{snmp_c0mmun1ty_l34k}`)
- **Root Flag:** `/root/root.txt` (`VULN{m0n1t0r_r00t3d_m4ch1n3_6}`)

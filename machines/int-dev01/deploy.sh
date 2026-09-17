#!/bin/bash
# ================================================================
# VulnCorp — Machine 9: int-dev01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp DevOps (int-dev01)      "
echo "============================================="

# Detect the VM's outbound IP to show correct access URLs
VM_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_VM_IP")

# Ensure curl and nc are available (some fresh Debian VMs lack them)
if ! command -v curl &> /dev/null || ! command -v nc &> /dev/null; then
    echo "[*] Installing curl and netcat..."
    apt-get update -qq && apt-get install -y -qq curl netcat-openbsd
fi

if ! command -v docker &> /dev/null; then
    echo "[*] Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi

if ! docker compose version &> /dev/null; then
    echo "[*] Installing Docker Compose plugin..."
    apt-get update && apt-get install -y docker-compose-v2
fi

echo "[*] Building and starting int-dev01 container..."
docker compose up -d --build

echo ""
echo "[*] Waiting for all services to come up inside the container..."
echo "    (GitLab takes 2-3 minutes on first boot — please be patient)"
echo ""

# ── Health check function ─────────────────────────────────────────────────────
check_port() {
    local name=$1
    local host=$2
    local port=$3
    local timeout=${4:-120}
    printf "    %-14s [:%-4s] ... " "$name" "$port"
    for i in $(seq 1 $timeout); do
        if curl -sf "http://${host}:${port}" > /dev/null 2>&1 || \
           nc -z "$host" "$port" 2>/dev/null; then
            echo "✅  UP"
            return 0
        fi
        sleep 1
    done
    echo "❌  NOT responding after ${timeout}s"
    return 1
}

# ── Check SSH (nc) ────────────────────────────────────────────────────────────
printf "    %-14s [:%-4s] ... " "SSH" "2222"
for i in $(seq 1 30); do
    if nc -z "${VM_IP}" 2222 2>/dev/null; then
        echo "✅  UP"
        break
    fi
    [ $i -eq 30 ] && echo "❌  NOT responding after 30s"
    sleep 1
done

# ── Check Docker API ──────────────────────────────────────────────────────────
printf "    %-14s [:%-4s] ... " "Docker API" "2375"
for i in $(seq 1 30); do
    if curl -sf "http://${VM_IP}:2375/version" > /dev/null 2>&1; then
        echo "✅  UP"
        break
    fi
    [ $i -eq 30 ] && echo "❌  NOT responding after 30s"
    sleep 1
done

# ── Check Jenkins ─────────────────────────────────────────────────────────────
check_port "Jenkins" "${VM_IP}" "8080" 120

# ── Check GitLab ──────────────────────────────────────────────────────────────
check_port "GitLab" "${VM_IP}" "80" 240

echo ""
echo "============================================="
echo "  int-dev01 DEPLOYED SUCCESSFULLY!           "
echo "============================================="
echo "  GitLab (root/gitlab_root_pass): http://${VM_IP}:80"
echo "  Jenkins (No Auth):              http://${VM_IP}:8080"
echo "  Docker API (No TLS):            curl http://${VM_IP}:2375/version"
echo "  SSH (developer/dev123):         ssh developer@${VM_IP} -p 2222"
echo "============================================="
echo ""
echo "  📋 Debug logs (if anything failed):"
echo "     sudo docker exec -it vulncorp-dev01 cat /var/log/dockerd.log"
echo "     sudo docker exec -it vulncorp-dev01 cat /var/log/gitlab-reconfigure.log"
echo "     sudo docker exec -it vulncorp-dev01 journalctl -u jenkins"
echo "============================================="


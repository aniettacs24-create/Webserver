#!/bin/bash
# ============================================================================
#  VulnCorp — int-dev01 entrypoint
#  Starts: SSH | Docker daemon (no TLS) | Jenkins (no auth) | GitLab CE
# ============================================================================
set -e

echo "============================================="
echo "  VulnCorp DevOps Server (int-dev01)         "
echo "============================================="

# ── 1. SSH ───────────────────────────────────────────────────────────────────
echo "[*] Starting SSH..."
service ssh start
echo "[+] SSH is up on :22"

# ── 2. Docker daemon — TCP on 2375 with NO TLS (vulnerability) ───────────────
echo "[*] Starting Docker daemon (API exposed on 0.0.0.0:2375 — NO TLS)..."
# Write daemon config to expose TCP without TLS
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "hosts": ["fd://", "tcp://0.0.0.0:2375"],
  "tls": false
}
EOF

# Start dockerd in background; redirect its output to a log file
dockerd --config-file /etc/docker/daemon.json > /var/log/dockerd.log 2>&1 &
DOCKERD_PID=$!

# Wait for dockerd to be ready (up to 30 seconds)
echo "[*] Waiting for Docker daemon to be ready..."
for i in $(seq 1 30); do
    if docker -H tcp://127.0.0.1:2375 info > /dev/null 2>&1; then
        echo "[+] Docker daemon ready (PID ${DOCKERD_PID}), API on :2375"
        break
    fi
    [ $i -eq 30 ] && echo "[!] WARNING: dockerd did not become ready in 30s" && break
    sleep 1
done

# ── 3. Jenkins — no authentication (vulnerability) ────────────────────────────
echo "[*] Starting Jenkins (no auth) on :8080..."
export JENKINS_HOME=/var/lib/jenkins
export JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Start Jenkins WAR directly (no init.d script since we installed via WAR)
sudo -u jenkins \
    java $JAVA_OPTS \
    -jar /usr/share/jenkins.war \
    --httpPort=8080 \
    --prefix=/ \
    > /var/log/jenkins/jenkins.log 2>&1 &

# Wait for Jenkins to be ready (up to 90 seconds — it's slow on first boot)
echo "[*] Waiting for Jenkins to be ready..."
for i in $(seq 1 90); do
    if curl -sf http://127.0.0.1:8080 > /dev/null 2>&1; then
        echo "[+] Jenkins is up on :8080"
        break
    fi
    [ $i -eq 90 ] && echo "[!] WARNING: Jenkins did not become ready in 90s" && break
    sleep 1
done

# ── 4. GitLab CE — CVE-2021-22205 (vulnerability) ─────────────────────────────
echo "[*] Starting GitLab CE (vulnerable to CVE-2021-22205) on :80..."
# Pre-configure external URL and root password
cat > /etc/gitlab/gitlab.rb <<'EOF'
external_url 'http://localhost'
gitlab_rails['initial_root_password'] = 'gitlab_root_pass'
gitlab_rails['initial_shared_runners_registration_token'] = 'disabled'
nginx['listen_port'] = 80
EOF

# Run gitlab-ctl reconfigure only if first start (flag file doesn't exist)
if [ ! -f /etc/gitlab/.configured ]; then
    echo "[*] Running gitlab-ctl reconfigure (first boot — this may take 2-3 mins)..."
    gitlab-ctl reconfigure > /var/log/gitlab-reconfigure.log 2>&1 && \
        touch /etc/gitlab/.configured
else
    echo "[*] GitLab already configured, starting services..."
    gitlab-ctl start > /var/log/gitlab-start.log 2>&1
fi

# Wait for GitLab to be ready (up to 3 minutes)
echo "[*] Waiting for GitLab to be ready..."
for i in $(seq 1 180); do
    if curl -sf http://127.0.0.1:80 > /dev/null 2>&1; then
        echo "[+] GitLab is up on :80"
        break
    fi
    [ $i -eq 180 ] && echo "[!] WARNING: GitLab did not become ready in 3 mins" && break
    sleep 1
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "============================================="
echo "  Services Status:"
echo "  GitLab:     http://localhost:80  (root/gitlab_root_pass)"
echo "  Jenkins:    http://localhost:8080 (NO AUTH)"
echo "  Docker API: curl http://localhost:2375/version  (NO TLS!)"
echo "  SSH:        Port 22 (host maps to :2222)"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="

# Verify all ports are actually listening
echo "[*] Port check:"
ss -lntp 2>/dev/null | grep -E ':22|:80|:2375|:8080' || \
    netstat -lntp 2>/dev/null | grep -E ':22|:80|:2375|:8080' || true

# Keep the container alive
exec tail -f /dev/null


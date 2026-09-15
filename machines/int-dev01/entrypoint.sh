#!/bin/bash
echo "============================================="
echo "  VulnCorp DevOps Server (int-dev01)         "
echo "============================================="
echo "[*] Starting SSH..."
service ssh start

echo "[*] Starting Docker daemon (API on 0.0.0.0:2375 — NO TLS)..."
dockerd -H fd:// -H tcp://0.0.0.0:2375 &
sleep 5

echo "[*] Starting GitLab CE (vulnerable ver — CVE-2021-22205)..."
docker run -d \
  --name vulncorp-gitlab \
  --hostname vulncorp-gitlab \
  --restart always \
  -p 80:80 \
  -e GITLAB_OMNIBUS_CONFIG="external_url 'http://localhost'; gitlab_rails['initial_root_password'] = 'gitlab_root_pass'" \
  -v gitlab_config:/etc/gitlab \
  -v gitlab_data:/var/opt/gitlab \
  gitlab/gitlab-ce:14.0.12-ce.0

echo "[*] Starting Jenkins (no auth)..."
docker run -d \
  --name vulncorp-jenkins \
  --restart always \
  -p 8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --user root \
  -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
  jenkins/jenkins:2.387.1

echo ""
echo "  GitLab:     http://localhost:80  (root/gitlab_root_pass)"
echo "  Jenkins:    http://localhost:8080 (NO AUTH)"
echo "  Docker API: curl http://localhost:2375/version  (NO TLS!)"
echo "  SSH:        Port 22 (inside container, host maps to 2222)"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null

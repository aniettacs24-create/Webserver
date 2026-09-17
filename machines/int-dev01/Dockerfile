FROM ubuntu:24.04

LABEL maintainer="VulnCorp Lab"
LABEL description="int-dev01 — GitLab CVE-2021-22205 + Jenkins No Auth + Docker API Exposed"
LABEL machine="9"

ENV DEBIAN_FRONTEND=noninteractive

# ── Base tools ────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    curl wget gnupg ca-certificates lsb-release \
    net-tools netcat-openbsd iproute2 procps vim sudo git \
    && rm -rf /var/lib/apt/lists/*

# ── Java (required for Jenkins) ───────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# ── Jenkins (native — pinned version, auth disabled = vulnerability) ──────────
RUN curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
      | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
      https://pkg.jenkins.io/debian-stable binary/" \
      > /etc/apt/sources.list.d/jenkins.list \
    && apt-get update && apt-get install -y --no-install-recommends jenkins \
    && rm -rf /var/lib/apt/lists/*

# ── Docker CE (for the exposed unauthenticated Docker API vulnerability) ──────
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /usr/share/keyrings/docker-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends \
      docker-ce docker-ce-cli containerd.io docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# ── SSH hardening off (intentionally weak for lab) ────────────────────────────
RUN mkdir -p /var/run/sshd && ssh-keygen -A

# ── Copy and run setup scripts at BUILD time (users, secrets, flags) ──────────
COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/setup/*.sh /entrypoint.sh

# Bake in users/secrets/flags during image build
RUN /opt/setup/setup_dev.sh

# ── Jenkins: disable setup wizard and authentication (vulnerability) ───────────
RUN mkdir -p /var/lib/jenkins/init.groovy.d
COPY setup/jenkins_disable_security.groovy /var/lib/jenkins/init.groovy.d/disable-security.groovy
RUN chown -R jenkins:jenkins /var/lib/jenkins 2>/dev/null || true

# ── Jenkins: JAVA_OPTS to skip setup wizard ───────────────────────────────────
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

EXPOSE 22 80 2375 8080

ENTRYPOINT ["/entrypoint.sh"]

FROM ubuntu:24.04

LABEL maintainer="VulnCorp Lab"
LABEL description="int-dev01 — GitLab CVE-2021-22205 + Jenkins No Auth + Docker API Exposed"
LABEL machine="9"

ENV DEBIAN_FRONTEND=noninteractive

# ── Base tools ────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    curl wget gnupg ca-certificates lsb-release \
    net-tools netcat-openbsd iproute2 procps vim sudo git socat \
    openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# ── GitLab CE (vulnerable version — CVE-2021-22205) ─────────────────────────
# Pinned to 14.0.12 for the CVE.
RUN curl -fsSL https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey \
      | gpg --dearmor -o /usr/share/keyrings/gitlab-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/gitlab-keyring.gpg] \
      https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/ jammy main" \
      > /etc/apt/sources.list.d/gitlab-ce.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gitlab-ce=14.0.12-ce.0 \
    && rm -rf /var/lib/apt/lists/*

# ── Jenkins WAR (direct download — distro-agnostic, no apt repo needed) ─────
# Pin to 2.387.3 LTS — works with Java 17, auth disabled = vulnerability
ENV JENKINS_VERSION=2.387.3
ENV JENKINS_HOME=/var/lib/jenkins
RUN groupadd -r jenkins && useradd -r -g jenkins -d /var/lib/jenkins -s /bin/bash jenkins \
    && mkdir -p /var/lib/jenkins /var/log/jenkins /var/cache/jenkins \
    && curl -fsSL \
       "https://github.com/jenkinsci/jenkins/releases/download/jenkins-${JENKINS_VERSION}/jenkins.war" \
       -o /usr/share/jenkins.war \
    && chown -R jenkins:jenkins /var/lib/jenkins /var/log/jenkins /var/cache/jenkins

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
RUN chown -R jenkins:jenkins /var/lib/jenkins

# ── Jenkins: JAVA_OPTS to skip setup wizard ───────────────────────────────────
ENV JENKINS_OPTS="--httpPort=8080"
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

EXPOSE 22 80 2375 8080

ENTRYPOINT ["/entrypoint.sh"]

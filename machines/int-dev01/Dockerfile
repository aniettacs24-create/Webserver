FROM ubuntu:24.04

LABEL maintainer="VulnCorp Lab"
LABEL description="int-dev01 — GitLab CVE-2021-22205 + Jenkins No Auth + Docker API Exposed"
LABEL machine="9"

ENV DEBIAN_FRONTEND=noninteractive

# Install Docker-in-Docker + tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    docker.io \
    docker-compose-v2 \
    openssh-server \
    curl wget net-tools vim sudo git \
    && rm -rf /var/lib/apt/lists/*

COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh
RUN mkdir -p /var/run/sshd && ssh-keygen -A

# Expose Docker API without TLS (critical vuln)
RUN mkdir -p /etc/systemd/system/docker.service.d

EXPOSE 22 80 2222 2375 8080

ENTRYPOINT ["/entrypoint.sh"]

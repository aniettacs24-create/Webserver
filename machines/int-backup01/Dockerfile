FROM debian:bookworm-slim

LABEL maintainer="VulnCorp Lab"
LABEL description="int-backup01 — rsync No Auth + Writable Cron Privesc"
LABEL machine="11"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    rsync \
    openssh-server \
    cron \
    curl wget net-tools vim sudo python3 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash backupadmin && echo "backupadmin:backup123" | chpasswd && \
    usermod -aG sudo backupadmin

COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh
RUN mkdir -p /var/run/sshd && ssh-keygen -A
RUN /opt/setup/setup_backup.sh

EXPOSE 22 873

ENTRYPOINT ["/entrypoint.sh"]

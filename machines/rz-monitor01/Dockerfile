FROM debian:bookworm-slim

LABEL maintainer="VulnCorp Lab"
LABEL description="rz-monitor01 — Nagios Default Creds + SNMP Public Community"
LABEL machine="6"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    nagios4 nagios-plugins \
    snmpd snmp \
    apache2 php libapache2-mod-php \
    openssh-server \
    curl wget net-tools vim sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash monitor && echo "monitor:monitor123" | chpasswd

COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh
RUN mkdir -p /var/run/sshd && ssh-keygen -A
RUN /opt/setup/setup_monitor.sh

EXPOSE 22 80 161/udp

ENTRYPOINT ["/entrypoint.sh"]

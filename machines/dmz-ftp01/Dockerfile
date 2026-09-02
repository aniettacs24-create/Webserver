FROM debian:bookworm-slim

LABEL maintainer="VulnCorp Lab"
LABEL description="dmz-ftp01 — Intentionally Vulnerable FTP Server (Anon Write, ProFTPD mod_copy)"
LABEL machine="3"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    vsftpd \
    proftpd \
    apache2 \
    openssh-server \
    python3 \
    curl wget net-tools vim sudo ftp \
    && rm -rf /var/lib/apt/lists/*

# Create FTP user
RUN useradd -m -s /bin/bash ftpuser && echo "ftpuser:ftp123" | chpasswd

# Directories for FTP pub
RUN mkdir -p /var/ftp/pub/keys && chmod -R 777 /var/ftp

# Copy setup scripts
COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh
RUN /opt/setup/setup_ftp.sh
RUN /opt/setup/setup_breadcrumbs.sh

RUN mkdir -p /var/run/sshd && ssh-keygen -A

EXPOSE 21 22 80 2121 40000-40100

ENTRYPOINT ["/entrypoint.sh"]

FROM debian:bookworm-slim

LABEL maintainer="VulnCorp Lab"
LABEL description="Intentionally Vulnerable Web Server - FOR EDUCATIONAL USE ONLY"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# ── Install packages ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    openssh-server \
    vsftpd \
    cron \
    sudo \
    curl \
    wget \
    nmap \
    net-tools \
    iputils-ping \
    vim \
    nano \
    gcc \
    make \
    && rm -rf /var/lib/apt/lists/*

# ── Python dependencies ──────────────────────────────────────────
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir flask

# ── Create vulnerable users ──────────────────────────────────────
# webuser  — the web application runs as this user (initial shell target)
# backup   — has sudo misconfiguration
RUN useradd -m -s /bin/bash webuser && \
    echo "webuser:webuser123" | chpasswd && \
    useradd -m -s /bin/bash backup && \
    echo "backup:backup2024" | chpasswd

# ── Copy application files ───────────────────────────────────────
COPY app/ /opt/vulncorp/app/
RUN mkdir -p /opt/vulncorp/app/uploads && \
    mkdir -p /opt/vulncorp/db && \
    mkdir -p /opt/vulncorp/app/static/docs && \
    chown -R webuser:webuser /opt/vulncorp

# ── Copy and run setup scripts ───────────────────────────────────
COPY setup/ /opt/setup/
RUN chmod +x /opt/setup/*.sh

# ── Run vulnerability setup ──────────────────────────────────────
RUN /opt/setup/setup_privesc.sh
RUN /opt/setup/setup_services.sh
RUN /opt/setup/setup_breadcrumbs.sh

# ── Copy entrypoint ──────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ── Expose ports ─────────────────────────────────────────────────
# 80   = Web Application (Flask)
# 22   = SSH
# 21   = FTP
EXPOSE 80 22 21

# ── Start all services ───────────────────────────────────────────
ENTRYPOINT ["/entrypoint.sh"]

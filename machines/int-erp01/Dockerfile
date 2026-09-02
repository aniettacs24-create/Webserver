FROM ubuntu:24.04

LABEL maintainer="VulnCorp Lab"
LABEL description="int-erp01 — Flask ERP with SQLi, IDOR, SSRF"
LABEL machine="8"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
    postgresql postgresql-contrib \
    openssh-server \
    curl wget net-tools vim sudo \
    && pip3 install flask flask-sqlalchemy psycopg2-binary requests --break-system-packages \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash erpuser && echo "erpuser:Erp@User2024" | chpasswd

COPY app/ /opt/erp_app/
COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh
RUN mkdir -p /var/run/sshd && ssh-keygen -A

EXPOSE 22 80 5432

ENTRYPOINT ["/entrypoint.sh"]

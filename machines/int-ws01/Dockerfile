FROM debian:bookworm-slim

LABEL maintainer="VulnCorp Lab"
LABEL description="int-ws01 — Domain-Joined Workstation Simulation (EternalBlue, PrintNightmare, Stored Creds)"
LABEL machine="12"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    samba samba-common \
    openssh-server \
    python3 python3-pip \
    curl wget net-tools vim sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ws_admin && echo "ws_admin:Desktop@2024" | chpasswd && \
    usermod -aG sudo ws_admin && \
    useradd -m -s /bin/bash john.doe && echo "john.doe:Corp@Admin2024" | chpasswd

COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh
RUN mkdir -p /var/run/sshd && ssh-keygen -A
RUN /opt/setup/setup_workstation.sh

EXPOSE 22 80 139 445

ENTRYPOINT ["/entrypoint.sh"]

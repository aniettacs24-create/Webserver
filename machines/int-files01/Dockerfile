FROM debian:bookworm-slim

LABEL maintainer="VulnCorp Lab"
LABEL description="int-files01 — Samba SMBv1 (EternalBlue) + NFS no_root_squash"
LABEL machine="10"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    samba samba-common \
    nfs-kernel-server nfs-common \
    openssh-server \
    curl wget net-tools vim sudo python3 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash fileuser && echo "fileuser:File@User2024" | chpasswd && \
    useradd -m -s /bin/bash hruser   && echo "hruser:HR@User2024"    | chpasswd

COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh
RUN mkdir -p /var/run/sshd && ssh-keygen -A
RUN /opt/setup/setup_files.sh

EXPOSE 22 139 445 2049

ENTRYPOINT ["/entrypoint.sh"]

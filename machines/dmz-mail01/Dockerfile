FROM debian:bookworm-slim

LABEL maintainer="VulnCorp Lab"
LABEL description="dmz-mail01 — Intentionally Vulnerable Mail Server (Open Relay, Plaintext Auth)"
LABEL machine="2"

ENV DEBIAN_FRONTEND=noninteractive

# Install all required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    postfix \
    dovecot-core \
    dovecot-imapd \
    dovecot-pop3d \
    apache2 \
    libapache2-mod-php \
    php \
    openssh-server \
    curl \
    wget \
    net-tools \
    vim \
    sudo \
    telnet \
    swaks \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create mail users with weak passwords
RUN useradd -m -s /bin/bash admin       && echo "admin:Admin@2024!"     | chpasswd && \
    useradd -m -s /bin/bash sysadmin    && echo "sysadmin:Sysadmin#99"  | chpasswd && \
    useradd -m -s /bin/bash developer   && echo "developer:dev123"       | chpasswd && \
    useradd -m -s /bin/bash helpdesk    && echo "helpdesk:Helpdesk@123"  | chpasswd

# Create Maildir structure
RUN for user in admin sysadmin developer helpdesk; do \
      mkdir -p /home/$user/Maildir/{cur,new,tmp}; \
      chown -R $user:$user /home/$user/Maildir; \
    done

# Copy setup scripts and entrypoint
COPY setup/   /opt/setup/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh
RUN /opt/setup/setup_mail.sh
RUN /opt/setup/setup_breadcrumbs.sh

# SSH host keys
RUN mkdir -p /var/run/sshd && ssh-keygen -A

EXPOSE 22 25 110 143 80

ENTRYPOINT ["/entrypoint.sh"]

#!/bin/bash
# ================================================================
# setup_mail.sh — Postfix + Dovecot Vulnerability Configuration
# ================================================================
set -e

echo "[+] Configuring Postfix (Open Relay)..."
cat > /etc/postfix/main.cf << 'EOF'
myhostname = mail.vulncorp.local
mydomain = vulncorp.local
myorigin = $mydomain
inet_interfaces = all
inet_protocols = ipv4
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# OPEN RELAY — intentional vulnerability
mynetworks = 0.0.0.0/0
relay_domains = *

home_mailbox = Maildir/
smtpd_banner = $myhostname ESMTP Postfix (Debian/GNU)

# No TLS (intentional cleartext)
smtpd_use_tls = no
smtp_use_tls = no

# VRFY/EXPN enabled — user enumeration (intentional)
disable_vrfy_command = no
EOF

echo "[+] Configuring Dovecot (Plaintext Auth)..."
mkdir -p /etc/dovecot
cat > /etc/dovecot/dovecot.conf << 'EOF'
protocols = imap pop3
listen = *

# Plaintext auth with no TLS — intentional vulnerability
disable_plaintext_auth = no
auth_mechanisms = plain login

mail_location = maildir:~/Maildir

passdb {
  driver = pam
}

userdb {
  driver = passwd
}

service imap-login {
  inet_listener imap {
    port = 143
  }
}
EOF

echo "[+] Configuring weak SSH..."
mkdir -p /var/run/sshd
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
ListenAddress 0.0.0.0
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 10
UsePAM yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo "[+] Mail server setup complete!"

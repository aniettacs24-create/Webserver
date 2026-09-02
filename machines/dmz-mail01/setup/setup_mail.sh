#!/bin/bash
# ================================================================
# setup_mail.sh — Postfix + Dovecot Vulnerability Configuration
# ================================================================
set -e

echo "[+] Setting mailname..."
echo "vulncorp.local" > /etc/mailname

echo "[+] Configuring Postfix (Open Relay)..."
cat > /etc/postfix/main.cf << 'EOF'
compatibility_level = 2
myhostname = mail.vulncorp.local
mydomain = vulncorp.local
myorigin = $mydomain
inet_interfaces = all
inet_protocols = ipv4
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain, vulncorp.local

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

alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
recipient_delimiter = +
EOF

# Ensure aliases file and database exist
if [ ! -f /etc/aliases ]; then
    echo "postmaster: root" > /etc/aliases
    echo "root: admin" >> /etc/aliases
fi
postalias /etc/aliases 2>/dev/null || newaliases 2>/dev/null || true

# Disable chroot in master.cf (crucial for Docker containers)
sed -i 's/^smtp[[:space:]]\+inet[[:space:]]\+n[[:space:]]\+-[[:space:]]\+[yn]/smtp      inet  n       -       n/' /etc/postfix/master.cf

# Ensure spool directories exist
postfix set-permissions 2>/dev/null || true

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

service pop3-login {
  inet_listener pop3 {
    port = 110
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

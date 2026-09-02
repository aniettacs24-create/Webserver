#!/bin/bash
# setup_vpn.sh — VPN Admin Panel Setup (Default Creds, Path Traversal)
set -e

echo "[+] Creating VPN admin Flask app..."
mkdir -p /opt/vpn_admin/templates /etc/openvpn/clients

cat > /opt/vpn_admin/app.py << 'PYEOF'
from flask import Flask, render_template, request, session, redirect, send_file
import os

app = Flask(__name__)
app.secret_key = "vulncorp_vpn_secret_hardcoded_2024"

# DEFAULT CREDENTIALS — intentional vulnerability
ADMIN_USER = "admin"
ADMIN_PASS = "admin"
VPN_CONFIGS = "/etc/openvpn/clients"

@app.route("/")
def index():
    return redirect("/dashboard") if "user" in session else render_template("login.html")

@app.route("/login", methods=["POST"])
def login():
    if request.form.get("username") == ADMIN_USER and request.form.get("password") == ADMIN_PASS:
        session["user"] = ADMIN_USER
        return redirect("/dashboard")
    return render_template("login.html", error="Invalid credentials")

@app.route("/dashboard")
def dashboard():
    if "user" not in session:
        return redirect("/")
    configs = os.listdir(VPN_CONFIGS) if os.path.exists(VPN_CONFIGS) else []
    return render_template("dashboard.html", configs=configs)

@app.route("/download/<filename>")
def download(filename):
    if "user" not in session:
        return redirect("/")
    # PATH TRAVERSAL — no sanitization (intentional)
    return send_file(os.path.join(VPN_CONFIGS, filename), as_attachment=True)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8443, debug=True)
PYEOF

cat > /opt/vpn_admin/templates/login.html << 'EOF'
<!DOCTYPE html><html><head><title>VulnCorp VPN Admin</title></head>
<body style="font-family:sans-serif;max-width:400px;margin:100px auto">
<h2>VulnCorp VPN Admin Panel</h2>
{% if error %}<p style="color:red">{{ error }}</p>{% endif %}
<form method="POST" action="/login">
  <p>Username: <input name="username"></p>
  <p>Password: <input name="password" type="password"></p>
  <input type="submit" value="Login">
</form></body></html>
EOF

cat > /opt/vpn_admin/templates/dashboard.html << 'EOF'
<!DOCTYPE html><html><head><title>VPN Dashboard</title></head>
<body><h2>VPN Config Downloads</h2>
{% for c in configs %}<p><a href="/download/{{ c }}">{{ c }}</a></p>{% endfor %}
</body></html>
EOF

echo "[+] Planting VPN config files with credentials..."
cat > /etc/openvpn/clients/it-admin.ovpn << 'EOF'
client
dev tun
proto udp
remote vpn.vulncorp.local 1194
# Username: it-admin
# Password: ITAdmin@Vpn2024
# Next hop: 192.168.1.10 (Domain Controller)
EOF

cat > /etc/openvpn/clients/backup-agent.ovpn << 'EOF'
client
dev tun
proto udp
remote vpn.vulncorp.local 1194
# Username: backupadmin
# Password: backup123
# Access: 192.168.1.50 (Backup Server)
EOF

echo "[+] Planting leaked VPN log (credential exposure)..."
mkdir -p /var/log/openvpn
cat > /var/log/openvpn/openvpn.log << 'EOF'
Mon Sep 01 08:16:01 2026 AUTH: username=john.doe password=Corp@Admin2024
Mon Sep 01 08:16:02 2026 AUTH: username=Administrator password=Corp@Admin2024
Mon Sep 01 09:00:00 2026 MANAGEMENT: password=admin123 accepted
EOF

echo "[+] Configuring SSH..."
mkdir -p /var/run/sshd
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
MaxAuthTries 10
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo "[+] Planting flags..."
echo "VULN{vpn_s3rv3r_r00t3d_m4ch1n3_5}" > /root/root.txt

echo "[+] VPN setup complete!"

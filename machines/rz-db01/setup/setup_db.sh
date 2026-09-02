#!/bin/bash
# ================================================================
# setup_db.sh — MySQL + PostgreSQL + Redis Vulnerability Setup
# ================================================================
set -e

echo "[+] Configuring MySQL (root/toor, bind all interfaces)..."
service mysql start

mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'toor'; FLUSH PRIVILEGES;"
mysql -u root -ptoor -e "
  CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'toor';
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;"

sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql stop

echo "[+] Loading PII and credential data into MySQL..."
service mysql start

mysql -u root -ptoor << 'EOF'
CREATE DATABASE IF NOT EXISTS vulncorp_prod;
CREATE DATABASE IF NOT EXISTS vulncorp_hr;
CREATE DATABASE IF NOT EXISTS vulncorp_auth;

USE vulncorp_prod;
CREATE TABLE IF NOT EXISTS employees (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50), full_name VARCHAR(100),
  email VARCHAR(100), department VARCHAR(50),
  salary DECIMAL(10,2), ssn VARCHAR(20)
);
INSERT INTO employees VALUES
(1,'john.doe','John Doe','john.doe@vulncorp.local','IT',95000.00,'123-45-6789'),
(2,'jane.smith','Jane Smith','jane.smith@vulncorp.local','Dev',88000.00,'234-56-7890'),
(3,'admin','Admin User','admin@vulncorp.local','IT',110000.00,'345-67-8901'),
(4,'sysadmin','Sys Admin','sysadmin@vulncorp.local','IT',120000.00,'456-78-9012');

CREATE TABLE IF NOT EXISTS internal_credentials (
  id INT AUTO_INCREMENT PRIMARY KEY,
  service VARCHAR(50), host VARCHAR(50),
  username VARCHAR(50), password VARCHAR(100)
);
INSERT INTO internal_credentials VALUES
(1,'SSH','192.168.1.10','john.doe','Corp@Admin2024'),
(2,'RDP','192.168.1.10','Administrator','Corp@Admin2024'),
(3,'MSSQL','192.168.1.20','sa','sa'),
(4,'SSH','192.168.1.30','jenkins','jenkins123'),
(5,'Rsync','192.168.1.50','backupadmin','backup123'),
(6,'GitLab','192.168.1.30','root','gitlab_root_pass');

CREATE TABLE IF NOT EXISTS secret_flags (id INT AUTO_INCREMENT PRIMARY KEY, flag VARCHAR(100));
INSERT INTO secret_flags VALUES
(1,'VULN{mysql_d3fault_cr3ds}'),
(2,'VULN{pii_d4t4_3xfil}');
FLUSH PRIVILEGES;
EOF

service mysql stop

echo "[+] Configuring PostgreSQL (RCE via COPY PROGRAM)..."
service postgresql start

sudo -u postgres psql << 'EOF'
CREATE USER vulncorp_user WITH SUPERUSER PASSWORD 'vulncorp123';
CREATE DATABASE vulncorp_prod OWNER vulncorp_user;
\c vulncorp_prod
CREATE TABLE IF NOT EXISTS pg_flag (id SERIAL PRIMARY KEY, flag TEXT);
INSERT INTO pg_flag VALUES (1, 'VULN{pg_rce_4_th3_w1n}');
EOF

# Allow all hosts (intentional)
echo "host all all 0.0.0.0/0 md5"  >> /etc/postgresql/*/main/pg_hba.conf
sed -i "s/#listen_addresses.*/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
service postgresql stop

echo "[+] Configuring Redis (No Auth, Bind All)..."
sed -i 's/^bind 127.0.0.1.*/bind 0.0.0.0/' /etc/redis/redis.conf
sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf

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
echo "VULN{pii_d4t4_3xfil}"                   > /tmp/pii_flag.txt
echo "VULN{db_s3rv3r_r00t3d_m4ch1n3_4}"        > /root/root.txt

echo "[+] Database setup complete!"

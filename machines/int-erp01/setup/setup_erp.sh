#!/bin/bash
# setup_erp.sh — ERP database + app setup (runs at container startup)
set -e

# Only init if DB doesn't exist yet
if sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw erp_db; then
  echo "[*] ERP DB already initialized, skipping."
  exit 0
fi

echo "[+] Setting up ERP PostgreSQL database..."
sudo -u postgres psql << 'EOF'
CREATE USER erp_admin WITH PASSWORD 'erp_admin123' SUPERUSER;
CREATE DATABASE erp_db OWNER erp_admin;
\c erp_db erp_admin

CREATE TABLE users (
  id SERIAL PRIMARY KEY, username VARCHAR(50),
  password VARCHAR(100), role VARCHAR(20), email VARCHAR(100)
);
INSERT INTO users VALUES
(1,'admin','admin123','admin','admin@vulncorp.local'),
(2,'john.doe','Corp@Admin2024','user','john.doe@vulncorp.local'),
(3,'jane.smith','Jane@Dev2024','developer','jane.smith@vulncorp.local');

CREATE TABLE employee_records (
  id SERIAL PRIMARY KEY, user_id INTEGER, full_name VARCHAR(100),
  salary DECIMAL(10,2), ssn VARCHAR(20), bank_account VARCHAR(30)
);
INSERT INTO employee_records VALUES
(1,1,'Admin User',150000.00,'111-22-3333','VULNCORP-BANK-0001'),
(2,2,'John Doe',95000.00,'222-33-4444','VULNCORP-BANK-0002'),
(3,3,'Jane Smith',88000.00,'333-44-5555','VULNCORP-BANK-0003');

CREATE TABLE flags (id SERIAL PRIMARY KEY, flag_name VARCHAR(50), flag_value VARCHAR(100));
INSERT INTO flags VALUES
(1,'idor_flag','VULN{1d0r_3rp_r3c0rds}'),
(2,'ssrf_flag','VULN{ssrf_1nt3rn4l_s4n}'),
(3,'sqli_flag','VULN{sql1_erp_byp4ss}');
EOF

# Allow connections from all hosts
echo "host all all 0.0.0.0/0 md5"  >> /etc/postgresql/*/main/pg_hba.conf
sed -i "s/#listen_addresses.*/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
service postgresql restart

echo "[+] ERP DB initialized!"

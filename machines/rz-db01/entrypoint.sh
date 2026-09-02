#!/bin/bash
echo "============================================="
echo "  VulnCorp Database Server (rz-db01)         "
echo "============================================="
echo "[*] Starting SSH..."
service ssh start
echo "[*] Starting MySQL (root/toor, bind 0.0.0.0)..."
service mysql start
echo "[*] Starting PostgreSQL (COPY PROGRAM RCE enabled)..."
service postgresql start
echo "[*] Starting Redis (no auth, bind 0.0.0.0)..."
redis-server /etc/redis/redis.conf --daemonize yes
echo ""
echo "  MySQL:      mysql -h localhost -u root -ptoor"
echo "  PostgreSQL: psql -h localhost -U vulncorp_user -d vulncorp_prod"
echo "  Redis:      redis-cli (no auth)"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null

#!/bin/bash
echo "============================================="
echo "  VulnCorp File Server (int-files01)         "
echo "============================================="
echo "[*] Starting SSH..."
service ssh start
echo "[*] Starting Samba (SMBv1, open shares)..."
service smbd start
service nmbd start
echo "[*] Starting NFS (no_root_squash)..."
service nfs-kernel-server start || exportfs -ra
echo ""
echo "  SMB:  smbclient -L \\\\localhost -N"
echo "  NFS:  showmount -e localhost"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null

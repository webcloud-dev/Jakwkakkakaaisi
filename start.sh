#!/bin/bash

set -e

echo "============================================"
echo "   Railway Linux SSH + Tailscale Server     "
echo "============================================"

# ---- Check env vars ----
if [ -z "$TS_AUTHKEY" ]; then
    echo "[ERROR] TS_AUTHKEY is not set!"
    exit 1
fi

if [ -z "$SSH_PASSWORD" ]; then
    echo "[ERROR] SSH_PASSWORD is not set!"
    exit 1
fi

# ---- Set root password ----
echo "[INFO] Setting root password..."
echo "root:$SSH_PASSWORD" | chpasswd

# ---- Start SSH service ----
echo "[INFO] Starting SSH service..."
service ssh start

# ---- Start Tailscale daemon ----
echo "[INFO] Starting tailscaled..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
sleep 5

# ---- Connect Tailscale ----
echo "[INFO] Connecting to Tailscale..."
tailscale up \
  --authkey="$TS_AUTHKEY" \
  --hostname="railway-ssh" \
  --accept-routes \
  --ssh

# ---- Show IP ----
echo "============================================"
echo "    Tailscale IP:"
tailscale ip -4
echo "============================================"
echo "    SSH Login:"
echo "    user: root"
echo "    password: (your SSH_PASSWORD)"
echo "============================================"

# ---- Keep alive ----
tail -f /dev/null

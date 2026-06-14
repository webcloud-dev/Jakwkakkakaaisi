#!/bin/bash

set -e

echo "============================================"
echo "   Railway Linux Desktop + Tailscale VNC    "
echo "============================================"

# ---- Check env vars ----
if [ -z "$TS_AUTHKEY" ]; then
    echo "[ERROR] TS_AUTHKEY is not set!"
    exit 1
fi

if [ -z "$VNC_PASSWORD" ]; then
    echo "[ERROR] VNC_PASSWORD is not set!"
    exit 1
fi

if [ -z "$SSH_PASSWORD" ]; then
    SSH_PASSWORD="$VNC_PASSWORD"
fi

# ---- Set root password ----
echo "[INFO] Setting root password..."
echo "root:$SSH_PASSWORD" | chpasswd

# ---- Setup SSH ----
echo "[INFO] Configuring SSH..."
mkdir -p /var/run/sshd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
service ssh start

# ---- Setup VNC password ----
echo "[INFO] Setting VNC password..."
mkdir -p /root/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# ---- Create xstartup ----
cat > /root/.vnc/xstartup << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
exec startxfce4
EOF
chmod +x /root/.vnc/xstartup

# ---- Start VNC server ----
echo "[INFO] Starting VNC server on :1 (port 5901)..."
vncserver :1 -geometry 1280x800 -depth 24 -localhost no

# ---- Start noVNC ----
echo "[INFO] Starting noVNC on port 6080..."
websockify -D --web=/usr/share/novnc/ 6080 localhost:5901

# ---- Start Tailscale ----
echo "[INFO] Starting tailscaled..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
sleep 5

echo "[INFO] Connecting to Tailscale..."
tailscale up \
  --authkey="$TS_AUTHKEY" \
  --hostname="railway-desktop" \
  --accept-routes \
  --ssh

TS_IP=$(tailscale ip -4)

echo ""
echo "============================================"
echo "   ✅ DESKTOP READY                         "
echo "============================================"
echo " Tailscale IP : $TS_IP"
echo ""
echo " 🖥  VNC Viewer:"
echo "    Host: $TS_IP:5901"
echo "    Password: (your VNC_PASSWORD)"
echo ""
echo " 🌐 Browser (noVNC):"
echo "    http://$TS_IP:6080/vnc.html"
echo ""
echo " 🔐 SSH:"
echo "    ssh root@$TS_IP"
echo "    Password: (your SSH_PASSWORD)"
echo "============================================"

# ---- Keep container alive ----
tail -f /root/.vnc/*.log

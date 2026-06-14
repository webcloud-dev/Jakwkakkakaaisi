FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root
ENV HOME=/root
ENV DISPLAY=:1

# Install desktop environment + VNC + noVNC
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    sudo \
    nano \
    git \
    ca-certificates \
    iptables \
    iproute2 \
    openssh-server \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    dbus-x11 \
    xterm \
    firefox \
    python3 \
    python3-pip \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Setup VNC directory
RUN mkdir -p /root/.vnc

# Copy start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 5901 6080 22

CMD ["/start.sh"]

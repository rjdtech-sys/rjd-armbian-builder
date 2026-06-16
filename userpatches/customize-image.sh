#!/bin/bash
# ============================================================
# AJC PISOWIFI - Armbian Image Customization Script
# ============================================================
# This runs INSIDE the build chroot to customize the image
# before it's finalized.
# ============================================================
# Arguments: $RELEASE $FAMILY $BOARD $BUILD_DESKTOP
# ============================================================

RELEASE=$1
FAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

echo "[AJC] Starting image customization for ${BOARD}..."

# Prevent daemons from auto-starting during build
cat > /usr/sbin/policy-rc.d << 'EOF'
#!/bin/sh
exit 101
EOF
chmod +x /usr/sbin/policy-rc.d

# ========================================
# 1. INSTALL NODE.JS 20.x
# ========================================
echo "[AJC] Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g pm2 node-gyp@10

# ========================================
# 2. INSTALL AJC PISOWIFI
# ========================================
echo "[AJC] Installing AJC PISOWIFI..."

# Copy the overlay files (placed in userpatches/overlay by build system)
# They're available at /tmp/overlay/ during build
if [ -d /tmp/overlay/opt/ajc-pisowifi ]; then
    cp -r /tmp/overlay/opt/ajc-pisowifi /opt/ajc-pisowifi
else
    # Fallback: clone from git
    git clone --depth 1 https://github.com/YOUR_GITHUB/AJC-PISOWIFI-Management-System.git /opt/ajc-pisowifi
fi

cd /opt/ajc-pisowifi

# Copy .env if overlay provided it
if [ -f /tmp/overlay/opt/ajc-pisowifi/.env ]; then
    cp /tmp/overlay/opt/ajc-pisowifi/.env .env
fi

# Install dependencies
npm install --unsafe-perm --no-audit --no-fund --build-from-source

# Build frontend
npm run build

# ========================================
# 3. INSTALL SYSTEMD SERVICES
# ========================================
echo "[AJC] Installing systemd services..."

# Main AJC service
cp /tmp/overlay/etc/systemd/system/ajc-pisowifi.service /etc/systemd/system/
cp /tmp/overlay/etc/systemd/system/ajc-firstboot.service /etc/systemd/system/

# First-boot script
cp /tmp/overlay/usr/local/bin/ajc-firstboot.sh /usr/local/bin/
chmod +x /usr/local/bin/ajc-firstboot.sh

# ========================================
# 4. CONFIGURE SYSTEM
# ========================================
echo "[AJC] Configuring system..."

# Hostname
echo "ajc-orangepi" > /etc/hostname

# MOTD
cp /tmp/overlay/etc/motd /etc/motd 2>/dev/null || true

# SSH banner
cp /tmp/overlay/etc/ssh-banner /etc/ssh-banner 2>/dev/null || true

# Network defaults
cat > /etc/default/ajc-network << 'NETEOF'
WAN_INTERFACE=eth0
LAN_INTERFACE=wlan0
DEFAULT_SSID=AJC-WiFi
DEFAULT_WIFI_PASS=ajc@wifi123
NETEOF

# Enable services
systemctl enable ajc-pisowifi.service
systemctl enable ajc-firstboot.service

# Disable unnecessary services to free resources
systemctl disable bluetooth.service 2>/dev/null || true
systemctl disable hciuart.service 2>/dev/null || true

# ========================================
# 5. SET KERNEL PARAMETERS
# ========================================
echo "[AJC] Setting kernel parameters..."

# Enable IP forwarding (required for hotspot)
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

# ========================================
# 6. CLEANUP
# ========================================
echo "[AJC] Cleaning up..."

# Remove policy
rm -f /usr/sbin/policy-rc.d

# Clean apt
apt-get clean
rm -rf /var/lib/apt/lists/*

# Remove SSH host keys (will be regenerated on first boot)
rm -f /etc/ssh/ssh_host_*

# Clear machine-id
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id

# Clear logs
rm -rf /var/log/*
mkdir -p /var/log

# Clear npm cache
npm cache clean --force
rm -rf /root/.npm/_cacache

# Clear home
rm -rf /root/.bash_history /root/.lesshst

echo "[AJC] Image customization complete for ${BOARD}!"

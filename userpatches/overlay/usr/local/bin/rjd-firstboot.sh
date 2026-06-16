#!/bin/bash
# AJC PISOWIFI - First Boot Configuration Script
# Runs once on first customer boot, then self-destructs

LOGFILE="/var/log/ajc-firstboot.log"
exec 2>> "$LOGFILE"
set -e

echo "[$(date)] AJC First-Boot starting..."

# 1. Generate unique machine hostname
HOSTNAME="ajc-$(head -c 8 /etc/machine-id 2>/dev/null || echo $(tr -dc 'a-f0-9' < /dev/urandom | head -c 8))"
hostnamectl set-hostname "$HOSTNAME"
echo "$HOSTNAME" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts
echo "[$(date)] Hostname set to $HOSTNAME"

# 2. Generate SSH host keys
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    dpkg-reconfigure openssh-server
    echo "[$(date)] SSH host keys regenerated."
fi

# 3. Ensure PM2 persistence
pm2 delete ajc-pisowifi 2>/dev/null || true
cd /opt/ajc-pisowifi
pm2 start server.js --name "ajc-pisowifi" -- -p 80
pm2 save
pm2 startup systemd -u root --hp /root 2>&1 | tail -1 | bash || true

# 4. Set kernel caps
setcap 'cap_net_bind_service,cap_net_admin,cap_net_raw+ep' $(eval readlink -f $(which node))

# 5. Start main service
systemctl enable ajc-pisowifi.service
systemctl start ajc-pisowifi.service

# 6. Mark complete and self-destruct
touch /etc/ajc-firstboot-complete
systemctl disable ajc-firstboot.service
rm /etc/systemd/system/ajc-firstboot.service
systemctl daemon-reload

echo "[$(date)] AJC First-Boot complete!"

#!/bin/bash

# Script Name:	                file-server-deployment.sh
# Author:				          Juan Maldonado
# Date of lastest revision:	 6/10/2024
# Purpose:				           This script automates the deployment of a file server.


# This updates and upgrades the system OS
sudo apt update && sudo apt upgrade -y

# This installs the necessary packages for samba and netdata tools
sudo apt install -y samba netdata

# This configures Samba file
SAMBA_CONF="/etc/samba/smb.conf"
SHARED_DIR="/srv/samba/share"
USERNAME="sambauser"
PASSWORD="password"

# This creates a shared directory and prevents root user access to file server
sudo mkdir -p $SHARED_DIR
sudo chown -R nobody:nogroup $SHARED_DIR
sudo chmod -R 0775 $SHARED_DIR

# This backs up the original Samba configuration file ( in case of rollback needs)
sudo cp $SAMBA_CONF "$SAMBA_CONF.bak"

# This configures Samba, the firewall on linux, and applies changes 
cat <<EOL | sudo tee -a $SAMBA_CONF

[share]
   path = $SHARED_DIR
   browseable = yes
   read only = no
   guest ok = yes
EOL

# Restart Samba service
sudo systemctl restart smbd

# Add Samba user
sudo smbpasswd -a $USERNAME

# Enable and start Netdata
sudo systemctl enable netdata
sudo systemctl start netdata

# Optional: Secure Netdata access (bind to localhost)
NETDATA_CONF="/etc/netdata/netdata.conf"
sudo cp $NETDATA_CONF "$NETDATA_CONF.bak"
sudo sed -i 's/# bind to = ::/bind to = 127.0.0.1/' $NETDATA_CONF
sudo systemctl restart netdata

# Configure firewall (if UFW is enabled)
if sudo ufw status | grep -q "Status: active"; then
    sudo ufw allow Samba
    sudo ufw allow 19999/tcp
fi

echo "Deployment complete. Access Samba share at \\<192.168.1.10>\share and Netdata at http://<192.168.1.10>:19999"

#!/bin/bash

# Color codes for output
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
NC='\e[0m'

echo -e "${GREEN}Starting Assignment 2 Configuration Script...${NC}"

## 1. Set static IP with netplan ##
echo -e "${YELLOW}Checking netplan config...${NC}"
NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"

if grep -q "192.168.16.21" "$NETPLAN_FILE"; then
    echo -e "${GREEN}Static IP already set to 192.168.16.21${NC}"
else
    sudo sed -i '/addresses:/c\            addresses: [192.168.16.21/24]' "$NETPLAN_FILE"
    sudo netplan apply
    echo -e "${GREEN}Static IP set to 192.168.16.21/24${NC}"
fi

## 2. Fix /etc/hosts ##
echo -e "${YELLOW}Updating /etc/hosts...${NC}"
sudo sed -i '/server1/d' /etc/hosts
echo "192.168.16.21 server1" | sudo tee -a /etc/hosts
echo -e "${GREEN}/etc/hosts updated.${NC}"

## 3. Install apache2 and squid ##
echo -e "${YELLOW}Installing apache2 and squid...${NC}"
for pkg in apache2 squid; do
    if ! dpkg -l | grep -qw "$pkg"; then
        sudo apt install -y "$pkg"
        echo -e "${GREEN}$pkg installed.${NC}"
    else
        echo -e "${GREEN}$pkg already installed.${NC}"
    fi
done

## 4. Create users and configure SSH ##
echo -e "${YELLOW}Creating user accounts and SSH keys...${NC}"

USERS=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)

for user in "${USERS[@]}"; do
    if id "$user" &>/dev/null; then
        echo -e "${GREEN}User $user already exists.${NC}"
    else
        sudo useradd -m -s /bin/bash "$user"
        echo -e "${GREEN}User $user created.${NC}"
    fi

    # Generate SSH keys if not already there
    HOME_DIR="/home/$user"
    SSH_DIR="$HOME_DIR/.ssh"
    AUTH_KEYS="$SSH_DIR/authorized_keys"

    sudo mkdir -p "$SSH_DIR"
    sudo chown "$user:$user" "$SSH_DIR"
    sudo chmod 700 "$SSH_DIR"

    # Generate keys only if missing
    if [ ! -f "$SSH_DIR/id_rsa.pub" ]; then
        sudo -u "$user" ssh-keygen -q -t rsa -N "" -f "$SSH_DIR/id_rsa"
    fi
    if [ ! -f "$SSH_DIR/id_ed25519.pub" ]; then

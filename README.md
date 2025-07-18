# assignment2
Script for COMP2137 Assignment 2 - Ubuntu Server Configuration
#!/bin/bash

echo "=== Assignment 2 Configuration Script ==="

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# ---- Configure network interface ----
echo "[*] Configuring network interface..."

NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
TARGET_IP="192.168.16.21/24"
GATEWAY="192.168.16.2"

if ! grep -q "$TARGET_IP" "$NETPLAN_FILE"; then
  cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  ethernets:
    enp0s8:
      addresses:
        - $TARGET_IP
      gateway4: $GATEWAY
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOF
  netplan apply
  echo "[+] Network interface configured."
else
  echo "[✓] Network already configured."
fi

# ---- Update /etc/hosts ----
echo "[*] Updating /etc/hosts..."
HOSTS_LINE="192.168.16.21 server1"

if ! grep -q "server1" /etc/hosts || grep -q "127.0.1.1 server1" /etc/hosts; then
  sed -i '/server1/d' /etc/hosts
  echo "$HOSTS_LINE" >> /etc/hosts
  echo "[+] /etc/hosts updated."
else
  echo "[✓] /etc/hosts already updated."
fi

# ---- Install required software ----
echo "[*] Installing required packages..."

apt update -y

for pkg in apache2 squid; do
  if ! dpkg -l | grep -q "$pkg"; then
    apt install -y "$pkg"
    echo "[+] Installed $pkg"
  else
    echo "[✓] $pkg already installed."
  fi
done

# ---- Create user accounts ----
echo "[*] Creating user accounts and setting up SSH..."

USERS=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)
PUB_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

for user in "${USERS[@]}"; do
  if ! id "$user" &>/dev/null; then
    useradd -m -s /bin/bash "$user"
    echo "[+] Created user: $user"
  else
    echo "[✓] User $user already exists."
  fi

  # Create SSH directory
  SSH_DIR="/home/$user/.ssh"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  touch "$SSH_DIR/authorized_keys"
  chown -R "$user:$user" "$SSH_DIR"

  # Generate SSH keys if not exist
  if [ ! -f "$SSH_DIR/id_rsa.pub" ]; then
    sudo -u "$user" ssh-keygen -t rsa -b 2048 -N "" -f "$SSH_DIR/id_rsa"
  fi
  if [ ! -f "$SSH_DIR/id_ed25519.pub" ]; then
    sudo -u "$user" ssh-keygen -t ed25519 -N "" -f "$SSH_DIR/id_ed25519"
  fi

  # Add public keys to authorized_keys
  cat "$SSH_DIR/id_rsa.pub" "$SSH_DIR/id_ed25519.pub" >> "$SSH_DIR/authorized_keys"

  # Special key for dennis
  if [ "$user" = "dennis" ]; then
    echo "$PUB_KEY" >> "$SSH_DIR/authorized_keys"
    usermod -aG sudo dennis
    echo "[+] Added sudo and key for dennis"
  fi

  chmod 600 "$SSH_DIR/authorized_keys"
done

echo "=== Script completed successfully! ==="

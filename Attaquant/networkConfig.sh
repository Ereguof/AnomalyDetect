#!/bin/bash

set -e

sudo hostnamectl set-hostname ServeurWeb

sudo ifdown enp0s3
sudo ifdown enp0s8

sudo tee /etc/network/interfaces > /dev/null << 'EOF'
# Boucle locale
auto lo
iface lo inet loopback

# Interface NAT (Internet)
auto enp0s3
iface enp0s3 inet dhcp

# Interface Réseau interne (IDS/Logs)
auto enp0s8
iface enp0s8 inet static
    address 10.0.0.3
    netmask 255.255.255.0
EOF

sudo ifup enp0s3
sudo ifup enp0s8

sudo systemctl restart networking || sudo service networking restart




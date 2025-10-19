#!/bin/bash
# Script d'installation pour Debian : nmap, hydra et une petite wordlist

set -e

# Mettre à jour les paquets
sudo apt update

# Installer nmap et hydra
sudo apt install -y nmap hydra openssh-server

# Créer une petite wordlist
cat <<EOL > /root/wordlist.txt
123456
admin
letmein
qwerty
password
welcome
EOL

# Activer et démarrer le service SSH pour permettre les connexions SCP
sudo systemctl enable ssh
sudo systemctl start ssh

echo "Installation terminée. Nmap, Hydra, OpenSSH et wordlist.txt sont prêts. La machine peut recevoir des connexions SCP."


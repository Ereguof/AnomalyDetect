#!/bin/bash
set -e  # Arrête le script si une commande échoue

echo "==== Nettoyage des installations précédentes ===="
sudo systemctl stop snort || true
sudo rm -rf /usr/src/snort-2.9.20* /usr/src/daq-2.0.7* /usr/local/bin/snort
sudo rm -rf /etc/snort /var/log/snort
sudo userdel snort || true
sudo groupdel snort || true

echo "==== Mise à jour du système et installation des dépendances ===="
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential libpcap-dev libpcre2-dev \
  libdumbnet-dev bison flex zlib1g-dev liblzma-dev openssl \
  libssl-dev pkg-config libhwloc-dev cmake libluajit-5.1-dev \
  libnghttp2-dev libpcap0.8-dev git wget curl libtirpc-dev

echo "==== Création de l'utilisateur et du groupe Snort ===="
sudo groupadd -f snort
sudo useradd -r -s /sbin/nologin -c "SNORT_IDS" -g snort snort || true

echo "==== Téléchargement et compilation de DAQ 2.0.7 ===="
cd /usr/src
wget https://www.snort.org/downloads/snort/daq-2.0.7.tar.gz
tar -xvzf daq-2.0.7.tar.gz
cd daq-2.0.7
./configure
make
sudo make install

echo “==== Téléchargement et compilation de PCRE ====”

cd /usr/src
wget https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz
tar -xvzf pcre-8.45.tar.gz
cd pcre-8.45
./configure
make
sudo make install

echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/local-libpcre.conf
sudo ldconfig


echo "==== Téléchargement et compilation de Snort 2.9.20 ===="
cd /usr/src
wget https://www.snort.org/downloads/snort/snort-2.9.20.tar.gz
tar -xvzf snort-2.9.20.tar.gz
cd snort-2.9.20

# Flags pour inclure libtirpc (évite rpc/rpc.h)
export CFLAGS="-I/usr/include/tirpc -I/usr/local/include"
export CPPFLAGS="-I/usr/include/tirpc -I/usr/local/include"
export LDFLAGS="-L/usr/lib/x86_64-linux-gnu -ltirpc"
export LIBS="-ltirpc"

./configure --enable-sourcefire --with-tirpc-includes=/usr/include/tirpc --with-tirpc-libraries=/usr/lib/x86_64-linux-gnu
make
sudo make install

echo "==== Vérification de l'installation ===="
snort -V 
